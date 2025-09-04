'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Shield, User, CheckCircle, AlertCircle, RotateCw } from 'lucide-react';
import { useTranslation } from '@/contexts/TranslationContext';
import { toast } from 'sonner';

// Firebase
import { useDocument, useCollection } from 'react-firebase-hooks/firestore';
import { collection, doc, orderBy, query, Timestamp, updateDoc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';

// Conversation
import ConversationView from '../[reportId]/ConversationView';

// Notifications
import { createReportUpdatePayload } from '@/utils/notificationPayloads';

interface ReportQuickDialogProps {
  reportId: string | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export default function ReportQuickDialog({ reportId, open, onOpenChange }: ReportQuickDialogProps) {
  const { t, locale } = useTranslation();
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [isUpdating, setIsUpdating] = useState(false);

  // Fetch report
  const [reportSnapshot, reportLoading] = useDocument(
    reportId ? doc(db, 'usersReports', reportId) : null
  );

  const report = useMemo(() => {
    if (!reportSnapshot?.exists()) return null;
    const data = reportSnapshot.data();
    return {
      id: reportSnapshot.id,
      uid: data.uid || '',
      time: data.time || Timestamp.now(),
      reportTypeId: data.reportTypeId || data.reportType || 'dataError',
      status: data.status || 'pending',
      initialMessage: data.initialMessage || data.userJustification || '',
      lastUpdated: data.lastUpdated || data.time || Timestamp.now(),
      messagesCount: data.messagesCount || 1,
    } as const;
  }, [reportSnapshot]);

  // Fetch user
  const [userSnapshot] = useDocument(
    report ? doc(db, 'users', report.uid) : null
  );

  const user = useMemo(() => {
    if (!userSnapshot?.exists()) return null;
    const data = userSnapshot.data();
    return {
      uid: userSnapshot.id,
      displayName: data.displayName,
      locale: data.locale || 'en',
      messagingToken: data.messagingToken,
    } as const;
  }, [userSnapshot]);

  // Report types for name
  const [reportTypesSnapshot] = useCollection(
    query(collection(db, 'reportTypes'), orderBy('updatedAt', 'desc'))
  );

  const reportTypesMap = useMemo(() => {
    const map = new Map<string, { nameEn: string; nameAr: string }>();
    reportTypesSnapshot?.docs.forEach(d => {
      const data = d.data();
      map.set(d.id, { nameEn: data.nameEn || '', nameAr: data.nameAr || '' });
    });
    return map;
  }, [reportTypesSnapshot]);

  const getReportTypeName = (id?: string) => {
    if (!id) return t('modules.userManagement.reports.reportDetails.unknownType') || 'Unknown Type';
    const rt = reportTypesMap.get(id);
    if (!rt) return t('modules.userManagement.reports.reportDetails.unknownType') || 'Unknown Type';
    return locale === 'ar' ? rt.nameAr : rt.nameEn;
  };

  useEffect(() => {
    if (report) setSelectedStatus(report.status);
  }, [reportId, report?.status]);

  const getValidTransitions = (current: string) => {
    switch (current) {
      case 'pending':
        return ['inProgress', 'closed'];
      case 'inProgress':
        return ['closed', 'finalized'];
      case 'waitingForAdminResponse':
        return ['inProgress', 'closed'];
      case 'closed':
        return ['finalized'];
      default:
        return [];
    }
  };

  const sendStatusNotificationToUser = async (newStatus: string) => {
    if (!user?.messagingToken || !user?.locale || !report) return;
    try {
      const userLocale = user.locale === 'arabic' ? 'ar' : 'en';
      const notificationKey = `body${newStatus.charAt(0).toUpperCase() + newStatus.slice(1)}`;
      const title = t(`modules.userManagement.reports.notifications.statusUpdate.${userLocale}.title`);

      // Map report type to key if available
      const reportTypeKey = 'dataError';
      const body = t(`modules.userManagement.reports.notifications.statusUpdate.${userLocale}.${reportTypeKey}.${notificationKey}`);

      const payload = createReportUpdatePayload(title, body, report.id, newStatus, userLocale);
      await fetch('/api/admin/notifications/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token: user.messagingToken, ...payload }),
      });
    } catch (e) {
      console.warn('Failed sending notification', e);
    }
  };

  const handleUpdateStatus = async () => {
    if (!report || !selectedStatus || selectedStatus === report.status) {
      toast.error(t('modules.userManagement.reports.reportDetails.selectDifferentStatus') || 'Please select a different status');
      return;
    }
    const valid = getValidTransitions(report.status);
    if (!valid.includes(selectedStatus)) {
      toast.error(t('modules.userManagement.reports.reportDetails.statusTransitionError') || 'Invalid status transition');
      return;
    }
    setIsUpdating(true);
    try {
      await updateDoc(doc(db, 'usersReports', report.id), { status: selectedStatus, lastUpdated: Timestamp.now() });
      await sendStatusNotificationToUser(selectedStatus);
      toast.success(t('modules.userManagement.reports.reportDetails.updateSuccess') || 'Report updated successfully');
    } catch (e) {
      console.error(e);
      toast.error(t('modules.userManagement.reports.reportDetails.updateError') || 'Failed to update report');
    } finally {
      setIsUpdating(false);
    }
  };

  const renderHeader = () => (
    <div className="flex items-center justify-between gap-3">
      <div className="min-w-0">
        <div className="text-sm text-muted-foreground">{t('modules.userManagement.reports.reportId')}: <span className="font-mono">{report?.id}</span></div>
        <div className="text-sm text-muted-foreground">{t('modules.userManagement.reports.userId')}: <span className="font-mono">{report?.uid}</span></div>
      </div>
      <Badge variant="secondary">{getReportTypeName(report?.reportTypeId)}</Badge>
    </div>
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl">
        <DialogHeader>
          <DialogTitle>{t('modules.userManagement.reports.quickManageDialog.title') || 'Quick Manage Report'}</DialogTitle>
          <DialogDescription>
            {t('modules.userManagement.reports.quickManageDialog.description') || 'Manage the report status and conversation without leaving the list.'}
          </DialogDescription>
        </DialogHeader>
        {reportLoading || !report ? (
          <div className="space-y-3">
            <Skeleton className="h-24 w-full" />
            <Skeleton className="h-72 w-full" />
          </div>
        ) : (
          <div className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center justify-between gap-2">
                  {renderHeader()}
                  <div className="flex items-center gap-2">
                    <Select value={selectedStatus} onValueChange={setSelectedStatus}>
                      <SelectTrigger className="w-[200px] h-9">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="pending">{t('modules.userManagement.reports.statusPending') || 'Pending'}</SelectItem>
                        <SelectItem value="inProgress">{t('modules.userManagement.reports.statusInProgress') || 'In Progress'}</SelectItem>
                        <SelectItem value="waitingForAdminResponse">{t('modules.userManagement.reports.statusWaitingForAdminResponse') || 'Waiting for Admin Response'}</SelectItem>
                        <SelectItem value="closed">{t('modules.userManagement.reports.statusClosed') || 'Closed'}</SelectItem>
                        <SelectItem value="finalized">{t('modules.userManagement.reports.statusFinalized') || 'Finalized'}</SelectItem>
                      </SelectContent>
                    </Select>
                    <Button onClick={handleUpdateStatus} disabled={isUpdating} className="h-9">
                      {isUpdating ? (
                        <>
                          <RotateCw className="h-4 w-4 mr-2 animate-spin" />
                          {t('modules.userManagement.reports.reportDetails.updating') || 'Updating...'}
                        </>
                      ) : (
                        <>
                          <CheckCircle className="h-4 w-4 mr-2" />
                          {t('modules.userManagement.reports.reportDetails.updateStatus') || 'Update Status'}
                        </>
                      )}
                    </Button>
                  </div>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-sm text-muted-foreground">
                  {t('modules.userManagement.reports.reportDetails.initialMessage')}: {report.initialMessage || '-'}
                </div>
              </CardContent>
            </Card>

            <ConversationView
              reportId={report.id}
              reportStatus={report.status}
              onStatusChange={() => { /* no-op here */ }}
            />
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}


