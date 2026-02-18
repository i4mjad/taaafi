# Sprint 5: Group Challenges System (3 weeks)

**Sprint Goal:** Build complete challenges system with creation, participation, and leaderboards

**Duration:** 3 weeks  
**Priority:** HIGH  
**Dependencies:** Sprints 1-4 completed

---

## Feature 5.1: Challenges Infrastructure

**User Story:** As a group member, I want to participate in challenges so that I can stay motivated with the group.

### Technical Tasks

#### Backend - Database Schema

**Task 5.1.1: Create Challenges Collection Schema**
- **Collection:** `group_challenges`
- **Document Structure:**
```dart
{
  id: string,
  groupId: string,
  title: string,                    // Max 60 chars
  description: string,              // Max 500 chars
  type: 'duration' | 'goal' | 'team' | 'recurring',
  
  // Duration-based fields
  startDate: timestamp,
  endDate: timestamp,
  durationDays: int,
  
  // Goal-based fields
  goalType: 'messages' | 'days_active' | 'custom',
  goalTarget: int,
  goalUnit: string,
  
  // Participation
  participants: array<string>,      // cpIds
  participantCount: int,
  maxParticipants: int?,           // null = unlimited
  
  // Status
  status: 'draft' | 'active' | 'completed' | 'cancelled',
  
  // Metadata
  createdBy: string,               // cpId
  createdAt: timestamp,
  updatedAt: timestamp,
  
  // Settings
  isRecurring: boolean,
  recurringInterval: 'daily' | 'weekly' | 'monthly',
  allowLateJoin: boolean,
  notifyOnMilestone: boolean,
  
  // Rewards
  badgeId: string?,
  pointsReward: int,
  
  // Privacy
  visibility: 'public' | 'private'
}
```
- **Estimated Time:** 1 hour
- **Assignee:** Backend Developer

**Task 5.1.2: Create Challenge Participation Collection**
- **Collection:** `challenge_participants`
- **Document ID:** `${challengeId}_${cpId}`
- **Document Structure:**
```dart
{
  id: string,
  challengeId: string,
  cpId: string,
  groupId: string,
  
  // Progress
  progress: int,                   // 0-100 percentage or absolute value
  currentValue: int,               // e.g., 5 days completed out of 30
  goalValue: int,                  // e.g., 30 days
  
  // Status
  status: 'active' | 'completed' | 'failed' | 'quit',
  completedAt: timestamp?,
  
  // Tracking
  joinedAt: timestamp,
  lastUpdateAt: timestamp,
  
  // Daily tracking (for streaks)
  dailyLog: array<timestamp>,     // dates of activity
  streakCount: int,
  longestStreak: int,
  
  // Ranking
  rank: int?,
  points: int
}
```
- **Estimated Time:** 1 hour
- **Assignee:** Backend Developer

**Task 5.1.3: Create Challenge Updates Collection**
- **Collection:** `challenge_updates`
- **Document Structure:**
```dart
{
  id: string,
  challengeId: string,
  cpId: string,
  type: 'progress' | 'milestone' | 'completion' | 'comment',
  message: string,
  value: int?,                    // for progress updates
  createdAt: timestamp
}
```
- **Estimated Time:** 30 minutes
- **Assignee:** Backend Developer

#### Backend - Domain Layer

**Task 5.1.4: Create Challenge Entity**
- **File:** `lib/features/groups/domain/entities/challenge_entity.dart` (new file)
- **Properties:** Map all fields from schema to entity
- **Methods:**
  1. `isActive()` - check if challenge is currently active
  2. `canJoin()` - check if new members can join
  3. `isCompleted()` - check if challenge is finished
  4. `getDaysRemaining()` - calculate days left
  5. `getProgressPercentage()` - overall group progress
- **Estimated Time:** 3 hours
- **Assignee:** Backend Developer

**Task 5.1.5: Create Challenge Participation Entity**
- **File:** `lib/features/groups/domain/entities/challenge_participation_entity.dart` (new file)
- **Properties:** Map all fields
- **Methods:**
  1. `getProgressPercentage()` - personal progress
  2. `isOnTrack()` - check if meeting goals
  3. `updateProgress(int value)` - update current progress
  4. `completeChallenge()` - mark as completed
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

