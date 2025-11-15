# Sprint 7: Analytics Dashboard (1.5 weeks)

**Sprint Goal:** Build comprehensive analytics for admins

**Duration:** 1.5 weeks  
**Priority:** MEDIUM  
**Dependencies:** Sprints 1-6 completed

---

## Feature 7.1: Analytics Infrastructure

**User Story:** As a group admin, I want to view detailed analytics so that I can understand group health and engagement.

### Technical Tasks

#### Backend - Analytics Collection

**Task 7.1.1: Create Analytics Schema**
- **Collection:** `group_analytics_daily`
- **Document ID:** `${groupId}_${date}`
- **Structure:**
```dart
{
  groupId: string,
  date: timestamp,
  
  // Member metrics
  totalMembers: int,
  activeMembers: int,            // active in last 24h
  newMembers: int,
  leftMembers: int,
  
  // Activity metrics
  messageCount: int,
  averageMessagesPerMember: float,
  reactionsCount: int,
  
  // Engagement
  engagementScore: float,
  peakActivityHour: int,
  activeHoursMap: map<int, int>, // hour -> message count
  
  // Challenges
  activeChallenges: int,
  challengeParticipants: int,
  challengeCompletions: int,
  
  // Updates
  updatesPosted: int,
  updatesEngagement: int,
  
  // Calculated
  growthRate: float,
  retentionRate: float,
  healthScore: float             // 0-100
}
```
- **Estimated Time:** 1 hour
- **Assignee:** Backend Developer

**Task 7.1.2: Create Analytics Service**
- **File:** `lib/features/groups/domain/services/group_analytics_service.dart` (new file)
- **Methods:**
```dart
// Data collection
Future<void> aggregateDailyAnalytics(String groupId, DateTime date);
Future<void> calculateHealthScore(String groupId);

// Queries
Future<List<DailyAnalytics>> getAnalyticsRange(
  String groupId,
  DateTime start,
  DateTime end,
);
Future<AnalyticsSummary> getAnalyticsSummary(
  String groupId,
  AnalyticsPeriod period, // 7d, 30d, 90d
);

// Insights
Future<List<Insight>> generateInsights(String groupId);
Future<List<TopMember>> getTopMembers(String groupId, TopMemberType type);
```
- **Estimated Time:** 8 hours
- **Assignee:** Backend Developer

**Task 7.1.3: Create Analytics Aggregation Job**
- **File:** Cloud Function or background service
- **Function:** Run daily at midnight
- **Process:**
  1. Calculate all metrics for previous day
  2. Store in analytics collection
  3. Update trends
  4. Generate insights
- **Estimated Time:** 6 hours
- **Assignee:** Backend Developer

**Task 7.1.4: Create Analytics Entities**
- **Files:** Multiple entity files for analytics data
- **Entities:**
  - `DailyAnalyticsEntity`
  - `AnalyticsSummaryEntity`
  - `InsightEntity`
  - `TopMemberEntity`
- **Estimated Time:** 4 hours
- **Assignee:** Backend Developer

**Task 7.1.5: Create Analytics Repository**
- **File:** `lib/features/groups/domain/repositories/analytics_repository.dart` (new file)
- **Implement all query methods**
- **Estimated Time:** 6 hours
- **Assignee:** Backend Developer

#### Frontend - Providers

**Task 7.1.6: Create Analytics Providers**
- **File:** `lib/features/groups/providers/analytics_providers.dart` (new file)
- **Providers:**
```dart
@riverpod Future<AnalyticsSummary> groupAnalytics(ref, groupId, period);
@riverpod Future<List<TopMember>> topMembers(ref, groupId, type);
@riverpod Future<List<Insight>> analyticsInsights(ref, groupId);
@riverpod Future<ChartData> activityChart(ref, groupId, period);
```
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

#### Testing

