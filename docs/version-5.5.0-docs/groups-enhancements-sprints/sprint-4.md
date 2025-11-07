# Sprint 4: Member Experience & Mobile UX (1.5 weeks)

**Sprint Goal:** Enhance member profiles and improve mobile user experience

**Duration:** 1.5 weeks  
**Priority:** LOW-MEDIUM  
**Dependencies:** Sprints 1-3 completed

---

## Feature 4.1: Enhanced Member Profiles

**User Story:** As a group member, I want to view and update my profile visible to the group so that others can learn more about me.

### Technical Tasks

#### Backend Tasks

**Task 4.1.1: Add Profile Fields to Community Profile**
- **File:** `lib/features/community/domain/entities/community_profile_entity.dart`
- **Fields (if not already exist):**
  1. `groupBio` (String?, 200 chars max)
  2. `interests` (List<String>, tags/categories)
  3. `groupAchievements` (List<Achievement>)
- **Note:** Check if these exist in community profile already
- **Estimated Time:** 2 hours

**Task 4.1.2: Create Achievement Entity**
- **File:** `lib/features/groups/domain/entities/group_achievement_entity.dart` (new file)
- **Properties:**
```dart
class GroupAchievementEntity {
  final String id;
  final String groupId;
  final String cpId;
  final String achievementType; // 'first_message', 'week_streak', etc.
  final String title;
  final String description;
  final String? iconUrl;
  final DateTime earnedAt;
}
```
- **Estimated Time:** 1 hour

**Task 4.1.3: Add Profile Update Methods**
- **File:** `lib/features/community/domain/repositories/community_repository.dart`
- **Methods:**
```dart
/// Update group-specific bio
Future<void> updateGroupBio(String cpId, String bio);

/// Update interests/tags
Future<void> updateInterests(String cpId, List<String> interests);
```
- **Estimated Time:** 2 hours

**Task 4.1.4: Create Achievements System**
- **File:** `lib/features/groups/domain/services/group_achievements_service.dart` (new file)
- **Methods:**
  1. `checkAndAwardAchievements(String groupId, String cpId)` - check if earned
  2. `getAchievements(String groupId, String cpId)` - get user's achievements
  3. `getAllAchievements()` - get achievement definitions
- **Achievement Types:**
  - First Message
  - Welcome (joined group)
  - Week Warrior (active 7 days straight)
  - Month Master (active 30 days)
  - Helpful (10+ supportive reactions received)
  - Top Contributor (most messages in a month)
- **Estimated Time:** 5 hours

#### Frontend Tasks

**Task 4.1.5: Create Profile View Modal**
- **File:** `lib/features/groups/presentation/widgets/member_profile_modal.dart` (new file)
- **Sections:**
  1. **Header:**
     - Avatar
     - Name
     - Role badge
     - Join date
  2. **Bio Section:**
     - Bio text (or "No bio yet")
  3. **Interests/Tags:**
     - Chip list of interests
  4. **Achievements:**
     - Grid of earned badges
     - Lock icon for unearned
  5. **Stats:**
     - Messages sent
     - Days active
     - Engagement score
  6. **Actions:**
     - Message button (opens 1-on-1 chat)
     - Edit button (if own profile)
- **Estimated Time:** 5 hours

**Task 4.1.6: Create Profile Edit Modal**
- **File:** `lib/features/groups/presentation/widgets/edit_member_profile_modal.dart` (new file)
- **Fields:**
  1. Bio text area (200 char limit with counter)
  2. Interests selector (multi-select chips)
  3. Available interests: Fitness, Wellness, Faith, Study, Support, Goals, etc.
  4. Save button
- **Estimated Time:** 3 hours

**Task 4.1.7: Update Member Item to Show Profile**
- **File:** `lib/features/groups/presentation/widgets/group_member_item.dart`
- **Actions:**
  1. Tap member to open profile modal
  2. Show preview of bio (first 50 chars)
  3. Show interest count
- **Estimated Time:** 2 hours

**Task 4.1.8: Add Profile Link to Settings**
- **File:** `lib/features/groups/presentation/screens/group_settings_screen.dart`
- **Actions:**
  1. Add "My Group Profile" card
  2. Show preview of bio
  3. Navigate to edit modal
- **Estimated Time:** 1 hour

**Task 4.1.9: Create Achievement Badge Widget**
- **File:** `lib/features/groups/presentation/widgets/achievement_badge_widget.dart` (new file)
- **UI:**
  1. Circular badge with icon
  2. Colored border if earned
  3. Gray/locked if not earned
  4. Tap to show details
- **Estimated Time:** 2 hours

#### Localization Tasks

