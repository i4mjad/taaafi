import { beforeUserCreated } from 'firebase-functions/v2/identity';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { createHash } from 'crypto';

const db = admin.firestore();

/**
 * Hash an identifier (email or phone) using SHA-256 for privacy.
 */
function hashIdentifier(identifier: string): string {
  return createHash('sha256').update(identifier.toLowerCase().trim()).digest('hex');
}

/**
 * Firebase Auth blocking function that runs before a new user is created.
 * Checks if the email or phone is associated with a banned account.
 * Blocks sign-up if a match is found.
 */
export const checkBannedIdentifierBeforeSignup = beforeUserCreated(async (event) => {
  const { email, phoneNumber } = event.data;

  try {
    // Check email
    if (email) {
      const emailHash = hashIdentifier(email);
      const emailDoc = await db.collection('bannedIdentifiers').doc(emailHash).get();

      if (emailDoc.exists) {
        const data = emailDoc.data();
        if (data?.isActive) {
          logger.warn(`Blocked sign-up attempt from banned email: ${emailHash}`);
          throw new Error('This account has been restricted from accessing the application. Contact support for assistance.');
        }
      }
    }

    // Check phone number
    if (phoneNumber) {
      const phoneHash = hashIdentifier(phoneNumber);
      const phoneDoc = await db.collection('bannedIdentifiers').doc(phoneHash).get();

      if (phoneDoc.exists) {
        const data = phoneDoc.data();
        if (data?.isActive) {
          logger.warn(`Blocked sign-up attempt from banned phone: ${phoneHash}`);
          throw new Error('This account has been restricted from accessing the application. Contact support for assistance.');
        }
      }
    }
  } catch (error) {
    // Re-throw our intentional blocks
    if (error instanceof Error && error.message.includes('restricted from accessing')) {
      throw error;
    }
    // Fail open for unexpected errors — don't block legitimate sign-ups
    logger.error('Error checking banned identifiers:', error);
  }
});
