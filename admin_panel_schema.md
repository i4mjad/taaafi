# Admin Panel Database Schema (Based on Actual Codebase)

## Overview
This document outlines the database collections and their relationships for the Next.js admin panel managing community and groups features, based on the actual Flutter app implementation using Firebase/Firestore.

## Collections Structure

### 1. communityProfiles Collection
```typescript
interface CommunityProfile {
  id: string;              // Document ID (matches user UID)
  displayName: string;
  gender: string;          // male/female/other
  avatarUrl?: string;      // URL to profile image
  isAnonymous: boolean;    // Whether user posts anonymously by default
  createdAt: Date;
  updatedAt?: Date;
}
```

### 2. postCategories Collection
```typescript
interface PostCategory {
  id: string;              // Document ID
  name: string;            // English name
  nameAr: string;          // Arabic name
  iconName: string;        // Icon identifier
  colorHex: string;        // Color code for UI
  isActive: boolean;
  sortOrder: number;       // Display order
}
```

### 3. forumPosts Collection
```typescript
interface Post {
  id: string;              // Document ID
  authorCPId: string;      // Foreign key -> communityProfiles.id
  title: string;
  body: string;            // Post content
  category: string;        // Category ID reference
  score: number;           // Overall score (likes - dislikes)
  likeCount: number;
  dislikeCount: number;
  createdAt: Date;
  updatedAt?: Date;
}
```

### 4. comments Collection
```typescript
interface Comment {
  id: string;              // Document ID
  postId: string;          // Foreign key -> forumPosts.id
  authorCPId: string;      // Foreign key -> communityProfiles.id
  body: string;            // Comment content
  score: number;           // Overall score (likes - dislikes)
  likeCount: number;
  dislikeCount: number;
  createdAt: Date;
  updatedAt?: Date;
}
```

### 5. interactions Collection
```typescript
interface Interaction {
  id: string;              // Document ID (pattern: {userCPId}_{targetType}_{targetId})
  targetType: string;      // 'post' or 'comment'
  targetId: string;        // Foreign key -> forumPosts.id or comments.id
  userCPId: string;        // Foreign key -> communityProfiles.id
  type: string;            // 'like' (extensible for future types)
  value: number;           // 1 for like, -1 for dislike, 0 for neutral
  createdAt: Date;
  updatedAt?: Date;
}
```

### 6. groups Collection
```typescript
interface Group {
  id: string;              // Document ID
  name: string;
  description: string;
  memberCount: number;     // Current member count
  capacity: number;        // Maximum members allowed
  gender: string;          // Target gender for the group
  createdAt: Date;
  updatedAt?: Date;
}
```

### 7. features Collection (Interest Tracking)
```typescript
interface FeatureInterest {
  id: string;              // Document ID (e.g., 'community')
  interest_count: number;  // Number of users who showed interest
}
```

## Relationships

### Primary Relationships
- **communityProfiles** → **forumPosts** (1:N) - One profile can create many posts
- **communityProfiles** → **comments** (1:N) - One profile can create many comments
- **postCategories** → **forumPosts** (1:N) - One category contains many posts
- **forumPosts** → **comments** (1:N) - One post can have many comments
- **communityProfiles** → **interactions** (1:N) - One profile can have many interactions
- **forumPosts/comments** → **interactions** (1:N) - Items can receive many interactions

### Notes on Current Implementation
- Comments appear to be flat (no threading/replies in current model)
- Groups exist but seem to be in development phase
- No explicit user roles beyond community profiles
- No moderation/reporting system implemented yet
- Likes/dislikes are handled through interactions with numeric values

## Firebase/Firestore Indexes (Based on Code Patterns)

### Required Indexes
```typescript
// forumPosts
- authorCPId
- category
- createdAt
- (category, createdAt) // For category-filtered post lists

// comments
- postId
- authorCPId
- createdAt
- (postId, createdAt) // For post comment threads

// interactions
- userCPId
- targetType
- targetId
- (targetType, targetId) // For counting likes/dislikes
- (userCPId, targetType, targetId) // For checking user interactions

// postCategories
- isActive
- sortOrder
- (isActive, sortOrder) // For active category lists

// groups
- gender
- createdAt
- (gender, createdAt) // For gender-filtered group lists
```

## Current Admin Panel Requirements

### Content Management
- View/manage forum posts
- View/manage comments
- Monitor post categories and their usage
- Track user engagement through interactions

### User Management
- View community profiles
- Monitor user activity and post history
- Track anonymous vs. identified posting patterns

### Groups Management (Future)
- View group listings
- Monitor group membership
- Track group activity and engagement

### Analytics Dashboard
- Post engagement metrics (likes, dislikes, comments)
- Category popularity tracking
- User activity patterns
- Community growth metrics

## Future Considerations (Not Currently Implemented)

Based on typical community features that might be added:
- User roles and permissions system
- Content moderation and reporting
- Advanced group membership management
- Notification system
- Content approval workflows
- Ban/suspension system 