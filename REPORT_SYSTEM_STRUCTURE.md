# User Reports System - Admin Portal Structure

## Overview

This document outlines the enhanced user reports system structure for the Next.js admin portal. The system supports conversation-based reporting where users initiate reports and administrators can engage in ongoing conversations to resolve issues.

## Database Structure (Firebase Firestore)

### 1. Main Collection: `usersReports`

Each document represents a user report with the following structure:

```javascript
{
  id: "auto-generated-document-id",
  uid: "user-id-who-submitted-report",
  time: Timestamp, // When the report was initially created
  reportTypeId: "AVgC6BG76LJqDaalZFvV", // Reference to reportTypes collection (Data Error Report) map it to the document details in reportTypes
  status: "pending" | "inProgress" | "waitingForAdminResponse" | "closed" | "finalized",
  initialMessage: "User's first message describing the issue",
  lastUpdated: Timestamp, // Last activity on this report (used for sorting)
  messagesCount: Number // Total number of messages in the conversation
}
```

### 2. Subcollection: `usersReports/{reportId}/messages`

Each report contains a subcollection of messages representing the conversation:

```javascript
{
  id: "auto-generated-message-id",
  reportId: "parent-report-id",
  senderId: "user-id" | "admin",
  senderRole: "user" | "admin",
  message: "Message content (max 220 characters)",
  timestamp: Timestamp,
  isRead: Boolean
}
```

### 3. Reference Collection: `reportTypes`

Report types are managed in a separate collection:

```javascript
{
  id: "AVgC6BG76LJqDaalZFvV", // Document ID for Data Error Report type
  name: "Data Error Report",
  description: "Reports related to incorrect user statistics",
  isActive: Boolean,
  createdAt: Timestamp
}
```

## Status Management & Admin Actions

### Status Definitions

1. **`pending`**: New report submitted by user, awaiting admin review
2. **`inProgress`**: Admin has started reviewing and working on the report
3. **`waitingForAdminResponse`**: User has sent a new message, waiting for admin response
4. **`closed`**: Admin has closed the report (user cannot send more messages)
5. **`finalized`**: Report is completely resolved and archived

### Admin Status Transitions

```
pending → inProgress (when admin starts reviewing)
inProgress → waitingForAdminResponse (when user sends message)
waitingForAdminResponse → inProgress (when admin responds)
inProgress → closed (when admin closes report)
closed → finalized (when admin archives resolved report)
```

### Admin Permissions & Actions

- **View all reports** across all users
- **Filter reports** by status, date range, user, etc.
- **Change report status** with proper validation
- **Send messages** to users in any status except `closed` and `finalized`
- **Close reports** to prevent further user messages
- **Finalize reports** for archival

## Required Admin Portal Features

### 1. Reports Dashboard
- **List all reports** with pagination
- **Filter options**:
  - Status (pending, inProgress, waitingForAdminResponse, closed, finalized)
  - Date range (time, lastUpdated)
  - User ID search
  - Report type
- **Sort options**:
  - Most recent activity (lastUpdated DESC)
  - Creation date (time DESC)
  - Status priority
- **Display columns**:
  - Report ID
  - User ID
  - Report type
  - Status (with color coding)
  - Messages count
  - Last updated
  - Initial message preview

### 2. Report Conversation View
- **Full conversation history** showing all messages chronologically
- **User information panel** (user ID, email if available)
- **Status management controls** with dropdown/buttons
- **Message composition area** for admin responses
- **Conversation metadata**:
  - Created date
  - Last activity
  - Total messages
  - Current status

### 3. Status Update Notifications
When admin changes status, send push notifications to users:
- **`inProgress`**: "Your report is being reviewed"
- **`waitingForAdminResponse`**: (No notification - triggered by user)
- **`closed`**: "Your report has been closed"
- **`finalized`**: "Your report has been resolved"

### 4. Message Management
- **Character limit validation** (220 characters)
- **Timestamp tracking** for all messages
- **Read status management**
- **Real-time updates** when new user messages arrive

## Implementation Guidelines

### Firestore Queries

```javascript
// Get all reports (dashboard)
const reportsQuery = query(
  collection(db, 'usersReports'),
  orderBy('lastUpdated', 'desc'),
  where('status', 'in', ['pending', 'inProgress', 'waitingForAdminResponse'])
);

// Get messages for specific report
const messagesQuery = query(
  collection(db, 'usersReports', reportId, 'messages'),
  orderBy('timestamp', 'asc')
);

// Get reports by status
const pendingReportsQuery = query(
  collection(db, 'usersReports'),
  where('status', '==', 'pending'),
  orderBy('time', 'desc')
);
```

### Status Update Function

```javascript
async function updateReportStatus(reportId, newStatus) {
  await updateDoc(doc(db, 'usersReports', reportId), {
    status: newStatus,
    lastUpdated: serverTimestamp()
  });
  
  // Send push notification to user
  await sendStatusUpdateNotification(reportId, newStatus);
}
```

### Add Admin Message Function

```javascript
async function addAdminMessage(reportId, message) {
  // Add message to subcollection
  await addDoc(collection(db, 'usersReports', reportId, 'messages'), {
    reportId: reportId,
    senderId: 'admin',
    senderRole: 'admin',
    message: message,
    timestamp: serverTimestamp(),
    isRead: false
  });
  
  // Update report metadata
  await updateDoc(doc(db, 'usersReports', reportId), {
    status: 'inProgress',
    lastUpdated: serverTimestamp(),
    messagesCount: increment(1)
  });
}
```
## Analytics & Metrics

Consider implementing:
- **Response time tracking** (time between user message and admin response)
- **Resolution time** (time from creation to closure)
- **Report volume** by day/week/month
- **Status distribution** charts
- **User satisfaction** (if feedback system is added)

## Real-time Updates

Implement real-time listeners for:
- **New reports** appearing in dashboard
- **Status changes** reflecting immediately
- **New user messages** in open conversations
- **Live message count** updates