**Task 5.1.6: Create Challenge Repository Interface**
- **File:** `lib/features/groups/domain/repositories/challenges_repository.dart` (new file)
- **Methods:**
```dart
// Challenge CRUD
Future<String> createChallenge(ChallengeEntity challenge);
Future<ChallengeEntity?> getChallengeById(String challengeId);
Future<void> updateChallenge(ChallengeEntity challenge);
Future<void> deleteChallenge(String challengeId);

// Challenge queries
Stream<List<ChallengeEntity>> getGroupChallenges(String groupId);
Future<List<ChallengeEntity>> getActiveChallenges(String groupId);
Future<List<ChallengeEntity>> getCompletedChallenges(String groupId);

// Participation
Future<void> joinChallenge(String challengeId, String cpId);
Future<void> leaveChallenge(String challengeId, String cpId);
Future<void> updateProgress(String challengeId, String cpId, int value);
Future<ChallengeParticipationEntity?> getParticipation(
  String challengeId,
  String cpId,
);
Stream<List<ChallengeParticipationEntity>> getChallengeParticipants(
  String challengeId,
);

// Leaderboard
Future<List<ChallengeParticipationEntity>> getLeaderboard(
  String challengeId,
  {int limit = 10}
);

// Stats
Future<int> getParticipantCount(String challengeId);
Future<double> getAverageProgress(String challengeId);
```
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

#### Backend - Data Layer

**Task 5.1.7: Create Challenge Model**
- **File:** `lib/features/groups/data/models/challenge_model.dart` (new file)
- **Methods:**
  1. `fromFirestore(DocumentSnapshot doc)`
  2. `toFirestore()`
  3. `toEntity()`
  4. `fromEntity(ChallengeEntity entity)`
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

**Task 5.1.8: Create Challenge Participation Model**
- **File:** `lib/features/groups/data/models/challenge_participation_model.dart` (new file)
- **Methods:** Same as above
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

**Task 5.1.9: Create Challenges Firestore DataSource**
- **File:** `lib/features/groups/data/datasources/challenges_firestore_datasource.dart` (new file)
- **Implement all repository methods with Firestore**
- **Include:**
  1. Proper error handling
  2. Transaction support where needed
  3. Batch operations for performance
  4. Real-time listeners
- **Estimated Time:** 8 hours
- **Assignee:** Backend Developer

**Task 5.1.10: Implement Challenges Repository**
- **File:** `lib/features/groups/data/repositories/challenges_repository_impl.dart` (new file)
- **Implement all methods from interface**
- **Add validation:**
  1. Verify group membership before creating
  2. Check if already participating
  3. Validate progress values
  4. Check challenge is active before joining
- **Estimated Time:** 8 hours
- **Assignee:** Backend Developer

#### Backend - Application Layer

**Task 5.1.11: Create Challenges Service**
- **File:** `lib/features/groups/domain/services/challenges_service.dart` (new file)
- **Business Logic:**
```dart
// Challenge lifecycle
Future<CreateChallengeResult> createChallenge({...});
Future<void> startChallenge(String challengeId);
Future<void> completeChallenge(String challengeId);
Future<void> cancelChallenge(String challengeId);

// Participation management
Future<JoinChallengeResult> joinChallenge(String challengeId, String cpId);
Future<void> quitChallenge(String challengeId, String cpId);

// Progress tracking
Future<void> recordProgress(String challengeId, String cpId, int value);
Future<void> recordDailyActivity(String challengeId, String cpId);
Future<void> checkMilestones(String challengeId, String cpId);

// Automated checks
Future<void> checkChallengeCompletions();
Future<void> updateRankings(String challengeId);
Future<void> sendNotifications(String challengeId);
```
- **Estimated Time:** 10 hours
- **Assignee:** Backend Developer

**Task 5.1.12: Create Challenge Progress Tracker**
- **File:** `lib/features/groups/application/challenge_progress_tracker.dart` (new file)
- **Purpose:** Background service to track challenge progress
- **Functions:**
  1. Listen to relevant events (messages, updates, etc.)
  2. Automatically update challenge progress
  3. Check for completions
  4. Update rankings
  5. Trigger notifications
