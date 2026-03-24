import { onDocumentCreated } from 'firebase-functions/v2/firestore';
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
 * Triggered when a new ban document is created in the bans collection.
 * Automatically populates the bannedDevices collection and ensures
 * restrictedDevices is filled from the user's device list.
 */
export const onBanCreated = onDocumentCreated('bans/{banId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.warn('onBanCreated: No data in event');
    return;
  }

  const banData = snapshot.data();
  const banId = event.params.banId;
  const userId = banData.userId;
  const banType = banData.type;
  const isActive = banData.isActive ?? true;

  if (!isActive) {
    logger.info(`Ban ${banId} created as inactive, skipping device ban creation`);
    return;
  }

  try {
    // Get user's device IDs from their profile
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const userDeviceIds: string[] = userData?.devicesIds ?? [];

    // For user_ban and device_ban: auto-populate restrictedDevices if empty
    if (banType === 'user_ban' || banType === 'device_ban') {
      const restrictedDevices: string[] = banData.restrictedDevices ?? [];

      if (restrictedDevices.length === 0 && userDeviceIds.length > 0) {
        // Auto-populate restrictedDevices with all user devices
        await snapshot.ref.update({
          restrictedDevices: userDeviceIds,
          deviceIds: userDeviceIds,
        });
        logger.info(`Auto-populated ${userDeviceIds.length} devices for ban ${banId}`);
      }

      // Create bannedDevices entries for ALL user devices
      const devicesToBlock = restrictedDevices.length > 0 ? restrictedDevices : userDeviceIds;
      const batch = db.batch();

      for (const deviceId of devicesToBlock) {
        const bannedDeviceRef = db.collection('bannedDevices').doc(deviceId);
        batch.set(bannedDeviceRef, {
          deviceId,
          bannedAt: admin.firestore.FieldValue.serverTimestamp(),
          reason: banData.reason ?? 'Policy violation',
          banId,
          userId,
          isActive: true,
          expiresAt: banData.expiresAt ?? null,
          banType,
        }, { merge: true });
      }

      await batch.commit();
      logger.info(`Created ${devicesToBlock.length} bannedDevices entries for ban ${banId}`);
    }

    // Create bannedIdentifiers entries for email/phone correlation
    try {
      const userRecord = await admin.auth().getUser(userId);
      const identifierBatch = db.batch();
      let identifierCount = 0;

      if (userRecord.email) {
        const emailHash = hashIdentifier(userRecord.email);
        identifierBatch.set(db.collection('bannedIdentifiers').doc(emailHash), {
          identifierType: 'email',
          bannedAt: admin.firestore.FieldValue.serverTimestamp(),
          banId,
          userId,
          isActive: true,
        }, { merge: true });
        identifierCount++;
      }

      if (userRecord.phoneNumber) {
        const phoneHash = hashIdentifier(userRecord.phoneNumber);
        identifierBatch.set(db.collection('bannedIdentifiers').doc(phoneHash), {
          identifierType: 'phone',
          bannedAt: admin.firestore.FieldValue.serverTimestamp(),
          banId,
          userId,
          isActive: true,
        }, { merge: true });
        identifierCount++;
      }

      if (identifierCount > 0) {
        await identifierBatch.commit();
        logger.info(`Created ${identifierCount} bannedIdentifiers entries for ban ${banId}`);
      }
    } catch (authError) {
      // Don't fail the whole function if identifier banning fails
      logger.error(`Failed to create bannedIdentifiers for ban ${banId}:`, authError);
    }
  } catch (error) {
    logger.error(`Error processing ban ${banId}:`, error);
    throw error;
  }
});
