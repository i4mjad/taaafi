# Referral Reward Claim Fix

**Date**: November 23, 2025
**Issue**: Users getting "INTERNAL" error when claiming 3-day Premium reward

## Problem
The `claimRefereeReward` Cloud Function was failing with an internal error because the RevenueCat secret key wasn't being loaded properly.

## Root Cause
- The code was looking for `process.env.REVENUECAT_SECRET_KEY`
- But the key was stored in the deprecated Firebase config: `functions.config().revenuecat.secret_key`
- This caused the RevenueCat API client to initialize without a valid key

## Solution
Updated `functions/src/referral/revenuecat/revenuecatClient.ts` to support both:
1. Modern `.env` file approach (recommended)
2. Legacy Firebase config (for backward compatibility)

## Changes Made

### 1. RevenueCat Client Constructor
```typescript
constructor(secretKey?: string) {
  // Get API key from .env file OR Firebase config (for backward compatibility)
  // Priority: 1. Constructor param, 2. .env, 3. Firebase config (deprecated)
  this.secretKey =
    secretKey ||
    process.env.REVENUECAT_SECRET_KEY ||
    functions.config().revenuecat?.secret_key ||
    "";

  if (!this.secretKey) {
    console.error(
      "❌ RevenueCat: Secret key not configured. Add REVENUECAT_SECRET_KEY to functions/.env file or set via Firebase config"
    );
    throw new Error("RevenueCat secret key is not configured");
  }

  console.log(
    `✅ RevenueCat client initialized with key: ${this.secretKey.substring(0, 8)}...`
  );
}
```

### 2. Enhanced Error Logging
Added detailed logging to help diagnose future issues:
- API request details (URL, body, headers)
- Response data
- Detailed error messages with context

## Testing Instructions

### For the User Who Reported the Issue:
1. **Open the app** and go to your referral dashboard
2. **Navigate to "My Verification Progress"**
3. **Tap "Claim" button** for the 3-day Premium reward
4. **Expected result**: Success message showing "Congratulations! You now have 3 days of Premium access!"

### If Issues Persist:
1. Check Firebase Functions logs:
   ```bash
   firebase functions:log --only claimRefereeReward
   ```
2. Look for these log messages:
   - ✅ `RevenueCat client initialized with key: sk_...`
   - 🎁 `RevenueCat API: Granting taaafi_plus to {userId}`
   - ✅ `Successfully granted 3-day reward to {userId}`

### Test User Available:
- **User ID**: `EHcKp4TAPOgsml5uyUK6wKA7yqW2`
- **Status**: Verified ✅
- **Reward Claimed**: No (eligible to test)
- **Referred by**: `mLEVjhvi9sTrlie0YI8prj5sXOu2`

## RevenueCat Configuration (Verified)
- **Project ID**: `proj93a7bb98`
- **Entitlement ID**: `entl97c8877098`
- **Entitlement Lookup Key**: `taaafi_plus` ✅
- **Apps configured**: 
  - iOS (App Store): `com.amjadkhalfan.RebootApp`
  - Android (Play Store): `com.amjadkhalfan.reboot_app_3`
  - Stripe

## Migration Note
Firebase is deprecating `functions.config()` API after December 31, 2025. The code now supports both methods, but you should migrate to `.env` file approach before that date.

### To Migrate (Recommended):
1. Create `functions/.env` file with:
   ```
   REVENUECAT_SECRET_KEY=sk_GqblrMNfgDajKMEhhIKmjYVyusIsW
   ```
2. Remove the old Firebase config:
   ```bash
   firebase functions:config:unset revenuecat.secret_key
   ```
3. The code will automatically use the `.env` file

## Deployment Status
✅ **Deployed**: November 23, 2025
✅ **Function**: `claimRefereeReward`
✅ **Region**: `us-central1`
✅ **Node Version**: 22

## Next Steps
1. User should test claiming the reward
2. If successful, mark this issue as resolved
3. Consider migrating to `.env` file before Dec 31, 2025
4. Monitor logs for any other users experiencing issues

## Related Files
- `functions/src/referral/rewards/claimRefereeReward.ts`
- `functions/src/referral/revenuecat/revenuecatClient.ts`
- `functions/src/referral/revenuecat/revenuecatHelper.ts`
- `referral_feature/sprint_11_revenuecat_rewards.md`

