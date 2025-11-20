# Sprint 14: User Referral Lookup & Search

**Status**: Not Started
**Previous Sprint**: `sprint_13_fraud_queue.md`
**Next Sprint**: `sprint_15_manual_adjustments.md`
**Estimated Duration**: 6-8 hours

---

## Objectives
Create search and lookup interface to view any user's referral details, history, and stats.

---

## Tasks

### Task 1: Create User Search API
**File**: `app/api/admin/referrals/search/route.ts`
- Search by email, user ID, referral code
- Return user info + referral stats

### Task 2: Create Search Interface
**File**: `app/admin/referrals/users/page.tsx`
- Search bar with autocomplete
- Search by email, ID, or code
- Display search results

### Task 3: Create User Detail Page
**File**: `app/admin/referrals/users/[userId]/page.tsx`
- User profile info
- Referral code
- Complete referral stats
- List of people they referred
- List of rewards earned
- Verification checklist (if they were referred)

### Task 4: Create Referred Users Table
- Show all users referred by this user
- Status, progress, fraud score
- Link to each user's detail page

### Task 5: Create Referral Timeline
- Visual timeline of referral events
- Signup, tasks completed, verification, rewards

### Task 6: Create Export Functionality
- Export user's referral data to CSV
- Include all stats and history

---

## Testing Criteria
- [ ] Search works by email, ID, code
- [ ] User detail page shows all info
- [ ] Referred users table accurate
- [ ] Timeline renders correctly
- [ ] Export to CSV works

---

**Next Sprint**: `sprint_15_manual_adjustments.md`
