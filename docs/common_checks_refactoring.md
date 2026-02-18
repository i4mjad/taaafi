# Common Checks Refactoring - Community Tabs

## Summary
Removed duplicate common checks from individual tab widgets and centralized them at the parent `CommunityMainScreen` level.

## Changes Made

### 1. GroupsMainScreen (`lib/features/groups/presentation/screens/groups_main_screen.dart`)

**Removed:**
- ❌ Shorebird Update check
- ❌ User Document check  
- ❌ Account Status checks:
  - `needCompleteRegistration` → CompleteRegistrationBanner
  - `needConfirmDetails` → ConfirmDetailsBanner
  - `needEmailVerification` → ConfirmEmailBanner
  - `pendingDeletion` → AccountActionBanner
- ❌ `_shouldBlockForShorebirdUpdate()` helper function

**Removed Imports:**
- `account_status_provider.dart`
- `user_document_provider.dart`
- `account_action_banner.dart`
- `complete_registration_banner.dart`
- `confirm_details_banner.dart`
- `confirm_email_banner.dart`
- `shorebird_update_widget.dart`
- `group_screen.dart` (unused)

**Kept:**
- ✅ Groups-specific status checks (GroupsStatus enum)
- ✅ Feature access guards for creating/joining groups

### 2. CommunityChatsScreen (`lib/features/direct_messaging/presentation/screens/community_chats_screen.dart`)

**No Changes Needed:**
- Already didn't have the common checks
- Only has tab-specific community profile check (correct behavior)

### 3. CommunityMainScreen (Parent)

**No Changes - Already Correct:**
- ✅ Handles all common checks for all 3 tabs
- ✅ Shorebird Update blocking
- ✅ User Document loading/error states
- ✅ All Account Status cases
- ✅ Community Profile validation

## Architecture After Refactoring

```
CommunityMainScreen (Parent)
├── Common Checks (Applied to ALL tabs)
│   ├── Shorebird Update
│   ├── User Document
│   ├── Account Status
│   └── Community Profile
│
└── TabBarView
    ├── Tab 1: Forum/Posts
    │   └── No additional checks
    │
    ├── Tab 2: Community Chats
    │   └── Check: Current profile null
    │
    └── Tab 3: Groups
        └── Check: Groups Status + Feature Access
```

## Benefits

1. **No Code Duplication**: Common checks exist only once at the parent level
2. **Consistent UX**: All tabs show the same blocking screens for common issues
3. **Better Performance**: Checks run once instead of per-tab
4. **Easier Maintenance**: Changes to common checks only need to be made in one place
5. **Cleaner Code**: Tab widgets focus on their specific functionality

## Testing Checklist

- [ ] All 3 tabs work correctly when user is logged in
- [ ] Email verification banner blocks all tabs
- [ ] Registration completion banner blocks all tabs  
- [ ] Detail confirmation banner blocks all tabs
- [ ] Pending deletion banner blocks all tabs
- [ ] Shorebird update blocks all tabs
- [ ] Community profile check works for Forum tab
- [ ] Community profile check works for Chats tab
- [ ] Groups status checks work correctly
- [ ] Feature access guards work for group creation/joining

## Date
November 9, 2025

