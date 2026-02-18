'use client';

import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Separator } from '@/components/ui/separator';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { useTranslation } from '@/contexts/TranslationContext';
import { MessageWithSender } from '@/types/directMessages';
import { StatusBadge } from './StatusBadge';
import { SeverityBadge } from './SeverityBadge';
import { ConfidenceIndicator } from './ConfidenceIndicator';
import { ViolationTypeBadge } from './ViolationTypeBadge';
import { format } from 'date-fns';
import { CheckCircle2, XCircle, UserX, Eye } from 'lucide-react';
import { Badge } from '@/components/ui/badge';

interface MessageDetailModalProps {
  message: MessageWithSender | null;
  isOpen: boolean;
  onClose: () => void;
  onApprove: (messageId: string, notes?: string) => Promise<void>;
  onReject: (messageId: string, notes?: string) => Promise<void>;
  onBanUser: (cpId: string) => void;
  onViewConversation: (conversationId: string) => void;
}

export function MessageDetailModal({
  message,
  isOpen,
  onClose,
  onApprove,
  onReject,
  onBanUser,
  onViewConversation,
}: MessageDetailModalProps) {
  const { t } = useTranslation();
  const [reviewNotes, setReviewNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  if (!message) return null;
  
  const handleApprove = async () => {
    setIsSubmitting(true);
    try {
      await onApprove(message.id, reviewNotes);
      onClose();
      setReviewNotes('');
    } catch (error) {
      console.error('Error approving message:', error);
    } finally {
      setIsSubmitting(false);
    }
  };
  
  const handleReject = async () => {
    setIsSubmitting(true);
    try {
      await onReject(message.id, reviewNotes);
      onClose();
      setReviewNotes('');
    } catch (error) {
      console.error('Error rejecting message:', error);
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{t('modules.community.directMessages.modals.messageDetail.title')}</DialogTitle>
          <DialogDescription>
            {t('modules.community.directMessages.messages.columns.messageId')}: {message.id}
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-6">
          {/* Message Content */}
          <div>
            <h3 className="text-sm font-semibold mb-2">
              {t('modules.community.directMessages.modals.messageDetail.fullContent')}
            </h3>
            <div className="bg-muted p-4 rounded-lg">
              <p className="whitespace-pre-wrap">{message.body}</p>
            </div>
            <div className="flex items-center gap-2 mt-2">
              <StatusBadge status={message.moderation?.status || (message as any).status || 'pending'} type="moderation" />
              {message.createdAt && (
                <span className="text-xs text-muted-foreground">
                  {format(message.createdAt.toDate(), 'PPpp')}
                </span>
              )}
            </div>
          </div>
          
          <Separator />
          
          {/* Sender Information */}
          <div>
            <h3 className="text-sm font-semibold mb-2">
              {t('modules.community.directMessages.modals.messageDetail.senderInfo')}
            </h3>
            <div className="flex items-center gap-3">
              <Avatar>
                <AvatarImage src={message.sender?.photoURL} />
                <AvatarFallback>{message.sender?.displayName?.[0] || 'U'}</AvatarFallback>
              </Avatar>
              <div>
                <p className="font-medium">{message.sender?.displayName || 'Unknown User'}</p>
                <p className="text-xs text-muted-foreground">ID: {message.sender?.id || 'N/A'}</p>
                <p className="text-xs text-muted-foreground">UID: {message.sender?.userUID || 'N/A'}</p>
              </div>
            </div>
          </div>
          
          <Separator />
          
          {/* Conversation Information */}
          <div>
            <h3 className="text-sm font-semibold mb-2">
              {t('modules.community.directMessages.modals.messageDetail.conversationInfo')}
            </h3>
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">
                {t('modules.community.directMessages.conversations.columns.conversationId')}: {message.conversationId}
              </p>
              <Button 
                variant="outline" 
                size="sm"
                onClick={() => onViewConversation(message.conversationId)}
              >
                <Eye className="h-4 w-4 mr-2" />
                {t('modules.community.directMessages.moderationQueue.actions.viewConversation')}
              </Button>
            </div>
          </div>
          
          {/* AI Analysis */}
          {message.moderation.ai && (
            <>
              <Separator />
              <div>
                <h3 className="text-sm font-semibold mb-3">
                  {t('modules.community.directMessages.modals.messageDetail.aiAnalysis')}
                </h3>
                <div className="space-y-3">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">
                        {t('modules.community.directMessages.moderationQueue.columns.violationType')}
                      </p>
                      <ViolationTypeBadge violationType={message.moderation.ai.violationType} />
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">
                        {t('modules.community.directMessages.moderationQueue.columns.severity')}
                      </p>
                      <SeverityBadge severity={message.moderation.ai.severity} />
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">
                        {t('modules.community.directMessages.moderationQueue.columns.confidence')}
                      </p>
                      <ConfidenceIndicator confidence={message.moderation.ai.confidence} />
                    </div>
                  </div>
                  
                  {message.moderation.ai.reason && (
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">Reason</p>
                      <p className="text-sm bg-muted p-2 rounded">{message.moderation.ai.reason}</p>
                    </div>
                  )}
                  
                  {message.moderation.ai.detectedContent && message.moderation.ai.detectedContent.length > 0 && (
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">Detected Content</p>
                      <div className="flex flex-wrap gap-1">
                        {message.moderation.ai.detectedContent.map((content: string) => (
                          <Badge key={content} variant="outline">{content}</Badge>
                        ))}
                      </div>
                    </div>
                  )}
                  
                  {message.moderation.ai.culturalContext && (
                    <div>
                      <p className="text-xs text-muted-foreground mb-1">Cultural Context</p>
                      <p className="text-sm bg-muted p-2 rounded">{message.moderation.ai.culturalContext}</p>
                    </div>
                  )}
                </div>
              </div>
            </>
          )}
          
          {/* Custom Rules */}
          {message.moderation.customRules && message.moderation.customRules.length > 0 && (
            <>
              <Separator />
              <div>
                <h3 className="text-sm font-semibold mb-3">
                  {t('modules.community.directMessages.modals.messageDetail.customRules')}
                </h3>
                <div className="space-y-2">
                  {message.moderation.customRules.map((rule: any) => (
                    <div key={`${rule.type}-${rule.severity}`} className="bg-muted p-3 rounded space-y-1">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-medium">{rule.type}</span>
                        <div className="flex items-center gap-2">
                          <SeverityBadge severity={rule.severity} />
                          <ConfidenceIndicator confidence={rule.confidence} showPercentage={true} />
                        </div>
                      </div>
                      <p className="text-xs text-muted-foreground">{rule.reason}</p>
                    </div>
                  ))}
                </div>
              </div>
            </>
          )}
          
          {/* Previous Review */}
          {message.moderation.reviewedAt && (
            <>
              <Separator />
              <div>
                <h3 className="text-sm font-semibold mb-2">Previous Review</h3>
                <div className="space-y-2">
                  <p className="text-sm">
                    <span className="text-muted-foreground">Reviewed by:</span> {message.moderation.reviewedBy}
                  </p>
                  <p className="text-sm">
                    <span className="text-muted-foreground">Action:</span> {message.moderation.reviewAction}
                  </p>
                  {message.moderation.reviewNotes && (
                    <div className="bg-muted p-2 rounded">
                      <p className="text-sm">{message.moderation.reviewNotes}</p>
                    </div>
                  )}
                </div>
              </div>
            </>
          )}
          
          {/* Admin Actions */}
          <Separator />
          <div>
            <h3 className="text-sm font-semibold mb-3">
              {t('modules.community.directMessages.modals.messageDetail.adminActions')}
            </h3>
            
            <div className="space-y-3">
              <div>
                <label className="text-xs text-muted-foreground mb-1 block">
                  {t('modules.community.directMessages.modals.messageDetail.reviewNotes')}
                </label>
                <Textarea
                  value={reviewNotes}
                  onChange={(e) => setReviewNotes(e.target.value)}
                  placeholder={t('modules.community.directMessages.modals.messageDetail.addNotes')}
                  rows={3}
                />
              </div>
              
              <div className="flex flex-wrap gap-2">
                <Button 
                  onClick={handleApprove}
                  disabled={isSubmitting}
                  className="flex-1"
                >
                  <CheckCircle2 className="h-4 w-4 mr-2" />
                  {t('modules.community.directMessages.moderationQueue.actions.approve')}
                </Button>
                
                <Button 
                  onClick={handleReject}
                  disabled={isSubmitting}
                  variant="destructive"
                  className="flex-1"
                >
                  <XCircle className="h-4 w-4 mr-2" />
                  {t('modules.community.directMessages.moderationQueue.actions.reject')}
                </Button>
                
                <Button 
                  onClick={() => message.sender?.id && onBanUser(message.sender.id)}
                  disabled={isSubmitting}
                  variant="outline"
                  className="w-full"
                >
                  <UserX className="h-4 w-4 mr-2" />
                  {t('modules.community.directMessages.moderationQueue.actions.banUser')}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

