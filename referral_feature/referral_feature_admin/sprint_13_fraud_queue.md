# Sprint 13: Fraud Detection Review Queue

**Status**: Not Started
**Previous Sprint**: `sprint_12_admin_dashboard.md`
**Next Sprint**: `sprint_14_user_lookup.md`
**Estimated Duration**: 6-8 hours

---

## Objectives
Create admin interface to review flagged referrals, view fraud details, and approve/block users.

---

## Tasks

### Task 1: Create Fraud Queue API Route
**File**: `app/api/admin/referrals/fraud-queue/route.ts`
- Fetch all verifications with fraudScore >= 40
- Sort by fraud score (highest first)
- Include user details and fraud flags

### Task 2: Create Fraud Queue Page
**File**: `app/admin/referrals/fraud-queue/page.tsx`
- Table of flagged users
- Columns: User, Fraud Score, Flags, Referrer, Actions
- Filters: Score range, flag types
- Pagination

### Task 3: Create Fraud Details Modal
- Show complete fraud check breakdown
- Display all flags with descriptions
- Show user activity timeline
- Compare with referrer activity

### Task 4: Create Approve/Block Actions
**API Routes**:
- `POST /api/admin/referrals/approve` - Approve and clear flags
- `POST /api/admin/referrals/block` - Block user with reason

### Task 5: Add Bulk Actions
- Select multiple users
- Bulk approve low-risk
- Bulk block high-risk

### Task 6: Create Fraud Score Visualization
- Visual indicator (color-coded)
- Score breakdown chart
- Historical fraud score changes

### Task 7: Add Admin Notes
- Allow admins to add notes to verification
- Log all admin actions
- Audit trail

---

## Testing Criteria
- [ ] Queue shows all flagged users
- [ ] Fraud details accurate
- [ ] Approve action works
- [ ] Block action works
- [ ] Bulk actions functional
- [ ] Admin actions logged

---

**Next Sprint**: `sprint_14_user_lookup.md`
