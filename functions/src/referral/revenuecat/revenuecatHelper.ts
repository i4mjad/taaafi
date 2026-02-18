/**
 * RevenueCat Helper Functions
 * High-level helper functions for granting rewards and managing entitlements
 */

import * as admin from "firebase-admin";
import { getRevenueCatClient, RevenueCatClient } from "./revenuecatClient";
import { GrantEntitlementResponse } from "./types";

const ENTITLEMENT_ID = "taaafi_plus";

/**
 * Grant promotional entitlement to a user
 * @param userId - Firebase UID
 * @param durationDays - Number of days to grant access
 * @returns Response with success status and expiration date
 */
export async function grantPromotionalEntitlement(
  userId: string,
  durationDays: number
): Promise<GrantEntitlementResponse> {
  try {
    console.log(
      `Granting ${durationDays} days of ${ENTITLEMENT_ID} to user ${userId}`
    );

    // Validate duration
    if (durationDays < 1) {
      throw new Error("Duration must be at least 1 day");
    }

    if (durationDays > 365) {
      throw new Error("Duration cannot exceed 365 days");
    }

    // Get RevenueCat client
    const client = getRevenueCatClient();

    // Convert days to ISO 8601 duration
    const isoDuration = RevenueCatClient.daysToISO8601Duration(durationDays);

    // Grant entitlement via RevenueCat API
    const response = await client.grantPromotionalEntitlement(
      userId,
      ENTITLEMENT_ID,
      {
        duration: isoDuration,
      }
    );

    if (!response) {
      throw new Error("Failed to grant promotional entitlement");
    }

    // Calculate expiration date
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + durationDays);

    console.log(
      `Successfully granted ${durationDays} days to ${userId}, expires at ${expiresAt.toISOString()}`
    );

    return {
      success: true,
      expiresAt,
    };
  } catch (error) {
    console.error(
      `Error granting promotional entitlement to ${userId}:`,
      error
    );
    return {
      success: false,
      expiresAt: new Date(),
      error: error instanceof Error ? error.message : "Unknown error",
    };
  }
}

/**
 * Get user's current subscription status from RevenueCat
 */
export async function getSubscriptionStatus(
  userId: string
): Promise<{
  hasActiveSubscription: boolean;
  expiresAt: Date | null;
  isPromotional: boolean;
}> {
  try {
    const client = getRevenueCatClient();
    const subscriber = await client.getSubscriber(userId);

    if (!subscriber) {
      return {
        hasActiveSubscription: false,
        expiresAt: null,
        isPromotional: false,
      };
    }

    const entitlement =
      subscriber.subscriber.entitlements[ENTITLEMENT_ID];

    if (!entitlement) {
      return {
        hasActiveSubscription: false,
        expiresAt: null,
        isPromotional: false,
      };
    }

    // Check if expired
    const expiresAt = entitlement.expires_date
      ? new Date(entitlement.expires_date)
      : null;

    const hasActiveSubscription =
      !expiresAt || expiresAt > new Date();

    const isPromotional =
      entitlement.product_identifier === "promotional";

    return {
      hasActiveSubscription,
      expiresAt,
      isPromotional,
    };
  } catch (error) {
    console.error(
      `Error getting subscription status for ${userId}:`,
      error
    );
    return {
      hasActiveSubscription: false,
      expiresAt: null,
      isPromotional: false,
    };
  }
}

/**
 * Check if user has active entitlement
 */
export async function hasActiveEntitlement(
  userId: string
): Promise<boolean> {
  const client = getRevenueCatClient();
  return await client.hasActiveEntitlement(userId, ENTITLEMENT_ID);
}

/**
 * Revoke promotional entitlement (for fraud cases)
 * Note: RevenueCat API v1 doesn't have direct revoke endpoint
 * This is a placeholder for future implementation or manual dashboard action
 */
export async function revokePromotionalEntitlement(
  userId: string
): Promise<void> {
  console.warn(
    `Revoke entitlement requested for ${userId}. This requires manual action in RevenueCat dashboard.`
  );
  // Log to Firestore for admin review
  await admin.firestore().collection("referralAdminActions").add({
    type: "entitlement_revocation_requested",
    userId,
    requestedAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "pending_manual_action",
    instructions:
      "Manually revoke entitlement in RevenueCat dashboard",
  });
}

