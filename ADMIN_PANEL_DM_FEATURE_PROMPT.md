# Admin Panel: Direct Messaging Management Feature

## Context
Build a comprehensive Direct Messaging (DM) management module for an existing Next.js admin panel. This feature manages 1-on-1 private messages between community profiles in a recovery/support app. The module must integrate with the existing ban management system and follow the current admin panel architecture.

## Tech Stack
- **Framework**: Next.js (React)
- **Firebase Integration**: `react-firebase-hooks` package for Firestore queries
- **Localization**: Multi-language support (English & Arabic)
- **Existing Features**: Ban management system is already implemented and functional

---

## Data Models & Firestore Collections

### 1. `direct_conversations` Collection
Top-level collection storing conversation metadata.

**Document ID**: Auto-generated conversation ID  
**Fields**:
```typescript
{
  id: string;                           // Conversation ID
  participantCpIds: string[];           // Array of 2 community profile IDs
  lastMessage: string;                  // Preview of last message body
  lastActivityAt: Timestamp;            // Last message timestamp
  unreadBy: {                           // Map of cpId -> unread count
    [cpId: string]: number;
  };
  mutedBy: string[];                    // cpIds who muted this conversation
  archivedBy: string[];                 // cpIds who archived this conversation
  deletedFor: string[];                 // cpIds who soft-deleted (not actually deleted)
  createdAt: Timestamp;
  createdByCpId: string;                // Who initiated the conversation
}
```

### 2. `direct_messages` Subcollection
Nested under each conversation: `direct_conversations/{conversationId}/messages/{messageId}`

**Fields**:
```typescript
{
  id: string;
  conversationId: string;
  senderCpId: string;
  body: string;                         // Message content
  replyToMessageId?: string;            // If replying to another message
  quotedPreview?: string;               // Preview of replied message
  mentions: string[];                   // cpIds mentioned in message
  tokens: string[];                     // Search tokens (Arabic-aware)
  isDeleted: boolean;                   // Soft delete flag
  isHidden: boolean;                    // Hidden flag
  createdAt: Timestamp;
  
  // Moderation fields (added by Cloud Function)
  moderation: {
    status: 'pending' | 'approved' | 'blocked' | 'manual_review';
    reason: string | null;              // Localized reason for user
    
    // AI Analysis (optional, added when AI reviews)
    ai?: {
      reason: string;                   // Technical reason
      violationType: string;            // Type of violation detected
      severity: 'low' | 'medium' | 'high';
      confidence: number;               // 0.0 - 1.0
      detectedContent: string[];        // List of detected problematic content
      culturalContext?: string;         // Cultural context notes
    };
    
    // Final Decision (optional)
    finalDecision?: {
      action: 'allow' | 'review' | 'block' | 'allow_with_redaction';
      reason: string;
      violationType?: string;
      confidence: number;
    };
    
    // Custom Rules (optional)
    customRules?: Array<{
      type: string;                     // Rule type triggered
      severity: 'low' | 'medium' | 'high';
      confidence: number;
      reason: string;
    }>;
    
    analysisAt?: Timestamp;             // When AI analyzed
    
    // Admin Review (added when admin reviews)
    reviewedAt?: Timestamp;
    reviewedBy?: string;                // Admin UID
    reviewAction?: 'approve' | 'reject' | 'delete';
    reviewNotes?: string;
  };
}
```

### 3. ~~`moderation_queue` Collection~~ (REMOVED)
**This collection has been removed.** All moderation data is now stored inline in the `direct_messages` collection. Admin panel queries messages directly with filters like `moderation.status == 'manual_review'`.

### 3. `usersReports` Collection
User-submitted reports for messages or users.

**Fields**:
```typescript
{
  id: string;
  reportType: 'user' | 'message';
  reporterCpId: string;                 // Who reported
  reportedCpId?: string;                // For user reports
  messageId?: string;                   // For message reports
  conversationId?: string;              // For DM message reports
  groupId?: string;                     // For group message reports
  messageSender?: string;               // cpId of message sender
  messageContent?: string;              // Content of reported message
  userMessage: string;                  // Reporter's description (max 1500 chars)
  status: 'active' | 'resolved' | 'dismissed';
  createdAt: Timestamp;
  resolvedAt?: Timestamp;
  resolvedBy?: string;                  // Admin UID
  resolutionNotes?: string;
  actionTaken?: string;                 // What action was taken
}
```

