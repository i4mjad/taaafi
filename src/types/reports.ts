import { Timestamp } from 'firebase/firestore';

export interface UserReport {
  id: string;
  uid: string;
  time: Timestamp;
  reportTypeId: string;
  status: 'pending' | 'inProgress' | 'waitingForAdminResponse' | 'closed' | 'finalized';
  initialMessage: string;
  lastUpdated: Timestamp;
  messagesCount: number;
  // New related content structure
  relatedContent?: {
    type: 'post' | 'comment';  // Type of the reported content (extensible for future types)
    contentId: string;         // ID of the reported post or comment
  };
  // Legacy fields for backward compatibility
  targetId?: string;           // ID of the reported item (post, comment, etc.)
  targetType?: 'post' | 'comment' | 'user' | 'other';  // Type of the reported item
}

export interface ReportMessage {
  id: string;
  reportId: string;
  senderId: string;
  senderRole: 'user' | 'admin';
  message: string;
  timestamp: Timestamp;
  isRead: boolean;
}

export interface ReportType {
  id: string;
  nameEn: string;
  nameAr: string;
  descriptionEn: string;
  descriptionAr: string;
  isActive: boolean;
  targetType?: 'post' | 'comment' | 'user' | 'general';  // What this report type applies to
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
}

export interface UserProfile {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  locale?: string;
  createdAt: Timestamp;
  lastLoginAt?: Timestamp;
  messagingToken?: string;
}

// Known report type IDs for posts and comments
export const REPORT_TYPE_IDS = {
  POST: 'WV2Lpe4V9ajwf0NmsAwN',
  COMMENT: 'n8LCt8NsTfCcYh0mN0e6'
} as const;

// Filters for reports
export interface ReportFilters {
  status?: 'pending' | 'inProgress' | 'waitingForAdminResponse' | 'closed' | 'finalized';
  reportTypeId?: string;
  targetType?: 'post' | 'comment' | 'user' | 'other';
  targetId?: string;
  uid?: string;
  dateRange?: {
    from: Date;
    to: Date;
  };
}

// Analytics for reports
export interface ReportAnalytics {
  totalReports: number;
  pendingReports: number;
  resolvedReports: number;
  reportsByType: {
    reportTypeId: string;
    typeName: string;
    count: number;
  }[];
  reportsByTargetType: {
    targetType: string;
    count: number;
  }[];
}

// Extended interface for reports with related item context
export interface ReportWithContext extends UserReport {
  relatedItem?: {
    type: 'post' | 'comment';
    id: string;
    title?: string;        // For posts
    body: string;          // Content of post or comment
    authorCPId: string;    // Author of the reported item
    createdAt: Date;       // When the reported item was created
    isHidden?: boolean;    // Whether the item is currently hidden
    postId?: string;       // For comments, the parent post ID
  };
  reporter?: {
    uid: string;
    displayName?: string;
    email?: string;
  };
} 