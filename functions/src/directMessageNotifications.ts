import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";

/**
 * Cloud Function to send push notifications when new direct messages are created
 * Triggers on: /direct_messages/{messageId} document creation
 */
export const sendDirectMessageNotification = onDocumentCreated(
  "direct_messages/{messageId}",
  async (event) => {
    try {
      logger.info(`[DM_NOTIFICATION] Starting notification process for message: ${event.params.messageId}`);

      const messageData = event.data?.data();
      if (!messageData) {
        logger.warn("[DM_NOTIFICATION] No message data found");
        return;
      }

      const {
        conversationId,
        senderCpId,
        body,
        isDeleted = false,
        isHidden = false,
        moderation = {},
      } = messageData;

      // Skip notifications for deleted, hidden, or blocked messages
      if (isDeleted || isHidden || moderation?.status === "blocked") {
        logger.info(`[DM_NOTIFICATION] Skipping notification - isDeleted: ${isDeleted}, isHidden: ${isHidden}, moderationStatus: ${moderation?.status}`);
        return;
      }

      const db = getFirestore();

      // Get conversation information
      logger.info(`[DM_NOTIFICATION] Fetching conversation data for: ${conversationId}`);
      const conversationDoc = await db.collection("direct_conversations").doc(conversationId).get();
      if (!conversationDoc.exists) {
        logger.error(`[DM_NOTIFICATION] Conversation ${conversationId} not found`);
        return;
      }

      const conversationData = conversationDoc.data()!;
      const participantCpIds = conversationData.participantCpIds as string[];

      // Find recipient (the other participant)
      const recipientCpId = participantCpIds.find((cpId: string) => cpId !== senderCpId);
      if (!recipientCpId) {
        logger.error("[DM_NOTIFICATION] Could not determine recipient");
        return;
      }

      logger.info(`[DM_NOTIFICATION] Recipient CP ID: ${recipientCpId}`);

      // Check if conversation is muted by recipient
      const mutedBy = conversationData.mutedBy || [];
      if (mutedBy.includes(recipientCpId)) {
        logger.info("[DM_NOTIFICATION] Conversation is muted for recipient");
        return;
      }

      // Get sender's community profile
      logger.info(`[DM_NOTIFICATION] Fetching sender profile: ${senderCpId}`);
      const senderProfileDoc = await db.collection("communityProfiles").doc(senderCpId).get();
      if (!senderProfileDoc.exists) {
        logger.error("[DM_NOTIFICATION] Sender profile not found");
        return;
      }

      const senderProfile = senderProfileDoc.data()!;
      const senderDisplayName = senderProfile.isDeleted
        ? "Deleted User"
        : senderProfile.isAnonymous
          ? "Anonymous User"
          : (senderProfile.displayName || "User");

      // Get recipient's community profile
      logger.info(`[DM_NOTIFICATION] Fetching recipient profile: ${recipientCpId}`);
      const recipientProfileDoc = await db.collection("communityProfiles").doc(recipientCpId).get();
      if (!recipientProfileDoc.exists) {
        logger.error("[DM_NOTIFICATION] Recipient profile not found");
        return;
      }

      const recipientProfile = recipientProfileDoc.data()!;
      if (recipientProfile.isDeleted) {
        logger.info("[DM_NOTIFICATION] Recipient profile is deleted");
        return;
      }

      const recipientUid = recipientProfile.userUID;

      // Check if user has blocked sender
      const blockId = `${recipientCpId}_${senderCpId}`;
      const blockDoc = await db.collection("user_blocks").doc(blockId).get();
      if (blockDoc.exists) {
        logger.info("[DM_NOTIFICATION] Recipient has blocked sender");
        return;
      }

      // Get recipient's user document for FCM token
      logger.info(`[DM_NOTIFICATION] Fetching recipient user document: ${recipientUid}`);
      const recipientUserDoc = await db.collection("users").doc(recipientUid).get();
      if (!recipientUserDoc.exists) {
        logger.error("[DM_NOTIFICATION] Recipient user document not found");
        return;
      }

      const recipientUserData = recipientUserDoc.data()!;

      // Check if account is deleted
      if (recipientUserData.isDeleted) {
        logger.info("[DM_NOTIFICATION] Recipient account is deleted");
        return;
      }

      // Check notification preferences
      const appNotificationsEnabled = recipientUserData.appNotificationsEnabled !== false;
      if (!appNotificationsEnabled) {
        logger.info("[DM_NOTIFICATION] App notifications disabled for recipient");
        return;
      }

      // Get FCM token
      const fcmToken = recipientUserData.messagingToken;
      if (!fcmToken) {
        logger.warn("[DM_NOTIFICATION] No FCM token for recipient");
        return;
      }

      // Truncate message body for notification
      const notificationBody = body.length > 100 ? `${body.substring(0, 100)}...` : body;

      // Determine locale for notification
      const locale = recipientUserData.locale || "english";
      const isArabic = locale === "arabic";

      const notificationTitle = isArabic
        ? `رسالة جديدة من ${senderDisplayName}`
        : `New message from ${senderDisplayName}`;

      // Send notification
      logger.info("[DM_NOTIFICATION] Sending notification");
      const message = {
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          type: "direct_message",
          conversationId: conversationId,
          messageId: event.params.messageId,
          senderCpId: senderCpId,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
          route: `/community/chats/${conversationId}`,
        },
        token: fcmToken,
      };

      try {
        await getMessaging().send(message);
        logger.info("[DM_NOTIFICATION] Notification sent successfully");
      } catch (sendError: any) {
        logger.error("[DM_NOTIFICATION] Error sending notification:", sendError);

        // If token is invalid, clean it up
        if (sendError.code === "messaging/invalid-registration-token" ||
            sendError.code === "messaging/registration-token-not-registered") {
          logger.info("[DM_NOTIFICATION] Cleaning up invalid FCM token");
          await db.collection("users").doc(recipientUid).update({
            messagingToken: null,
          });
        }
      }
    } catch (error) {
      logger.error("[DM_NOTIFICATION] Error in notification function:", error);
    }
  }
);


