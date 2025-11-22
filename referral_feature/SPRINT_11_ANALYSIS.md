# Sprint 11: RevenueCat Rewards Integration - Analysis

**Date**: November 21, 2025  
**Status**: Ready to Implement

---

## 📊 RevenueCat Configuration Analysis

### Current Setup
- **Project ID**: `proj93a7bb98`
- **Project Name**: Ta'aafi Platform
- **Created**: 2021

### Apps Configured
1. **iOS** (`appede7b17987`)
   - Bundle ID: `com.amjadkhalfan.RebootApp`
   - Type: `app_store`

2. **Android** (`app7f58d43d48`)
   - Package Name: `com.amjadkhalfan.reboot_app_3`
   - Type: `play_store`

3. **Stripe** (`app32b24e9ca0`)
   - Type: `stripe`
   - Account: Not configured yet

### Entitlement Configuration ✅
- **Entitlement ID**: `entl97c8877098`
- **Lookup Key**: `taaafi_plus`
- **Display Name**: "Ta'aafi Plus: allowing user to unlock more potential in their journey"
- **Products Attached**: 2
  - iOS Monthly: `prod86aee8335b` (com.amjadkhalfan.RebootApp.monthlyMain) - P1M + P1W trial
  - Android Monthly: `prod708568971f` (android.taaafi_plus.monthly.basic:taaafi-plus2025) - P1M + P7D grace

### Offering Configuration ✅
- **Offering ID**: `ofrng24673935c7`
- **Lookup Key**: `taaafi_plus_monthly`
- **Display Name**: "Ta'aafi Plus (Monthly)"
- **Is Current**: Yes ✅
- **Package**: `$rc_monthly` (pkge83da6ca7b1)

---

## ✅ Existing Integration (Flutter App)

### RevenueCat SDK
- **Package**: `purchases_flutter: ^9.1.0`
- **Service**: `lib/features/plus/data/services/revenue_cat_service.dart`
- **API Keys**: Configured for iOS and Android
- **User Sync**: Fully integrated with Firebase Auth
- **Entitlement Checking**: `taaafi_plus` (correct ID)

### Subscription Management
- **Repository**: `SubscriptionRepository` with RevenueCat integration
- **Providers**: User-aware subscription providers
- **Sync Service**: `RevenueCatAuthSyncService` handles Firebase UID sync
- **Status**: Production-ready ✅

### User Data Sync
- **isPlusUser**: Synced to Firestore (`users` & `communityProfiles`)
- **Service**: `UserSubscriptionSyncService` updates Firestore on subscription change
- **Cloud Functions**: Can check `isPlusUser(userId)` from `lib/security.ts`

---

## ✅ Existing Referral System

### Cloud Functions
- **Location**: `functions/src/referral/`
- **Triggers**: Complete verification tracking system
- **Notifications**: Fully implemented in Sprint 10
- **Stats**: `referralStats` collection tracks all metrics

### Flutter App
- **Repository**: `ReferralRepositoryImpl`
- **Models**: Complete entities for code, stats, verification
- **Providers**: Dashboard and stats providers ready
- **UI**: Dashboard screen exists

### Firestore Collections
- `referralCodes`: User referral codes
- `referralStats`: Referral statistics (including `totalPaidConversions`)
- `referralVerifications`: Verification progress tracking
- `notificationLogs`: Notification tracking (Sprint 10)

---

## ⚠️ RevenueCat Promotional Entitlements - Important Discovery

### API Limitations
**RevenueCat REST API does NOT support directly granting promotional entitlements with custom durations!**

### Available Options

#### Option 1: Grant Promotional Subscription (Recommended) ⭐
**API**: `POST /v1/subscribers/{app_user_id}/subscriptions`

**Capabilities**:
- Grant promotional subscription with duration
- Supported durations: days, weeks, months
- Automatic expiration handling
- Tracks promotional vs paid subscriptions

**Limitations**:
- Requires RevenueCat Secret API Key (V1 API)
- Need to configure promotional subscription in RevenueCat Dashboard
- Cannot stack promotional subscriptions

**Implementation**:
```typescript
POST https://api.revenuecat.com/v1/subscribers/{firebase_uid}/subscriptions
Headers:
  Authorization: Bearer {SECRET_API_KEY}
  
Body:
{
  "product_id": "promotional_subscription_id",
  "duration": "P30D", // ISO 8601 duration
  "store": "promotional"
}
```

#### Option 2: Use RevenueCat Test Store (Alternative)
- Create test products with custom prices
- Grant via Test Store API
- More flexible but requires Test Store setup

