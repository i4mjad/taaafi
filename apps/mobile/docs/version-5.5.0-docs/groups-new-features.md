# Groups New Features - Version 5.5.0

**Document Version:** 1.0  
**Last Updated:** November 7, 2025  
**Target Release:** Version 5.5.0  

---

## Overview

This document outlines all NEW major features for the groups functionality, organized by sprint with detailed technical tasks and deliverables.

### New Feature Categories
1. Group Challenges System
2. Shared Updates Feed
3. Group Analytics Dashboard
4. Onboarding Experience
5. Scheduled Messages & Polls

---

## Sprint 5: Group Challenges Foundation (3 weeks)

**Sprint Goal:** Build complete challenges system with creation, participation, and leaderboards

**Duration:** 3 weeks  
**Priority:** HIGH  
**Dependencies:** Sprints 1-4 completed

---

### Feature 5.1: Challenges Infrastructure

**User Story:** As a group member, I want to participate in challenges so that I can stay motivated with the group.

#### Technical Tasks

##### Backend - Database Schema

**Task 5.1.1: Create Challenges Collection Schema**
- **Collection:** `group_challenges`
- **Document Structure:**
```dart
{
  id: string,
  groupId: string,
  title: string (60 chars max),
  description: string (500 chars max),
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
  participants: array<string> (cpIds),
  participantCount: int,
  maxParticipants: int? (null = unlimited),
  
  // Status
  status: 'draft' | 'active' | 'completed' | 'cancelled',
  
  // Metadata
  createdBy: string (cpId),
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
  visibility: 'public' | 'private',
}
```
- **Estimated Time:** 1 hour

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
  progress: int (0-100 percentage or absolute value),
  currentValue: int (e.g., 5 days completed out of 30),
  goalValue: int (e.g., 30 days),
  
  // Status
  status: 'active' | 'completed' | 'failed' | 'quit',
  completedAt: timestamp?,
  
  // Tracking
  joinedAt: timestamp,
  lastUpdateAt: timestamp,
  
  // Daily tracking (for streaks)
  dailyLog: array<timestamp> (dates of activity),
  streakCount: int,
  longestStreak: int,
  
  // Ranking
  rank: int?,
  points: int,
}
```
- **Estimated Time:** 1 hour

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
  value: int?, (for progress updates)
  createdAt: timestamp,
}
```
- **Estimated Time:** 30 minutes

##### Backend - Domain Layer

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

**Task 5.1.5: Create Challenge Participation Entity**
- **File:** `lib/features/groups/domain/entities/challenge_participation_entity.dart` (new file)
- **Properties:** Map all fields
- **Methods:**
  1. `getProgressPercentage()` - personal progress
  2. `isOnTrack()` - check if meeting goals
  3. `updateProgress(int value)` - update current progress
  4. `completeChallenge()` - mark as completed
- **Estimated Time:** 2 hours

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

##### Backend - Data Layer

**Task 5.1.7: Create Challenge Model**
- **File:** `lib/features/groups/data/models/challenge_model.dart` (new file)
- **Methods:**
  1. `fromFirestore(DocumentSnapshot doc)`
  2. `toFirestore()`
  3. `toEntity()`
  4. `fromEntity(ChallengeEntity entity)`
- **Estimated Time:** 2 hours

**Task 5.1.8: Create Challenge Participation Model**
- **File:** `lib/features/groups/data/models/challenge_participation_model.dart` (new file)
- **Methods:** Same as above
- **Estimated Time:** 2 hours

**Task 5.1.9: Create Challenges Firestore DataSource**
- **File:** `lib/features/groups/data/datasources/challenges_firestore_datasource.dart` (new file)
- **Implement all repository methods with Firestore**
- **Include:**
  1. Proper error handling
  2. Transaction support where needed
  3. Batch operations for performance
  4. Real-time listeners
- **Estimated Time:** 8 hours

**Task 5.1.10: Implement Challenges Repository**
- **File:** `lib/features/groups/data/repositories/challenges_repository_impl.dart` (new file)
- **Implement all methods from interface**
- **Add validation:**
  1. Verify group membership before creating
  2. Check if already participating
  3. Validate progress values
  4. Check challenge is active before joining
- **Estimated Time:** 8 hours

##### Backend - Application Layer

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

##### Frontend - Providers

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

##### Firestore Setup

**Task 5.1.15: Create Firestore Indexes**
- **Indexes needed:**
  1. `group_challenges` composite index:
     - `groupId` + `status` + `createdAt`
     - `groupId` + `type` + `startDate`
  2. `challenge_participants` composite index:
     - `challengeId` + `status` + `progress` (for leaderboard)
     - `cpId` + `status` + `joinedAt`
- **Estimated Time:** 1 hour