- **Estimated Time:** 6 hours
- **Assignee:** Backend Developer

#### Frontend - Providers

**Task 5.1.13: Create Challenges Providers**
- **File:** `lib/features/groups/providers/challenges_providers.dart` (new file)
- **Providers:**
```dart
// Repository provider
@riverpod ChallengesRepository challengesRepository(ref);

// Challenge queries
@riverpod Stream<List<ChallengeEntity>> groupChallenges(ref, groupId);
@riverpod Future<ChallengeEntity?> challengeById(ref, challengeId);
@riverpod Future<List<ChallengeEntity>> activeChallenges(ref, groupId);
@riverpod Future<List<ChallengeEntity>> completedChallenges(ref, groupId);

// Participation
@riverpod Future<ChallengeParticipationEntity?> userParticipation(
  ref, 
  challengeId, 
  cpId
);
@riverpod Stream<List<ChallengeParticipationEntity>> challengeParticipants(
  ref,
  challengeId
);
@riverpod Future<List<ChallengeParticipationEntity>> leaderboard(
  ref,
  challengeId
);

// Stats
@riverpod Future<ChallengeStats> challengeStats(ref, challengeId);
```
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 5.1.14: Create Challenge Controller**
- **File:** `lib/features/groups/application/challenges_controller.dart` (new file)
- **Controller Methods:**
```dart
Future<void> createChallenge({...});
Future<void> joinChallenge(String challengeId);
Future<void> leaveChallenge(String challengeId);
Future<void> updateProgress(String challengeId, int value);
Future<void> completeChallenge(String challengeId);
```
- **State management for loading, errors, success**
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

#### Firestore Setup

**Task 5.1.15: Create Firestore Indexes**
- **Indexes needed:**
  1. `group_challenges` composite index:
     - `groupId` + `status` + `createdAt`
     - `groupId` + `type` + `startDate`
  2. `challenge_participants` composite index:
     - `challengeId` + `status` + `progress` (for leaderboard)
     - `cpId` + `status` + `joinedAt`
- **Estimated Time:** 1 hour
- **Assignee:** Backend Developer

**Task 5.1.16: Security Rules**
- **File:** `firestore.rules`
- **Rules:**
```javascript
// group_challenges
match /group_challenges/{challengeId} {
  allow read: if isGroupMember(resource.data.groupId);
  allow create: if isGroupMember(request.resource.data.groupId);
  allow update: if isGroupMember(resource.data.groupId) 
                && (isAdmin() || isCreator());
  allow delete: if isAdmin() || isCreator();
}

// challenge_participants
match /challenge_participants/{participationId} {
  allow read: if isGroupMember(getChallenge().groupId);
  allow create: if isGroupMember(getChallenge().groupId);
  allow update: if request.auth.uid == resource.data.cpId;
  allow delete: if request.auth.uid == resource.data.cpId;
}
```
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

#### Testing Tasks

**Task 5.1.17: Unit Tests - Backend**
- **Test Files:**
  1. `challenge_entity_test.dart`
  2. `challenges_repository_impl_test.dart`
  3. `challenges_service_test.dart`
- **Test Cases:**
  1. Create challenge with valid data
  2. Fail to create with invalid data
  3. Join challenge successfully
  4. Cannot join full challenge
  5. Cannot join completed challenge
  6. Progress updates correctly
  7. Leaderboard ranks correctly
  8. Challenge completes when goal met
- **Estimated Time:** 10 hours
- **Assignee:** QA Engineer

**Task 5.1.18: Integration Tests**
- **Test Scenarios:**
  1. Complete challenge flow: create → join → progress → complete
  2. Multiple users racing in challenge
  3. Real-time leaderboard updates
  4. Automated progress tracking
- **Estimated Time:** 6 hours
- **Assignee:** QA Engineer

### Deliverables - Sprint 5 Week 1

- [ ] Database schema designed and implemented
- [ ] Domain entities created
- [ ] Repository interface and implementation complete
- [ ] Service layer with business logic
- [ ] Progress tracking system
- [ ] Providers created
- [ ] Firestore indexes and rules
- [ ] Unit tests passing
- [ ] Integration tests passing

