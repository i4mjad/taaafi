import { FieldValue } from 'firebase-admin/firestore';

export type ContentType = 'group_message' | 'forum_post' | 'comment' | 'group_update';
export type ViolationType = 'account_sharing' | 'none';
export type ModerationStatusType = 'pending' | 'approved' | 'manual_review';

export interface LLMClassification {
  shouldFlag: boolean;
  violationType: ViolationType;
  confidence: number;
  reason: string;
  detectedContent: string[];
}

export interface ModerationConfig {
  textExtractor: (data: Record<string, any>) => string;
  authorIdField: string;
  contentType: ContentType;
  autoHideOnFlag: boolean;
}

export interface ModerationWriteData {
  moderation: {
    status: ModerationStatusType;
    reason: string | null;
    violationType: ViolationType;
    confidence: number;
    detectedContent: string[];
    completedAt: FieldValue;
    ai: {
      reason: string;
    };
  };
  isHidden?: boolean;
}
