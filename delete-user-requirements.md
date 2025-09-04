# User Account Deletion Data Structure Guide

## Overview
This document outlines the complete data structure and deletion strategy for the Ta'aafi app's user account deletion system. The deletion process follows a hybrid approach: **soft deletion** for community data (to preserve forum integrity) and **hard deletion** for personal/vault data (for complete privacy).

## Data Categories & Deletion Strategy

### 1. Community Data (SOFT DELETE)
Community data is soft deleted to maintain forum conversation integrity while anonymizing the user.

#### Collection: `communityProfiles`
**Document ID**: `{userUID}` (Firebase Auth UID)
**Structure**:
```json
{
  "id": "string",               //auto generated doc id 
  "userUID": "string",           // Firebase Auth UID reference
  "displayName": "string",       // Display name for community
  "gender": "string",           // male/female/other
  "avatarUrl": "string|null",   // Profile picture URL
  "isAnonymous": "boolean",     // Default anonymous posting preference
  "isDeleted": "boolean",       // Soft deletion flag
  "isPlusUser": "boolean|null", // Plus subscription status
  "shareRelapseStreaks": "boolean", // Share streak data preference
  "createdAt": "Timestamp",     // Profile creation date
  "updatedAt": "Timestamp|null" // Last update timestamp
}
```
**Deletion Action**: 
- Set `isDeleted: true`
- Set `deletedAt: serverTimestamp()`
- Change `displayName: '[Deleted User]'`
- Remove `avatarUrl: null`
- Update `updatedAt: serverTimestamp()`

#### Collection: `forumPosts`
**Query**: `WHERE authorCPId == {userUID}`
**Structure**:
```json
{
  "authorCPId": "string",       // Community profile ID (userUID)
  "title": "string",           // Post title
  "body": "string",            // Post content
  "category": "string",        // Post category
  "isPinned": "boolean",       // Admin pinned status
  "isDeleted": "boolean",      // Soft deletion flag
  "isCommentingAllowed": "boolean", // Comments enabled
  "score": "number",           // Combined like/dislike score
  "likeCount": "number",       // Total likes
  "dislikeCount": "number",    // Total dislikes
  "createdAt": "Timestamp",    // Post creation
  "updatedAt": "Timestamp|null" // Last update
}
```
**Deletion Action**:
- Set `isDeleted: true`
- Set `deletedAt: serverTimestamp()`
- Change `title: '[Post by deleted user]'`
- Change `body: '[This post was created by a user who has deleted their account]'`
- Update `updatedAt: serverTimestamp()`

#### Collection: `comments`
**Query**: `WHERE authorCPId == {userUID}`
**Structure**:
```json
{
  "postId": "string",          // Parent post ID
  "authorCPId": "string",      // Community profile ID (userUID)
  "body": "string",            // Comment content
  "isDeleted": "boolean",      // Soft deletion flag
  "score": "number",           // Combined like/dislike score
  "likeCount": "number",       // Total likes
  "dislikeCount": "number",    // Total dislikes
  "createdAt": "Timestamp",    // Comment creation
  "updatedAt": "Timestamp|null" // Last update
}
```
**Deletion Action**:
- Set `isDeleted: true`
- Set `deletedAt: serverTimestamp()`
- Change `body: '[Comment by deleted user]'`
- Update `updatedAt: serverTimestamp()`

#### Collection: `interactions`
**Query**: `WHERE userCPId == {userUID}`
**Document ID Pattern**: `{userCPId}_{targetType}_{targetId}`
**Structure**:
```json
{
  "targetType": "string",      // 'post' or 'comment'
  "targetId": "string",        // Post or comment ID
  "userCPId": "string",        // User community profile ID
  "type": "string",            // 'like' (extensible)
  "value": "number",           // 1 (like), -1 (dislike), 0 (neutral)
  "isDeleted": "boolean",      // Soft deletion flag
  "createdAt": "Timestamp",    // Interaction timestamp
  "updatedAt": "Timestamp|null" // Last update
}
```
**Deletion Action**:
- Set `isDeleted: true`
- Set `deletedAt: serverTimestamp()`
- Update `updatedAt: serverTimestamp()`

#### Collection: `communityInterest` (HARD DELETE)
**Document ID**: `{userUID}`
**Structure**: Interest tracking data
**Deletion Action**: Complete document deletion

### 2. Vault Data (HARD DELETE)
Personal vault data is completely removed for user privacy.

#### Subcollection: `users/{userUID}/activities`
**Structure**:
```json
{
  "activityName": "string",       // Activity name
  "activityDescription": "string", // Activity description
  "activityDifficulty": "string", // starter/intermediate/advanced
  "subscriberCount": "number",    // Number of subscribers
  "tasks": "array",              // Related tasks (from subcollection)
  "createdAt": "Timestamp",      // Creation date
  "updatedAt": "Timestamp|null"  // Last update
}
```
**Deletion Action**: Complete collection deletion

