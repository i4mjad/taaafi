'use client';

import { useState } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { doc, updateDoc, writeBatch } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { CheckCircle, EyeOff, Trash2, X } from 'lucide-react';
import { toast } from 'sonner';

interface GroupMessage {
  id: string;
  groupId: string;
  senderCpId: string;
  body: string;
  isDeleted: boolean;
  isHidden: boolean;
  moderation: {
    status: 'pending' | 'approved' | 'blocked';
    reason?: string;
  };
  createdAt: Date;
}

interface BulkModerationToolsProps {
  messages: GroupMessage[];
  onSelectionChange?: (selectedIds: string[]) => void;
}

export const BulkModerationTools: React.FC<BulkModerationToolsProps> = ({
  messages,
  onSelectionChange
}) => {
  const { t } = useTranslation();
  const [selectedMessageIds, setSelectedMessageIds] = useState<string[]>([]);
  const [showBulkDialog, setShowBulkDialog] = useState(false);
  const [bulkAction, setBulkAction] = useState<'approve' | 'hide' | 'delete'>('approve');
  const [bulkReason, setBulkReason] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);

  const moderatableMessages = messages.filter(m => !m.isDeleted && !m.isHidden);

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      const allIds = moderatableMessages.map(m => m.id);
      setSelectedMessageIds(allIds);
      onSelectionChange?.(allIds);
    } else {
      setSelectedMessageIds([]);
      onSelectionChange?.([]);
    }
  };

  const handleSelectMessage = (messageId: string, checked: boolean) => {
    let newSelection: string[];
    if (checked) {
      newSelection = [...selectedMessageIds, messageId];
    } else {
      newSelection = selectedMessageIds.filter(id => id !== messageId);
    }
    setSelectedMessageIds(newSelection);
    onSelectionChange?.(newSelection);
  };

  const handleBulkModeration = async () => {
    if (selectedMessageIds.length === 0) return;

    setIsProcessing(true);
    try {
      const batch = writeBatch(db);

      selectedMessageIds.forEach(messageId => {
        const messageRef = doc(db, 'group_messages', messageId);
        const updates: any = {
          moderation: {
            status: bulkAction === 'approve' ? 'approved' : 'blocked',
            reason: bulkReason || undefined,
            moderatedBy: 'admin', // TODO: Get actual admin CP ID
            moderatedAt: new Date(),
          }
        };

        if (bulkAction === 'hide') {
          updates.isHidden = true;
        } else if (bulkAction === 'delete') {
          updates.isDeleted = true;
        }

        batch.update(messageRef, updates);
      });

      await batch.commit();

      toast.success(t('modules.modules.admin.content.bulk.success', { count: selectedMessageIds.length }));
      setShowBulkDialog(false);
      setSelectedMessageIds([]);
      setBulkReason('');
      onSelectionChange?.([]);
    } catch (error) {
      console.error('Error bulk moderating messages:', error);
      toast.error(t('modules.admin.content.bulk.error'));
    } finally {
      setIsProcessing(false);
    }
  };

  const openBulkDialog = (action: 'approve' | 'hide' | 'delete') => {
    setBulkAction(action);
    setShowBulkDialog(true);
  };

  const selectedCount = selectedMessageIds.length;
  const allSelected = selectedCount === moderatableMessages.length && moderatableMessages.length > 0;
  const someSelected = selectedCount > 0 && selectedCount < moderatableMessages.length;

  return (
    <>
      {/* Bulk Selection Controls */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span>{t('modules.admin.content.bulk.title')}</span>
            {selectedCount > 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setSelectedMessageIds([]);
                  onSelectionChange?.([]);
                }}
              >
                <X className="h-4 w-4 mr-1" />
                {t('modules.admin.content.bulk.clearSelection')}
              </Button>
            )}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Select All Checkbox */}
          <div className="flex items-center space-x-2">
            <Checkbox
              id="select-all"
              checked={allSelected}
              ref={(el) => {
                const inputEl = el?.querySelector('input');
                if (inputEl) inputEl.indeterminate = someSelected;
              }}
              onCheckedChange={handleSelectAll}
            />
            <Label htmlFor="select-all" className="text-sm">
              {allSelected 
                ? t('modules.admin.content.bulk.deselectAll')
                : someSelected 
                  ? t('modules.admin.content.bulk.selectAll', { count: moderatableMessages.length - selectedCount })
                  : t('modules.admin.content.bulk.selectAll', { count: moderatableMessages.length })
              }
            </Label>
          </div>

          {/* Selection Summary */}
          {selectedCount > 0 && (
            <div className="flex items-center justify-between p-3 bg-primary/10 rounded-lg">
              <span className="text-sm font-medium">
                {t('modules.admin.content.bulk.selected', { count: selectedCount })}
              </span>
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => openBulkDialog('approve')}
                  disabled={isProcessing}
                >
                  <CheckCircle className="h-4 w-4 mr-1" />
                  {t('modules.admin.content.actions.approve')}
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => openBulkDialog('hide')}
                  disabled={isProcessing}
                >
                  <EyeOff className="h-4 w-4 mr-1" />
                  {t('modules.admin.content.actions.hide')}
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={() => openBulkDialog('delete')}
                  disabled={isProcessing}
                >
                  <Trash2 className="h-4 w-4 mr-1" />
                  {t('modules.admin.content.actions.delete')}
                </Button>
              </div>
            </div>
          )}

          {/* Quick Filters */}
          <div className="flex gap-2 text-sm">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                const pendingIds = messages
                  .filter(m => m.moderation?.status === 'pending' && !m.isDeleted && !m.isHidden)
                  .map(m => m.id);
                setSelectedMessageIds(pendingIds);
                onSelectionChange?.(pendingIds);
              }}
            >
              {t('modules.admin.content.bulk.selectPending')}
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => {
                // Select reported messages (this would need to be passed as prop)
                // For now, just select pending
                const pendingIds = messages
                  .filter(m => m.moderation?.status === 'pending')
                  .map(m => m.id);
                setSelectedMessageIds(pendingIds);
                onSelectionChange?.(pendingIds);
              }}
            >
              {t('modules.admin.content.bulk.selectReported')}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Message Selection Checkboxes (to be used in parent component) */}
      <div className="hidden">
        {moderatableMessages.map((message) => (
          <Checkbox
            key={message.id}
            id={`message-${message.id}`}
            checked={selectedMessageIds.includes(message.id)}
            onCheckedChange={(checked) => handleSelectMessage(message.id, checked as boolean)}
          />
        ))}
      </div>

      {/* Bulk Moderation Dialog */}
      <Dialog open={showBulkDialog} onOpenChange={setShowBulkDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {bulkAction === 'approve' && t('modules.admin.content.bulk.approveTitle')}
              {bulkAction === 'hide' && t('modules.admin.content.bulk.hideTitle')}
              {bulkAction === 'delete' && t('modules.admin.content.bulk.deleteTitle')}
            </DialogTitle>
            <DialogDescription>
              {t('modules.admin.content.bulk.confirmAction', { 
                count: selectedCount,
                action: t(`modules.admin.content.actions.${bulkAction}`).toLowerCase()
              })}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="bulk-reason">{t('modules.admin.content.moderation.reason')}</Label>
              <Textarea
                id="bulk-reason"
                placeholder={t('modules.admin.content.moderation.reasonPlaceholder')}
                value={bulkReason}
                onChange={(e) => setBulkReason(e.target.value)}
                rows={3}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowBulkDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button 
              onClick={handleBulkModeration}
              disabled={isProcessing}
              variant={bulkAction === 'delete' ? 'destructive' : 'default'}
            >
              {isProcessing 
                ? t('modules.admin.content.bulk.processing') 
                : t('modules.admin.content.bulk.confirm', { action: t(`modules.admin.content.actions.${bulkAction}`) })
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
};
