import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

const db = admin.firestore();

/**
 * Callable function to validate a device during app startup.
 * Checks if the device is banned before allowing access.
 * Called by the mobile app during the startup security flow.
 */
export const validateDeviceOnAuth = onCall(async (request) => {
  const { deviceId } = request.data;

  if (!deviceId || typeof deviceId !== 'string') {
    throw new HttpsError('invalid-argument', 'deviceId is required');
  }

  try {
    // Check bannedDevices collection (O(1) lookup by document ID)
    const bannedDeviceDoc = await db.collection('bannedDevices').doc(deviceId).get();

    if (bannedDeviceDoc.exists) {
      const data = bannedDeviceDoc.data();

      if (data?.isActive) {
        // Check if ban has expired
        if (data.expiresAt) {
          const expiresAt = data.expiresAt.toDate ? data.expiresAt.toDate() : new Date(data.expiresAt);
          if (expiresAt <= new Date()) {
            // Ban expired — deactivate it
            await bannedDeviceDoc.ref.update({
              isActive: false,
              deactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
              deactivationReason: 'expired',
            });

            return { banned: false };
          }
        }

        logger.info(`Device ${deviceId} is banned. Ban ID: ${data.banId}`);
        return {
          banned: true,
          reason: data.reason ?? 'Device has been restricted',
          expiresAt: data.expiresAt ?? null,
          banId: data.banId,
        };
      }
    }

    // Also check if authenticated user has any active bans
    if (request.auth?.uid) {
      const userBans = await db.collection('bans')
        .where('userId', '==', request.auth.uid)
        .where('isActive', '==', true)
        .where('scope', '==', 'app_wide')
        .limit(1)
        .get();

      if (!userBans.empty) {
        const ban = userBans.docs[0].data();
        return {
          banned: true,
          reason: ban.reason ?? 'Account has been restricted',
          expiresAt: ban.expiresAt ?? null,
          banId: userBans.docs[0].id,
        };
      }
    }

    return { banned: false };
  } catch (error) {
    logger.error(`Error validating device ${deviceId}:`, error);
    // Fail open — allow access if we can't verify
    return { banned: false, error: 'Validation check failed' };
  }
});