### 4. `communityProfiles` Collection (Reference)
User profiles in the community.

**Relevant Fields**:
```typescript
{
  id: string;                           // Community Profile ID
  userUID: string;                      // Firebase Auth UID
  displayName: string;
  photoURL?: string;
  allowDirectMessages: boolean;         // Privacy setting
  // ... other profile fields
}
```

### 5. `bans` Collection (Already Implemented)
3-tier ban system: `user_ban`, `device_ban`, `feature_ban`

**Relevant Feature Names** for DM:
- `start_conversation`: Ban on starting new DM conversations
- `sending_in_groups`: Ban on sending messages (shared with group messaging)

---

## Moderation System Architecture

### Cloud Function: `moderateDirectMessage`
Automatically triggered on new message creation. Uses an 8-step pipeline:

1. **Text Normalization**: Lowercase, trim, normalize Arabic characters
2. **Token De-obfuscation**: Detect obfuscated social media handles (e.g., "i n s t a g r a m")
3. **Language Detection**: Auto-detect Arabic vs English
4. **OpenAI Analysis**: GPT-4o-mini analyzes content for violations
5. **Custom Rule Evaluation**: Pattern matching for specific violations
6. **Decision Synthesis**: Combines AI + custom rules
7. **Status Update**: Updates message document inline with moderation results
8. ~~**Queue Routing**~~: **REMOVED** - No separate queue, all data in message document

**Moderation Behavior for DMs**:
- More lenient than group messages (1-on-1 context)
- Does NOT auto-block; routes to manual review instead
- Flags only: explicit sexual requests, clear promotional content

**Violation Types Detected**:
- `social_media_sharing`: Promotion of social media accounts
- `sexual_content`: Explicit sexual content
- `cuckoldry_content`: Specific inappropriate content
- `homosexuality_content`: Specific inappropriate content
- `none`: No violations

**Message Statuses**:
- `pending`: Initial status, awaiting moderation
- `approved`: Passed moderation or approved by admin
- `blocked`: Blocked by admin
- `manual_review`: Flagged for admin review

---

## Required Admin Panel Screens

### Main Section: "Direct Messaging Management"

Create a dedicated section in the admin panel with the following sub-screens/tabs:

---

### **1. Dashboard Overview**
Display key metrics and statistics for direct messaging.

**Metrics to Show**:
- Total conversations (all-time, last 30 days, last 7 days)
- Total messages (all-time, last 30 days, last 7 days)
- Messages by status:
  - Approved
  - Pending review
  - Blocked
  - Under manual review
- User reports (active, resolved, dismissed)
- Average response time to flagged messages
- Top violation types detected

**Visualizations**:
- Line chart: Messages sent over time (daily/weekly/monthly)
- Pie chart: Message statuses distribution
- Bar chart: Top violation types

**Implementation Notes**:
- Use `react-firebase-hooks` with aggregation queries
- Cache results with appropriate refresh intervals
- Support date range filters

---

### **2. Messages Requiring Review**
View and review all messages with `moderation.status == 'manual_review'`.

**Query**: `direct_messages` collection where `moderation.status == 'manual_review'`

**Features**:

**Filters**:
- Violation Type: All types from detection system
- Date Range: Custom date range picker
- Sender: Search by community profile ID or display name
- Confidence: Range slider (0-100)

**Table Columns**:
- Message ID (clickable to view details)
- Sender (display name + cpId, clickable to view profile)
- Message Preview (first 100 chars)
- Violation Type (from `moderation.ai.violationType`)
- Confidence Score (from `moderation.finalDecision.confidence`)
- Severity (from `moderation.ai.severity`)
- Created At (relative time + exact timestamp on hover)
- Actions (Quick Review buttons)

**Quick Actions** (on each row):
- **View Details**: Opens modal with full message and analysis
- **Approve**: Updates `moderation.status` to `approved`, `isHidden` to `false`
- **Block**: Updates `moderation.status` to `blocked`, `isHidden` to `true`
- **View Conversation**: Opens full conversation view
- **View Sender**: Opens sender's profile/history

**Bulk Actions** (select multiple):
- Approve selected (batch update)
- Block selected (batch update)
- Export selected (CSV)

