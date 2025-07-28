# Ta'aafi Plus Smart Alert Suite - Implementation Documentation

## Overview
This document outlines the complete implementation of the Ta'aafi Plus Smart Alert Suite, which provides intelligent, personalized notifications to help prevent relapses based on user behavior patterns.

## Business Requirements Implemented

### A. High-Risk Hour Alert
- **Goal**: Nudge Plus users 30 minutes before their statistically highest risk hour
- **Eligibility**: Plus subscription + ≥30 follow-up events in last 30 days
- **Calculation**: Single hour (0-23) with highest relapse count from last 30 days
- **Delivery**: Exactly 30 minutes before risk hour in user's timezone
- **Frequency**: Max 1 alert per calendar day
- **Cancellation**: Cancelled if user relapses before scheduled time

### B. Streak Vulnerability Alert  
- **Goal**: Weekly proactive push at 8 AM on most vulnerable weekday
- **Eligibility**: Plus subscription + ≥6 weeks of follow-up history
- **Calculation**: Weekday with highest relapse count from last 90 days
- **Delivery**: 8:00 AM on vulnerable weekday
- **Frequency**: One alert per week maximum
- **Adaptiveness**: Message varies based on recent behavior

### C. Shared Features
- **Zero-spam**: Never send both alerts within 2-hour window (High-Risk has priority)
- **Privacy**: No explicit terms in notification banners
- **Graceful degradation**: Proper handling of permission denied states
- **Analytics**: Comprehensive logging for effectiveness measurement

## Architecture Overview

The implementation follows Clean Architecture principles with clear separation of concerns:

```
presentation/
├── widgets/
│   └── smart_alerts/
│       └── smart_alerts_settings_modal.dart     # UI for settings configuration
│
application/
├── smart_alerts_service.dart                    # Business logic & calculations  
└── smart_alerts_notification_service.dart      # Notification scheduling & delivery
│
data/
├── models/
│   └── smart_alert_settings.dart               # Data models & enums
├── repositories/
│   └── smart_alerts_repository.dart            # Firestore persistence
└── smart_alerts/
    └── smart_alerts_notifier.dart              # Riverpod state management
```

## Core Components

### 1. Data Models (`smart_alert_settings.dart`)

#### SmartAlertSettings
```dart
class SmartAlertSettings {
  final bool isHighRiskHourEnabled;
  final bool isStreakVulnerabilityEnabled;
  final int? lastCalculatedRiskHour;        // 0-23
  final int? lastCalculatedVulnerableWeekday; // 1-7 (Mon-Sun)
  final DateTime? lastAlertSent;
  // ... additional tracking fields
}
```

#### SmartAlertEligibility
```dart
class SmartAlertEligibility {
  final bool isEligibleForRiskHour;
  final bool isEligibleForVulnerability;
  final String? riskHourReason;
  final String? vulnerabilityReason;
  final int followUpCount;
  final int weeksOfData;
}
```

### 2. Business Logic (`smart_alerts_service.dart`)

#### Key Methods:
- `checkEligibility()` - Validates Plus subscription and data requirements
- `calculateRiskHour()` - Finds highest-risk hour from last 30 days of relapses
- `calculateVulnerableWeekday()` - Determines most vulnerable day from last 90 days
- `hasRelapsedBeforeAlert()` - Checks if user relapsed before scheduled notification
- `generateAlertMessage()` - Creates context-aware notification content

#### Risk Hour Calculation Algorithm:
1. Get all relapse events from last 30 days
2. Count relapses by hour (0-23)
3. Find hour with maximum count
4. Use earliest hour as tie-breaker
5. Store result and schedule 30-min-prior notification

#### Vulnerable Weekday Calculation Algorithm:
1. Get all relapse events from last 90 days
2. Count relapses by weekday (1-7, Mon-Sun)
3. Find weekday with maximum count
4. Use earliest weekday as tie-breaker (Monday first)
5. Store result and schedule 8 AM notification

### 3. Notification Management (`smart_alerts_notification_service.dart`)

#### Core Features:
- Permission handling via Firebase Messaging
- Local notification scheduling with timezone awareness
- Conflict detection (2-hour rule enforcement)
- Daily recalculation at 3 AM
- Graceful handling of system restrictions

#### Notification IDs:
- High-Risk Hour: `9001`
- Vulnerability Alert: `9002`

### 4. Data Persistence (`smart_alerts_repository.dart`)

