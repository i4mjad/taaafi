# Sprint 15: Manual Adjustment Tools

**Status**: Not Started
**Previous Sprint**: `sprint_14_user_lookup.md`
**Next Sprint**: `sprint_16_analytics.md`
**Estimated Duration**: 6-8 hours

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
- [ ] All adjustment tools work
- [ ] Audit log records all actions
- [ ] Confirmations prevent accidents
- [ ] Reasons are required
- [ ] Changes reflect immediately

---

**Next Sprint**: `sprint_16_analytics.md`
