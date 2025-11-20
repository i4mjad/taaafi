# Sprint 03: Referral Code Input During Signup

**Status**: Not Started
**Previous Sprint**: `sprint_02_referral_code_generation.md`
**Next Sprint**: `sprint_04_checklist_functions_setup.md`
**Estimated Duration**: 6-8 hours

---

## Objectives
Add referral code input to the signup flow. Allow new users to optionally enter a referral code during registration and link them to their referrer.

---

## Prerequisites

### Verify Sprint 02 Completion
- [ ] Referral codes generated for users
- [ ] Repository and models working
- [ ] Cloud Functions deployed

### Codebase Checks
1. Find signup/registration flow (search for "signup", "register", "auth")
2. Check navigation structure (GoRouter routes)
3. Examine form validation patterns
4. Look at existing onboarding screens
5. Check localization files for both English and Arabic

---

## Tasks

### Task 1: Create Cloud Function - Redeem Referral Code

**File**: `functions/src/referral/redeemReferralCode.ts`

```typescript
export const redeemReferralCode = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  // Validate code exists and is active
  // Check user hasn't already used a code
  // Check user isn't redeeming their own code
  // Create referralVerifications document
  // Update referralCode totalRedemptions
  // Update referrer's referralStats (totalReferred++)
  // Update referee's user document (referredBy field)
  // Return success with referrer info
});
```

**Validation checks**:
- Code must exist in `referralCodes` collection
- Code must be active (`isActive: true`)
- User's `referredBy` field must be null
- User cannot use their own code
- Referrer account must be active

---

### Task 2: Update Repository with Redemption Method

**File**: `lib/features/referral/data/repositories/referral_repository.dart`

Add method:
```dart
Future<RedemptionResult> redeemReferralCode(String code) async {
  // Call Cloud Function
  // Handle errors (invalid code, already used, etc.)
  // Return result with success/error message
}
```

Create result model:
```dart
class RedemptionResult {
  final bool success;
  final String? errorMessage;
  final String? referrerName;
  final String? referrerId;
}
```

---

### Task 3: Create Referral Code Input Screen

**File**: `lib/features/referral/presentation/screens/referral_code_input_screen.dart`

**Design specs**:
- Optional step (user can skip)
- Text input field for code (uppercase, 6-8 chars)
- Real-time validation (check format)
- "Verify Code" button
- Loading state during verification
- Success/error feedback
- "Skip" button at bottom

**UI Elements**:
- Title: "Do you have a referral code?" (localized)
- Subtitle: "Enter your friend's code to unlock rewards" (localized)
- Input field with proper formatting (auto-uppercase)
- Error messages for invalid codes
- Success animation when valid code accepted

**Localization keys**:
```json
{
  "referral.input.title": "Do you have a referral code?",
  "referral.input.subtitle": "Enter your friend's code to unlock rewards",
  "referral.input.placeholder": "Enter code",
  "referral.input.verify": "Verify Code",
  "referral.input.skip": "Skip for now",
  "referral.input.invalid": "Invalid code. Please check and try again.",
  "referral.input.already_used": "You've already used a referral code.",
  "referral.input.own_code": "You cannot use your own referral code.",
  "referral.input.success": "Code verified! Welcome from {referrerName}!"
}
```

---

### Task 4: Integrate into Signup Flow

**Location**: Find existing signup/onboarding flow

**Integration points**:
1. **After email/password registration**: Add referral code input as next step
2. **After Google/Apple Sign-In**: Show referral code input if first-time user
3. **Optional vs Required**: Make it optional, allow skip

**Navigation flow**:
```
Signup → Email Verification → [Referral Code Input] → Profile Setup → Home
                                      ↓
                                   (Skip) → Profile Setup
```

Update GoRouter to include new route.

---

### Task 5: Create Referral Code Input Widget (Reusable)

**File**: `lib/features/referral/presentation/widgets/referral_code_input_widget.dart`

Reusable widget with:
- Text field with formatting
- Validation logic
- Loading state
- Error display
- Success callback

Can be used in signup flow or settings.

---

### Task 6: Add State Management

**File**: `lib/features/referral/presentation/providers/referral_code_input_provider.dart`

Using Riverpod, manage:
- Code input value
- Validation state
- Loading state
- Error messages
- Redemption result

---

### Task 7: Analytics Events

Track the following events:
```dart
// When screen shown
analytics.logEvent('referral_code_input_shown');

// When code submitted
analytics.logEvent('referral_code_submitted', parameters: {
  'success': true/false,
  'error_type': 'invalid' | 'already_used' | 'network' | null
});

// When skipped
analytics.logEvent('referral_code_skipped');

// When verified successfully
analytics.logEvent('referral_code_verified', parameters: {
  'referrer_id': referrerId
});
```

---

## Testing Criteria

### Unit Tests
1. **Input Validation**: Test code format validation
2. **State Management**: Test provider state transitions
3. **Repository Method**: Mock Cloud Function call

### Integration Tests
1. **Valid Code**: Enter existing code, verify success
2. **Invalid Code**: Enter non-existent code, verify error
3. **Already Used**: Try using code twice, verify error
4. **Own Code**: Try using own code, verify error
5. **Skip**: Test skip flow continues to next screen

### Manual Testing
1. Create two test accounts
2. Get referral code from first account
3. Sign up second account and enter first account's code
4. Verify:
   - Success message shown
   - `referralVerifications` document created
   - `referralStats` updated for referrer
   - User document updated with `referredBy`
5. Test skip functionality
6. Test Arabic localization

### Success Criteria
- [ ] Referral code input integrated into signup flow
- [ ] Cloud Function for redemption working
- [ ] Valid codes accepted, invalid codes rejected
- [ ] User documents properly linked
- [ ] Skip option works correctly
- [ ] UI looks good in both English and Arabic
- [ ] Analytics events firing
- [ ] App builds and deploys successfully

---

## Deployment Checklist

1. Deploy Cloud Function: `firebase deploy --only functions:redeemReferralCode`
2. Build and test Flutter app in staging
3. Test complete signup flow with referral code
4. Verify Firestore documents created correctly
5. Test edge cases (own code, already used, etc.)

---

## Edge Cases to Handle

1. **Network errors**: Show retry option
2. **Code expired** (if implementing expiration): Clear error message
3. **Referrer deleted account**: Prevent redemption
4. **Case sensitivity**: Auto-convert to uppercase
5. **Spaces in code**: Trim whitespace
6. **Special characters**: Filter to alphanumeric only

---

## UI/UX Considerations

- **Smooth transitions**: Animate success state
- **Clear errors**: Don't blame user, be helpful
- **Easy skip**: Make skip button visible but not prominent
- **Loading feedback**: Show spinner during verification
- **Accessibility**: Proper labels for screen readers

---

## Notes for Next Sprint

Document:
- Redemption success rate (for analytics)
- Common error types
- User feedback on flow

---

**Next Sprint**: `sprint_04_checklist_functions_setup.md`