**Task 5.1.16: Security Rules**
- **File:** Firestore security rules
- **Rules:**
```
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

**Task 5.1.18: Integration Tests**
- **Test Scenarios:**
  1. Complete challenge flow: create → join → progress → complete
  2. Multiple users racing in challenge
  3. Real-time leaderboard updates
  4. Automated progress tracking
- **Estimated Time:** 6 hours

#### Deliverables - Sprint 5 Week 1

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

### Feature 5.2: Challenges UI - Creation & Management

**User Story:** As a group member, I want to create and manage challenges so that I can motivate the group.

#### Technical Tasks

##### UI - Challenge Creation

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

**Task 5.2.5: Create Challenge Preview Widget**
- **File:** `lib/features/groups/presentation/widgets/challenges/challenge_preview_card.dart` (new file)
- **Display:**
  1. Challenge type badge
  2. Title and description
  3. Duration/goal summary
  4. Reward info
  5. "Looks good!" confirmation
- **Estimated Time:** 2 hours

##### UI - Challenge List & Detail

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

##### UI - Progress Management

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

**Task 5.2.11: Create Progress Update Widget**
- **File:** `lib/features/groups/presentation/widgets/challenges/progress_update_item.dart` (new file)
- **Display update in feed:**
  1. User avatar
  2. Name
  3. Update message ("reached 50%!")
  4. Timestamp
  5. Reactions (optional)
- **Estimated Time:** 2 hours

##### Integration Points

**Task 5.2.12: Add Challenges to Group Screen**
- **File:** `lib/features/groups/presentation/screens/group_screen.dart`
- **Actions:**
  1. Replace "Coming Soon" card with real Challenges button
  2. Show active challenge count
  3. Navigate to challenges list
- **Estimated Time:** 1 hour

**Task 5.2.13: Add Challenges to Group Settings**
- **File:** `lib/features/groups/presentation/screens/group_settings_screen.dart`
- **Actions:**
  1. Add "Manage Challenges" for admins
  2. Show count of active challenges
- **Estimated Time:** 1 hour

##### Localization

**Task 5.2.14: Add Localization Keys**
- **File:** Translation files
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

#### Testing Tasks

**Task 5.2.15: Widget Tests**
- **Test Files:**
  1. Challenge creation forms
  2. Challenge cards
  3. Progress widgets
  4. Leaderboard
- **Estimated Time:** 8 hours

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

#### Deliverables - Sprint 5 Week 2

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

### Feature 5.3: Challenges Notifications & Automation

**User Story:** As a challenge participant, I want to receive timely notifications so that I stay on track.

#### Technical Tasks

##### Notification System

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

**Task 5.3.2: Implement Scheduled Notifications**
- **Use Cloud Functions or local scheduler**
- **Schedule:**
  1. Daily check at 8 PM local time
  2. Pre-start reminders
  3. End-of-challenge reminders
- **Estimated Time:** 4 hours

**Task 5.3.3: Add Notification Preferences**
- **File:** `lib/features/groups/presentation/screens/challenge_notification_settings_screen.dart` (new file)
- **Settings:**
  1. Daily reminders toggle
  2. Milestone alerts toggle
  3. Rank updates toggle
  4. Challenge start/end toggle
  5. Quiet hours setting
- **Estimated Time:** 3 hours

##### Automation

**Task 5.3.4: Create Challenge Auto-Updater**
- **File:** `lib/features/groups/application/challenge_auto_updater.dart` (new file)
- **Functions:**
  1. Auto-update progress based on tracked activities
  2. For "active days" challenges: check daily activity
  3. For "message count" challenges: count messages
  4. Auto-complete challenges when goal met
  5. Auto-fail challenges when time expires
- **Estimated Time:** 6 hours

**Task 5.3.5: Implement Background Jobs**
- **Jobs needed:**
  1. Daily challenge status check
  2. Progress calculation
  3. Ranking updates
  4. Completion checks
  5. Notification delivery
- **Technology:** Cloud Functions (recommended) or local background processing
- **Estimated Time:** 8 hours

**Task 5.3.6: Create Challenge Analytics Tracker**
- **File:** `lib/features/groups/application/challenge_analytics_tracker.dart` (new file)
- **Track:**
  1. Challenge completion rates
  2. Average participation
  3. Most popular challenge types
  4. Engagement metrics
- **Estimated Time:** 4 hours

#### Testing Tasks

**Task 5.3.7: Test Automation**
- **Test Cases:**
  1. Progress auto-updates on activity
  2. Notifications sent at correct times
  3. Challenges auto-complete
  4. Rankings auto-update
- **Estimated Time:** 4 hours

**Task 5.3.8: Manual Testing Checklist**
- [ ] Notifications arrive correctly
- [ ] Daily reminders work
- [ ] Milestone alerts trigger
- [ ] Auto-progress updates work
- [ ] Auto-complete works
- [ ] Rankings update automatically
- [ ] Preferences respected
- **Estimated Time:** 2 hours

#### Deliverables - Sprint 5 Week 3

- [ ] Notification system complete
- [ ] Scheduled notifications working
- [ ] Auto-progress updates functional
- [ ] Background jobs running
- [ ] Notification preferences available
- [ ] Analytics tracking in place
- [ ] All tests passing

---

### Sprint 5 Summary

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

## Sprint 6: Shared Updates Feed (2 weeks)

**Sprint Goal:** Build updates feed integrated with user's followup system

**Duration:** 2 weeks  
**Priority:** HIGH  
**Dependencies:** Sprint 5 completed, User followup system exists

---

### Feature 6.1: Updates Infrastructure

**User Story:** As a group member, I want to share my progress updates so that I can stay accountable and receive support.

#### Technical Tasks

##### Backend - Database Schema

**Task 6.1.1: Create Updates Collection Schema**
- **Collection:** `group_updates`
- **Document Structure:**
```dart
{
  id: string,
  groupId: string,
  authorCpId: string,
  
  // Content
  type: 'progress' | 'milestone' | 'checkin' | 'general' | 'encouragement',
  title: string (100 chars),
  content: string (1000 chars),
  imageUrl: string?,
  
  // Links to user data
  linkedFollowupId: string?, // Link to user's followup entry
  linkedChallengeId: string?, // Link to challenge if relevant
  linkedMilestoneId: string?, // Link to achievement/milestone
  
  // Metadata
  isAnonymous: boolean,
  visibility: 'public' | 'members_only',
  
  // Engagement
  reactions: map<string, array<string>>, // emoji -> [cpIds]
  commentCount: int,
  supportCount: int, // count of support reactions
  
  // Status
  isPinned: boolean,
  isHidden: boolean,
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp,
}
```
- **Estimated Time:** 1 hour

**Task 6.1.2: Create Update Comments Collection**
- **Collection:** `update_comments`
- **Document Structure:**
```dart
{
  id: string,
  updateId: string,
  groupId: string,
  authorCpId: string,
  content: string (500 chars),
  isAnonymous: boolean,
  isHidden: boolean,
  reactions: map<string, array<string>>,
  createdAt: timestamp,
}
```
- **Estimated Time:** 30 minutes

##### Backend - Domain Layer

**Task 6.1.3: Create Update Entity**
- **File:** `lib/features/groups/domain/entities/group_update_entity.dart` (new file)
- **Properties:** Map all fields
- **Methods:**
  1. `getReactionCount(String emoji)`
  2. `hasUserReacted(String cpId, String emoji)`
  3. `getTotalReactions()`
  4. `canEdit(String cpId)` - check if user can edit
  5. `canDelete(String cpId, bool isAdmin)` - check permissions
- **Estimated Time:** 2 hours

**Task 6.1.4: Create Update Comment Entity**
- **File:** `lib/features/groups/domain/entities/update_comment_entity.dart` (new file)
- **Properties:** Map all fields
- **Estimated Time:** 1 hour

**Task 6.1.5: Create Updates Repository Interface**
- **File:** `lib/features/groups/domain/repositories/updates_repository.dart` (new file)
- **Methods:**
```dart
// Update CRUD
Future<String> createUpdate(GroupUpdateEntity update);
Future<GroupUpdateEntity?> getUpdateById(String updateId);
Future<void> updateUpdate(GroupUpdateEntity update);
Future<void> deleteUpdate(String updateId);