---

## Feature 5.2: Challenges UI - Creation & Management

**User Story:** As a group member, I want to create and manage challenges so that I can motivate the group.

### Technical Tasks

#### UI - Challenge Creation

**Task 5.2.1: Create Challenge Type Selection Screen**
- **File:** `lib/features/groups/presentation/screens/challenges/select_challenge_type_screen.dart` (new file)
- **UI:**
  1. Grid of challenge type cards:
     - Duration Challenge (e.g., 30-day streak)
     - Goal Challenge (e.g., 100 messages)
     - Team Challenge (collaborative goal)
     - Recurring Challenge (weekly check-ins)
  2. Each card shows:
     - Icon
     - Title
     - Description
     - "Coming Soon" badge if not yet available
  3. Tap to proceed to creation form
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 5.2.2: Create Duration Challenge Form**
- **File:** `lib/features/groups/presentation/screens/challenges/create_duration_challenge_screen.dart` (new file)
- **Form Fields:**
  1. Challenge Title (required, 60 chars)
  2. Description (optional, 500 chars)
  3. Start Date picker (default: tomorrow)
  4. Duration selector (7, 14, 21, 30, 60, 90 days or custom)
  5. Goal Type selector:
     - Active every day
     - Send X messages
     - Custom metric
  6. Max participants (optional, default unlimited)
  7. Allow late joining toggle
  8. Points reward slider
  9. Preview section
  10. Create button
- **Validation:**
  - Title required
  - Start date must be future or today
  - Duration > 0
- **Estimated Time:** 6 hours
- **Assignee:** Frontend Developer

**Task 5.2.3: Create Goal Challenge Form**
- **File:** `lib/features/groups/presentation/screens/challenges/create_goal_challenge_screen.dart` (new file)
- **Form Fields:**
  1. Title and description (same as above)
  2. Goal Type selector:
     - Message count
     - Days active
     - Custom
  3. Target value input
  4. Time limit toggle (optional)
  5. If time limit: Duration picker
  6. Other settings (same as duration)
- **Estimated Time:** 5 hours
- **Assignee:** Frontend Developer

**Task 5.2.4: Create Team Challenge Form**
- **File:** `lib/features/groups/presentation/screens/challenges/create_team_challenge_screen.dart` (new file)
- **Form Fields:**
  1. Title and description
  2. Team goal type (collaborative)
  3. Target value (group goal)
  4. Duration
  5. Individual vs. cumulative toggle
  6. Other settings
- **Estimated Time:** 5 hours
- **Assignee:** Frontend Developer

**Task 5.2.5: Create Challenge Preview Widget**
- **File:** `lib/features/groups/presentation/widgets/challenges/challenge_preview_card.dart` (new file)
- **Display:**
  1. Challenge type badge
  2. Title and description
  3. Duration/goal summary
  4. Reward info
  5. "Looks good!" confirmation
- **Estimated Time:** 2 hours
- **Assignee:** Frontend Developer

#### UI - Challenge List & Detail

**Task 5.2.6: Create Challenges List Screen**
- **File:** `lib/features/groups/presentation/screens/challenges/challenges_list_screen.dart` (new file)
- **Tabs:**
  1. **Active** - ongoing challenges
  2. **Upcoming** - scheduled challenges
  3. **Completed** - finished challenges
- **Each tab shows:**
  - List of challenge cards
  - Filter options (type, participation status)
  - Sort options (newest, ending soon, most popular)
  - Empty state if no challenges
- **FAB:** Create Challenge button (opens type selector)
- **Estimated Time:** 6 hours
- **Assignee:** Frontend Developer

**Task 5.2.7: Create Challenge Card Widget**
- **File:** `lib/features/groups/presentation/widgets/challenges/challenge_card_widget.dart` (new file)
- **Display:**
  1. Challenge type badge
  2. Title
  3. Description (first 100 chars)
  4. Progress bar (for active challenges)
  5. Participant count with avatars
  6. Days remaining badge
  7. Status indicator (active/completed/upcoming)
  8. Join/View button