#### Subcollection: `users/{userUID}/emotions`
**Structure**:
```json
{
  "emotionEmoji": "string",    // Emoji representation
  "emotionName": "string",     // Emotion name
  "date": "Timestamp"          // When emotion was recorded
}
```
**Deletion Action**: Complete collection deletion

#### Subcollection: `users/{userUID}/followups`
**Structure**:
```json
{
  "type": "string",           // relapse/pornOnly/mastOnly/slipUp/none
  "time": "Timestamp",        // When follow-up occurred
  "triggers": "array",        // List of trigger IDs
  "moodRating": "number|null", // -5 to +5 mood rating
  "notes": "string|null",     // Additional notes
  "hourOfDay": "number"       // Hour when event occurred (0-23)
}
```
**Deletion Action**: Complete collection deletion

#### Subcollection: `users/{userUID}/diaries`
**Structure**:
```json
{
  "title": "string",          // Diary entry title
  "plainText": "string",      // Plain text content
  "formattedContent": "array|null", // Rich text formatting
  "date": "Timestamp",        // Entry date
  "updatedAt": "Timestamp|null", // Last update
  "linkedTaskIds": "array",   // Connected activity task IDs
  "linkedTasks": "array"      // Full task objects (computed)
}
```
**Deletion Action**: Complete collection deletion

### 3. Main User Document (HARD DELETE)

#### Collection: `users`
**Document ID**: `{userUID}` (Firebase Auth UID)
**Structure**:
```json
{
  "displayName": "string",     // User's display name
  "email": "string",           // User's email
  "gender": "string",          // male/female/other
  "locale": "string",          // User's language preference
  "role": "string",            // User role (user/admin)
  "dayOfBirth": "Timestamp",   // Birth date
  "userFirstDate": "Timestamp", // Account creation date
  "messagingToken": "string|null", // FCM token for notifications
  "currentStreak": "number",   // Current streak days
  "streakData": "object"       // Additional streak information
}
```
**Deletion Action**: Complete document deletion

### 4. Firebase Authentication (HARD DELETE)
**Action**: Delete Firebase Auth user account completely

### 5. Collections That DON'T Exist
The following collections mentioned in the original cloud function code do not exist in the current system:
- `userSessions`
- `refreshTokens`
- `deviceTokens`
- `loginHistory`

## Deletion Process Flow

### Step 1: Community Data Soft Deletion
1. Update `communityProfiles/{userUID}` - anonymize profile
2. Update all `forumPosts` where `authorCPId == userUID` - anonymize content
3. Update all `comments` where `authorCPId == userUID` - anonymize content
4. Update all `interactions` where `userCPId == userUID` - mark as deleted
5. Hard delete `communityInterest/{userUID}` document

### Step 2: Vault Data Hard Deletion
1. Delete `users/{userUID}/activities` subcollection
2. Delete `users/{userUID}/emotions` subcollection
3. Delete `users/{userUID}/followups` subcollection
4. Delete `users/{userUID}/diaries` subcollection

### Step 3: User Profile Hard Deletion
1. Delete `users/{userUID}` main document

### Step 4: Authentication Deletion
1. Delete Firebase Auth user account

### Step 5: Audit Trail Creation
1. Create record in `deletedUsers/{userUID}` collection with:
   - Deletion timestamp
   - Collections processed counts
   - Processing duration
   - Any errors encountered
   - Success status

## Implementation Notes for AI Agents

### Batch Operations
- Use Firestore batch operations with 500 document limit
- Process collections sequentially to handle errors gracefully
- Implement proper error handling and logging

### Error Handling
- Continue deletion process even if some steps fail
- Always create audit record regardless of partial failures
- Log detailed information for troubleshooting

### Performance Considerations
- 9-minute timeout configured for comprehensive deletion
- Use appropriate batch sizes for large data sets
- Consider user data volume when processing

### Privacy Compliance
- Soft delete preserves community integrity
- Hard delete ensures complete privacy for personal data
- Audit trail maintains compliance records

## Data Relationships
- `communityProfiles.userUID` → `users.uid` (Firebase Auth UID)
- `forumPosts.authorCPId` → `communityProfiles.userUID`
- `comments.authorCPId` → `communityProfiles.userUID`
- `interactions.userCPId` → `communityProfiles.userUID`
- All vault subcollections are under `users/{userUID}/`

This structure ensures user privacy while maintaining community forum integrity and provides a complete audit trail for compliance purposes.