// Update queries
Stream<List<GroupUpdateEntity>> getGroupUpdates(String groupId);
Future<List<GroupUpdateEntity>> getRecentUpdates(String groupId, int limit);
Future<List<GroupUpdateEntity>> getUserUpdates(String groupId, String cpId);
Future<List<GroupUpdateEntity>> getUpdatesByType(String groupId, String type);

// Reactions
Future<void> toggleReaction(String updateId, String cpId, String emoji);

// Comments
Future<String> addComment(UpdateCommentEntity comment);
Future<void> deleteComment(String commentId);
Stream<List<UpdateCommentEntity>> getUpdateComments(String updateId);

// Moderation
Future<void> hideUpdate(String updateId, String adminCpId);
Future<void> unhideUpdate(String updateId, String adminCpId);
Future<void> pinUpdate(String updateId, String adminCpId);
Future<void> unpinUpdate(String updateId, String adminCpId);
```
- **Estimated Time:** 2 hours

##### Backend - Data Layer

**Task 6.1.6: Create Update Model**
- **File:** `lib/features/groups/data/models/group_update_model.dart` (new file)
- **Standard model methods**
- **Estimated Time:** 2 hours

**Task 6.1.7: Create Update Comment Model**
- **File:** `lib/features/groups/data/models/update_comment_model.dart` (new file)
- **Standard model methods**
- **Estimated Time:** 1 hour

**Task 6.1.8: Implement Updates Repository**
- **File:** `lib/features/groups/data/repositories/updates_repository_impl.dart` (new file)
- **Implement all methods with Firestore**
- **Add validation and error handling**
- **Estimated Time:** 8 hours

##### Backend - Application Layer

**Task 6.1.9: Create Updates Service**
- **File:** `lib/features/groups/domain/services/updates_service.dart` (new file)
- **Methods:**
```dart
// Post update
Future<PostUpdateResult> postUpdate({...});

// Link to followup system
Future<GroupUpdateEntity> createUpdateFromFollowup(String followupId, String groupId);

// Link to milestone
Future<GroupUpdateEntity> createMilestoneUpdate(String milestoneId, String groupId);

// Auto-suggest updates
Future<List<UpdateSuggestion>> getSuggestedUpdates(String cpId, String groupId);

// Engagement
Future<void> reactToUpdate(String updateId, String cpId, String emoji);
Future<void> commentOnUpdate(String updateId, String cpId, String content);
```
- **Estimated Time:** 6 hours

**Task 6.1.10: Create Followup Integration Service**
- **File:** `lib/features/groups/domain/services/followup_integration_service.dart` (new file)
- **Purpose:** Bridge between followup system and updates
- **Methods:**
```dart
// Get user's recent followups
Future<List<FollowupEntry>> getRecentFollowups(String cpId);

// Check if followup already shared
Future<bool> isFollowupShared(String followupId, String groupId);

// Get suggested content from followup
String generateUpdateContent(FollowupEntry followup);

