'use client';

import React, { useMemo, useState } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useAuth } from '@/auth/AuthProvider';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { useDocument } from 'react-firebase-hooks/firestore';
import { addDoc, collection, doc, serverTimestamp, Timestamp, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { AlertTriangle, Ban, FileText, User } from 'lucide-react';
import { toast } from 'sonner';

type TargetType = 'post' | 'comment';

interface ModerationActionDialogProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  targetType: TargetType;
  targetId: string;
  targetTitle?: string;
  authorCPId: string;
  contentStatus?: { isHidden?: boolean; isDeleted?: boolean };
}

export default function ModerationActionDialog(props: ModerationActionDialogProps) {
  const { isOpen, onOpenChange, targetType, targetId, targetTitle, authorCPId, contentStatus } = props;
  const { t, locale } = useTranslation();
  const { user: currentUser } = useAuth();

  // Resolve community profile -> user UID
  const [profileDoc, profileLoading] = useDocument(
    isOpen ? doc(db, 'communityProfiles', authorCPId) : null
  );

  const userUid = useMemo(() => profileDoc?.data()?.userUID as string | undefined, [profileDoc]);
  const authorDisplayName = useMemo(() => profileDoc?.data()?.displayName as string | undefined, [profileDoc]);

  const [mode, setMode] = useState<'warning' | 'ban'>('warning');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Community rule presets
  const ruleIds = [
    'no_personal_contact',
    'respect',
    'anonymous_not_abuse',
    'inappropriate_content',
    'no_medical_advice',
    'honesty_with_empathy',
    'report_responsibility',
    'admin_rights',
  ] as const;
  type RuleId = typeof ruleIds[number];
  const [selectedRule, setSelectedRule] = useState<RuleId | 'custom'>('custom');

  // Warning form
  const [warningData, setWarningData] = useState({
    type: 'content_violation' as 'content_violation' | 'inappropriate_behavior' | 'spam' | 'harassment' | 'other',
    severity: 'medium' as 'low' | 'medium' | 'high' | 'critical',
    reason: '',
    description: '',
    reportId: '',
  });

  // Ban form (minimal for quick actions)
  const [banData, setBanData] = useState({
    severity: 'temporary' as 'temporary' | 'permanent',
    reason: '',
    description: '',
    expiresDate: '' as string, // yyyy-mm-dd
    expiresTime: '' as string, // HH:mm
  });

  // Content actions
  const [shouldHide, setShouldHide] = useState(false);
  const [shouldDelete, setShouldDelete] = useState(false);

  // Reset when opened
  React.useEffect(() => {
    if (isOpen) {
      setMode('warning');
      setSelectedRule('custom');
      setWarningData({ type: 'content_violation', severity: 'medium', reason: '', description: '', reportId: '' });
      setBanData({ severity: 'temporary', reason: '', description: '', expiresDate: '', expiresTime: '' });
      setShouldHide(!contentStatus?.isHidden);
      setShouldDelete(false);
    }
  }, [isOpen, contentStatus?.isHidden]);

  // When a preset rule is selected, pre-fill reason/description but allow editing
  React.useEffect(() => {
    if (selectedRule && selectedRule !== 'custom') {
      const title = t(`modules.community.rules.${selectedRule}.title`);
      const desc = t(`modules.community.rules.${selectedRule}.description`);
      setWarningData((prev) => ({ ...prev, reason: title || prev.reason, description: prev.description || (desc || '') }));
      setBanData((prev) => ({ ...prev, reason: title || prev.reason, description: prev.description || (desc || '') }));
    }
  }, [selectedRule, t]);

  const createWarning = async () => {
    if (!userUid) {
      toast.error(t('modules.community.posts.moderation.errors.userUidMissing'));
      return;
    }
    if (!warningData.reason.trim()) {
      toast.error(t('modules.userManagement.warnings.errors.reasonRequired'));
      return;
    }
    const relatedContent = {
      type: targetType,
      id: targetId,
      ...(targetTitle ? { title: targetTitle } : {}),
    } as const;
    await addDoc(collection(db, 'warnings'), {
      userId: userUid,
      type: warningData.type,
      reason: warningData.reason.trim(),
      description: warningData.description.trim() || null,
      severity: warningData.severity,
      issuedBy: currentUser?.uid || 'unknown-admin',
      issuedAt: serverTimestamp(),
      isActive: true,
      relatedContent,
      reportId: warningData.reportId.trim() || null,
    });
  };

  const createBan = async () => {
    if (!userUid) {
      toast.error(t('modules.community.posts.moderation.errors.userUidMissing'));
      return;
    }
    if (!banData.reason.trim()) {
      toast.error(t('modules.userManagement.bans.errors.reasonRequired'));
      return;
    }
    let expiresAt: Timestamp | null = null;
    if (banData.severity === 'temporary') {
      if (!banData.expiresDate || !banData.expiresTime) {
        toast.error(t('modules.userManagement.bans.expirationRequired'));
        return;
      }
      const [h, m] = banData.expiresTime.split(':').map(Number);
      const d = new Date(banData.expiresDate);
      d.setHours(h || 0, m || 0, 0, 0);
      expiresAt = Timestamp.fromDate(d);
    }
    const relatedContent = {
      type: targetType,
      id: targetId,
      ...(targetTitle ? { title: targetTitle } : {}),
    } as const;
    await addDoc(collection(db, 'bans'), {
      userId: userUid,
      type: 'user_ban',
      scope: 'app_wide',
      reason: banData.reason.trim(),
      description: banData.description.trim() || null,
      severity: banData.severity,
      issuedBy: currentUser?.uid || 'unknown-admin',
      issuedAt: serverTimestamp(),
      expiresAt,
      isActive: true,
      relatedContent,
    });
  };

  const updateContent = async () => {
    const coll = targetType === 'post' ? 'forumPosts' : 'comments';
    const ref = doc(db, coll, targetId);
    const updates: Record<string, any> = { updatedAt: new Date() };
    if (shouldDelete && !contentStatus?.isDeleted) updates.isDeleted = true;
    if (shouldHide !== undefined) updates.isHidden = shouldHide;
    await updateDoc(ref, updates);
  };

  const handleSubmit = async () => {
    try {
      setIsSubmitting(true);
      if (mode === 'warning') {
        await createWarning();
      } else {
        await createBan();
      }
      if (shouldHide || shouldDelete) {
        await updateContent();
      }
      toast.success(t('modules.community.posts.moderation.success'));
      onOpenChange(false);
    } catch (e) {
      console.error(e);
      toast.error(t('modules.community.posts.moderation.error'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const contentBadge = (
    <div className="flex items-center gap-2">
      <Badge variant="outline" className="text-xs">
        <FileText className="h-3 w-3 mr-1" />
        {targetType.toUpperCase()} • {targetId}
      </Badge>
      {targetTitle && (
        <span className="text-xs text-muted-foreground truncate max-w-[240px]">{targetTitle}</span>
      )}
    </div>
  );

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent className="w-[calc(100vw-2rem)] sm:w-[calc(100vw-6rem)] max-w-md sm:max-w-xl md:max-w-2xl max-h-[85dvh] overflow-y-auto p-4 sm:p-6">
        <DialogHeader>
          <DialogTitle>{t('modules.community.posts.moderation.title')}</DialogTitle>
          <DialogDescription>{t('modules.community.posts.moderation.description')}</DialogDescription>
        </DialogHeader>

        <div className="space-y-5">
          {/* Author */}
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div className="space-y-1 min-w-0">
              <Label className="text-xs">{t('modules.community.posts.moderation.author')}</Label>
              <div className="flex flex-wrap items-center gap-2 text-sm">
                <User className="h-4 w-4" />
                <span className="truncate max-w-full sm:max-w-[240px]">{authorDisplayName || authorCPId}</span>
                <Badge variant="secondary" className="text-[10px] break-all max-w-full sm:max-w-[260px]">CP: {authorCPId}</Badge>
                {userUid && (
                  <Badge variant="outline" className="text-[10px] break-all max-w-full sm:max-w-[260px]">UID: {userUid}</Badge>
                )}
              </div>
            </div>
            <div className="space-y-1 sm:text-right min-w-0">
              <Label className="text-xs">{t('modules.community.posts.moderation.content')}</Label>
              {contentBadge}
            </div>
          </div>

          {/* Mode selector */}
          <div className="flex flex-wrap gap-2">
            <Button variant={mode === 'warning' ? 'default' : 'outline'} size="sm" onClick={() => setMode('warning')}>
              <AlertTriangle className="h-4 w-4 mr-2" />
              {t('modules.userManagement.warnings.issueWarning')}
            </Button>
            <Button variant={mode === 'ban' ? 'destructive' : 'outline'} size="sm" onClick={() => setMode('ban')}>
              <Ban className="h-4 w-4 mr-2" />
              {t('modules.userManagement.bans.issueBan')}
            </Button>
          </div>

          {/* Forms */}
          {mode === 'warning' ? (
            <div className="grid gap-3">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <Label className="text-xs">{t('modules.userManagement.warnings.type.label')}</Label>
                  <Select value={warningData.type} onValueChange={(v) => setWarningData({ ...warningData, type: v as any })}>
                    <SelectTrigger className="h-8 text-sm">
                      <SelectValue placeholder={t('modules.userManagement.warnings.type.selectType')} />
                    </SelectTrigger>
                    <SelectContent>
                      {['content_violation','inappropriate_behavior','spam','harassment','other'].map((v) => (
                        <SelectItem key={v} value={v}>{t(`modules.userManagement.warnings.type.${v}`)}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-1.5">
                  <Label className="text-xs">{t('modules.userManagement.warnings.severity.label')}</Label>
                  <Select value={warningData.severity} onValueChange={(v) => setWarningData({ ...warningData, severity: v as any })}>
                    <SelectTrigger className="h-8 text-sm">
                      <SelectValue placeholder={t('modules.userManagement.warnings.severity.selectSeverity')} />
                    </SelectTrigger>
                    <SelectContent>
                      {['low','medium','high','critical'].map((v) => (
                        <SelectItem key={v} value={v}>{t(`modules.userManagement.warnings.severity.${v}`)}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <div className="space-y-1.5">
                <Label className="text-xs">{t('modules.community.posts.moderation.reasonPresets.label')}</Label>
                <Select value={selectedRule} onValueChange={(v) => setSelectedRule(v as RuleId | 'custom')}>
                  <SelectTrigger className="h-8 text-sm w-full">
                    <SelectValue placeholder={t('modules.community.posts.moderation.reasonPresets.placeholder')} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="custom">{t('modules.community.posts.moderation.reasonPresets.custom')}</SelectItem>
                    {ruleIds.map((id) => (
                      <SelectItem key={id} value={id}>{t(`modules.community.rules.${id}.title`)}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label className="text-xs">{t('modules.userManagement.warnings.reason')}</Label>
                <Input className="h-8 text-sm" value={warningData.reason} onChange={(e) => setWarningData({ ...warningData, reason: e.target.value })} placeholder={t('modules.userManagement.warnings.reasonPlaceholder') || ''} />
              </div>
              <div className="space-y-1.5">
                <Label className="text-xs">{t('modules.userManagement.warnings.description')}</Label>
                <Textarea rows={3} className="text-sm" value={warningData.description} onChange={(e) => setWarningData({ ...warningData, description: e.target.value })} placeholder={t('modules.userManagement.warnings.descriptionPlaceholder') || ''} />
              </div>
              <div className="space-y-1.5">
                <Label className="text-xs">{t('modules.userManagement.warnings.reportId')}</Label>
                <Input className="h-8 text-sm" value={warningData.reportId} onChange={(e) => setWarningData({ ...warningData, reportId: e.target.value })} placeholder={t('modules.userManagement.warnings.reportIdPlaceholder') || ''} />
              </div>
            </div>
          ) : (
            <div className="grid gap-3">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <Label className="text-xs">{t('modules.userManagement.bans.severity.label')}</Label>
                  <Select value={banData.severity} onValueChange={(v) => setBanData({ ...banData, severity: v as any })}>
                    <SelectTrigger className="h-8 text-sm">
                      <SelectValue placeholder={t('modules.userManagement.bans.severity.selectSeverity')} />
                    </SelectTrigger>
                    <SelectContent>
                      {['temporary','permanent'].map((v) => (
                        <SelectItem key={v} value={v}>{t(`modules.userManagement.bans.severity.${v}`)}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                {banData.severity === 'temporary' && (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div className="space-y-1.5">
                      <Label className="text-xs">{t('modules.userManagement.bans.expiresDate')}</Label>
                      <Input type="date" className="h-8 text-sm" value={banData.expiresDate} onChange={(e) => setBanData({ ...banData, expiresDate: e.target.value })} />
                    </div>
                    <div className="space-y-1.5">
                      <Label className="text-xs">{t('modules.userManagement.bans.expiresTime')}</Label>
                      <Input type="time" className="h-8 text-sm" value={banData.expiresTime} onChange={(e) => setBanData({ ...banData, expiresTime: e.target.value })} />
                    </div>
                  </div>
                )}
              </div>
              <div className="space-y-1.5">
                <Label className="text-xs">{t('modules.community.posts.moderation.reasonPresets.label')}</Label>
                <Select value={selectedRule} onValueChange={(v) => setSelectedRule(v as RuleId | 'custom')}>
                  <SelectTrigger className="h-8 text-sm w-full">
                    <SelectValue placeholder={t('modules.community.posts.moderation.reasonPresets.placeholder')} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="custom">{t('modules.community.posts.moderation.reasonPresets.custom')}</SelectItem>
                    {ruleIds.map((id) => (
                      <SelectItem key={id} value={id}>{t(`modules.community.rules.${id}.title`)}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label className="text-xs">{t('modules.userManagement.bans.reason')}</Label>
                <Input className="h-8 text-sm" value={banData.reason} onChange={(e) => setBanData({ ...banData, reason: e.target.value })} placeholder={t('modules.userManagement.bans.reasonPlaceholder') || ''} />
              </div>
              <div className="space-y-1.5">
                <Label className="text-xs">{t('modules.userManagement.bans.description')}</Label>
                <Textarea rows={3} className="text-sm" value={banData.description} onChange={(e) => setBanData({ ...banData, description: e.target.value })} placeholder={t('modules.userManagement.bans.descriptionPlaceholder') || ''} />
              </div>
            </div>
          )}

          {/* Content actions */}
          <div className="grid gap-2 p-3 rounded border">
            <div className="flex items-center gap-2 text-sm">
              <FileText className="h-4 w-4" />
              <span className="font-medium">{t('modules.community.posts.moderation.contentActions.title')}</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="flex items-center gap-2">
                <input id="hide" type="checkbox" checked={shouldHide} onChange={(e) => setShouldHide(e.target.checked)} />
                <Label htmlFor="hide" className="text-sm">
                  {contentStatus?.isHidden ? t('modules.community.posts.moderation.contentActions.unhide') : t('modules.community.posts.moderation.contentActions.hide')}
                </Label>
              </div>
              <div className="flex items-center gap-2">
                <input id="delete" type="checkbox" checked={shouldDelete} disabled={contentStatus?.isDeleted} onChange={(e) => setShouldDelete(e.target.checked)} />
                <Label htmlFor="delete" className="text-sm">
                  {t('modules.community.posts.moderation.contentActions.delete')}
                  {contentStatus?.isDeleted && (
                    <span className="ml-2 text-xs text-muted-foreground">{t('modules.community.posts.detailPage.deleted')}</span>
                  )}
                </Label>
              </div>
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={isSubmitting}>
            {t('common.cancel')}
          </Button>
          <Button onClick={handleSubmit} disabled={isSubmitting || profileLoading}>
            {isSubmitting ? t('common.saving') : t('modules.community.posts.moderation.apply')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}


