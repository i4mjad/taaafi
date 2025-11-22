import { Timestamp } from 'firebase/firestore';

// ============================================
// Direct Conversation Types
// ============================================

export interface DirectConversation {
  id: string;
  participantCpIds: string[];
  lastMessage: string;
  lastActivityAt: Timestamp;
  unreadBy: {
    [cpId: string]: number;
  };
  mutedBy: string[];
  archivedBy: string[];
  deletedFor: string[];
  createdAt: Timestamp;
  createdByCpId: string;
}

// ============================================
// Direct Message Types
// ============================================

export type ModerationStatus = 'pending' | 'approved' | 'blocked' | 'manual_review';
export type Severity = 'low' | 'medium' | 'high';
export type ViolationType = 
  | 'social_media_sharing' 
  | 'sexual_content' 
  | 'cuckoldry_content' 
  | 'homosexuality_content' 
  | 'harassment' 
  | 'spam' 
  | 'none';

export interface AIAnalysis {
  reason: string;
  violationType: ViolationType;
  severity: Severity;
  confidence: number;
  detectedContent: string[];
  culturalContext?: string;
}

export interface FinalDecision {
  action: 'allow' | 'review' | 'block' | 'allow_with_redaction';
  reason: string;
  violationType?: ViolationType;
  confidence: number;
}

export interface CustomRule {
  type: string;
  severity: Severity;
  confidence: number;
  reason: string;
}

export interface Moderation {
  status: ModerationStatus;
  reason: string | null;
  
  // AI Analysis (optional)
  ai?: AIAnalysis;
  
  // Final Decision (optional)
  finalDecision?: FinalDecision;
  
  // Custom Rules (optional)
  customRules?: CustomRule[];
  
  analysisAt?: Timestamp;
  
  // Admin Review (optional)
  reviewedAt?: Timestamp;
  reviewedBy?: string;
  reviewAction?: 'approve' | 'reject' | 'delete';
  reviewNotes?: string;
}

export interface DirectMessage {
  id: string;
  conversationId: string;
  senderCpId: string;
  body: string;
  replyToMessageId?: string;
  quotedPreview?: string;
  mentions: string[];
  tokens: string[];
  isDeleted: boolean;
  isHidden: boolean;
  createdAt: Timestamp;
  moderation: Moderation;
}

// ============================================
// Moderation Queue Types
// ============================================

export type MessageType = 'direct_message' | 'group_message';
export type Priority = 'low' | 'medium' | 'high' | 'critical';
export type QueueStatus = 'pending' | 'reviewed' | 'dismissed';

export interface OpenAIAnalysis {
  shouldBlock: boolean;
  violationType: ViolationType;
  severity: Severity;
  confidence: number;
  reason: string;
  detectedContent: string[];
  culturalContext?: string;
}

export interface CustomRuleResult {
  detected: boolean;
  type: string;
  severity: Severity;
  confidence: number;
  reason: string;
}

export interface ModerationQueueItem {
  id: string;
  messageType: MessageType;
  messageId: string;
  conversationId?: string;
  groupId?: string;
  senderCpId: string;
  messageBody: string;
  
  // AI Analysis Results
  openaiAnalysis?: OpenAIAnalysis;
  customRuleResults?: CustomRuleResult[];
  finalDecision?: FinalDecision;
  
  // Queue Management
  priority: Priority;
  status: QueueStatus;
  createdAt: Timestamp;
  reviewedAt?: Timestamp;
  reviewedBy?: string;
  reviewAction?: 'approve' | 'reject' | 'delete' | 'dismiss';
  reviewNotes?: string;
  
  // Error Tracking
  error?: string;
}

// ============================================
// User Reports Types
// ============================================

export type ReportType = 'user' | 'message';
export type ReportStatus = 'active' | 'resolved' | 'dismissed';

export interface UserReport {
  id: string;
  reportType: ReportType;
  reporterCpId: string;
  reportedCpId?: string;
  messageId?: string;
  conversationId?: string;
  groupId?: string;
  messageSender?: string;
  messageContent?: string;
  userMessage: string;
  status: ReportStatus;
  createdAt: Timestamp;
  resolvedAt?: Timestamp;
  resolvedBy?: string;
  resolutionNotes?: string;
  actionTaken?: string;
}

// ============================================
// Community Profile Types (Reference)
// ============================================

export interface CommunityProfile {
  id: string;
  userUID: string;
  displayName: string;
  photoURL?: string;
  allowDirectMessages: boolean;
}

// ============================================
// UI Helper Types
// ============================================

export interface ConversationWithProfiles extends DirectConversation {
  participants: CommunityProfile[];
  flaggedCount?: number;
  reportsCount?: number;
}

export interface MessageWithSender extends DirectMessage {
  sender: CommunityProfile;
}

export interface QueueItemWithSender extends ModerationQueueItem {
  sender: CommunityProfile;
}

export interface ReportWithProfiles extends UserReport {
  reporter: CommunityProfile;
  reported?: CommunityProfile;
}

// ============================================
// Dashboard Statistics Types
// ============================================

export interface DMStatistics {
  totalConversations: number;
  totalMessages: number;
  messagesByStatus: {
    pending: number;
    approved: number;
    blocked: number;
    manual_review: number;
  };
  activeReports: number;
  avgResponseTime: number; // in minutes
  topViolations: Array<{
    type: ViolationType;
    count: number;
  }>;
}

export interface TimeRangeStats {
  allTime: DMStatistics;
  last30Days: DMStatistics;
  last7Days: DMStatistics;
  today: DMStatistics;
}

// ============================================
// Sender Profile Statistics Types
// ============================================

export interface SenderStatistics {
  totalConversations: number;
  totalMessages: number;
  approvedMessages: number;
  flaggedMessages: number;
  blockedMessages: number;
  reportsReceived: number;
  activeBans: number;
}

// ============================================
// Filter Types
// ============================================

export interface ModerationQueueFilters {
  status?: QueueStatus | 'all';
  priority?: Priority | 'all';
  messageType?: MessageType | 'all';
  violationType?: ViolationType | 'all';
  dateRange?: {
    start: Date;
    end: Date;
  };
  senderCpId?: string;
}

export interface ConversationFilters {
  status?: 'active' | 'archived' | 'deleted' | 'all';
  dateRange?: {
    start: Date;
    end: Date;
  };
  participantCpId?: string;
  hasFlagged?: boolean;
  hasReports?: boolean;
}

export interface MessageFilters {
  moderationStatus?: ModerationStatus | 'all';
  dateRange?: {
    start: Date;
    end: Date;
  };
  senderCpId?: string;
  conversationId?: string;
  hasViolations?: boolean;
  violationType?: ViolationType | 'all';
}

export interface ReportFilters {
  reportType?: ReportType | 'all';
  status?: ReportStatus | 'all';
  dateRange?: {
    start: Date;
    end: Date;
  };
  reporterCpId?: string;
  reportedCpId?: string;
}