// Link update to followup
Future<void> linkUpdateToFollowup(String updateId, String followupId);
```
- **Estimated Time:** 4 hours

##### Frontend - Providers

**Task 6.1.11: Create Updates Providers**
- **File:** `lib/features/groups/providers/updates_providers.dart` (new file)
- **Providers:**
```dart
@riverpod Stream<List<GroupUpdateEntity>> groupUpdates(ref, groupId);
@riverpod Future<GroupUpdateEntity?> updateById(ref, updateId);
@riverpod Stream<List<UpdateCommentEntity>> updateComments(ref, updateId);
@riverpod Future<List<UpdateSuggestion>> updateSuggestions(ref, cpId, groupId);
```
- **Estimated Time:** 3 hours

**Task 6.1.12: Create Updates Controller**
- **File:** `lib/features/groups/application/updates_controller.dart` (new file)
- **Controller methods with state management**
- **Estimated Time:** 3 hours

##### Firestore Setup

**Task 6.1.13: Create Indexes and Security Rules**
- **Indexes:**
  1. `group_updates`: `groupId` + `createdAt` + `isPinned`
  2. `update_comments`: `updateId` + `createdAt`
- **Security Rules:** Read/write permissions
- **Estimated Time:** 2 hours

#### Testing Tasks

**Task 6.1.14: Unit Tests**
- **Test all repository and service methods**
- **Estimated Time:** 6 hours

#### Deliverables - Sprint 6 Week 1

- [ ] Database schema implemented
- [ ] Domain entities created
- [ ] Repository complete
- [ ] Services with business logic
- [ ] Followup integration working
- [ ] Providers created
- [ ] Tests passing

---

### Feature 6.2: Updates Feed UI

**User Story:** As a group member, I want to view and interact with updates so that I can support others and stay connected.

#### Technical Tasks

##### UI Components

**Task 6.2.1: Create Updates Feed Screen**
- **File:** `lib/features/groups/presentation/screens/updates/group_updates_feed_screen.dart` (new file)
- **Sections:**
  1. **Header:**
     - "Updates" title
     - Filter button (All, Progress, Milestones, Check-ins)
     - Post button (FAB)
  2. **Pinned Updates:**
     - Horizontal scrollable cards
     - Max 3 pinned
  3. **Feed:**
     - Infinite scroll list
     - Pull-to-refresh
     - Update cards
     - "Load More" at bottom
  4. **Empty State:**
     - "No updates yet"
     - "Be the first to share!" button
- **Estimated Time:** 5 hours

**Task 6.2.2: Create Update Card Widget**
- **File:** `lib/features/groups/presentation/widgets/updates/update_card_widget.dart` (new file)
- **Display:**
  1. **Header:**
     - Avatar (or anonymous icon)
     - Name (or "Anonymous Member")
     - Update type badge
     - Timestamp
     - Options menu (3 dots)
  2. **Content:**
     - Title (if exists)
     - Content text (expand/collapse if long)
     - Image (if exists)
     - Linked challenge badge (if applicable)
  3. **Engagement Bar:**
     - Reactions row (emoji counts)
     - Add reaction button
     - Comment count with icon
     - Support button (heart)
  4. **Comments Preview:**
     - Show first 2 comments
     - "View all X comments" button
- **Interactions:**
  - Tap image to view full screen
  - Tap reactions to see who reacted
  - Tap comments to expand all
  - Long press for quick actions
- **Estimated Time:** 6 hours

**Task 6.2.3: Create Post Update Modal**
- **File:** `lib/features/groups/presentation/widgets/updates/post_update_modal.dart` (new file)
- **UI:**
  1. **Type Selector:**
     - Chips: Progress, Milestone, Check-in, General
  2. **Content Input:**
     - Title field (optional, 100 chars)
     - Content textarea (required, 1000 chars)
     - Character counter
  3. **Options:**
     - Add image button (camera/gallery)
     - Link followup toggle (if applicable)
     - Anonymous posting toggle
     - Link challenge selector (if in challenge)
  4. **Followup Integration Section:**
     - "Share from your followup" button
     - Shows recent followups
     - Auto-fill content option
  5. **Preview:**
     - Show how update will look
  6. **Actions:**
     - Cancel button
     - Post button (disabled if invalid)
- **Estimated Time:** 6 hours

**Task 6.2.4: Create Followup Selector Modal**
- **File:** `lib/features/groups/presentation/widgets/updates/followup_selector_modal.dart` (new file)
- **UI:**
  1. List of recent followups (last 7 days)
  2. Each shows:
     - Date
     - Type (prayer, activity, etc.)
     - Preview of content
     - "Already shared" badge if applicable
  3. Select button
  4. Auto-populate update with followup data
- **Estimated Time:** 4 hours

**Task 6.2.5: Create Comment Section Widget**
- **File:** `lib/features/groups/presentation/widgets/updates/update_comments_widget.dart` (new file)
- **UI:**
  1. Comments list
  2. Each comment shows:
     - Avatar
     - Name
     - Content
     - Timestamp
     - Reactions
     - Reply button (future feature)
  3. Add comment field at bottom
  4. Send button
- **Estimated Time:** 4 hours

**Task 6.2.6: Create Update Details Screen**
- **File:** `lib/features/groups/presentation/screens/updates/update_detail_screen.dart` (new file)
- **Purpose:** Full screen view of single update
- **Sections:**
  1. Full update card
  2. All comments
  3. Engagement details
- **Estimated Time:** 3 hours

**Task 6.2.7: Create Weekly Check-in Prompt**
- **File:** `lib/features/groups/presentation/widgets/updates/weekly_checkin_prompt_widget.dart` (new file)
- **UI:**
  1. Friendly prompt card at top of feed
  2. "How was your week?" message
  3. Quick post button
  4. Dismiss for this week option
- **Show logic:**
  - Only once per week
  - Only if user hasn't posted in 7 days
  - Dismissible
- **Estimated Time:** 3 hours

##### Integration Points

**Task 6.2.8: Add Updates to Group Screen**
- **File:** `lib/features/groups/presentation/screens/group_screen.dart`
- **Actions:**
  1. Replace "Coming Soon" card with real Updates button
  2. Show recent update count
  3. Navigate to updates feed
- **Estimated Time:** 1 hour

**Task 6.2.9: Link from Challenges**
- **File:** Challenge detail screen
- **Actions:**
  1. Add "Share Update" button
  2. Pre-fill with challenge info
  3. Auto-link to challenge
- **Estimated Time:** 2 hours

##### Localization

**Task 6.2.10: Add Localization Keys**
- **Keys:** (80+ keys)
```json
{
  "updates": "Updates",
  "updates-feed": "Updates Feed",
  "post-update": "Post Update",
  "share-update": "Share Update",
  "update-types": "Update Types",
  "progress-update": "Progress Update",
  "milestone-update": "Milestone",
  "checkin-update": "Check-in",
  "general-update": "General",
  "encouragement": "Encouragement",
  "update-title": "Title (optional)",
  "update-content": "What's your update?",
  "add-image": "Add Image",
  "post-anonymously": "Post Anonymously",
  "link-followup": "Link to Followup",
  "link-challenge": "Link to Challenge",
  "post-update-button": "Post Update",
  "update-posted": "Update posted!",
  "select-from-followup": "Share from Followup",
  "recent-followups": "Recent Followups",
  "already-shared": "Already Shared",
  "no-recent-followups": "No recent followups",
  "view-all-comments": "View all {count} comments",
  "add-comment": "Add a comment...",
  "send-comment": "Send",
  "comment-added": "Comment added",
  "delete-update": "Delete Update",
  "edit-update": "Edit Update",
  "hide-update": "Hide Update",
  "pin-update": "Pin Update",
  "report-update": "Report Update",
  "confirm-delete-update": "Are you sure you want to delete this update?",
  "update-deleted": "Update deleted",
  "no-updates-yet": "No updates yet",
  "be-first-to-share": "Be the first to share your progress!",
  "filter-updates": "Filter Updates",
  "weekly-checkin-prompt": "How was your week? Share an update with the group!",
  "dismiss-checkin": "Ask me next week",
  "linked-to-challenge": "Linked to challenge: {challengeName}",
  "linked-to-followup": "Shared from followup"
}
```
- **Estimated Time:** 2 hours

#### Testing Tasks

**Task 6.2.11: Widget Tests**
- **Test all update widgets**
- **Estimated Time:** 6 hours

**Task 6.2.12: Manual Testing Checklist**
- [ ] Can post all update types
- [ ] Can link followup data
- [ ] Can link challenges
- [ ] Images upload correctly
- [ ] Anonymous posting works
- [ ] Comments work
- [ ] Reactions work
- [ ] Feed loads smoothly
- [ ] Pull-to-refresh works
- [ ] Infinite scroll works
- [ ] Edit/delete works (own updates)
- [ ] Admin can hide updates
- [ ] Pin/unpin works
- [ ] Empty states display
- **Estimated Time:** 3 hours

#### Deliverables - Sprint 6 Week 2

- [ ] Updates feed complete
- [ ] Post update flow working
- [ ] Followup integration functional
- [ ] Challenge linking works
- [ ] Comments system complete
- [ ] Reactions working
- [ ] All UI polished
- [ ] Localization complete
- [ ] Tests passing

---

### Sprint 6 Summary

**Total Estimated Time:** 10 working days (2 weeks)

**Sprint Deliverables:**
- [ ] Complete updates feed system
- [ ] Post/view/interact with updates
- [ ] Followup integration working
- [ ] Challenge integration working
- [ ] Comments and reactions functional
- [ ] UI polished
- [ ] All tests passing

**Sprint Review Checklist:**
- [ ] Demo posting update
- [ ] Demo followup integration
- [ ] Demo challenge linking
- [ ] Demo engagement features
- [ ] Show real-time updates
- [ ] Review performance

---

## Sprint 7: Analytics Dashboard (1.5 weeks)

**Sprint Goal:** Build comprehensive analytics for admins

**Duration:** 1.5 weeks  
**Priority:** MEDIUM  
**Dependencies:** Sprints 1-6 completed

---

### Feature 7.1: Analytics Infrastructure

**User Story:** As a group admin, I want to view detailed analytics so that I can understand group health and engagement.

#### Technical Tasks

##### Backend - Analytics Collection

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
  activeMembers: int, // active in last 24h
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
  healthScore: float, // 0-100
}
```
- **Estimated Time:** 1 hour

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