- **Interactions:**
  - Tap to view details
  - Long press for quick actions (admin only)
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 5.2.8: Create Challenge Detail Screen**
- **File:** `lib/features/groups/presentation/screens/challenges/challenge_detail_screen.dart` (new file)
- **Sections:**
  1. **Header:**
     - Type badge
     - Title
     - Created by info
     - Edit button (admin/creator only)
  2. **Description:**
     - Full description text
     - Goal details
     - Duration info
  3. **Progress Section:**
     - Overall progress bar
     - Days remaining countdown
     - Participant count
     - Average progress
  4. **Leaderboard Preview:**
     - Top 5 participants
     - Current user's rank
     - "View Full Leaderboard" button
  5. **Your Progress:**
     - Personal progress bar
     - Current value / target
     - Streak count (if applicable)
     - Last update time
     - Update Progress button
  6. **Participants Section:**
     - Grid of participant avatars
     - "View All" button
  7. **Updates Feed:**
     - Recent milestone achievements
     - Member completions
     - Progress updates
  8. **Actions:**
     - Join Challenge button (if not joined)
     - Update Progress button (if joined)
     - Leave Challenge (if joined)
     - Share Challenge
- **Estimated Time:** 8 hours
- **Assignee:** Frontend Developer

**Task 5.2.9: Create Leaderboard Screen**
- **File:** `lib/features/groups/presentation/screens/challenges/challenge_leaderboard_screen.dart` (new file)
- **UI:**
  1. **Top 3 Podium:**
     - Large cards for 1st, 2nd, 3rd place
     - Avatar, name, progress
     - Crown/medal icons
  2. **Full Ranking List:**
     - Rank number
     - Avatar
     - Name
     - Progress bar
     - Progress value
     - Highlight current user
  3. **Filters:**
     - All time
     - This week
     - Friends only (if applicable)
  4. **Stats:**
     - Your rank
     - Distance from next rank
- **Estimated Time:** 5 hours
- **Assignee:** Frontend Developer

#### UI - Progress Management

**Task 5.2.10: Create Update Progress Modal**
- **File:** `lib/features/groups/presentation/widgets/challenges/update_progress_modal.dart` (new file)
- **UI:**
  1. Current progress display
  2. New value input (number or slider)
  3. Optional note/comment field
  4. Preview of new progress
  5. Submit button
  6. Success animation
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 5.2.11: Create Progress Update Widget**
- **File:** `lib/features/groups/presentation/widgets/challenges/progress_update_item.dart` (new file)
- **Display update in feed:**
  1. User avatar
  2. Name
  3. Update message ("reached 50%!")
  4. Timestamp
  5. Reactions (optional)
- **Estimated Time:** 2 hours
- **Assignee:** Frontend Developer

#### Integration Points

**Task 5.2.12: Add Challenges to Group Screen**
- **File:** `lib/features/groups/presentation/screens/group_screen.dart`
- **Actions:**
  1. Replace "Coming Soon" card with real Challenges button
  2. Show active challenge count
  3. Navigate to challenges list
- **Estimated Time:** 1 hour
- **Assignee:** Frontend Developer

**Task 5.2.13: Add Challenges to Group Settings**
- **File:** `lib/features/groups/presentation/screens/group_settings_screen.dart`
- **Actions:**
  1. Add "Manage Challenges" for admins
  2. Show count of active challenges
- **Estimated Time:** 1 hour
- **Assignee:** Frontend Developer

#### Localization

**Task 5.2.14: Add Localization Keys**
- **Files:** 
  - `lib/i18n/en_translations.dart`
  - `lib/i18n/ar_translations.dart`
