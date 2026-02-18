# Sprint 11: RevenueCat API Approach

**Date**: November 21, 2025  
**Research Status**: ✅ Complete

---

## 🎯 Chosen Approach: RevenueCat REST API v1

After researching RevenueCat's capabilities, we'll use **RevenueCat's REST API v1** to grant promotional entitlements programmatically.

---

## 📡 API Implementation Strategy

### Method 1: Grant Promotional Entitlements (Primary) ⭐

**Endpoint**: `POST /v1/subscribers/{app_user_id}/entitlements/{entitlement_identifier}/promotional`

**Use Case**: Grant time-limited promotional access to `taaafi_plus` entitlement

```typescript
POST https://api.revenuecat.com/v1/subscribers/{firebase_uid}/entitlements/taaafi_plus/promotional
Headers:
  Authorization: Bearer {SECRET_API_KEY}
  Content-Type: application/json
  
Body:
{
  "duration": "P30D",  // ISO 8601 duration (30 days)
  "start_time_ms": 1700000000000  // Unix timestamp in milliseconds
}
```

**Supported Durations**:
- Days: `P3D` (3 days), `P7D` (7 days), `P14D` (14 days), `P30D` (30 days)
- Weeks: `P1W` (1 week), `P2W` (2 weeks)
- Months: `P1M` (1 month)
- Combined: `P1M14D` (1 month + 14 days)

**Benefits**:
- ✅ Native RevenueCat feature
- ✅ Automatic expiration handling
- ✅ Shows in RevenueCat dashboard
- ✅ Tracked separately from paid subscriptions
- ✅ Works with existing entitlement checks

### Method 2: Get Customer Info (For Validation)

**Endpoint**: `GET /v1/subscribers/{app_user_id}`

**Use Case**: Check current subscription/entitlement status

```typescript
GET https://api.revenuecat.com/v1/subscribers/{firebase_uid}
Headers:
  Authorization: Bearer {SECRET_API_KEY}
```

**Response**:
```json
{
  "subscriber": {
    "entitlements": {
      "taaafi_plus": {
        "expires_date": "2025-12-21T10:30:00Z",
        "product_identifier": "promotional",
        "purchase_date": "2025-11-21T10:30:00Z"
      }
    }
  }
}
```

---

## 🔑 Required API Key

**Type**: RevenueCat Secret API Key (v1 REST API)

**Location**: RevenueCat Dashboard → Project Settings → API Keys → Secret Keys

**Format**: Starts with `sk_` (example: `sk_ABCDefgh123456789`)

**Security**: Must be stored in Firebase Functions config (never in code!)

---

## 🏗️ Implementation Architecture

### Cloud Functions Structure

```
functions/src/referral/
├── revenuecat/
│   ├── revenuecatClient.ts          # Axios-based API client
│   ├── revenuecatHelper.ts          # High-level helpers
│   └── types.ts                     # TypeScript interfaces
├── rewards/
│   ├── rewardCalculator.ts          # Calculate earned rewards
│   ├── redeemRewards.ts             # Callable function
│   └── rewardTypes.ts               # Reward interfaces
└── webhooks/
    └── revenuecatWebhook.ts         # Handle paid conversions
```

### Key Functions

1. **`grantPromotionalEntitlement(userId, days)`**
   - Calculates ISO duration
   - Calls RevenueCat API
   - Returns expiration date
   - Logs to `referralRewards` collection

2. **`calculateUserRewards(userId)`**
   - Queries `referralStats`
   - Calculates: months = floor(verified / 5)
   - Calculates: weeks = paidConversions * 2
   - Returns total days + breakdown

3. **`redeemReferralRewards` (callable)**
   - Validates user has rewards
   - Checks if already redeemed
   - Grants promotional entitlement
   - Sends success notification
   - Logs redemption

4. **`handleRevenueCatWebhook` (HTTP)**
   - Verifies webhook signature
   - Detects `INITIAL_PURCHASE` events
   - Grants 2-week bonus to referrer
   - Updates `totalPaidConversions`

---

## 📊 Reward Calculation Logic

### For Referrer

**Verification Milestones**:
- 5 verified referrals = 1 month Premium (30 days)
- 10 verified referrals = 2 months Premium (60 days)
- Formula: `floor(totalVerified / 5) * 30` days

**Paid Conversion Bonus**:
- Each referred user who subscribes = 2 weeks (14 days)
- Formula: `totalPaidConversions * 14` days

**Total Reward**:
```typescript
const monthsEarned = Math.floor(stats.totalVerified / 5);
const weeksEarned = stats.totalPaidConversions * 2;
const totalDays = (monthsEarned * 30) + (weeksEarned * 7);
```

**Example**:
- 7 verified referrals → 1 month (30 days)
- 2 paid conversions → 4 weeks (28 days)
- **Total**: 58 days Premium

### For Referee

**Verification Reward**:
- Complete all verification tasks = 3 days Premium
- Granted automatically on verification completion
- No redemption needed

---

## 🔒 Security & Fraud Prevention

### Before Granting Rewards

1. **Check Blocked Referrals**:
   ```typescript
   if (stats.blockedReferrals > 0) {
     const adjustedVerified = stats.totalVerified - stats.blockedReferrals;
     // Recalculate rewards with adjusted count
   }
   ```

2. **Check Fraud Flags**:
   ```typescript
   const fraudFlags = await checkRecentFraudFlags(userId);
   if (fraudFlags.length > 0) {
     throw new Error('Rewards suspended due to fraud review');
   }
   ```

