import { Timestamp } from 'firebase/firestore';

export interface GroupUpdate {
  id: string;
  groupId: string;
  authorCpId: string;
  type: 'general' | 'achievement' | 'milestone' | 'support';
  title: string;
  content: string;
  locale: 'en' | 'ar';
  linkedChallengeId?: string;
  linkedFollowupId?: string;
  linkedMilestoneId?: string;
  isAnonymous: boolean;
  isHidden: boolean;
  visibility: 'membersOnly' | 'public';
  
  // Engagement
  reactions: Record<string, string[]>;
  commentCount: number;
  supportCount: number;
  
  // Moderation
  moderation: {
    status: 'pending' | 'approved' | 'manual_review' | 'blocked';
    reason: string | null;
    ai?: {
      reason: string;
      violationType: string;
      severity: 'low' | 'medium' | 'high';
      confidence: number;
      detectedContent: string[];
      culturalContext?: string;
    };
    finalDecision?: {
      action: 'block' | 'review' | 'allow_with_redaction' | 'allow';
      reason: string;
      violationType?: string;
      confidence: number;
    };
    customRules?: Array<{
      type: string;
      severity: string;
      confidence: number;
      reason: string;
    }>;
    analysisAt?: Timestamp;
    moderatedBy?: string;
    moderatedAt?: Timestamp;
    adminAction?: {
      moderatorId: string;
      action: 'approved' | 'blocked' | 'kept_under_review';
      notes?: string;
      reason?: string;
      timestamp: Timestamp;
    };
  };
  
  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface UpdatesFilterState {
  status: 'all' | 'pending' | 'manual_review' | 'approved' | 'blocked';
  language: 'all' | 'en' | 'ar';
  updateType: 'all' | 'general' | 'achievement' | 'milestone' | 'support';
  violationType: string;
  dateRange: {
    from: Date | null;
    to: Date | null;
  } | null;
  searchTerm: string;
}

export interface ModerationStats {
  total: number;
  pending: number;
  manualReview: number;
  approved: number;
  blocked: number;
  byViolationType: Record<string, number>;
  byLanguage: {
    en: number;
    ar: number;
  };
  byUpdateType: {
    general: number;
    achievement: number;
    milestone: number;
    support: number;
  };
}

export interface ModerationAction {
  action: 'approve' | 'block' | 'keep_under_review';
  reason?: string;
  notes?: string;
  violationType?: string;
}

