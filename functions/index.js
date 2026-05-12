const functions = require('firebase-functions/v1');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const db = getFirestore();

/**
 * medicine_log가 업데이트될 때 실행
 * taken이 false이고 scheduledTime 기준 30분이 지났으면 보호자에게 FCM 푸시
 */
exports.notifyMissedDose = functions
  .region('asia-northeast3')
  .firestore.document('users/{uid}/medicine_logs/{logId}')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const uid = context.params.uid;

    // 이미 복용했으면 스킵
    if (after.taken) return null;

    // scheduledTime 기준 30분이 지나지 않았으면 스킵
    const scheduledTime = after.scheduledTime?.toDate();
    if (!scheduledTime) return null;

    const now = new Date();
    const diffMinutes = (now - scheduledTime) / 1000 / 60;
    if (diffMinutes < 30) return null;

    // 이미 알림 발송했으면 스킵 (중복 방지)
    if (after.notified) return null;

    // 시니어 doc에서 보호자 uid 목록 조회
    const seniorDoc = await db.collection('users').doc(uid).get();
    if (!seniorDoc.exists) return null;

    const linkedFamilyUids = seniorDoc.data().linkedFamilyUids || [];
    if (linkedFamilyUids.length === 0) return null;

    const medicineName = after.medicineName || '약';
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
          medicineLogId: context.params.logId,
          seniorUid: uid,
        },
      });

      // Firestore notifications 컬렉션에 알림 기록
      await db.collection('users').doc(familyUid).collection('notifications').add({
        type: 'missed_dose',
        medicineName,
        seniorUid: uid,
        medicineLogId: context.params.logId,
        isRead: false,
        createdAt: Timestamp.now(),
      });
    }

    if (messages.length > 0) {
      await getMessaging().sendEach(messages);
    }

    // 중복 알림 방지 플래그
    await change.after.ref.update({ notified: true });

    return null;
  });