**Task 7.1.7: Test Analytics Calculations**
- **Test Cases:**
  1. Daily aggregation accurate
  2. Health score calculated correctly
  3. Trends identified correctly
  4. Top members ranked correctly
- **Estimated Time:** 4 hours
- **Assignee:** QA Engineer

### Deliverables - Part 1 (Days 1-4)

- [ ] Analytics schema designed
- [ ] Analytics service implemented
- [ ] Daily aggregation job running
- [ ] Repository complete
- [ ] Providers created
- [ ] Tests passing

---

## Feature 7.2: Analytics Dashboard UI

**User Story:** As a group admin, I want an intuitive dashboard so that I can quickly understand group performance.

### Technical Tasks

#### UI Components

**Task 7.2.1: Create Analytics Dashboard Screen**
- **File:** `lib/features/groups/presentation/screens/analytics/group_analytics_dashboard_screen.dart` (new file)
- **Layout:**
  1. **Period Selector:**
     - Tabs: 7 Days, 30 Days, 90 Days, All Time
  2. **Overview Cards:**
     - Total Members
     - Active Members (%)
     - Messages Today
     - Engagement Score
  3. **Charts Section:**
     - Member Growth Chart
     - Activity Heatmap
     - Engagement Trend
  4. **Top Contributors:**
     - Top 5 most active members
     - With stats
  5. **Insights Section:**
     - Auto-generated insights
     - Recommendations
  6. **Export Button:**
     - Export data as CSV
- **Estimated Time:** 8 hours
- **Assignee:** Frontend Developer

**Task 7.2.2: Create Overview Card Widget**
- **File:** `lib/features/groups/presentation/widgets/analytics/analytics_overview_card.dart` (new file)
- **Display:**
  1. Icon
  2. Value (large number)
  3. Label
  4. Trend indicator (up/down arrow)
  5. Comparison text ("↑ 12% vs last week")
- **Estimated Time:** 2 hours
- **Assignee:** Frontend Developer

**Task 7.2.3: Create Member Growth Chart**
- **File:** `lib/features/groups/presentation/widgets/analytics/member_growth_chart.dart` (new file)
- **Chart Type:** Line chart
- **Data:** Members over time
- **Features:**
  - Zoom/pan
  - Tooltip on hover
  - Smooth line
- **Dependencies:** `fl_chart` package
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 7.2.4: Create Activity Heatmap**
- **File:** `lib/features/groups/presentation/widgets/analytics/activity_heatmap.dart` (new file)
- **Display:**
  1. Grid: Days (rows) × Hours (columns)
  2. Color intensity based on message count
  3. Legend
  4. Tap to see details
- **Estimated Time:** 5 hours
- **Assignee:** Frontend Developer

**Task 7.2.5: Create Engagement Chart**
- **File:** `lib/features/groups/presentation/widgets/analytics/engagement_chart.dart` (new file)
- **Chart Type:** Bar chart
- **Data:** Daily engagement score
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 7.2.6: Create Top Members Widget**
- **File:** `lib/features/groups/presentation/widgets/analytics/top_members_widget.dart` (new file)
- **Display:**
  1. Ranked list (1-5)
  2. Avatar
  3. Name
  4. Stats (messages, reactions, etc.)
  5. Trend indicator
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 7.2.7: Create Insights Widget**
- **File:** `lib/features/groups/presentation/widgets/analytics/analytics_insights_widget.dart` (new file)
- **Display:**
  1. Card for each insight
  2. Icon/emoji
  3. Insight text
  4. Action button (if applicable)
- **Example Insights:**
  - "Engagement is up 25% this week! 🎉"
  - "3 members haven't been active in 7 days"
  - "Peak activity is between 8-10 PM"
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 7.2.8: Create Export Functionality**
- **File:** Part of dashboard screen
- **Features:**
  1. Generate CSV with all analytics data
  2. Include member list with stats
  3. Include charts as images (optional)
  4. Share via platform share sheet
- **Dependencies:** `csv` package
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

