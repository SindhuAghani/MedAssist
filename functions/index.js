const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const DOSES = "MedicationDoses";
const NOTIFICATIONS = "Notifications";
const USERS = "Users";
const GRACE_MINUTES = 15;

exports.sendPushForNotification = onDocumentCreated(
  `${NOTIFICATIONS}/{notificationId}`,
  async (event) => {
    const notification = event.data && event.data.data();
    if (!notification) return;

    const recipientIds = Array.isArray(notification.recipientIds)
      ? notification.recipientIds.filter(Boolean)
      : [];
    if (recipientIds.length === 0) return;

    const tokens = await getTokensForUsers(recipientIds);
    if (tokens.length === 0) {
      logger.info("No FCM tokens for notification recipients", {
        notificationId: event.params.notificationId,
        recipientIds,
      });
      return;
    }

    await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: notification.title || "MindHeal",
        body: notification.body || "",
      },
      data: {
        notificationId: event.params.notificationId,
        type: notification.type || "",
        route: notification.route || "",
        id: notification.routeId || "",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "medication_reminders",
          sound: "default",
        },
      },
    });
  },
);

exports.processMedicationReminders = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Asia/Karachi",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const cutoffDate = new Date(Date.now() - GRACE_MINUTES * 60 * 1000);
    const cutoff = admin.firestore.Timestamp.fromDate(cutoffDate);

    await sendDueReminders(now);
    await escalateUnansweredDoses(cutoff);
  },
);

async function sendDueReminders(now) {
  for (const status of ["pending", "snoozed"]) {
    const snapshot = await db.collection(DOSES)
      .where("status", "==", status)
      .where("scheduledAt", "<=", now)
      .orderBy("scheduledAt")
      .limit(100)
      .get();

    for (const doc of snapshot.docs) {
      const dose = doc.data();
      if (dose.reminderSentAt) continue;

      if (dose.patientId) {
        await createNotification({
          title: "Medication due",
          body: `Time for ${dose.medicationName} ${dose.dosage}.`,
          senderId: "system",
          recipientIds: [dose.patientId],
          type: "dose_reminder",
          route: "/patient-medications",
          routeId: doc.id,
        });
      }

      if (dose.caregiverId) {
        await createNotification({
          title: "Patient medication due",
          body: `${dose.medicationName} ${dose.dosage} is due now.`,
          senderId: "system",
          recipientIds: [dose.caregiverId],
          type: "caregiver_dose_reminder",
          route: "/medication-schedule",
          routeId: doc.id,
        });
      }

      await doc.ref.update({
        reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
}

async function escalateUnansweredDoses(cutoff) {
  for (const status of ["pending", "snoozed"]) {
    const snapshot = await db.collection(DOSES)
      .where("status", "==", status)
      .where("reminderSentAt", "<=", cutoff)
      .orderBy("reminderSentAt")
      .limit(100)
      .get();

    for (const doc of snapshot.docs) {
      const dose = doc.data();
      if (!dose.reminderSentAt || !dose.caregiverId || dose.escalationSentAt || dose.respondedAt) continue;

      await createNotification({
        title: "Dose not confirmed",
        body: `${dose.medicationName} ${dose.dosage} was not confirmed within ${GRACE_MINUTES} minutes.`,
        senderId: "system",
        recipientIds: [dose.caregiverId],
        type: "dose_missed_alert",
        route: "/medication-schedule",
        routeId: doc.id,
      });

      await doc.ref.update({
        status: "missed",
        escalationSentAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
}

async function createNotification({
  title,
  body,
  senderId,
  recipientIds,
  type,
  route,
  routeId,
}) {
  const seenBy = {};
  for (const id of recipientIds) {
    seenBy[id] = false;
  }

  await db.collection(NOTIFICATIONS).add({
    title,
    body,
    senderId,
    recipientIds,
    type,
    route,
    routeId,
    isBroadcast: recipientIds.length > 1,
    seenBy,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    seenAt: null,
  });
}

async function getTokensForUsers(userIds) {
  const tokenSet = new Set();

  for (const userId of userIds) {
    const user = await db.collection(USERS).doc(userId).get();
    if (!user.exists) continue;

    const data = user.data();
    if (data.deviceToken) tokenSet.add(data.deviceToken);
    if (data.fcmToken) tokenSet.add(data.fcmToken);
    if (Array.isArray(data.fcmTokens)) {
      for (const token of data.fcmTokens) {
        if (token) tokenSet.add(token);
      }
    }
  }

  return Array.from(tokenSet);
}