**Detail Modal** (when clicking message):
- Full message content
- Sender info (name, profile pic, cpId, userUID)
- Conversation info (participants, message count, created date)
- AI Analysis (from `moderation.ai`):
  - Reason
  - Confidence score
  - Detected content
  - Violation type
  - Severity
  - Cultural context (if available)
- Custom Rules triggered (from `moderation.customRules`)
- Final Decision (from `moderation.finalDecision`)
- Admin actions:
  - **Approve**: Update message document:
    ```javascript
    {
      'moderation.status': 'approved',
      'moderation.moderatedBy': adminUID,
      'moderation.moderatedAt': serverTimestamp(),
      'moderation.reviewAction': 'approve',
      'moderation.reviewNotes': notes,
      'isHidden': false
    }
    ```
  - **Block**: Update message document:
    ```javascript
    {
      'moderation.status': 'blocked',
      'moderation.moderatedBy': adminUID,
      'moderation.moderatedAt': serverTimestamp(),
      'moderation.reviewAction': 'block',
      'moderation.reviewNotes': notes,
      'isHidden': true
    }
    ```
  - Notes field (admin can add review notes)
  - Ban user (integrated with existing ban system):
    - Ban from sending messages
    - Ban from starting conversations
    - App-wide ban
    - Custom feature ban
- View full conversation link

**Pagination**:
- Support for large datasets
- Page size selector (25, 50, 100)

**Real-time Updates**:
- Auto-refresh when new items enter queue
- Notification badge on sidebar

---

### **3. All Conversations**
Browse and search all direct conversations.

**Features**:

**Filters**:
- Status: Active | Archived | Deleted
- Date Range: Conversation creation date
- Participants: Search by cpId or display name
- Has Flagged Messages: Boolean filter
- Has User Reports: Boolean filter

**Search**:
- Search by participant names
- Search by conversation ID

**Table Columns**:
- Conversation ID
- Participants (both display names + avatars)
- Last Message (preview)
- Last Activity (timestamp)
- Message Count
- Flagged Message Count (if > 0, show badge)
- Active Reports Count (if > 0, show badge)
- Created At
- Actions

**Actions** (per row):
- **View Messages**: Opens conversation messages screen
- **View Participants**: Opens both profiles
- **Delete Conversation**: Soft delete (add both cpIds to `deletedFor`)
- **Export Conversation**: Export all messages to JSON/CSV

**Implementation Notes**:
- Use `useCollectionData` from `react-firebase-hooks/firestore`
- Implement infinite scroll or pagination
- Show loading skeletons

---

### **4. All Messages**
Browse and search all direct messages across all conversations.

**Features**:

**Filters**:
- Moderation Status: `pending` | `approved` | `blocked` | `manual_review`
- Date Range: Message creation date
- Sender: Search by cpId or display name
- Conversation: Filter by specific conversation ID
- Has Violations: Boolean filter
- Violation Type: Dropdown of all violation types

**Search**:
- Full-text search in message body
- Search by message ID
- Search by sender display name

**Table Columns**:
- Message ID
- Sender (name + avatar)
- Message Preview (first 80 chars, expandable)
- Conversation ID (clickable)
- Moderation Status (badge with color coding)
- Violation Type (if flagged)
- Confidence Score (if analyzed)
- Created At
- Actions

**Actions** (per row):
- **View Full Message**: Opens detail modal
- **View Conversation**: Opens full conversation
- **Review Moderation**: If flagged, opens review modal
- **Delete Message**: Soft delete
- **View Sender Profile**: Opens sender's profile

**Detail Modal**:
- Full message content
- All moderation details (same as moderation queue modal)
- Conversation context (previous/next messages)
- Admin actions

**Bulk Actions**:
- Export selected messages
- Delete selected messages

---

### **5. User Reports**
Manage all user-submitted reports (both user reports and message reports).

**Features**:

**Filters**:
- Report Type: `user` | `message`
- Status: `active` | `resolved` | `dismissed`
- Date Range: Report creation date
- Reporter: Search by cpId or display name
- Reported: Search by cpId or display name (for user reports)

