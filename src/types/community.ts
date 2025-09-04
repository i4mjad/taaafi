export interface CommunityProfile {
  id: string;              // Document ID (matches user UID)
  displayName: string;
  gender: 'male' | 'female' | 'other';
  avatarUrl?: string;      // URL to profile image
  isAnonymous: boolean;    // Whether user posts anonymously by default
  postAnonymouslyByDefault?: boolean; // Alternative naming from cursor rule
  referralCode?: string;   // Optional referral code
  userUID?: string;        // User UID in users collection (source of truth for user details)
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
  isDeleted?: boolean;     // Whether this post is soft deleted
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
  isDeleted?: boolean;     // Whether this comment is soft deleted
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
  name: string;            // 1–60 characters
  description?: string;    // 0–500 characters, optional
  memberCapacity: number;  // Maximum members allowed (default 6)
  gender: 'male' | 'female';  // Target gender for the group (from schema)
  adminCpId: string;       // FK → communityProfiles (current admin)
  createdByCpId: string;   // FK → communityProfiles (original creator)
  visibility: 'public' | 'private';  // Group visibility
  joinMethod: 'any' | 'admin_only' | 'code_only';  // How members can join
  joinCode?: string;       // Join code for code_only groups
  joinCodeExpiresAt?: Date;  // Join code expiration
  joinCodeMaxUses?: number;  // Maximum uses for join code
  joinCodeUseCount: number;  // Current usage count
  isActive: boolean;       // Whether group is active (default true)
  isPaused: boolean;       // Whether group is paused (default false)
  pauseReason?: string;    // Reason for pause
  createdAt: Date;
  updatedAt?: Date;
}

export interface GroupMember {
  id: string;              // Document ID (${groupId}_${cpId} or random)
  groupId: string;         // FK → groups
  cpId: string;            // FK → communityProfiles
  role: 'admin' | 'member'; // Member role
  isActive: boolean;       // Whether membership is active (default true)
  joinedAt: Date;          // When they joined
  leftAt?: Date;           // When they left (if applicable)
  pointsTotal: number;     // Total points earned (default 0)
  displayName?: string;    // Cached display name from CP
}

export interface GroupMessage {
  id: string;              // Document ID
  groupId: string;         // FK → groups
  senderCpId: string;      // FK → communityProfiles
  body: string;            // Message content (1–5000 chars)
  replyToMessageId?: string; // Reply to another message
  quotedPreview?: string;  // Small excerpt for replies
  mentions: string[];      // Array of cpIds mentioned
  mentionHandles: string[]; // Array of handles for rendering
  tokens: string[];        // Tokenized terms for search
  isDeleted: boolean;      // Hard delete flag (default false)
  isHidden: boolean;       // Moderation hide flag (default false)
  moderation?: {
    status: 'pending' | 'approved' | 'blocked';
    reason?: string;
    moderatedBy?: string;
    moderatedAt?: Date;
  };
  createdAt: Date;
  senderDisplayName?: string; // Cached display name
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
  description?: string;           // Optional per F3 schema
  memberCapacity: number;         // Correct field name
  gender: 'male' | 'female';      // F3 only supports male/female
  visibility: 'public' | 'private';
  joinMethod: 'any' | 'admin_only' | 'code_only';
  adminCpId: string;              // Required admin CP ID
  createdByCpId: string;          // Required creator CP ID
}

export interface UpdateGroupRequest {
  name?: string;
  description?: string;
  memberCapacity?: number;        // Correct field name
  visibility?: 'public' | 'private';
  joinMethod?: 'any' | 'admin_only' | 'code_only';
  isActive?: boolean;
  isPaused?: boolean;
  pauseReason?: string;
} 