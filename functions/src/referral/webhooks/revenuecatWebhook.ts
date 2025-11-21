/**
 * RevenueCat Webhook Handler
 * Handles webhook events from RevenueCat, specifically INITIAL_PURCHASE events
 * to grant bonuses to referrers when their referees subscribe
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { grantPromotionalEntitlement } from "../revenuecat/revenuecatHelper";
import {
  sendReferralNotification,
  getUserDisplayName,
} from "../notifications/notificationHelper";
import { NotificationType } from "../notifications/notificationTypes";

const db = admin.firestore();

/**
 * Handle RevenueCat Webhook Events
 */
export const handleRevenueCatWebhook = functions.https.onRequest(
  async (req, res) => {
    // Only accept POST requests
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      console.log("RevenueCat Webhook received:", req.body);

      const event = req.body;

      // Verify webhook has required fields
      if (!event || !event.event) {
        console.error("Invalid webhook payload - missing event");
        res.status(400).send("Invalid payload");
        return;
      }

      // TODO: Verify webhook signature for security
      // const signature = req.headers['x-revenuecat-signature'];
      // if (!verifyWebhookSignature(req.body, signature)) {
      //   res.status(401).send('Invalid signature');
      //   return;
      // }

      const eventType = event.event.type;
      const appUserId = event.event.app_user_id;

      console.log(
        `Processing ${eventType} event for user ${appUserId}`
      );

      // Handle INITIAL_PURCHASE event
      if (eventType === "INITIAL_PURCHASE") {
        await handleInitialPurchase(appUserId, event.event);
      }

      // Handle RENEWAL event (optional - could track long-term conversions)
      if (eventType === "RENEWAL") {
        console.log(
          `Renewal event for ${appUserId} - no action taken`
        );
      }

      // Handle CANCELLATION event (optional - could track churn)
      if (eventType === "CANCELLATION") {
        console.log(
          `Cancellation event for ${appUserId} - no action taken`
        );
      }

      res.status(200).send({ received: true });
    } catch (error) {
      console.error("Error processing RevenueCat webhook:", error);
      res.status(500).send("Internal server error");
    }
  }
);

/**
 * Handle INITIAL_PURCHASE event
 * Grant 2-week bonus to referrer when referred user subscribes
 */
async function handleInitialPurchase(
  userId: string,
  eventData: any
): Promise<void> {
  console.log(`Processing initial purchase for ${userId}`);

  // Check if user was referred
  const verificationDoc = await db
    .collection("referralVerifications")
    .doc(userId)
    .get();

  if (!verificationDoc.exists) {
    console.log(`User ${userId} was not referred - no bonus to grant`);
    return;
  }

  const verification = verificationDoc.data()!;

  // Only grant bonus if user is verified
  if (verification.verificationStatus !== "verified") {
    console.log(
      `User ${userId} is not verified (status: ${verification.verificationStatus}) - no bonus`
    );
    return;
  }

  // Check if we've already granted a paid conversion bonus for this user
  const existingBonusSnapshot = await db
    .collection("referralRewards")
    .where("type", "==", "paid_conversion")
    .where("verifiedUserIds", "array-contains", userId)
    .limit(1)
    .get();

  if (!existingBonusSnapshot.empty) {
    console.log(
      `Paid conversion bonus already granted for ${userId} - skipping`
    );
    return;
  }

  const referrerId = verification.referrerId;

  console.log(
    `Granting 2-week paid conversion bonus to referrer ${referrerId}`
  );

  // Grant 2-week bonus to referrer (14 days)
  const rewardResult = await grantPromotionalEntitlement(
    referrerId,
    14
  );

  if (!rewardResult.success) {
    console.error(
      `Failed to grant bonus to ${referrerId}: ${rewardResult.error}`
    );
    return;
  }

  // Update stats
  await db
    .collection("referralStats")
    .doc(referrerId)
    .update({
      totalPaidConversions: admin.firestore.FieldValue.increment(1),
      "rewardsEarned.totalWeeks":
        admin.firestore.FieldValue.increment(2),
      lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  // Update verification document to mark as paid
  await db
    .collection("referralVerifications")
    .doc(userId)
    .update({
      currentTier: "paid",
      paidConversionDate:
        admin.firestore.FieldValue.serverTimestamp(),
    });

  // Log reward in referralRewards collection
  await db.collection("referralRewards").add({
    referrerId,
    type: "paid_conversion",
    amount: "2 weeks",
    daysGranted: 14,
    verifiedUserIds: [userId],
    revenueCatResponse: {
      expiresAt: rewardResult.expiresAt.toISOString(),
      eventType: "INITIAL_PURCHASE",
    },
    awardedAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: rewardResult.expiresAt,
    status: "awarded",
  });

  // Send notification to referrer
  try {
    const friendName = await getUserDisplayName(userId);

    await sendReferralNotification(
      referrerId,
      NotificationType.FRIEND_SUBSCRIBED,
      {
        friendName,
      }
    );

    console.log(`Notification sent to referrer ${referrerId}`);
  } catch (notificationError) {
    console.error(
      "Error sending paid conversion notification:",
      notificationError
    );
  }

  console.log(
    `✅ Successfully granted 2-week bonus to referrer ${referrerId}`
  );
}

/**
 * Verify webhook signature (placeholder)
 * TODO: Implement signature verification for security
 */
function verifyWebhookSignature(
  payload: any,
  signature: string | undefined
): boolean {
  // RevenueCat provides webhook signatures for verification
  // Implement signature verification here
  // For now, we'll skip verification (not recommended for production)

  if (!signature) {
    console.warn(
      "⚠️ Webhook signature verification not implemented - security risk!"
    );
    return true; // Allow for now
  }

  // TODO: Implement proper signature verification
  // const webhookSecret = functions.config().revenuecat?.webhook_secret;
  // const computedSignature = crypto.createHmac('sha256', webhookSecret)
  //   .update(JSON.stringify(payload))
  //   .digest('hex');
  // return signature === computedSignature;

  return true;
}