**Task 7.1.3: Create Analytics Aggregation Job**
- **File:** Cloud Function or background service
- **Function:** Run daily at midnight
- **Process:**
  1. Calculate all metrics for previous day
  2. Store in analytics collection
  3. Update trends
  4. Generate insights
- **Estimated Time:** 6 hours

**Task 7.1.4: Create Analytics Entities**
- **Files:** Multiple entity files for analytics data
- **Entities:**
  - `DailyAnalyticsEntity`
  - `AnalyticsSummaryEntity`
  - `InsightEntity`
  - `TopMemberEntity`
- **Estimated Time:** 4 hours

**Task 7.1.5: Create Analytics Repository**
- **File:** `lib/features/groups/domain/repositories/analytics_repository.dart` (new file)
- **Implement all query methods**
- **Estimated Time:** 6 hours

##### Frontend - Providers

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

#### Testing

**Task 7.1.7: Test Analytics Calculations**
- **Test Cases:**
  1. Daily aggregation accurate
  2. Health score calculated correctly
  3. Trends identified correctly
  4. Top members ranked correctly
- **Estimated Time:** 4 hours

#### Deliverables - Part 1

- [ ] Analytics schema designed
- [ ] Analytics service implemented
- [ ] Daily aggregation job running
- [ ] Repository complete
- [ ] Providers created
- [ ] Tests passing