3. **Prevent Double Redemption**:
   - Check `referralRewards` collection for recent redemption
   - Track `lastRewardAt` in `referralStats`

### Webhook Verification

```typescript
// Verify RevenueCat webhook signature
const signature = req.headers['x-revenuecat-signature'];
const isValid = verifyWebhookSignature(req.body, signature);
if (!isValid) {
  return res.status(401).send('Invalid signature');
}
```

---

## 📝 Firestore Schema Updates

### New Collection: `referralRewards`

```typescript
interface ReferralReward {
  referrerId: string;
  type: 'verification_milestone' | 'paid_conversion';
  amount: string;  // "1 month" or "2 weeks"
  daysGranted: number;
  verifiedUserIds: string[];  // Contributing users
  revenueCatResponse?: object;
  awardedAt: Timestamp;
  expiresAt: Date;
  status: 'awarded' | 'expired' | 'revoked';
  revocationReason?: string;
}
```

### Update: `referralStats`

```typescript
rewardsEarned: {
  totalMonths: number;
  totalWeeks: number;
  lastRewardAt: Timestamp | null;
  lastRedemptionAt: Timestamp | null;  // NEW
  totalDaysGranted: number;  // NEW
}
```

---

## 🔄 User Flow

### Referrer Redemption Flow

1. User opens Referral Dashboard
2. Sees "Redeem 58 Days Premium" button (if eligible)
3. Taps button → calls `redeemReferralRewards`
4. Cloud Function:
   - Validates eligibility
   - Calculates total days
   - Grants promotional entitlement via RevenueCat API
   - Logs to Firestore
   - Sends notification
5. Returns success with expiration date
6. User's subscription status refreshes
7. `isPlusUser` becomes `true` in Firestore
8. Premium features unlock immediately

### Referee Reward Flow

1. User completes all verification tasks
2. `handleVerificationCompletion` triggered
3. Cloud Function:
   - Marks verification as complete
   - Grants 3-day promotional entitlement
   - Sends celebration notification
4. Premium access activates immediately
5. User sees "You're verified! Enjoy 3 days Premium" notification

### Paid Conversion Flow

1. Referred user purchases subscription (via RevenueCat)
2. RevenueCat sends `INITIAL_PURCHASE` webhook
3. `handleRevenueCatWebhook` function:
   - Verifies webhook signature
   - Checks if user was referred
   - Grants 2-week bonus to referrer
   - Updates `totalPaidConversions`
   - Sends notification to referrer
4. Referrer can redeem additional rewards

---

## 🧪 Testing Strategy

### Development Testing

1. **Test Promotional Entitlement Grant**:
   ```bash
   # Grant 3 days to test user
   curl -X POST https://api.revenuecat.com/v1/subscribers/test_user_id/entitlements/taaafi_plus/promotional \
     -H "Authorization: Bearer sk_TEST_KEY" \
     -d '{"duration": "P3D"}'
   ```

2. **Test Reward Calculation**:
   - Create test `referralStats` with 5 verified users
   - Call `calculateUserRewards`
   - Verify returns 30 days

3. **Test Redemption**:
   - Call `redeemReferralRewards` from Flutter app
   - Verify promotional entitlement granted
   - Check Firestore `referralRewards` document created

4. **Test Webhook**:
   - Simulate RevenueCat webhook event
   - Verify bonus granted to referrer

### Validation Checklist

- [ ] RevenueCat API returns success (200)
- [ ] Promotional entitlement shows in RevenueCat dashboard
- [ ] Flutter app detects `isPlusUser = true`
- [ ] Premium features unlock
- [ ] Firestore documents created correctly
- [ ] Notifications sent
- [ ] Expiration date calculated correctly
- [ ] Fraud checks prevent abuse

---

## 📦 Dependencies

### Cloud Functions

Add to `functions/package.json`:
```json
{
  "dependencies": {
    "axios": "^1.6.2"
  }
}
```

### Firebase Config

```bash
# Set RevenueCat Secret API Key
firebase functions:config:set revenuecat.secret_key="sk_XXXXX"

# Set webhook verification secret (if needed)
firebase functions:config:set revenuecat.webhook_secret="whsec_XXXXX"

# View config
firebase functions:config:get
```

---

## ⚡ Next Steps

### Before Implementation

✅ 1. Research RevenueCat API (Complete)  
⚠️ 2. **Get RevenueCat Secret API Key from Dashboard**  
⚠️ 3. **Add API key to Firebase Functions config**  

### During Implementation

- [ ] 4. Add axios to Cloud Functions
- [ ] 5. Create RevenueCat API client
- [ ] 6. Implement reward calculation
- [ ] 7. Create redemption function
- [ ] 8. Create webhook handler
- [ ] 9. Update Flutter repository
- [ ] 10. Add UI to dashboard

### After Implementation

- [ ] 11. Test with test users
- [ ] 12. Configure webhook in RevenueCat Dashboard
- [ ] 13. Deploy Cloud Functions
- [ ] 14. Test end-to-end flow
- [ ] 15. Monitor logs and errors

---

## 🚨 Important Notes

1. **API Key Security**: Never commit Secret API Key to git
2. **Rate Limits**: RevenueCat API has rate limits (check documentation)
3. **Expiration Handling**: Promotional entitlements auto-expire
4. **Subscription Conflicts**: Promotional access ends when user subscribes
5. **Testing**: Use RevenueCat Sandbox for testing

---

**Ready to proceed once Secret API Key is obtained!** 🚀