- **Keys:** (100+ keys for challenges feature)
```json
{
  "challenges": "Challenges",
  "create-challenge": "Create Challenge",
  "select-challenge-type": "Select Challenge Type",
  "duration-challenge": "Duration Challenge",
  "duration-challenge-desc": "Complete an activity for a set number of days",
  "goal-challenge": "Goal Challenge",
  "goal-challenge-desc": "Reach a specific target or milestone",
  "team-challenge": "Team Challenge",
  "team-challenge-desc": "Work together toward a group goal",
  "recurring-challenge": "Recurring Challenge",
  "recurring-challenge-desc": "Regular check-ins on a schedule",
  "challenge-details": "Challenge Details",
  "challenge-title": "Challenge Title",
  "challenge-description": "Description",
  "start-date": "Start Date",
  "duration-days": "Duration (days)",
  "goal-type": "Goal Type",
  "target-value": "Target Value",
  "max-participants": "Max Participants",
  "unlimited-participants": "Unlimited",
  "allow-late-join": "Allow Late Joining",
  "points-reward": "Points Reward",
  "create-challenge-button": "Create Challenge",
  "active-challenges": "Active",
  "upcoming-challenges": "Upcoming",
  "completed-challenges": "Completed",
  "join-challenge": "Join Challenge",
  "leave-challenge": "Leave Challenge",
  "update-progress": "Update Progress",
  "your-progress": "Your Progress",
  "overall-progress": "Overall Progress",
  "days-remaining": "{days} days remaining",
  "challenge-completed": "Challenge Completed!",
  "challenge-failed": "Challenge Not Completed",
  "leaderboard": "Leaderboard",
  "your-rank": "Your Rank: #{rank}",
  "top-participants": "Top Participants",
  "view-leaderboard": "View Leaderboard",
  "participant-count": "{count} participants",
  "progress-value": "{current}/{target}",
  "progress-percentage": "{percent}% complete",
  "current-streak": "{days} day streak",
  "record-progress": "Record Progress",
  "progress-updated": "Progress updated successfully",
  "challenge-joined": "You joined the challenge!",
  "challenge-left": "You left the challenge",
  "cannot-join-full-challenge": "This challenge is full",
  "cannot-join-completed": "This challenge has ended",
  "confirm-leave-challenge": "Are you sure you want to leave this challenge?",
  "challenge-type-active-days": "Be active every day",
  "challenge-type-message-count": "Send messages",
  "challenge-type-custom": "Custom goal"
}
```
- **Estimated Time:** 3 hours
- **Assignee:** Developer + Translator

#### Testing Tasks

**Task 5.2.15: Widget Tests**
- **Test Files:**
  1. Challenge creation forms
  2. Challenge cards
  3. Progress widgets
  4. Leaderboard
- **Estimated Time:** 8 hours
- **Assignee:** QA Engineer

**Task 5.2.16: Manual Testing Checklist**
- [ ] Can create all challenge types
- [ ] Forms validate correctly
- [ ] Challenge list displays correctly
- [ ] Can join/leave challenges
- [ ] Progress updates work
- [ ] Leaderboard ranks correctly
- [ ] Real-time updates work
- [ ] Animations smooth
- [ ] Empty states display
- [ ] Error handling works
- **Estimated Time:** 4 hours
- **Assignee:** QA Engineer

### Deliverables - Sprint 5 Week 2

- [ ] Challenge creation flow complete
- [ ] All challenge types supported
- [ ] Challenge list screen functional
- [ ] Challenge detail screen complete
- [ ] Leaderboard working
- [ ] Progress updates functional
- [ ] All UI polished
- [ ] Localization complete
- [ ] Widget tests passing

---

## Feature 5.3: Challenges Notifications & Automation

**User Story:** As a challenge participant, I want to receive timely notifications so that I stay on track.

### Technical Tasks

#### Notification System

**Task 5.3.1: Create Challenge Notification Service**
- **File:** `lib/features/groups/domain/services/challenge_notification_service.dart` (new file)
- **Notification Types:**
  1. Challenge starting soon (24h before)
  2. Daily reminder (if not updated today)
  3. Milestone reached (25%, 50%, 75%, 100%)
  4. Falling behind warning
  5. Challenge ending soon (3 days, 1 day, 6 hours)
  6. Challenge completed
  7. Rank changed (moved up/down)
  8. New participant joined
- **Methods:**
```dart
Future<void> sendChallengeReminder(String challengeId, String cpId);
Future<void> sendMilestoneNotification(String challengeId, String cpId, int milestone);
Future<void> sendChallengeComplete(String challengeId, String cpId);
Future<void> sendRankUpdate(String challengeId, String cpId, int oldRank, int newRank);
```
- **Estimated Time:** 6 hours
- **Assignee:** Backend Developer

