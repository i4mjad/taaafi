/**
 * Referral Program - Initialize Configuration
 * 
 * This function initializes the global referral program configuration
 * in Firestore. It should be called once during initial setup.
 */

import * as admin from "firebase-admin";

/**
 * Initialize the referral program configuration document
 */
export async function initializeReferralConfig(): Promise<void> {
  const db = admin.firestore();

  const configDoc = {
    isEnabled: true,
    verificationRequirements: {
      minAccountAgeDays: 7,
      minForumPosts: 3,
      minInteractions: 5,
      minGroupMessages: 3,
      minActivitiesStarted: 1,
    },
    rewards: {
      usersPerMonth: 5,
      paidConversionBonusWeeks: 2,
    },
    fraudThresholds: {
      lowRisk: 40,
      highRisk: 70,
      autoBlock: 71,
    },
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: "system",
  };

  await db.doc("referralProgram/config/settings").set(configDoc);
  
  console.log("Referral program configuration initialized successfully");
}
