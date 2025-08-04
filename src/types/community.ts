export interface CommunityProfile {
  id: string;              // Document ID (matches user UID)
  displayName: string;
  gender: 'male' | 'female' | 'other';
  avatarUrl?: string;      // URL to profile image
  isAnonymous: boolean;    // Whether user posts anonymously by default
  postAnonymouslyByDefault?: boolean; // Alternative naming from cursor rule
  referralCode?: string;   // Optional referral code
  createdAt: Date;
  updatedAt?: Date;
}

export interface PostCategory {
  id: string;              // Document ID
  name: string;            // English name
  nameAr: string;          // Arabic name
  iconName: string;        // Icon identifier
  colorHex: string;        // Color code for UI
  isActive: boolean;
  isForAdminOnly?: boolean; // Whether this category is restricted to admin users only
  sortOrder: number;       // Display order
  createdAt?: Date;
  updatedAt?: Date;
}

export interface ForumPost {
  id: string;              // Document ID
  authorCPId: string;      // Foreign key -> communityProfiles.id
  title: string;
  body: string;            // Post content
  category: string;        // Category ID reference
  isAnonymous?: boolean;   // Whether this specific post is anonymous
  isHidden?: boolean;      // Whether this post is hidden by admin
  isPinned?: boolean;      // Whether this post is pinned to the top
  score: number;           // Overall score (likes - dislikes)
  likeCount: number;
  dislikeCount: number;
  createdAt: Date;
  updatedAt?: Date;
}

export interface Comment {
  id: string;              // Document ID
  postId: string;          // Foreign key -> forumPosts.id
  authorCPId: string;      // Foreign key -> communityProfiles.id
  body: string;            // Comment content
  isAnonymous?: boolean;   // Whether this comment is anonymous
  isHidden?: boolean;      // Whether this comment is hidden by admin
  score: number;           // Overall score (likes - dislikes)
  likeCount: number;
  dislikeCount: number;
  createdAt: Date;
  updatedAt?: Date;
}

export interface Interaction {
  id: string;              // Document ID (pattern: {userCPId}_{targetType}_{targetId})
  targetType: 'post' | 'comment';
  targetId: string;        // Foreign key -> forumPosts.id or comments.id
  userCPId: string;        // Foreign key -> communityProfiles.id
  type: 'like';            // Extensible for future types
  value: number;           // 1 for like, -1 for dislike, 0 for neutral
  createdAt: Date;
  updatedAt?: Date;
}

export interface Group {
  id: string;              // Document ID
  name: string;
  description: string;
  memberCount: number;     // Current member count
  capacity: number;        // Maximum members allowed
  gender: 'male' | 'female' | 'mixed' | 'other';  // Target gender for the group
  isActive?: boolean;      // Whether group is accepting new members
  createdAt: Date;
  updatedAt?: Date;
}

export interface FeatureInterest {
  id: string;              // Document ID (e.g., 'community')
  interest_count: number;  // Number of users who showed interest
  updatedAt?: Date;
}

// Extended interface for app features (from existing features module)
export interface AppFeature {
  id: string;
  uniqueName: string;      // Generated from English name
  nameEn: string;
  nameAr: string;
  descriptionEn: string;
  descriptionAr: string;
  category: 'core' | 'social' | 'content' | 'communication' | 'settings';
  iconName: string;
  isActive: boolean;
  isBannable: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Filter interfaces for queries
export interface CommunityProfileFilters {
  gender?: 'male' | 'female' | 'other';
  isAnonymous?: boolean;
  search?: string;
}

export interface ForumPostFilters {
  category?: string;
  authorCPId?: string;
  isAnonymous?: boolean;
  search?: string;
  dateFrom?: Date;
  dateTo?: Date;
}

export interface CommentFilters {
  postId?: string;
  authorCPId?: string;
  isAnonymous?: boolean;
  search?: string;
}

export interface InteractionFilters {
  targetType?: 'post' | 'comment';
  targetId?: string;
  userCPId?: string;
  type?: 'like';
}

export interface GroupFilters {
  gender?: 'male' | 'female' | 'mixed' | 'other';
  isActive?: boolean;
  search?: string;
}

// Analytics interfaces
export interface CommunityAnalytics {
  totalPosts: number;
  totalComments: number;
  totalInteractions: number;
  totalProfiles: number;
  activeGroups: number;
  postsToday: number;
  engagement: {
    averageCommentsPerPost: number;
    averageLikesPerPost: number;
    mostActiveCategories: { categoryId: string; categoryName: string; postCount: number }[];
  };
}

export interface PostEngagement {
  postId: string;
  title: string;
  authorName: string;
  commentCount: number;
  likeCount: number;
  dislikeCount: number;
  score: number;
  createdAt: Date;
}

// Request/Response interfaces for CRUD operations
export interface CreateCommunityProfileRequest {
  displayName: string;
  gender: 'male' | 'female' | 'other';
  avatarUrl?: string;
  isAnonymous: boolean;
}

export interface UpdateCommunityProfileRequest {
  displayName?: string;
  gender?: 'male' | 'female' | 'other';
  avatarUrl?: string;
  isAnonymous?: boolean;
}

export interface CreateForumPostRequest {
  authorCPId: string;
  title: string;
  body: string;
  category: string;
}

export interface UpdateForumPostRequest {
  title?: string;
  body?: string;
  category?: string;
  isAnonymous?: boolean;
}

export interface CreateCommentRequest {
  postId: string;
  authorCPId: string;
  body: string;
  isAnonymous?: boolean;
}

export interface UpdateCommentRequest {
  body?: string;
  isAnonymous?: boolean;
}

export interface CreateGroupRequest {
  name: string;
  description: string;
  capacity: number;
  gender: 'male' | 'female' | 'mixed' | 'other';
}

export interface UpdateGroupRequest {
  name?: string;
  description?: string;
  capacity?: number;
  gender?: 'male' | 'female' | 'mixed' | 'other';
  isActive?: boolean;
} 