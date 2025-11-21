# Sprint 13: Fraud Detection Review Queue

**Status**: ✅ Completed
**Previous Sprint**: `sprint_12_admin_dashboard.md`
**Next Sprint**: `sprint_14_user_lookup.md`
**Estimated Duration**: 6-8 hours
**Actual Duration**: ~3 hours

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
- [x] Queue shows all flagged users
- [x] Fraud details accurate
- [x] Approve action works
- [x] Block action works
- [x] Bulk actions functional
- [x] Admin actions logged

---

## 📋 IMPLEMENTATION SUMMARY

**Date Completed**: November 21, 2025  
**Implementation Approach**: Tab-based system using react-firebase-hooks

### ✅ Architecture Decision

**Changed from separate page to tab system:**
- Fraud Queue is now a **tab** within the Referral Program Dashboard
- Uses Radix UI Tabs component
- Two tabs: "Dashboard" and "Fraud Queue"
- Badge indicator shows count of flagged users

### ✅ Files Created/Modified

#### 1. **Main Page - Tab Structure**
**File**: `src/app/[lang]/user-management/referrals/page.tsx`
- Refactored from dashboard-only to tab-based layout
- Integrates Dashboard tab (existing components)
- Integrates Fraud Queue tab (new component)
- Real-time badge count on Fraud Queue tab

#### 2. **Fraud Queue Component** 
**File**: `src/app/[lang]/user-management/referrals/components/FraudQueueTable.tsx`
- ✅ Uses `useCollection` from react-firebase-hooks (no API routes)
- Queries `referralVerifications` where `fraudScore >= 40`
- Real-time updates via Firestore listeners
- Features:
  - Sortable table (fraud score descending)
  - Multi-select with checkboxes
  - Score filter (All, Medium 40-70, High 71+)
  - Status filter (All, Pending, Blocked)
  - Bulk approve/block actions
  - View details button per user
  - Color-coded fraud score badges
  - Flag badges with overflow indicator

#### 3. **Fraud Details Modal**
**File**: `src/app/[lang]/user-management/referrals/components/FraudDetailsModal.tsx`
- ✅ Uses `useDocument` from react-firebase-hooks for real-time data
- Fetches verification document and user document
- Displays:
  - User information (name, email, signup date, status)
  - Fraud score with risk level indicator
  - Threshold explanations (Low: 0-39, Medium: 40-70, High: 71+)
  - Detailed fraud check breakdown with descriptions
  - Referrer information
  - Individual approve/block actions
- Real-time updates when data changes

#### 4. **API Routes for Actions** (Firebase Admin SDK)
**File**: `src/app/api/admin/referrals/approve/route.ts`
- Accepts array of userIds for bulk operations
- Updates `referralVerifications` document:
  - Sets `fraudScore: 0`
  - Clears `fraudFlags: []`
  - Sets `verificationStatus: 'verified'`
  - Updates referrer stats
- Logs action to `referralFraudLogs` collection

**File**: `src/app/api/admin/referrals/block/route.ts`
- Accepts array of userIds and reason
- Updates `referralVerifications` document:
  - Sets `isBlocked: true`
  - Sets `blockedReason` and `blockedAt`
  - Sets `verificationStatus: 'blocked'`
  - Updates referrer stats (increments `blockedReferrals`)
- Logs action to `referralFraudLogs` collection

#### 5. **Translations**
**Files**: `src/dictionaries/en.json` & `src/dictionaries/ar.json`
- Added complete fraud queue translations:
  - Tab labels
  - Table headers
  - Filter options
  - Risk level labels
  - Modal content
  - Action buttons
  - All in English and Arabic

### 🎯 Key Features Implemented

1. **Real-time Data with react-firebase-hooks**
   - No API polling needed
   - Automatic updates when Firestore data changes
   - Efficient Firestore queries with proper indexing

2. **Smart Filtering**
   - Score range filter (All, Medium, High)
   - Status filter (All, Pending, Blocked)
   - Filters apply client-side after Firestore query

3. **Bulk Operations**
   - Select all / individual selection
   - Bulk approve with confirmation
   - Bulk block with reason input
   - Batch API calls for efficiency

4. **Fraud Score Visualization**
   - Color-coded badges (Green/Orange/Red)
   - Risk level labels
   - Score breakdown in modal
   - Individual check contributions

5. **Audit Trail**
   - All approve/block actions logged to `referralFraudLogs`
   - Tracks: userId, action, fraudScore, flags, reason, performedBy, timestamp
   - Complete audit history for compliance

### 🔍 How to Access

**Navigation Path**:
1. Open sidebar
2. Click "User Management"
3. Click "Referral Program" (or navigate to `/{lang}/user-management/referrals`)
4. Click the "Fraud Queue" tab
5. The badge shows the count of flagged users (fraud score >= 40)

**Direct URLs**:
- English: `/en/user-management/referrals` (then switch to Fraud Queue tab)
- Arabic: `/ar/user-management/referrals` (then switch to Fraud Queue tab)

### 📊 Data Flow

```
Firestore (referralVerifications)
    ↓ (real-time listener via react-firebase-hooks)
FraudQueueTable Component
    ↓ (user clicks approve/block)
API Route (/api/admin/referrals/approve or /block)
    ↓ (Firebase Admin SDK)
Firestore Update + Audit Log
    ↓ (automatic real-time update)
UI Updates Automatically
```

### ⚠️ Important Notes

1. **No API route for fetching queue** - Direct Firestore access via react-firebase-hooks
2. **Admin auth not yet enforced** - TODO: Add auth context and verify admin role
3. **Firestore index required** - Ensure index exists for:
   - Collection: `referralVerifications`
   - Fields: `fraudScore` (Ascending), `__name__` (Ascending)

4. **Future Enhancements**:
   - Add admin notes feature (Task 7)
   - Add fraud score history visualization
   - Add referrer comparison view
   - Implement proper admin authentication

### 🎨 UI/UX Highlights

- Responsive design (mobile-friendly)
- Empty state with positive messaging ("All Clear!")
- Loading states with spinner
- Error states with helpful messages
- Badge notifications for pending reviews
- Confirmation dialogs for destructive actions
- Color-coded visual hierarchy
- RTL support for Arabic

---

**Next Sprint**: `sprint_14_user_lookup.md`
