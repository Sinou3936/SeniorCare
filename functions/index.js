const functions = require('firebase-functions/v1');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { CloudTasksClient } = require('@google-cloud/tasks');
const nodemailer = require('nodemailer');

initializeApp();

const db = getFirestore();
const tasksClient = new CloudTasksClient();

const PROJECT_ID = 'seniorcare-5e8a0';
const QUEUE_LOCATION = 'asia-northeast1';
const QUEUE_NAME = 'missed-dose-notifications';
const FUNCTION_URL = `https://asia-northeast3-${PROJECT_ID}.cloudfunctions.net/sendMissedDoseNotification`;

/**
 * 앱 내 문의 폼 → 이메일 발송 (nodemailer + Gmail SMTP).
 * 시크릿: GMAIL_USER(발송 계정), GMAIL_APP_PASSWORD(앱 비밀번호).
 *   firebase functions:secrets:set GMAIL_USER
 *   firebase functions:secrets:set GMAIL_APP_PASSWORD
 */
exports.sendInquiry = functions
  .region('asia-northeast3')
  .runWith({ secrets: ['GMAIL_USER', 'GMAIL_APP_PASSWORD'] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', '인증이 필요합니다.');
    }
    const category = (data && data.category) || '기타';
    const content = ((data && data.content) || '').toString().trim();
    const deviceInfo = ((data && data.deviceInfo) || '알 수 없음')
      .toString()
      .slice(0, 200);
    if (!content) {
      throw new functions.https.HttpsError('invalid-argument', '내용이 비어 있습니다.');
    }
    if (content.length > 5000) {
      throw new functions.https.HttpsError('invalid-argument', '내용이 너무 깁니다.');
    }

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.GMAIL_USER,
        pass: process.env.GMAIL_APP_PASSWORD,
      },
    });

    // 발송=수신 동일 계정(자기 자신에게) — 이메일을 코드에 하드코딩하지 않음
    await transporter.sendMail({
      from: `약봄 문의 <${process.env.GMAIL_USER}>`,
      to: process.env.GMAIL_USER,
      subject: '[약봄 문의]',
      text:
        `카테고리: ${category}\n` +
        `사용자 ID: ${context.auth.uid}\n` +
        `휴대폰 정보: ${deviceInfo}\n` +
        `내용: ${content}\n\n` +
        `조치 부탁드립니다.`,
    });

    return { ok: true };
  });

/** epoch millis → KST 기준 "오전 8시" / "오후 1시 30분" */
function koreanTimeLabel(millis) {
  const d = new Date(millis + 9 * 60 * 60 * 1000); // UTC+9 (KST)
  const hour = d.getUTCHours();
  const minute = d.getUTCMinutes();
  const period = hour < 12 ? '오전' : '오후';
  let h = hour % 12;
  if (h === 0) h = 12;
  const base = `${period} ${h}시`;
  return minute === 0 ? base : `${base} ${minute}분`;
}

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
    const timeLabel = koreanTimeLabel(slotMillis);

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
          body: `부모님이 ${timeLabel} ${namesText} 아직 복용하지 않으셨어요`,
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
