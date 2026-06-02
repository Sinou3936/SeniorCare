const functions = require('firebase-functions/v1');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { CloudTasksClient } = require('@google-cloud/tasks');

initializeApp();

const db = getFirestore();
const tasksClient = new CloudTasksClient();

const PROJECT_ID = 'seniorcare-5e8a0';
const QUEUE_LOCATION = 'asia-northeast1';
const QUEUE_NAME = 'missed-dose-notifications';
const FUNCTION_URL = `https://asia-northeast3-${PROJECT_ID}.cloudfunctions.net/sendMissedDoseNotification`;

/**
 * medicine_log 생성 시 scheduledTime + 20분에 Cloud Task 예약
 * Task 이름을 (uid + 복용시각)으로 묶어 같은 시간대 약은 Task 1개만 생성
 * (두 번째 이후 로그는 ALREADY_EXISTS로 무시 → 보호자에게 슬롯당 알림 1개)
 */
exports.scheduleMissedDoseCheck = functions
  .region('asia-northeast3')
  .firestore.document('users/{uid}/medicine_logs/{logId}')
  .onCreate(async (snap, context) => {
    const log = snap.data();
    if (log.taken) return null;

    const scheduledTime = log.scheduledTime.toDate();
    const notifyAt = new Date(scheduledTime.getTime() + 20 * 60 * 1000);
    const now = new Date();

    if (notifyAt <= now) return null;

    const uid = context.params.uid;
    const slotMillis = scheduledTime.getTime(); // 같은 시간대 로그는 동일 값

    const parent = tasksClient.queuePath(PROJECT_ID, QUEUE_LOCATION, QUEUE_NAME);

    const task = {
      name: `${parent}/tasks/${uid}_${slotMillis}`, // 슬롯 단위 중복 제거 키
      httpRequest: {
        httpMethod: 'POST',
        url: FUNCTION_URL,
        headers: { 'Content-Type': 'application/json' },
        body: Buffer.from(JSON.stringify({ uid, slotMillis })).toString('base64'),
        oidcToken: {
          serviceAccountEmail: `${PROJECT_ID}@appspot.gserviceaccount.com`,
        },
      },
      scheduleTime: {
        seconds: Math.floor(notifyAt.getTime() / 1000),
      },
    };

    try {
      await tasksClient.createTask({ parent, task });
    } catch (error) {
      if (error.code !== 6) throw error; // 6 = ALREADY_EXISTS, 중복 무시
    }

    return null;
  });

/**
 * Cloud Task 핸들러 — 해당 시간대(slotMillis) 미복용 로그 전부 모아 보호자에게 FCM 1개 발송
 */
exports.sendMissedDoseNotification = functions
  .region('asia-northeast3')
  .https.onRequest(async (req, res) => {
    if (!req.headers['x-cloudtasks-queuename']) {
      res.sendStatus(403);
      return;
    }

    const { uid, slotMillis } = req.body;
    if (!uid || slotMillis == null) {
      res.sendStatus(400);
      return;
    }

    // 해당 시간대 로그 전부 조회
    const slotTime = Timestamp.fromMillis(slotMillis);
    const logsSnap = await db
      .collection('users').doc(uid).collection('medicine_logs')
      .where('scheduledTime', '==', slotTime)
      .get();

    // 미복용 + 미알림 로그만 추림
    const pending = logsSnap.docs.filter(
      (d) => !d.data().taken && !d.data().notified
    );
    if (pending.length === 0) {
      res.sendStatus(200);
      return;
    }

    const names = pending.map((d) => d.data().medicineName || '약');
    const namesText = names.join(', ');

    // 알림 발송 여부와 무관하게 처리한 로그는 notified 표시 (중복 방지)
    const markNotified = async () => {
      const batch = db.batch();
      pending.forEach((d) => batch.update(d.ref, { notified: true }));
      await batch.commit();
    };

    const seniorDoc = await db.collection('users').doc(uid).get();
    if (!seniorDoc.exists) {
      res.sendStatus(200);
      return;
    }

    const linkedFamilyUids = seniorDoc.data().linkedFamilyUids || [];
    if (linkedFamilyUids.length === 0) {
      await markNotified();
      res.sendStatus(200);
      return;
    }

    const messages = [];

    for (const familyUid of linkedFamilyUids) {
      const familyDoc = await db.collection('users').doc(familyUid).get();
      if (!familyDoc.exists) continue;

      // 가족이 미복용 알림을 꺼둔 경우 발송 스킵 (기본값 true)
      if (familyDoc.data().missedDoseNotificationEnabled === false) continue;

      const fcmToken = familyDoc.data().fcmToken;
      if (!fcmToken) continue;

      messages.push({
        token: fcmToken,
        notification: {
          title: '미복용 알림',
          body: `부모님이 ${namesText} 아직 복용하지 않으셨어요`,
        },
        data: {
          type: 'missed_dose',
          seniorUid: uid,
        },
      });

      await db.collection('users').doc(familyUid).collection('notifications').add({
        type: 'missed_dose',
        medicineName: namesText,
        seniorUid: uid,
        isRead: false,
        createdAt: Timestamp.now(),
      });
    }

    if (messages.length > 0) {
      await getMessaging().sendEach(messages);
    }

    await markNotified();
    res.sendStatus(200);
  });
