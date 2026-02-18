'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { useTranslation } from '@/contexts/TranslationContext';
import { useAuth } from '@/auth/AuthProvider';
import { doc, updateDoc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { toast } from 'sonner';
import { CheckCircle, XCircle, Eye, EyeOff } from 'lucide-react';
import { ForumPostModeration, CommentModeration } from '@/types/community';

interface ForumModerationActionsProps {
  contentId: string;
  contentType: 'post' | 'comment';
  currentStatus?: ForumPostModeration | CommentModeration;
  isHidden?: boolean;
  isDeleted?: boolean;
  onActionComplete?: () => void;
}

export function ForumModerationActions({
  contentId,
  contentType,
  currentStatus,
  isHidden,
  isDeleted,
  onActionComplete
}: ForumModerationActionsProps) {
  const { t } = useTranslation();
  const { user } = useAuth();
  const [showDialog, setShowDialog] = useState(false);
  const [action, setAction] = useState<'approve' | 'block' | 'hide' | 'unhide' | null>(null);
  const [reason, setReason] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const collectionName = contentType === 'post' ? 'forumPosts' : 'comments';

  const handleAction = async (actionType: 'approve' | 'block' | 'hide' | 'unhide') => {
    setAction(actionType);
    setReason('');
    setShowDialog(true);
  };

  const executeAction = async () => {
    if (!action || !user) return;

    setIsSubmitting(true);
    try {
      const contentRef = doc(db, collectionName, contentId);
      const updates: any = {
        updatedAt: Timestamp.now(),
      };

      // Update moderation status
      if (action === 'approve') {
        updates['moderation.status'] = 'approved';
        updates.isHidden = false;
        if (reason) {
          updates['moderation.reason'] = reason;
        }
      } else if (action === 'block') {
        updates['moderation.status'] = 'blocked';
        updates.isHidden = true;
        if (reason) {
          updates['moderation.reason'] = reason;
        }
      } else if (action === 'hide') {
        updates.isHidden = true;
        if (reason && currentStatus) {
          updates['moderation.reason'] = reason;
        }
      } else if (action === 'unhide') {
        updates.isHidden = false;
      }

      await updateDoc(contentRef, updates);
      
      toast.success(t(`modules.community.forum.moderation.actions.${action}Success`));
      setShowDialog(false);
      onActionComplete?.();
    } catch (error) {
      console.error(`Error executing ${action}:`, error);
      toast.error(t('modules.community.forum.moderation.actions.error'));
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isDeleted) {
    return (
      <div className="text-sm text-muted-foreground">
        {t('modules.community.forum.moderation.deletedContent')}
      </div>
    );
  }

  return (
    <>
      <div className="flex flex-wrap gap-2">
        {currentStatus?.status !== 'approved' && (
          <Button
            size="sm"
            variant="outline"
            onClick={() => handleAction('approve')}
            className="text-green-600 hover:text-green-700 hover:bg-green-50 dark:hover:bg-green-950"
          >
            <CheckCircle className="h-4 w-4 mr-2" />
            {t('modules.community.forum.moderation.actions.approve')}
          </Button>
        )}
        
        {currentStatus?.status !== 'blocked' && (
          <Button
            size="sm"
            variant="outline"
            onClick={() => handleAction('block')}
            className="text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-950"
          >
            <XCircle className="h-4 w-4 mr-2" />
            {t('modules.community.forum.moderation.actions.block')}
          </Button>
        )}
        
        {!isHidden ? (
          <Button
            size="sm"
            variant="outline"
            onClick={() => handleAction('hide')}
          >
            <EyeOff className="h-4 w-4 mr-2" />
            {t('modules.community.forum.moderation.actions.hide')}
          </Button>
        ) : (
          <Button
            size="sm"
            variant="outline"
            onClick={() => handleAction('unhide')}
          >
            <Eye className="h-4 w-4 mr-2" />
            {t('modules.community.forum.moderation.actions.unhide')}
          </Button>
        )}
      </div>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {t(`modules.community.forum.moderation.actions.${action}Title`)}
            </DialogTitle>
            <DialogDescription>
              {t(`modules.community.forum.moderation.actions.${action}Description`)}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="reason">
                {t('modules.community.forum.moderation.actions.reasonLabel')}
                {(action === 'block' || action === 'hide') && (
                  <span className="text-red-500 ml-1">*</span>
                )}
              </Label>
              <Textarea
                id="reason"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder={t('modules.community.forum.moderation.actions.reasonPlaceholder')}
                rows={4}
              />
            </div>
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowDialog(false)}
              disabled={isSubmitting}
            >
              {t('common.cancel')}
            </Button>
            <Button
              onClick={executeAction}
              disabled={isSubmitting || ((action === 'block' || action === 'hide') && !reason.trim())}
            >
              {isSubmitting ? t('common.processing') : t('common.confirm')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}

