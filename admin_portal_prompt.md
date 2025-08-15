# Admin Portal - User Reports Management Module

## Overview
Create a new screen under the **user-management** module in your Next.js admin portal to review and manage user reports for data errors. This feature allows admins to respond to user-submitted reports about incorrect data in their recovery statistics.

## Database Structure (Firebase Firestore)

### Collection: `usersReports`

Each document represents a user report with the following structure:

```javascript
{
  id: string,                    // Auto-generated document ID
  uid: string,                   // User ID who submitted the report
  time: Timestamp,               // When the report was submitted
  reportType: string,            // Type of report ("dataError")
  status: string,                // Current status: "pending", "inProgress", "closed", "finalized"
  userJustification: string,     // User's explanation (max 220 characters)
  adminResponse: string | null   // Admin's response to the report (can be null)
}
```

### Firestore Security Rules
Ensure your Firestore rules allow admin read/write access to the `usersReports` collection:

```javascript
// In firestore.rules
match /usersReports/{reportId} {
  allow read, write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

## Required Features

### 1. Reports List View
- **Path**: `/admin/user-management/reports`
- **Table columns**:
  - Report ID (truncated with copy button)
  - User ID (with link to user profile if available)
  - Report Type (display "Data Error")
  - Status (with colored badges)
  - Submitted Date (formatted)
  - User Justification (truncated with expand option)
  - Actions (View/Edit/Update Status)

### 2. Filtering and Search
- Filter by status: All, Pending, In Progress, Closed, Finalized
- Search by User ID
- Date range picker for submission date
- Export functionality (CSV/Excel)

### 3. Report Details Modal/Page
- Display all report information
- Show user's full justification
- Admin response text area (if status allows editing)
- Status update dropdown
- User information panel (if user data is accessible)
- History/timeline of status changes (if you want to track this)

### 4. Status Management
- **Pending** → Can change to: In Progress, Closed
- **In Progress** → Can change to: Closed, Finalized
- **Closed** → Final state (no further changes)
- **Finalized** → Final state (no further changes)

### 5. Response System
- text only editor for admin responses
- Character limit: 500 characters recommended
- Auto-save draft functionality
- Required admin response before changing status to "Closed" or "Finalized"

### 6. Notification System (Critical)
**When an admin updates the status of a report, send a push notification to the user's device.**

#### Implementation Requirements:
1. **Retrieve User FCM Token**: Get the user's `messagingToken` from the `users` collection using the report's `uid`
2. **Send Notification**: Use Firebase Cloud Messaging (FCM) to send a push notification
3. **Notification Content**:
   - **Title**: "Report Update" (or localized equivalent)
   - **Body**: "Your data error report has been updated. Tap to view." (or localized)
   - **Data payload**: Include `reportId` to deep-link to the report status in the app
4. this should be based on user selected locale, so this should be displayed in the report, so prepart a set of text for each update and then send to the user based on their locale value in their document 

#### Notification Triggers:
- When status changes from "pending" to "inProgress"
- When status changes to "closed" or "finalized"
- When admin adds/updates a response

### 7. Analytics & Metrics
- Total reports count
- Reports by status (pie chart)
- Average response time
- Reports trends over time
- Most common user justifications

## Technical Implementation

### 1. Data Fetching

1. Fetch reports with pagination
2. use react-firebase-hooks package when dealing with firestore.



### 2. Status Update with Notification
1. use the existing api route for sending a notification to the user, check user page.

### 3. User Interface Components
- Use your existing design system (ShadCN)
- Implement responsive design for mobile admin access
- Add loading states and error handling
- Include confirmation dialogs for status changes
- Toast notifications for successful operations
- Every text you create should be localized through Translation context and the key should be added to ar.json and en.json files

## Development Checklist
- [ ] Create reports list page with filtering
- [ ] Implement report details modal/page
- [ ] Add status update functionality
- [ ] Create admin response system
- [ ] Implement FCM notification system
- [ ] Add analytics dashboard
- [ ] Implement proper error handling

This implementation will provide a comprehensive system for managing user data error reports with proper notification capabilities to keep users informed of their report status. 