**Task 4.1.10: Add Localization Keys**
- **Keys to Add:**
```json
{
  "member-profile": "Member Profile",
  "my-group-profile": "My Group Profile",
  "edit-profile": "Edit Profile",
  "group-bio": "Group Bio",
  "interests": "Interests",
  "achievements": "Achievements",
  "member-stats": "Member Stats",
  "days-active": "Days Active",
  "messages-sent": "Messages Sent",
  "add-bio": "Add a bio to tell others about yourself",
  "bio-placeholder": "Tell the group about yourself...",
  "select-interests": "Select your interests",
  "no-achievements-yet": "No achievements earned yet",
  "achievement-earned": "Achievement Earned!",
  "message-member": "Message {name}",
  "view-full-profile": "View Full Profile",
  "profile-updated": "Profile updated successfully",
  "first-message-achievement": "First Message",
  "first-message-desc": "Sent your first message to the group",
  "welcome-achievement": "Welcome",
  "welcome-desc": "Joined the group",
  "week-warrior-achievement": "Week Warrior",
  "week-warrior-desc": "Active for 7 days straight",
  "month-master-achievement": "Month Master",
  "month-master-desc": "Active for 30 days straight",
  "helpful-achievement": "Helpful",
  "helpful-desc": "Received 10+ supportive reactions",
  "top-contributor-achievement": "Top Contributor",
  "top-contributor-desc": "Most active member this month"
}
```
- **Estimated Time:** 1 hour

#### Testing Tasks

**Task 4.1.11: Unit Tests**
- **Test Cases:**
  1. Profile update saves correctly
  2. Bio validation works (200 chars)
  3. Achievements awarded correctly
  4. Achievement checks work
- **Estimated Time:** 3 hours

**Task 4.1.12: Manual Testing Checklist**
- [ ] Can view member profile
- [ ] Can edit own profile
- [ ] Bio saves correctly
- [ ] Interests save correctly
- [ ] Achievements display correctly
- [ ] Message button works
- [ ] Stats accurate
- [ ] Modals look good
- **Estimated Time:** 1 hour

### Deliverables

- [ ] Member profiles viewable
- [ ] Profile editing works
- [ ] Achievements system functional
- [ ] Direct messaging integrated
- [ ] All tests passing

---

## Feature 4.2: Mobile UX Improvements

**User Story:** As a mobile user, I want intuitive gestures and quick actions so that I can use the app more efficiently.

### Technical Tasks

#### Task 4.2.1: Implement Swipe to Reply
- **File:** `lib/features/groups/presentation/screens/group_chat_screen.dart`
- **Actions:**
  1. Add Dismissible widget to message bubbles
  2. Swipe right gesture triggers reply mode
  3. Show reply preview at bottom
  4. Animate smoothly
- **Estimated Time:** 3 hours

**Task 4.2.2: Implement Swipe Actions on Members**
- **File:** `lib/features/groups/presentation/widgets/group_member_item.dart`
- **Actions:**
  1. Swipe left to reveal action buttons
  2. Admin: Promote, Remove buttons
  3. Regular member: Message button
  4. Smooth animation
- **Estimated Time:** 3 hours

**Task 4.2.3: Add Quick Reply from Notifications**
- **File:** Notification handling service
- **Actions:**
  1. Add reply action to notification
  2. Handle inline reply
  3. Send message without opening app
  4. Show success/failure feedback
- **Platform:** iOS and Android
- **Estimated Time:** 4 hours

**Task 4.2.4: Implement Pull-to-Refresh**
- **Files:** 
  - `group_chat_screen.dart`
  - `group_members_list.dart`
  - `group_list_screen.dart`
- **Actions:**
  1. Add RefreshIndicator widget
  2. Trigger data refresh
  3. Show loading indicator
  4. Handle errors gracefully
- **Estimated Time:** 2 hours

**Task 4.2.5: Add Haptic Feedback**
- **Actions:**
  1. Add subtle haptic on long press
  2. Add haptic on swipe actions
  3. Add haptic on important actions
  4. Make it optional in settings
- **Dependencies:** Add haptic_feedback package
- **Estimated Time:** 2 hours

#### Localization Tasks

**Task 4.2.6: Add Localization Keys**
- **Keys to Add:**
```json
{
  "swipe-to-reply": "Swipe to reply",
  "swipe-for-actions": "Swipe for actions",
  "pull-to-refresh": "Pull to refresh",
  "refreshing": "Refreshing...",
  "reply-sent": "Reply sent",
  "quick-reply": "Quick Reply"
}
```
- **Estimated Time:** 30 minutes

#### Testing Tasks

**Task 4.2.7: Manual Testing Checklist**
- [ ] Swipe to reply works smoothly
- [ ] Swipe actions on members work
- [ ] Quick reply from notification works (iOS)
- [ ] Quick reply from notification works (Android)
- [ ] Pull-to-refresh works on all screens
- [ ] Haptic feedback appropriate
- [ ] Gestures don't conflict
- [ ] Animations smooth
- **Estimated Time:** 2 hours

### Deliverables

- [ ] Swipe gestures implemented
- [ ] Quick reply from notifications working
- [ ] Pull-to-refresh added
- [ ] Haptic feedback integrated
- [ ] All platforms tested

---

## Sprint 4 Summary

**Total Estimated Time:** 7.5 working days (1.5 weeks)

**Sprint Deliverables:**
- [ ] Member profiles enhanced
- [ ] Achievements system live
- [ ] Swipe gestures working
- [ ] Quick reply functional
- [ ] Pull-to-refresh added
- [ ] All tests passing

**Sprint Review Checklist:**
- [ ] Demo member profiles
- [ ] Demo achievements
- [ ] Demo swipe gestures
- [ ] Demo quick reply
- [ ] Review mobile UX
- [ ] Review test coverage