**Table Columns**:
- Report ID
- Report Type (badge)
- Reporter (name + avatar)
- Reported User/Message (depending on type)
- Description (reporter's message, first 100 chars)
- Status (badge)
- Created At
- Actions

**Actions** (per row):
- **View Details**: Opens report detail modal
- **Resolve**: Mark as resolved with notes
- **Dismiss**: Mark as dismissed
- **Take Action**: Quick access to ban/delete actions

**Detail Modal**:
- Full report details
- Reporter info (profile link)
- Reported content:
  - For user reports: Reported user's profile + recent messages
  - For message reports: Full message + conversation link
- Reporter's description (full text)
- Admin actions:
  - Resolve button (requires resolution notes)
  - Dismiss button
  - Ban reported user (opens ban modal)
  - Delete reported message
  - Contact reporter (future feature)
- Resolution history (if previously resolved/reopened)

**Statistics Panel** (top of page):
- Total reports
- Active reports
- Average resolution time
- Most reported users (top 5)
- Most common violation types

---

### **6. Conversation Detail Screen**
Deep dive into a specific conversation (accessed from other screens).

**Layout**:

**Header Section**:
- Conversation ID
- Participants (both profiles with avatars, names, cpIds)
- Created date
- Last activity date
- Message count
- Flagged message count
- Active reports count
- Actions:
  - Export conversation
  - Delete conversation
  - View participants' profiles
  - View conversation reports

**Messages Timeline**:
- Chronological display of all messages
- For each message:
  - Sender indicator (left/right or color coded)
  - Message body
  - Timestamp
  - Moderation status badge
  - If flagged: Violation type, confidence
  - Reply indicator (if replying to another message)
  - Actions:
    - View moderation details
    - Delete message
    - Report message (add to queue)

**Filters** (for messages in conversation):
- All messages
- Flagged only
- Approved only
- Date range

**Search** (within conversation):
- Search message content

---

### **7. Sender Profile & History**
View a community profile's DM activity and history (accessed from other screens).

**Profile Section**:
- Display name, avatar, cpId, userUID
- Account created date
- Direct message settings: `allowDirectMessages` (show if disabled)
- Link to full profile (if exists in current admin)

**DM Statistics**:
- Total conversations participated in
- Total messages sent
- Messages by status (approved, flagged, blocked)
- Total reports received
- Active bans related to DM

**Active Bans** (for DM features):
- Show any `start_conversation` or `sending_in_groups` bans
- Display ban details, expiry, reason

**Recent Messages** (last 50):
- Table similar to "All Messages" but filtered to this sender
- Quick actions available

**Conversations List**:
- All conversations this user participated in
- Link to conversation detail

**Reports Against User**:
- All reports where this user was reported
- Show status and resolution

**Admin Actions**:
- Ban from starting conversations (`start_conversation` feature)
- Ban from sending messages (`sending_in_groups` feature)
- App-wide ban
- View existing bans (link to ban management)

---

## Technical Requirements

### 1. React Hooks & Firebase Integration

Use `react-firebase-hooks` for all Firestore queries:

```typescript
import { useCollectionData, useDocumentData } from 'react-firebase-hooks/firestore';

// Example: Fetch moderation queue
const [queueItems, queueLoading, queueError] = useCollectionData(
  query(
    collection(db, 'moderation_queue'),
    where('status', '==', 'pending'),
    orderBy('createdAt', 'desc'),
    limit(50)
  ),
  { idField: 'id' }
);
```

**Best Practices**:
- Use `useMemo` to memoize queries
- Implement proper error handling for all hooks
- Show loading states with skeleton screens
- Handle real-time updates gracefully

### 2. Localization

Support English and Arabic throughout the interface.

**Implementation**:
- Use existing localization system in admin panel
- All UI strings must have both English and Arabic translations
- Support RTL layout for Arabic
- Localize dates, numbers, and relative time strings

**Key Strings to Localize**:
- All section titles and headers
- Table column headers
- Filter labels
- Button labels
- Status badges
- Error messages
- Success messages
- Confirmation dialogs

**Example**:
```typescript
{
  "en": {
    "dm.title": "Direct Messaging Management",
    "dm.moderation_queue": "Moderation Queue",
    "dm.status.pending": "Pending",
    "dm.status.approved": "Approved",
    "dm.actions.approve": "Approve",
    // ... more strings
  },
  "ar": {
    "dm.title": "إدارة الرسائل المباشرة",
    "dm.moderation_queue": "قائمة الانتظار للمراجعة",
    "dm.status.pending": "قيد المراجعة",
    "dm.status.approved": "مُعتمد",
    "dm.actions.approve": "اعتماد",
    // ... more strings
  }
}
```

### 3. UI/UX Requirements

**Design System**:
- Follow existing admin panel design system
- Consistent with existing ban management UI
- Responsive design (desktop-first, mobile-friendly)

**Color Coding**:
- Status badges:
  - Pending: Yellow/Orange
  - Approved: Green
  - Blocked: Red
  - Manual Review: Blue
- Confidence scores:
  - High (>0.8): Red
  - Medium (0.5-0.8): Yellow
  - Low (<0.5): Green
- Severity:
  - High: Red
  - Medium: Orange
  - Low: Yellow

**Components**:
- Use existing admin panel components (tables, modals, buttons, forms)
- Implement new components only if needed:
  - Message preview card
  - Moderation detail panel
  - Confidence score indicator
  - Violation type badge

**Loading States**:
- Skeleton screens for tables
- Spinner for actions
- Progress indicators for bulk actions

**Empty States**:
- Friendly empty state messages
- Illustrations or icons
- Call-to-action (if applicable)

**Error Handling**:
- Toast notifications for errors
- Inline error messages in forms
- Retry buttons for failed operations

### 4. Integration with Existing Ban System

The ban management system is already implemented. The DM module must integrate with it.

**Ban Features for DM**:
- `start_conversation`: Restrict starting new DM conversations
- `sending_in_groups`: Restrict sending messages (shared with group messaging)

**Integration Points**:

1. **In Review Modals**: When reviewing a flagged message, provide "Ban User" button that:
   - Opens existing ban creation modal
   - Pre-fills context (user, feature, reason)
   - Allows admin to select ban type:
     - Feature ban: `start_conversation`
     - Feature ban: `sending_in_groups`
     - App-wide ban
   - Allows admin to set duration, severity, reason

2. **In Sender Profile Screen**: Show all active bans related to DM features

3. **After Resolving Reports**: Option to ban user if report is valid

4. **Bulk Actions**: Option to ban multiple users from queue (if pattern detected)

**Implementation**:
- Reuse existing ban creation/management components
- Link to existing ban management screens
- Show ban status in user profiles

---

## Specific Functionalities

### 1. Approve Message
**Action**: Update message moderation status to `approved`.

**Implementation**:
```typescript
async function approveMessage(messageId: string, reviewNotes?: string) {
  const messageRef = doc(db, 'direct_messages', messageId);
  
  await updateDoc(messageRef, {
    'moderation.status': 'approved',
    'moderation.moderatedAt': serverTimestamp(),
    'moderation.moderatedBy': currentAdminUID,
    'moderation.reviewAction': 'approve',
    'moderation.reviewNotes': reviewNotes || null,
    'isHidden': false, // Make visible
  });
}
```

### 2. Block/Reject Message
**Action**: Update message moderation status to `blocked`.

**Implementation**:
```typescript
async function blockMessage(messageId: string, reviewNotes?: string) {
  const messageRef = doc(db, 'direct_messages', messageId);
  
  await updateDoc(messageRef, {
    'moderation.status': 'blocked',
    'moderation.moderatedAt': serverTimestamp(),
    'moderation.moderatedBy': currentAdminUID,
    'moderation.reviewAction': 'block',
    'moderation.reviewNotes': reviewNotes || null,
    'isHidden': true, // Hide from users
  });
}
```

### 3. Delete Message
**Action**: Soft delete message.

**Implementation**:
```typescript
async function deleteMessage(messageId: string) {
  const messageRef = doc(db, 'direct_messages', messageId);
  await updateDoc(messageRef, {
    isDeleted: true,
    deletedAt: serverTimestamp(),
    deletedBy: currentAdminUID,
  });
}
```

### 4. Resolve Report
**Action**: Mark report as resolved with notes.

**Implementation**:
```typescript
async function resolveReport(reportId: string, resolutionNotes: string, actionTaken?: string) {
  const reportRef = doc(db, 'usersReports', reportId);
  await updateDoc(reportRef, {
    status: 'resolved',
    resolvedAt: serverTimestamp(),
    resolvedBy: currentAdminUID,
    resolutionNotes,
    actionTaken: actionTaken || null,
  });
}
```

### 5. ~~Dismiss from Queue~~ (REMOVED)
**This action is no longer needed.** Messages remain with `manual_review` status until admin approves or blocks them.

### 6. Export Conversation
**Action**: Export all messages in a conversation to JSON or CSV.

**Implementation**:
- Fetch all messages in conversation
- Format as JSON or CSV
- Trigger browser download

---

## Security & Permissions

### Admin Authentication
- All screens require admin authentication
- Use Firebase Auth with custom claims or Firestore-based role system
- Check admin permissions before any write operation

### Audit Logging
- Log all admin actions:
  - Who performed the action
  - What action was performed
  - When it was performed
  - On which entity (message ID, conversation ID, etc.)
- Store in `admin_audit_logs` collection

### Rate Limiting
- Implement rate limiting for bulk actions
- Prevent accidental mass deletions/bans

---

## Performance Considerations

### Pagination & Lazy Loading
- Never load all data at once
- Use Firestore pagination (limit + startAfter)
- Implement infinite scroll or page-based pagination

### Indexing
Ensure Firestore indexes for common queries:
- `direct_messages`: 
  - Composite: `moderation.status`, `createdAt`
  - Composite: `senderCpId`, `moderation.status`, `createdAt`
  - Composite: `conversationId`, `createdAt`
- `usersReports`: `status`, `reportType`, `createdAt`

### Caching
- Cache frequently accessed data (profiles, conversation metadata)
- Use React Query or similar for client-side caching
- Set appropriate stale times

### Real-time Updates
- Use Firestore real-time listeners sparingly
- Only for critical screens (moderation queue dashboard)
- Detach listeners on unmount

---

## Testing Requirements

### Unit Tests
- Test all utility functions (date formatting, status mapping, etc.)
- Test data transformation functions

### Integration Tests
- Test Firestore query hooks
- Test admin actions (approve, block, delete)
- Mock Firebase in tests

### E2E Tests
- Test critical flows:
  - Reviewing and approving a message from queue
  - Resolving a user report
  - Banning a user from DM features
  - Exporting a conversation

---

## Deliverables

1. **All Screen Components**:
   - Dashboard
   - Moderation Queue
   - All Conversations
   - All Messages
   - User Reports
   - Conversation Detail
   - Sender Profile & History

2. **Shared Components**:
   - Message Preview Card
   - Moderation Detail Modal
   - Confidence Score Indicator
   - Violation Type Badge
   - Status Badge
   - Bulk Action Bar

3. **Utility Functions**:
   - Query builders for Firestore
   - Data transformation/formatting
   - Export functions (JSON, CSV)

4. **Localization Files**:
   - English translations
   - Arabic translations

5. **Documentation**:
   - Component usage docs
   - Admin user guide
   - API/query reference

---

## Future Enhancements (Out of Scope)

- In-app messaging to users (admin replies)
- Automated ban suggestions based on patterns
- Machine learning model retraining based on admin reviews
- Bulk import/export of moderation decisions
- Advanced analytics dashboards
- Integration with external moderation tools

---

## Notes

- **User Privacy**: Handle user data with care. Admin should only access DMs when necessary for moderation.
- **Scalability**: Design with future growth in mind. System should handle thousands of messages/day.
- **Moderation Accuracy**: Provide clear AI confidence indicators. Never fully trust automated decisions.
- **Cultural Sensitivity**: The app is for Arabic/English users. Be sensitive to cultural context in moderation.

---

## Questions for Clarification

Before implementation, clarify:
1. Admin role/permission structure (how to check if user is admin?)
2. Existing routing structure in Next.js admin panel
3. Preferred state management (Context, Redux, Zustand?)
4. Component library in use (Material-UI, Ant Design, custom?)
5. Existing table/data grid component preferences
6. Real-time update frequency preferences (balance between UX and costs)
7. Data retention policy for deleted messages/conversations
8. GDPR/data privacy requirements

---

## Summary

This prompt outlines a comprehensive Direct Messaging management module for the Next.js admin panel. It covers:
- Complete data models for all Firestore collections
- Detailed screen layouts and functionalities
- Integration with existing ban system
- Technical implementation guidelines using `react-firebase-hooks`
- Localization requirements
- Security, performance, and testing considerations

Implement this module to give admins full visibility and control over direct messaging, content moderation, and user reports, ensuring a safe and compliant platform.

