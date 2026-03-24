import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();

/**
 * Triggered when a ban document is updated.
 * Handles ban activation/deactivation by updating bannedDevices collection.
 */
export const onBanUpdated = onDocumentUpdated('bans/{banId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();

  if (!before || !after) {
    logger.warn('onBanUpdated: Missing before/after data');
    return;
  }

  const banId = event.params.banId;
  const wasActive = before.isActive ?? true;
  const isActive = after.isActive ?? true;

  // Only process if isActive changed
  if (wasActive === isActive) return;

  const restrictedDevices: string[] = after.restrictedDevices ?? [];
  const userId = after.userId;

  try {
    if (!isActive) {
      // Ban deactivated — check if each device has OTHER active bans
      for (const deviceId of restrictedDevices) {
        const otherActiveBans = await db.collection('bans')
          .where('isActive', '==', true)
          .where('restrictedDevices', 'array-contains', deviceId)
          .limit(2)
          .get();

        // Filter out the current ban from results
        const otherBans = otherActiveBans.docs.filter(doc => doc.id !== banId);

        if (otherBans.length === 0) {
          // No other active bans for this device — deactivate bannedDevices entry
          await db.collection('bannedDevices').doc(deviceId).update({
            isActive: false,
            deactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logger.info(`Deactivated bannedDevices entry for device ${deviceId}`);
        }
      }
      logger.info(`Processed ban deactivation for ban ${banId}`);
    } else {
      // Ban reactivated — re-create bannedDevices entries
      const batch = db.batch();

      for (const deviceId of restrictedDevices) {
        const bannedDeviceRef = db.collection('bannedDevices').doc(deviceId);
        batch.set(bannedDeviceRef, {
          deviceId,
          bannedAt: admin.firestore.FieldValue.serverTimestamp(),
          reason: after.reason ?? 'Policy violation',
          banId,
          userId,
          isActive: true,
          expiresAt: after.expiresAt ?? null,
          banType: after.type,
        }, { merge: true });
      }

      await batch.commit();
      logger.info(`Reactivated ${restrictedDevices.length} bannedDevices entries for ban ${banId}`);
    }
  } catch (error) {
    logger.error(`Error updating ban ${banId}:`, error);
    throw error;
  }
});