---

### Feature 7.2: Analytics Dashboard UI

**User Story:** As a group admin, I want an intuitive dashboard so that I can quickly understand group performance.

#### Technical Tasks

##### UI Components

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

**Task 7.2.2: Create Overview Card Widget**
- **File:** `lib/features/groups/presentation/widgets/analytics/analytics_overview_card.dart` (new file)
- **Display:**
  1. Icon
  2. Value (large number)
  3. Label
  4. Trend indicator (up/down arrow)
  5. Comparison text ("↑ 12% vs last week")
- **Estimated Time:** 2 hours

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

**Task 7.2.4: Create Activity Heatmap**
- **File:** `lib/features/groups/presentation/widgets/analytics/activity_heatmap.dart` (new file)
- **Display:**
  1. Grid: Days (rows) × Hours (columns)
  2. Color intensity based on message count
  3. Legend
  4. Tap to see details
- **Estimated Time:** 5 hours

**Task 7.2.5: Create Engagement Chart**
- **File:** `lib/features/groups/presentation/widgets/analytics/engagement_chart.dart` (new file)
- **Chart Type:** Bar chart
- **Data:** Daily engagement score
- **Estimated Time:** 3 hours

**Task 7.2.6: Create Top Members Widget**
- **File:** `lib/features/groups/presentation/widgets/analytics/top_members_widget.dart` (new file)
- **Display:**
  1. Ranked list (1-5)
  2. Avatar
  3. Name
  4. Stats (messages, reactions, etc.)
  5. Trend indicator
- **Estimated Time:** 3 hours

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

**Task 7.2.8: Create Export Functionality**
- **File:** Part of dashboard screen
- **Features:**
  1. Generate CSV with all analytics data
  2. Include member list with stats
  3. Include charts as images (optional)
  4. Share via platform share sheet
- **Estimated Time:** 3 hours

##### Integration

**Task 7.2.9: Add Analytics to Group Settings**
- **File:** `lib/features/groups/presentation/screens/group_settings_screen.dart`
- **Actions:**
  1. Add "Analytics" card for admins
  2. Show preview stat (e.g., "52% engagement this week")
  3. Navigate to dashboard
- **Estimated Time:** 1 hour

##### Localization

