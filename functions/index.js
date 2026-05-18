const functions = require('firebase-functions/v1');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const db = getFirestore();

/**
 * 5분마다 실행 — scheduledTime 기준 20분 초과 미복용 로그를 보호자에게 FCM 푸시
 * onUpdate 트리거 대신 pubsub.schedule 사용 (시니어가 앱을 켜지 않아도 동작)
 */
exports.checkMissedDoses = functions
  .region('asia-northeast3')
  .pubsub.schedule('every 5 minutes')
  .onRun(async () => {
    const now = new Date();
    const threshold = new Date(now.getTime() - 20 * 60 * 1000);

    const snapshot = await db.collectionGroup('medicine_logs')
      .where('taken', '==', false)
      .where('notified', '==', false)
      .where('scheduledTime', '<', Timestamp.fromDate(threshold))
      .get();

    if (snapshot.empty) return null;

    for (const doc of snapshot.docs) {
      const log = doc.data();
      // doc.ref.path = users/{uid}/medicine_logs/{logId}
      const uid = doc.ref.parent.parent.id;

      const seniorDoc = await db.collection('users').doc(uid).get();
      if (!seniorDoc.exists) {
        await doc.ref.update({ notified: true });
        continue;
      }

      const linkedFamilyUids = seniorDoc.data().linkedFamilyUids || [];
      if (linkedFamilyUids.length === 0) {
        await doc.ref.update({ notified: true });
        continue;
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
            medicineLogId: doc.id,
            seniorUid: uid,
          },
        });

        await db.collection('users').doc(familyUid).collection('notifications').add({
          type: 'missed_dose',
          medicineName,
          seniorUid: uid,
          medicineLogId: doc.id,
          isRead: false,
          createdAt: Timestamp.now(),
        });
      }

      if (messages.length > 0) {
        await getMessaging().sendEach(messages);
      }

      await doc.ref.update({ notified: true });
    }

    return null;
  });