**Task 5.3.2: Implement Scheduled Notifications**
- **Use Cloud Functions or local scheduler**
- **Schedule:**
  1. Daily check at 8 PM local time
  2. Pre-start reminders
  3. End-of-challenge reminders
- **Estimated Time:** 4 hours
- **Assignee:** Backend Developer

**Task 5.3.3: Add Notification Preferences**
- **File:** `lib/features/groups/presentation/screens/challenge_notification_settings_screen.dart` (new file)
- **Settings:**
  1. Daily reminders toggle
  2. Milestone alerts toggle
  3. Rank updates toggle
  4. Challenge start/end toggle
  5. Quiet hours setting
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

#### Automation

**Task 5.3.4: Create Challenge Auto-Updater**
- **File:** `lib/features/groups/application/challenge_auto_updater.dart` (new file)
- **Functions:**
  1. Auto-update progress based on tracked activities
  2. For "active days" challenges: check daily activity
  3. For "message count" challenges: count messages
  4. Auto-complete challenges when goal met
  5. Auto-fail challenges when time expires
- **Estimated Time:** 6 hours
- **Assignee:** Backend Developer

**Task 5.3.5: Implement Background Jobs**
- **Jobs needed:**
  1. Daily challenge status check
  2. Progress calculation
  3. Ranking updates
  4. Completion checks
  5. Notification delivery
- **Technology:** Cloud Functions (recommended) or local background processing
- **Estimated Time:** 8 hours
- **Assignee:** Backend Developer

**Task 5.3.6: Create Challenge Analytics Tracker**
- **File:** `lib/features/groups/application/challenge_analytics_tracker.dart` (new file)
- **Track:**
  1. Challenge completion rates
  2. Average participation
  3. Most popular challenge types
  4. Engagement metrics
- **Estimated Time:** 4 hours
- **Assignee:** Backend Developer

#### Testing Tasks

**Task 5.3.7: Test Automation**
- **Test Cases:**
  1. Progress auto-updates on activity
  2. Notifications sent at correct times
  3. Challenges auto-complete
  4. Rankings auto-update
- **Estimated Time:** 4 hours
- **Assignee:** QA Engineer

**Task 5.3.8: Manual Testing Checklist**
- [ ] Notifications arrive correctly
- [ ] Daily reminders work
- [ ] Milestone alerts trigger
- [ ] Auto-progress updates work
- [ ] Auto-complete works
- [ ] Rankings update automatically
- [ ] Preferences respected
- **Estimated Time:** 2 hours
- **Assignee:** QA Engineer

### Deliverables - Sprint 5 Week 3

- [ ] Notification system complete
- [ ] Scheduled notifications working
- [ ] Auto-progress updates functional
- [ ] Background jobs running
- [ ] Notification preferences available
- [ ] Analytics tracking in place
- [ ] All tests passing

---

## Sprint 5 Summary

**Total Estimated Time:** 15 working days (3 weeks)

**Sprint Deliverables:**
- [ ] Complete challenges system
- [ ] All challenge types supported
- [ ] Creation, joining, progress tracking working
- [ ] Leaderboards functional
- [ ] Notifications automated
- [ ] UI polished and tested
- [ ] All tests passing

**Sprint Review Checklist:**
- [ ] Demo creating challenge
- [ ] Demo joining and tracking progress
- [ ] Demo leaderboard
- [ ] Demo notifications
- [ ] Show auto-updates
- [ ] Review performance
- [ ] Review test coverage

---

## Firestore Schema Verification

**New Collections Created:**
1. ✅ `group_challenges` - Challenge headers
2. ✅ `challenge_participants` - Participation tracking
3. ✅ `challenge_updates` - Progress updates feed

**Indexes Required:**
```json
{
  "indexes": [
    {
      "collectionGroup": "group_challenges",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "group_challenges",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "challenge_participants",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "challengeId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "progress", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "challenge_participants",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "cpId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "joinedAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Security Rules Added:** ✅ See Task 5.1.16

---

**Sprint 5 Status:** 📋 READY TO START

**Dependencies:** All previous sprints (1-4) must be completed

