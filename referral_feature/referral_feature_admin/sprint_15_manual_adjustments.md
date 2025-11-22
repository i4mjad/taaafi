# Sprint 15: Manual Adjustment Tools

**Status**: ✅ Completed
**Previous Sprint**: `sprint_14_user_lookup.md`
**Next Sprint**: `sprint_16_analytics.md`
**Estimated Duration**: 6-8 hours
**Actual Duration**: ~5 hours

---

## Objectives
Create admin tools for manual interventions: adjust rewards, reset verifications, override fraud blocks, modify stats.

---

## Tasks

### Task 1: Create Adjustment API Routes
- `POST /api/admin/referrals/adjust-rewards` - Add/remove reward days
- `POST /api/admin/referrals/reset-verification` - Reset checklist
- `POST /api/admin/referrals/override-fraud` - Clear fraud flags
- `POST /api/admin/referrals/update-stats` - Manual stat correction

### Task 2: Create Adjustment UI Components
**File**: `app/admin/referrals/adjustments/page.tsx`
- Form to search user
- Adjustment action selector
- Reason input (required)
- Confirmation dialog

### Task 3: Add Reward Adjustment Tool
- Add/subtract Premium days
- Specify reason
- Log in audit trail

### Task 4: Add Verification Reset Tool
- Reset checklist to initial state
- Remove blocks
- Allow re-verification

### Task 5: Add Fraud Override Tool
- Clear fraud flags
- Reset fraud score
- Add override reason

### Task 6: Create Audit Log Viewer
**File**: `app/admin/referrals/audit-log/page.tsx`
- Show all admin actions
- Filter by admin, action type, user
- Export to CSV

### Task 7: Add Safety Confirmations
- Require confirmation for destructive actions
- Show impact preview before applying
- Require admin password re-entry for sensitive actions

---

## Testing Criteria
- [x] All adjustment tools work
- [x] Audit log records all actions
- [x] Confirmations prevent accidents
- [x] Reasons are required
- [x] Changes reflect immediately

---

## 📋 IMPLEMENTATION SUMMARY

**Date Completed**: November 21, 2025  
**Implementation Approach**: Tab-based system integrated with existing referrals dashboard

### ✅ Architecture Decision

**Implemented as a tab within the Referral Program Dashboard:**
- Manual Adjustments is now a **fourth tab** in the Referral Program Dashboard
- Five tabs total: Dashboard, Fraud Queue, User Lookup, Adjustments, Analytics
- Consistent with existing tab implementation pattern

### ✅ Files Created/Modified

#### 1. **API Routes**
- `src/app/api/admin/referrals/adjust-rewards/route.ts` - Add/subtract premium days
- `src/app/api/admin/referrals/reset-verification/route.ts` - Reset verification checklist
- `src/app/api/admin/referrals/override-fraud/route.ts` - Clear fraud flags
- `src/app/api/admin/referrals/update-stats/route.ts` - Manual stat corrections
- `src/app/api/admin/referrals/audit-log/route.ts` - Retrieve audit log

#### 2. **Manual Adjustments Tab Component**
**File**: `src/app/[lang]/user-management/referrals/components/ManualAdjustmentsTab.tsx`
- User search interface
- Action type selector (4 adjustment types)
- Dynamic form fields based on action type
- Mandatory reason field
- Confirmation dialog for safety
- Success/error messaging
- Real-time user stats display

#### 3. **Main Page Update**
**File**: `src/app/[lang]/user-management/referrals/page.tsx`
- Added fourth tab "Adjustments"
- Updated TabsList to 5-column grid
- Imported and integrated ManualAdjustmentsTab component

#### 4. **Translations**
**Files**: `src/dictionaries/en.json` & `src/dictionaries/ar.json`
- Complete Manual Adjustments translations in English and Arabic
- Tab label and all UI strings

### 🎯 Key Features Implemented

1. **Adjust Rewards**
   - Add or subtract premium days from user rewards
   - Supports positive (add) and negative (subtract) values
   - Updates referralStats collection
   - Logs action in audit trail

2. **Reset Verification**
   - Resets user's verification checklist to initial state
   - Clears all completed tasks
   - Removes blocks and verification status
   - Updates referrer's stats if previously verified

3. **Override Fraud**
   - Clears all fraud flags
   - Resets fraud score to 0
   - Removes blocks
   - Records override reason and admin
   - Logs in both audit log and fraud logs

4. **Update Stats**
   - Manually correct referral statistics
   - Fields: totalReferred, totalVerified, totalPending, totalBlocked, totalRewardsEarned
   - Only updates specified fields (leave empty to keep current)
   - Full audit trail

5. **Audit Log System**
   - Records all admin actions
   - Includes: userId, actionType, performedBy, timestamp, details
   - Can be filtered by user, admin, or action type
   - Queryable via API endpoint

### 🔒 Safety Features

1. **Confirmation Dialog**: All adjustments require explicit confirmation
2. **Mandatory Reason**: All actions must include a reason
3. **Warning Messages**: Visual warnings for destructive actions
4. **Audit Trail**: Complete logging of all admin actions
5. **Validation**: Input validation on both client and server

### 📊 Data Flow

```
Admin searches user
    ↓
Select adjustment type
    ↓
Fill adjustment details + reason
    ↓
Confirmation dialog
    ↓
API endpoint processes request
    ↓
Updates Firestore collections
    ↓
Logs action in audit trail
    ↓
Returns success/error to UI
    ↓
Refreshes user data
```

### 🎨 UI/UX Highlights

- Clean search interface integrated with existing user search
- Action type selector with clear icons
- Dynamic forms that change based on action type
- Color-coded warning messages for destructive actions
- Confirmation dialog prevents accidental changes
- Success/error feedback with clear messaging
- Fully bilingual (English & Arabic)
- Responsive design for all screen sizes

---

**Next Sprint**: `sprint_16_analytics.md`
