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
 * 같은 logId로 중복 생성 시 Cloud Tasks가 자동으로 무시
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
    const logId = context.params.logId;

    const parent = tasksClient.queuePath(PROJECT_ID, QUEUE_LOCATION, QUEUE_NAME);

    const task = {
      name: `${parent}/tasks/${logId}`,
      httpRequest: {
        httpMethod: 'POST',
        url: FUNCTION_URL,
        headers: { 'Content-Type': 'application/json' },
        body: Buffer.from(JSON.stringify({ uid, logId })).toString('base64'),
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
 * Cloud Task 핸들러 — taken: false이면 보호자에게 FCM 발송
 */
exports.sendMissedDoseNotification = functions
  .region('asia-northeast3')
  .https.onRequest(async (req, res) => {
    if (!req.headers['x-cloudtasks-queuename']) {
      res.sendStatus(403);
      return;
    }

    const { uid, logId } = req.body;
    if (!uid || !logId) {
      res.sendStatus(400);
      return;
    }

    const logRef = db.collection('users').doc(uid).collection('medicine_logs').doc(logId);
    const logDoc = await logRef.get();

    if (!logDoc.exists || logDoc.data().taken || logDoc.data().notified) {
      res.sendStatus(200);
      return;
    }

    const log = logDoc.data();
    const seniorDoc = await db.collection('users').doc(uid).get();
    if (!seniorDoc.exists) {
      res.sendStatus(200);
      return;
    }

    const linkedFamilyUids = seniorDoc.data().linkedFamilyUids || [];
    if (linkedFamilyUids.length === 0) {
      await logRef.update({ notified: true });
      res.sendStatus(200);
      return;
    }

    const medicineName = log.medicineName || '약';
    const messages = [];

    for (const familyUid of linkedFamilyUids) {
      const familyDoc = await db.collection('users').doc(familyUid).get();
      if (!familyDoc.exists) continue;

      const fcmToken = familyDoc.data().fcmToken;
      if (!fcmToken) continue;

      messages.push({
        token: fcmToken,
        notification: {
          title: '미복용 알림',
          body: `부모님이 ${medicineName}을(를) 아직 드시지 않으셨어요`,
        },
        data: {
          type: 'missed_dose',
          medicineLogId: logId,
          seniorUid: uid,
        },
      });

      await db.collection('users').doc(familyUid).collection('notifications').add({
        type: 'missed_dose',
        medicineName,
        seniorUid: uid,
        medicineLogId: logId,
        isRead: false,
        createdAt: Timestamp.now(),
      });
    }

    if (messages.length > 0) {
      await getMessaging().sendEach(messages);
    }

    await logRef.update({ notified: true });
    res.sendStatus(200);
  });