#### Option 3: Custom Implementation (Not Recommended)
- Manage promotional subscriptions in Firestore
- Override `isPlusUser` logic in app
- Loses RevenueCat analytics benefits

### Recommended Approach
**Use Option 1 with promotional subscription products**

We'll need to:
1. Configure promotional products in RevenueCat Dashboard (or use existing products)
2. Get RevenueCat Secret API Key (v1 REST API)
3. Grant subscriptions server-side via Cloud Functions
4. Track promotional vs paid subscriptions in `referralRewards` collection

---

## 🔧 Implementation Strategy

### Phase 1: Setup (Tasks 1-2)
1. Get RevenueCat Secret API Key from user
2. Add to Firebase Functions config
3. Install `axios` for HTTP requests
4. Create RevenueCat helper module

### Phase 2: Core Rewards (Tasks 3-5)
1. Implement reward calculation logic
2. Create `redeemReferralRewards` callable function
3. Handle referee 3-day reward on verification
4. Test promotional subscription granting

### Phase 3: Paid Conversions (Tasks 6-7)
1. Create RevenueCat webhook handler
2. Detect `INITIAL_PURCHASE` events
3. Grant 2-week bonus to referrer
4. Update `totalPaidConversions` in stats

### Phase 4: Flutter Integration (Tasks 8-9)
1. Add `redeemRewards()` method to repository
2. Create redemption UI in dashboard
3. Show reward calculation and redeem button
4. Handle success/error states

### Phase 5: Testing & Validation (Task 10)
1. Test reward calculation math
2. Test promotional subscription granting
3. Test paid conversion detection
4. End-to-end testing with real users

---

## 📝 Required Information from User

### Critical (Before Implementation)
1. **RevenueCat Secret API Key** (v1 REST API)
   - Location: RevenueCat Dashboard → Project Settings → API Keys
   - Type: Secret Key (starts with `sk_`)
   - Needed for: Server-side subscription granting

2. **Webhook Configuration**
   - Need to configure RevenueCat webhook URL
   - Will point to: `https://{region}-{project-id}.cloudfunctions.net/handleRevenueCatWebhook`

### Optional (Can Configure Later)
3. **Promotional Product IDs**
   - Can use existing monthly products
   - Or create separate promotional products

---

## 🚀 Next Steps

1. **User Action Required**:
   - Provide RevenueCat Secret API Key
   - Confirm webhook configuration approach

2. **Implementation**:
   - Add dependencies and API key to Firebase config
   - Implement RevenueCat helper module
   - Create reward redemption system
   - Add webhook handler
   - Update Flutter UI

3. **Testing**:
   - Test in development with test users
   - Verify promotional subscriptions work
   - Validate webhook events trigger correctly

---

## 📦 Dependencies to Add

### Cloud Functions
```json
{
  "dependencies": {
    "axios": "^1.6.0"  // For RevenueCat API calls
  }
}
```

### Firebase Functions Config
```bash
firebase functions:config:set revenuecat.api_key="sk_XXXXX"
```

---

## ⚠️ Important Considerations

1. **RevenueCat API Rate Limits**
   - v1 API: 2,000 requests/hour
   - Should be sufficient for referral rewards

2. **Promotional Subscription Behavior**
   - Cannot stack with paid subscriptions
   - Promotional period ends when user subscribes
   - Need to handle expiration notifications

3. **Fraud Prevention**
   - Always validate before granting rewards
   - Check `blockedReferrals` before redemption
   - Log all reward grants for audit

4. **User Experience**
   - Rewards should appear immediately in app
   - Need to refresh subscription status after grant
   - Show clear expiration dates

---

## 📋 Files to Create/Modify

### New Files
- `functions/src/referral/revenuecat/revenuecatHelper.ts`
- `functions/src/referral/rewards/rewardCalculator.ts`
- `functions/src/referral/rewards/redeemRewards.ts`
- `functions/src/referral/webhooks/revenuecatWebhook.ts`

### Modified Files
- `functions/package.json` (add axios)
- `functions/src/index.ts` (export new functions)
- `functions/src/referral/handlers/verificationHandler.ts` (add 3-day reward)
- `lib/features/referral/data/repositories/referral_repository_impl.dart`
- `lib/features/referral/domain/repositories/referral_repository.dart`
- `lib/features/referral/presentation/screens/referral_dashboard_screen.dart`

### New Models (Flutter)
- `lib/features/referral/domain/entities/redemption_response.dart`
- `lib/features/referral/domain/entities/reward_calculation.dart`

---

**Ready to proceed once RevenueCat Secret API Key is provided!** 🚀