#### Integration

**Task 7.2.9: Add Analytics to Group Settings**
- **File:** `lib/features/groups/presentation/screens/group_settings_screen.dart`
- **Actions:**
  1. Add "Analytics" card for admins
  2. Show preview stat (e.g., "52% engagement this week")
  3. Navigate to dashboard
- **Estimated Time:** 1 hour
- **Assignee:** Frontend Developer

#### Localization

**Task 7.2.10: Add Localization Keys**
- **Files:** 
  - `lib/i18n/en_translations.dart`
  - `lib/i18n/ar_translations.dart`
- **Keys:**
```json
{
  "analytics": "Analytics",
  "analytics-dashboard": "Analytics Dashboard",
  "overview": "Overview",
  "total-members": "Total Members",
  "active-members": "Active Members",
  "messages-today": "Messages Today",
  "engagement-score": "Engagement Score",
  "member-growth": "Member Growth",
  "activity-heatmap": "Activity Heatmap",
  "engagement-trend": "Engagement Trend",
  "top-contributors": "Top Contributors",
  "insights": "Insights",
  "export-analytics": "Export Analytics",
  "analytics-period-7d": "7 Days",
  "analytics-period-30d": "30 Days",
  "analytics-period-90d": "90 Days",
  "analytics-period-all": "All Time",
  "vs-last-week": "vs last week",
  "vs-last-month": "vs last month",
  "trend-up": "Trending up",
  "trend-down": "Trending down",
  "trend-stable": "Stable",
  "peak-activity-time": "Peak activity: {time}",
  "health-score": "Health Score",
  "healthy-group": "Healthy Group",
  "needs-attention": "Needs Attention",
  "analytics-exported": "Analytics exported successfully",
  "engagement-up": "Engagement is up {percent}% this week!",
  "inactive-members-warning": "{count} members haven't been active in 7+ days",
  "peak-activity-insight": "Peak activity is between {start} and {end}",
  "no-analytics-data": "Not enough data yet. Check back tomorrow!"
}
```
- **Estimated Time:** 1 hour
- **Assignee:** Developer + Translator

#### Testing

**Task 7.2.11: Widget Tests**
- **Test all analytics widgets**
- **Estimated Time:** 4 hours
- **Assignee:** QA Engineer

**Task 7.2.12: Manual Testing Checklist**
- [ ] Dashboard loads within 2 seconds
- [ ] All metrics display correctly
- [ ] Charts render properly
- [ ] Period selector works
- [ ] Top members accurate
- [ ] Insights generated correctly
- [ ] Export works
- [ ] Responsive on different screens
- [ ] Loading states show properly
- [ ] Error states handled gracefully
- **Estimated Time:** 2 hours
- **Assignee:** QA Engineer

### Deliverables - Part 2 (Days 5-7.5)

- [ ] Analytics dashboard complete
- [ ] All charts working
- [ ] Insights displayed
- [ ] Export functional
- [ ] UI polished
- [ ] Tests passing

---

## Sprint 7 Summary

**Total Estimated Time:** 7.5 working days (1.5 weeks)

**Sprint Deliverables:**
- [ ] Complete analytics system
- [ ] Dashboard with charts
- [ ] Insights generation
- [ ] Export functionality
- [ ] Admin-only access
- [ ] All tests passing

**Sprint Review Checklist:**
- [ ] Demo analytics dashboard
- [ ] Demo charts and visualizations
- [ ] Demo insights
- [ ] Demo export
- [ ] Review data accuracy
- [ ] Review performance

---

## Firestore Schema Verification

**New Collection Created:**
1. ✅ `group_analytics_daily` - Daily analytics aggregation

