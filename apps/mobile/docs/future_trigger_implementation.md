# Future Analytics Data Collection Implementation

## Overview
This document outlines the implementation plan for collecting real analytics data (triggers and mood ratings) to replace the current mock data in the premium analytics features.

## 1. Trigger Collection Implementation

### Current State
- Triggers are not currently collected during follow-up logging
- The `getTriggerRadarData()` method returns empty data
- Trigger Radar widget shows empty state when no data available

### Implementation Plan

#### 1.1 Data Model Updates
Extend the `FollowUpModel` to include trigger data:

```dart
class FollowUpModel {
  final String id;
  final FollowUpType type;
  final DateTime time;
  final List<String> triggers; // NEW: List of trigger IDs
  
  // ... rest of implementation
}
```

#### 1.2 UI Changes - Follow-up Sheet
Update `follow_up_sheet.dart` to include trigger selection:

1. **When to show triggers**: Only for relapse-related follow-ups (not for "free-day")
2. **UI Component**: Add trigger selection section using chips or checkboxes
3. **Trigger List**: Define common triggers like:
   - `stress`, `boredom`, `loneliness`, `late-night`, `social-media`, `urges`, `anxiety`, `anger`, `sadness`, `peer-pressure`

#### 1.3 Backend Updates
1. Update Firestore schema to store trigger arrays
2. Update `FollowUpRepository` to handle trigger data
3. Update `analytics_service.dart` to process real trigger data:

```dart
Future<Map<String, int>> getTriggerRadarData() async {
  final followUps = await _getFollowUpsForPeriod(30);
  final triggerCounts = <String, int>{};
  
  for (final followUp in followUps) {
    if (followUp.type != FollowUpType.none) {
      for (final trigger in followUp.triggers) {
        triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
      }
    }
  }
  
  return triggerCounts;
}
```

## 2. Mood Rating Collection Implementation

### Current State
- Basic emotions are collected but not numerical mood ratings
- The `getMoodCorrelationData()` method returns empty data
- Mood Correlation Chart shows empty state

### Implementation Plan

#### 2.1 Data Model Updates
Add mood rating to follow-up data:

```dart
class FollowUpModel {
  final String id;
  final FollowUpType type;
  final DateTime time;
  final List<String> triggers;
  final int? moodRating; // NEW: Scale from -5 to +5
  
  // ... rest of implementation
}
```

#### 2.2 UI Changes
1. **Mood Scale Component**: Create a slider or button selector for -5 to +5 scale
2. **When to collect**: Either daily or with each follow-up entry
3. **Integration**: Add to follow-up sheet or as separate daily check-in

#### 2.3 Backend Updates
Update analytics service to process real mood data:

```dart
Future<MoodCorrelationData> getMoodCorrelationData() async {
  final followUps = await _getFollowUpsForPeriod(30);
  final moodCounts = <int, int>{};
  final relapseCounts = <int, int>{};
  
  for (final followUp in followUps) {
    if (followUp.moodRating != null) {
      final mood = followUp.moodRating!;
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      
      if (followUp.type != FollowUpType.none) {
        relapseCounts[mood] = (relapseCounts[mood] ?? 0) + 1;
      }
    }
  }
  
  return MoodCorrelationData(
    moodCounts: moodCounts,
    relapseCounts: relapseCounts,
    correlation: _calculateCorrelation(moodCounts, relapseCounts),
  );
}
```

## 3. Migration Strategy

### 3.1 Backward Compatibility
- Ensure existing follow-ups without trigger/mood data don't break
- Provide default values for missing fields
- Analytics should gracefully handle missing data

### 3.2 Rollout Plan
1. **Phase 1**: Update data models and backend
2. **Phase 2**: Update UI to collect new data
3. **Phase 3**: Enable real analytics (remove mock data)
4. **Phase 4**: Optimize and enhance based on user feedback

### 3.3 Data Backfill
- Analytics will only work for new data going forward
- Consider optional user survey to backfill historical data
- Provide clear messaging about data collection timeline

## 4. Technical Considerations

### 4.1 Localization
- Trigger names must be translatable
- Mood scale labels need Arabic and English versions
- Error messages for data collection failures

### 4.2 Privacy
- All analytics data remains user-private
- Clear communication about data usage
- Option to delete analytics data

### 4.3 Performance
- Efficient querying for analytics calculations
- Caching for frequently accessed data
- Background processing for heavy analytics computations

## Next Steps
1. Review and approve this implementation plan
2. Update data models and backend infrastructure
3. Design and implement UI components for data collection
4. Test with real user data
5. Deploy and monitor analytics performance 