**Task 7.2.10: Add Localization Keys**
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
  "analytics-exported": "Analytics exported successfully"
}
```
- **Estimated Time:** 1 hour

#### Testing

**Task 7.2.11: Widget Tests**
- **Test all analytics widgets**
- **Estimated Time:** 4 hours

**Task 7.2.12: Manual Testing Checklist**
- [ ] Dashboard loads within 2 seconds
- [ ] All metrics display correctly
- [ ] Charts render properly
- [ ] Period selector works
- [ ] Top members accurate
- [ ] Insights generated correctly
- [ ] Export works
- [ ] Responsive on different screens
- **Estimated Time:** 2 hours

#### Deliverables - Part 2

- [ ] Analytics dashboard complete
- [ ] All charts working
- [ ] Insights displayed
- [ ] Export functional
- [ ] UI polished
- [ ] Tests passing

---

### Sprint 7 Summary

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

## Sprint 8: Onboarding & Polish (1 week)

**Sprint Goal:** Implement onboarding experience and final polish

**Duration:** 1 week  
**Priority:** LOW-MEDIUM  
**Dependencies:** All previous sprints completed

---

### Feature 8.1: Group Onboarding

**User Story:** As a new group member, I want a guided onboarding so that I understand how to use the group effectively.

#### Technical Tasks

**Task 8.1.1: Create Welcome Message System**
- **File:** `lib/features/groups/domain/services/group_onboarding_service.dart` (new file)
- **Features:**
  1. Configurable welcome message by admin
  2. Auto-send on member join
  3. Support for rich text
  4. Optional welcome checklist
- **Estimated Time:** 4 hours

**Task 8.1.2: Create Group Rules System**
- **File:** Extension of welcome system
- **Features:**
  1. Admin can set group rules
  2. New members must acknowledge rules
  3. Rules displayed in settings
  4. Can update rules (members notified)
- **Estimated Time:** 4 hours

**Task 8.1.3: Create Welcome Screen**
- **File:** `lib/features/groups/presentation/screens/onboarding/group_welcome_screen.dart` (new file)
- **UI:**
  1. Group name and description
  2. Welcome message from admin
  3. Group rules (if set)
  4. Accept rules checkbox
  5. Introduction prompt
  6. "Get Started" button
- **Estimated Time:** 4 hours

**Task 8.1.4: Create Introduction Prompt**
- **File:** `lib/features/groups/presentation/widgets/onboarding/introduction_prompt_modal.dart` (new file)
- **UI:**
  1. "Introduce yourself to the group!" message
  2. Quick template suggestions
  3. Text field for introduction
  4. Post to chat button
  5. Skip button
- **Estimated Time:** 3 hours

**Task 8.1.5: Implement Welcome Flow**
- **Flow:**
  1. Member joins group
  2. Show welcome screen (modal)
  3. Display welcome message
  4. Show rules (if exist), require acknowledgment
  5. Prompt introduction (skippable)
  6. Navigate to group screen
- **Estimated Time:** 3 hours

**Task 8.1.6: Add Rules to Group Settings**
- **File:** `lib/features/groups/presentation/screens/group_rules_settings_screen.dart` (new file)
- **Admin UI:**
  1. Edit rules text area
  2. Toggle "Require acknowledgment"
  3. Preview
  4. Save button
- **Member UI:**
  1. View-only rules display
  2. Acknowledged date
- **Estimated Time:** 3 hours

#### Localization

**Task 8.1.7: Add Localization Keys**
- **Keys:**
```json
{
  "welcome-to-group": "Welcome to {groupName}!",
  "group-rules": "Group Rules",
  "acknowledge-rules": "I acknowledge and agree to follow the group rules",
  "rules-required": "You must acknowledge the rules to continue",
  "introduce-yourself": "Introduce Yourself",
  "introduction-prompt": "Say hello to the group!",
  "introduction-placeholder": "Hi everyone! I'm...",
  "post-introduction": "Post Introduction",
  "skip-introduction": "Skip for now",
  "get-started": "Get Started",
  "set-group-rules": "Set Group Rules",
  "edit-group-rules": "Edit Group Rules",
  "no-rules-set": "No rules have been set for this group",
  "rules-updated": "Group rules updated",
  "members-will-be-notified": "Members will be notified of rule updates",
  "welcome-message": "Welcome Message",
  "set-welcome-message": "Set Welcome Message",
  "welcome-message-placeholder": "Welcome new members with a custom message...",
  "introduction-templates": "Templates",
  "template-short-intro": "Hi! I'm looking forward to being part of this group.",
  "template-goals": "Hello! I joined to work on...",
  "template-support": "Hi everyone! Excited to support each other!"
}
```
- **Estimated Time:** 1 hour

#### Testing

**Task 8.1.8: Manual Testing Checklist**
- [ ] Welcome screen shows on join
- [ ] Welcome message displays correctly
- [ ] Rules acknowledgment required (if set)
- [ ] Introduction prompt appears
- [ ] Can skip introduction
- [ ] Intro posts to chat correctly
- [ ] Admin can edit rules
- [ ] Admin can edit welcome message
- [ ] Changes save correctly
- **Estimated Time:** 1 hour

#### Deliverables - Part 1

- [ ] Welcome system complete
- [ ] Rules system functional
- [ ] Introduction prompt working
- [ ] Admin configuration screens
- [ ] Onboarding flow smooth
- [ ] Tests passing

---

### Feature 8.2: Scheduled Messages & Polls

**User Story:** As an admin, I want to schedule messages and create polls so that I can manage communication better.

#### Technical Tasks

**Task 8.2.1: Create Scheduled Messages**
- **Backend:**
  1. Add `scheduled_messages` collection
  2. Background job to send at scheduled time
  3. Admin-only creation
- **UI:**
  1. Schedule button in compose message
  2. Date/time picker
  3. Preview scheduled messages list
  4. Edit/delete scheduled messages
- **Estimated Time:** 6 hours

**Task 8.2.2: Create Polls System**
- **Backend:**
  1. Add `polls` collection
  2. Poll entity with options and votes
  3. Vote tracking
- **UI:**
  1. Create poll modal
  2. Add poll options (2-10)
  3. Duration setting
  4. Display poll in chat
  5. Vote on poll
  6. Show results
- **Estimated Time:** 8 hours

#### Localization

**Task 8.2.3: Add Localization Keys**
- **Keys:**
```json
{
  "schedule-message": "Schedule Message",
  "scheduled-messages": "Scheduled Messages",
  "schedule-for": "Schedule for",
  "message-scheduled": "Message scheduled",
  "create-poll": "Create Poll",
  "poll-question": "Poll Question",
  "poll-options": "Poll Options",
  "add-option": "Add Option",
  "poll-duration": "Poll Duration",
  "create-poll-button": "Create Poll",
  "vote": "Vote",
  "votes": "Votes",
  "poll-ended": "Poll Ended",
  "poll-results": "Results",
  "you-voted": "You voted for:",
  "poll-closes-in": "Closes in {time}"
}
```
- **Estimated Time:** 30 minutes

#### Testing

**Task 8.2.4: Manual Testing Checklist**
- [ ] Can schedule messages
- [ ] Messages send at correct time
- [ ] Can edit/delete scheduled messages
- [ ] Can create polls
- [ ] Can vote on polls
- [ ] Results display correctly
- [ ] Poll expires correctly
- **Estimated Time:** 1 hour

#### Deliverables - Part 2

- [ ] Scheduled messages working
- [ ] Polls functional
- [ ] Admin controls working
- [ ] UI polished
- [ ] Tests passing

---

### Feature 8.3: Final Polish & Bug Fixes

**Task 8.3.1: Performance Optimization**
- **Actions:**
  1. Optimize query performance
  2. Add caching where needed
  3. Lazy load images
  4. Optimize animations
  5. Reduce bundle size
- **Estimated Time:** 6 hours

**Task 8.3.2: Accessibility Review**
- **Actions:**
  1. Add semantic labels
  2. Test screen readers
  3. Improve contrast ratios
  4. Add keyboard navigation support
- **Estimated Time:** 4 hours

**Task 8.3.3: Bug Fixes**
- **Actions:**
  1. Fix any bugs found in testing
  2. Address edge cases
  3. Improve error messages
  4. Fix UI inconsistencies
- **Estimated Time:** 6 hours

**Task 8.3.4: Documentation**
- **Actions:**
  1. Update API documentation
  2. Create user guides
  3. Add code comments
  4. Update README
- **Estimated Time:** 4 hours

#### Deliverables - Part 3

- [ ] Performance optimized
- [ ] Accessibility improved
- [ ] All bugs fixed
- [ ] Documentation complete
- [ ] Ready for release

---

### Sprint 8 Summary

**Total Estimated Time:** 5 working days (1 week)

**Sprint Deliverables:**
- [ ] Onboarding experience complete
- [ ] Scheduled messages working
- [ ] Polls functional
- [ ] Performance optimized
- [ ] Accessibility improved
- [ ] All bugs fixed
- [ ] Ready for production

**Sprint Review Checklist:**
- [ ] Demo onboarding flow
- [ ] Demo scheduled messages
- [ ] Demo polls
- [ ] Review performance improvements
- [ ] Review accessibility
- [ ] Final QA approval

---

## Overall Project Timeline

### Total Duration: 12.5 weeks

- **Sprint 5:** Weeks 1-3 (Challenges System)
- **Sprint 6:** Weeks 4-5 (Updates Feed)
- **Sprint 7:** Weeks 6-7.5 (Analytics Dashboard)
- **Sprint 8:** Weeks 8-8.5 (Onboarding & Polish)

### Milestones

**Milestone 1: Challenges Live (End of Sprint 5)**
- ✅ Complete challenges system
- ✅ All challenge types supported
- ✅ Notifications working

**Milestone 2: Updates Feed Live (End of Sprint 6)**
- ✅ Updates feed functional
- ✅ Followup integration working
- ✅ Engagement features active

**Milestone 3: Analytics Ready (End of Sprint 7)**
- ✅ Analytics dashboard complete
- ✅ Insights generation working
- ✅ Export functional

**Milestone 4: Production Ready (End of Sprint 8)**
- ✅ Onboarding complete
- ✅ All features polished
- ✅ Performance optimized
- ✅ Ready for release

---

## Dependencies & Prerequisites

### External Packages
- `fl_chart` - for analytics charts
- `csv` - for data export
- `image_picker` - for update images

### Infrastructure
- Cloud Functions for:
  - Daily analytics aggregation
  - Scheduled notifications
  - Scheduled messages
  - Challenge auto-updates
- Firestore indexes for all queries
- Cloud Storage for images

### Internal Dependencies
- User followup system must be accessible
- User milestone system (for achievements)
- Notification system
- Community profile system

---

## Testing Strategy

### Unit Testing
- Target: 85%+ code coverage
- Test all business logic
- Test calculations (analytics, scores)
- Mock external dependencies

### Integration Testing
- Test complete user flows
- Test real-time synchronization
- Test cross-feature integration
- Test performance under load

### Manual Testing
- Test on iOS and Android
- Test with 50 members
- Test with slow network
- Test all user roles
- Accessibility testing

### Performance Testing
- Load time < 2s for all screens
- Charts render < 1s
- Smooth 60fps animations
- Memory usage < 150MB
- Battery usage reasonable

---

## Risk Management

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Challenges too complex for users | Medium | High | Start simple, iterate based on feedback |
| Performance issues with analytics | Medium | Medium | Optimize queries, use caching, lazy loading |
| Followup integration issues | Low | Medium | Test integration early, fallback options |
| Timeline slippage | Medium | Medium | Buffer time built in, parallel work |
| User adoption low | Medium | High | Onboarding, tutorials, incentives |

---

## Success Metrics

### Quantitative
- 70%+ groups create at least one challenge
- 50%+ members participate in challenges
- 40%+ members post updates weekly
- 60%+ admins check analytics weekly
- 90%+ new members complete onboarding
- < 2s load time for all screens
- 0 critical production bugs

### Qualitative
- Positive user feedback
- Increased engagement and retention
- Active participation in features
- Smooth onboarding experience
- Intuitive analytics

---

## Post-Sprint Activities

### Beta Testing (Week 13)
- Release to beta group
- Gather feedback
- Monitor metrics
- Quick bug fixes

### Staged Rollout (Weeks 14-15)
- 10% rollout
- Monitor crash reports
- 50% rollout
- Full rollout

### Support & Monitoring
- Monitor user feedback
- Track success metrics
- Quick response to issues
- Plan iteration based on data

---

**END OF NEW FEATURES DOCUMENT**