**Sample Document:**
```json
{
  "groupId": "abc123",
  "date": "2025-11-14T00:00:00Z",
  "totalMembers": 12,
  "activeMembers": 8,
  "newMembers": 1,
  "leftMembers": 0,
  "messageCount": 45,
  "averageMessagesPerMember": 3.75,
  "reactionsCount": 23,
  "engagementScore": 78.5,
  "peakActivityHour": 20,
  "activeHoursMap": {
    "8": 3,
    "12": 5,
    "18": 8,
    "20": 15,
    "21": 10,
    "22": 4
  },
  "activeChallenges": 2,
  "challengeParticipants": 7,
  "challengeCompletions": 3,
  "updatesPosted": 5,
  "updatesEngagement": 18,
  "growthRate": 9.1,
  "retentionRate": 87.5,
  "healthScore": 82.3
}
```

**Indexes Required:**
```json
{
  "indexes": [
    {
      "collectionGroup": "group_analytics_daily",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Security Rules:**
```javascript
match /group_analytics_daily/{analyticsId} {
  // Only admins can read analytics
  allow read: if isAuthenticated() && 
                 isGroupAdmin(resource.data.groupId);
  // Only system can write
  allow write: if false;
}
```

---

## Cloud Functions Required

**Function: Daily Analytics Aggregator**
- **Name:** `aggregateDailyGroupAnalytics`
- **Schedule:** Every day at 00:30 UTC
- **Process:**
  1. Get all active groups
  2. For each group:
     - Count members (total, active, new, left)
     - Count messages and reactions
     - Calculate engagement scores
     - Identify peak activity hour
     - Count challenges and participants
     - Count updates and engagement
     - Calculate health score
     - Store in `group_analytics_daily`
- **Estimated Time:** 8 hours to implement
- **Technology:** Firebase Cloud Functions (Node.js/TypeScript)

---

## Health Score Calculation Formula

```dart
double calculateHealthScore({
  required int totalMembers,
  required int activeMembers,
  required double averageMessagesPerMember,
  required int activeChallenges,
  required int challengeParticipants,
  required int updatesPosted,
  required double retentionRate,
}) {
  // Base score from activity (40%)
  double activityRatio = activeMembers / totalMembers;
  double activityScore = activityRatio * 40;
  
  // Messaging health (20%)
  double messagingScore = min(averageMessagesPerMember * 4, 20);
  
  // Challenge participation (15%)
  double challengeRatio = challengeParticipants / totalMembers;
  double challengeScore = challengeRatio * 15;
  
  // Updates engagement (10%)
  double updatesRatio = updatesPosted / totalMembers;
  double updatesScore = min(updatesRatio * 20, 10);
  
  // Retention (15%)
  double retentionScore = retentionRate * 0.15;
  
  // Total health score
  double health = activityScore + messagingScore + 
                  challengeScore + updatesScore + retentionScore;
  
  return min(health, 100).toDouble();
}
```

**Health Score Interpretation:**
- 90-100: Excellent (Very healthy group)
- 75-89: Good (Healthy group)
- 60-74: Fair (Needs attention)
- 40-59: Poor (Requires action)
- 0-39: Critical (Immediate intervention needed)

---

## Dependencies

**External Packages:**
```yaml
dependencies:
  fl_chart: ^0.65.0  # For charts
  csv: ^5.1.1        # For CSV export
```

**Cloud Functions:**
- Node.js 18+
- Firebase Admin SDK
- Scheduled execution (Cloud Scheduler)

---

## Performance Considerations

1. **Analytics Query Optimization:**
   - Cache recent analytics data (1 hour TTL)
   - Paginate historical data
   - Lazy load charts

2. **Chart Rendering:**
   - Use FutureBuilder with loading states
   - Render charts only when visible
   - Debounce period selector changes

3. **Export Performance:**
   - Limit export to last 90 days
   - Generate CSV in background
   - Show progress indicator

4. **Dashboard Loading:**
   - Load overview cards first
   - Progressively load charts
   - Show skeleton loaders

---

**Sprint 7 Status:** 📋 READY TO START

**Dependencies:** Sprints 1-6 completed, Cloud Functions environment set up