#### Firestore Structure:
```
users/{userId}/settings/smart_alerts
├── isHighRiskHourEnabled: boolean
├── isStreakVulnerabilityEnabled: boolean
├── lastCalculatedRiskHour: number (0-23)
├── lastCalculatedVulnerableWeekday: number (1-7)
├── lastRiskHourCalculation: timestamp
├── lastVulnerabilityCalculation: timestamp
├── lastAlertSent: timestamp
├── lastAlertType: string
└── hasPermissionDeniedBannerShown: boolean
```

### 5. State Management (`smart_alerts_notifier.dart`)

#### Riverpod Providers:
- `smartAlertsServiceProvider` - Business logic service
- `smartAlertsNotificationServiceProvider` - Notification service  
- `smartAlertSettingsProvider` - Settings stream
- `smartAlertEligibilityProvider` - Eligibility checking
- `smartAlertsNotifierProvider` - Main state management

### 6. User Interface (`smart_alerts_settings_modal.dart`)

#### Features:
- Plus subscription gate
- Permission request handling
- Real-time eligibility checking
- Toggle controls for each alert type
- Pattern calculation triggers
- Test notification buttons
- Next alert time display
- Comprehensive error handling

## Integration Points

### 1. Risk Clock Widget Integration
```dart
// In risk_clock.dart
GestureDetector(
  onTap: () => showSmartAlertsSettingsModal(context),
  child: // Enable Risk Alert button
)
```

### 2. Subscription Checking
Leverages existing Plus subscription infrastructure:
```dart
final hasSubscription = await _subscriptionService.isSubscriptionActive();
```

### 3. Follow-up Data Integration
Uses existing follow-up repository for pattern analysis:
```dart
final followUps = await _followUpRepository.readFollowUpsByDateRange(start, end);
```

## Notification Content Examples

### High-Risk Hour Alert
```
Title: "Ta'aafi Alert"
Body: "🛡️ Heads-up! Your high-risk hour starts at 10 PM. Plan a healthy distraction now."
```

### Vulnerability Alert (Standard)
```
Title: "Ta'aafi Weekly Check-in" 
Body: "☀️ Good morning! Mondays are your toughest day. Plan an evening walk or check in with your group."
```

### Vulnerability Alert (After Clean Week)
```
Title: "Ta'aafi Weekly Check-in"
Body: "🌟 You stayed strong last Monday—repeat the formula today!"
```

## Error Handling & Edge Cases

### Permission Denied
- Shows educational banner in Insights screen
- Graceful degradation with no background scheduling
- User can re-enable via settings modal

### Insufficient Data
- Clear messaging about requirements (30 events / 6 weeks)
- Educational banners explaining data needs
- Progressive disclosure of features

### Timezone Changes
- Automatic recalculation on app launch
- No duplicate alerts if already fired
- Proper handling of DST transitions

### System Restrictions
- iOS Focus mode / Android Do Not Disturb handling
- Expired notification suppression
- FCM quota throttling fallbacks

## Testing & Validation

### Test Notifications
- Immediate test notifications for both alert types
- Proper permission checking before sending
- Success/error feedback via SnackBar

### Manual Pattern Calculation
- "Calculate Risk Patterns" button for immediate analysis
- Loading states and error handling
- Automatic rescheduling after calculation

## Performance Considerations

### Efficient Data Queries
- Targeted date range queries instead of full history scans
- Batch operations where possible
- Proper indexing assumptions for Firestore queries

### Background Processing
- Minimal app startup impact
- 3 AM daily recalculation schedule
- Lazy loading of heavy computations

## Security & Privacy

### Data Protection
- All calculations happen locally
- No sensitive data in notification content
- Discreet notification wording

### Permission Respect
- Proper handling of denied permissions
- No spam after permission denial
- Clear user control over all features

## Future Enhancements

### Potential Improvements
1. **Machine Learning**: More sophisticated pattern recognition
2. **Context Awareness**: Location, calendar events, weather integration
3. **Social Integration**: Group accountability features
4. **Adaptive Timing**: Learning optimal notification timing per user
5. **Rich Notifications**: Action buttons for immediate coping strategies

## Deployment Considerations

### Code Generation
Required after changes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Dependencies
- Firebase Messaging for permissions
- Flutter Local Notifications for scheduling
- Riverpod for state management
- Existing vault feature infrastructure

### Configuration
- No additional FCM setup required
- Uses existing notification channels
- Inherits app's timezone handling

## Monitoring & Analytics

### Recommended Tracking Events
- `smart_alert_enabled` / `smart_alert_disabled`
- `risk_hour_calculated` / `vulnerable_weekday_calculated`
- `alert_scheduled` / `alert_cancelled` / `alert_delivered`
- `permission_requested` / `permission_granted` / `permission_denied`
- `test_notification_sent`

This comprehensive implementation provides a robust, scalable foundation for intelligent relapse prevention while maintaining user privacy and system performance. 