<!-- TODO: consider this -->

# Account Deletion - Subscription Requirements

## Overview
This document outlines the requirements for handling Plus subscription users when they attempt to delete their accounts.

## Core Requirements

### 1. Subscription Status Check
- **MUST** check RevenueCat subscription status before allowing account deletion
- **MUST** verify both subscription active status and expiration date
- **MUST** refresh subscription status from RevenueCat (not use cached data)

### 2. Deletion Prevention Rules
Account deletion **MUST BE BLOCKED** if the user has:
- ✅ Active Plus subscription (currently paying)
- ✅ Canceled subscription that still has remaining time (grace period)
- ✅ Any subscription that expires in the future

Account deletion **ALLOWED ONLY** when:
- ✅ User has no subscription (free user)
- ✅ Subscription has completely expired (past expiration date)
- ✅ User never had a subscription

### 3. User Experience Requirements

#### Delete Button State
- **DISABLED**: When user has any active subscription or grace period
- **ENABLED**: Only when user has no active subscription or completely expired subscription

#### User Messaging
When deletion is blocked, show clear message:
- Explain why deletion is blocked
- Provide instructions to cancel subscription in App Store/Play Store
- Show current subscription expiration date
- Provide "Refresh Status" button to re-check after cancellation

#### Store Cancellation Instructions
- **iOS Users**: Settings > Apple ID > Subscriptions > Ta3afi Plus > Cancel
- **Android Users**: Play Store > Account > Subscriptions > Ta3afi Plus > Cancel

### 4. Technical Implementation

#### Subscription Check Flow
1. User navigates to account deletion
2. App checks RevenueCat subscription status
3. If active subscription detected:
   - Show blocking dialog with instructions
   - Disable delete button
   - Provide refresh option
4. If no active subscription:
   - Allow normal deletion flow

#### Grace Period Handling
- Even if user cancels subscription, deletion remains blocked until expiration
- This prevents accidental deletion during paid period
- User gets full value of their paid subscription time

#### Error Handling
- If RevenueCat check fails, err on the side of caution (block deletion)
- Show error message asking user to try again
- Provide manual contact option if persistent issues

### 5. Implementation Files

#### New Components Required
- `lib/features/account/presentation/account_deletion_subscription_check_screen.dart`
- `lib/features/account/application/account_deletion_guard_service.dart`
- Updated subscription service with expiration validation

#### Modified Components
- Account deletion navigation flow
- Subscription repository (RevenueCat integration)
- Account settings screen (update delete button routing)

### 6. User Flow Diagram

```
[Account Settings] 
       ↓
[Delete Account Button]
       ↓
[Subscription Check Screen] ← NEW SCREEN
       ↓
┌─────────────────┐    ┌──────────────────┐
│ Has Active Sub? │───→│ Show Block Dialog│
│      YES        │    │ - Instructions   │
└─────────────────┘    │ - Refresh Button │
       ↓ NO            │ - Cancel Option  │
[Normal Deletion]      └──────────────────┘
```

### 7. Business Rules

#### Revenue Protection
- Prevents accidental cancellations during paid periods
- Ensures users get full value of their subscription
- Reduces support requests from users who deleted accounts accidentally

#### Legal Compliance
- Users maintain control over their subscriptions
- Clear communication about subscription management
- Follows app store guidelines for subscription handling

#### User Experience
- Simple, clear messaging
- No complex technical explanations
- Direct path to subscription management

### 8. Testing Requirements

#### Test Cases
1. **Free User**: Should allow deletion immediately
2. **Active Subscriber**: Should block deletion with clear message
3. **Canceled but Grace Period**: Should block deletion until expiration
4. **Expired Subscription**: Should allow deletion
5. **RevenueCat Error**: Should block deletion and show error
6. **Network Error**: Should block deletion and show retry option

#### Manual Testing
- Test on both iOS and Android
- Verify store cancellation instructions are accurate
- Test refresh functionality after cancellation
- Verify expiration date calculations

### 9. Monitoring & Analytics

#### Metrics to Track
- Number of deletion attempts by subscription status
- Conversion rate from blocked deletion to subscription cancellation
- Support tickets related to account deletion
- Revenue retention from deletion prevention

#### Alerts
- High failure rate on subscription status checks
- Unusual patterns in deletion attempts
- RevenueCat API errors

### 10. Future Considerations

#### Potential Enhancements
- Email reminder before subscription expires about account deletion option
- In-app notification when subscription expires
- Self-service subscription management within app

#### Maintenance
- Regularly verify store cancellation instructions remain accurate
- Monitor RevenueCat API changes
- Update messaging based on user feedback

## Implementation Summary

### Key Principles
1. **Safety First**: Block deletion when uncertain about subscription status
2. **User Control**: Direct users to official app store subscription management
3. **Clear Communication**: Explain why deletion is blocked and how to proceed
4. **Revenue Protection**: Prevent accidental subscription cancellations
5. **Compliance**: Follow app store guidelines and user data policies

### Success Criteria
- Zero unintentional subscription cancellations from account deletion
- Clear user understanding of subscription management process
- Reduced support tickets related to account deletion confusion
- Maintained revenue from subscription retention during grace periods 