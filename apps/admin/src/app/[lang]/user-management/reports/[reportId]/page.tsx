'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from "@/contexts/TranslationContext";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Separator } from '@/components/ui/separator';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Skeleton } from '@/components/ui/skeleton';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import {
  ArrowLeft,
  Copy,
  ExternalLink,
  User,
  Calendar,
  Clock,
  FileText,
  AlertCircle,
  CheckCircle,
  XCircle,
  Languages,
  MessageSquare,
} from 'lucide-react';
import Link from 'next/link';
import { toast } from 'sonner';

// Firebase imports
import { useDocument, useCollection } from 'react-firebase-hooks/firestore';
import { doc, updateDoc, Timestamp, collection, query, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';

// Import conversation component
import ConversationView from './ConversationView';
import MigrationManagementCard from '../../users/[uid]/MigrationManagementCard';

// Import notification payload utilities
import { createReportUpdatePayload } from '@/utils/notificationPayloads';

// Import types
import { UserReport as ExtendedUserReport, REPORT_TYPE_IDS } from '@/types/reports';
import { ForumPost, Comment, CommunityProfile } from '@/types/community';

// Use the extended UserReport from types
type UserReport = ExtendedUserReport;

interface UserProfile {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  locale?: string;
  createdAt: Timestamp;
  lastLoginAt?: Timestamp;
  messagingToken?: string;
  userRelapses?: string[];
  userMasturbatingWithoutWatching?: string[];
  userWatchingWithoutMasturbating?: string[];
}

export default function ReportDetailsPage() {
  const { t, locale } = useTranslation();
  const params = useParams();
  const router = useRouter();
  const reportId = params.reportId as string;

  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [isUpdating, setIsUpdating] = useState(false);
  const [migrationDialogOpen, setMigrationDialogOpen] = useState(false);

  // Fetch report data using react-firebase-hooks
  const [reportSnapshot, reportLoading, reportError] = useDocument(
    doc(db, 'usersReports', reportId)
  );

  // Parse report data
  const report: UserReport | null = reportSnapshot?.exists() ? {
    id: reportSnapshot.id,
    uid: reportSnapshot.data().uid || '',
    time: reportSnapshot.data().time || Timestamp.now(),
    reportTypeId: reportSnapshot.data().reportTypeId || reportSnapshot.data().reportType || 'dataError',
    status: reportSnapshot.data().status || 'pending',
    initialMessage: reportSnapshot.data().initialMessage || reportSnapshot.data().userJustification || '',
    lastUpdated: reportSnapshot.data().lastUpdated || reportSnapshot.data().time || Timestamp.now(),
    messagesCount: reportSnapshot.data().messagesCount || 1,
    // Support both new relatedContent structure and legacy targetId/targetType
    relatedContent: reportSnapshot.data().relatedContent || {
      type: reportSnapshot.data().targetType,
      contentId: reportSnapshot.data().targetId
    },
    // Keep legacy fields for backward compatibility
    targetId: reportSnapshot.data().targetId,
    targetType: reportSnapshot.data().targetType,
  } : null;

  // Fetch user data using react-firebase-hooks
  const [userSnapshot, userLoading, userError] = useDocument(
    report ? doc(db, 'users', report.uid) : null
  );

  // Parse user data
  const user: UserProfile | null = userSnapshot?.exists() ? {
    uid: userSnapshot.id,
    email: userSnapshot.data().email || '',
    displayName: userSnapshot.data().displayName,
    photoURL: userSnapshot.data().photoURL,
    locale: userSnapshot.data().locale || 'en',
    createdAt: userSnapshot.data().createdAt || Timestamp.now(),
    lastLoginAt: userSnapshot.data().lastLoginAt,
    messagingToken: userSnapshot.data().messagingToken,
    userRelapses: userSnapshot.data().userRelapses,
    userMasturbatingWithoutWatching: userSnapshot.data().userMasturbatingWithoutWatching,
    userWatchingWithoutMasturbating: userSnapshot.data().userWatchingWithoutMasturbating,
  } : null;

  // Fetch related post if the report is for a post
  const [relatedPostSnapshot] = useDocument(
    (report?.relatedContent?.type === 'post' && report.relatedContent.contentId) ||
    (report?.targetType === 'post' && report.targetId)
      ? doc(db, 'forumPosts', report.relatedContent?.contentId || report.targetId!)
      : null
  );

  // Fetch related comment if the report is for a comment
  const [relatedCommentSnapshot] = useDocument(
    (report?.relatedContent?.type === 'comment' && report.relatedContent.contentId) ||
    (report?.targetType === 'comment' && report.targetId)
      ? doc(db, 'comments', report.relatedContent?.contentId || report.targetId!)
      : null
  );

  // Fetch related community profile if the report is for a user
  const [relatedProfileSnapshot] = useDocument(
    (report?.relatedContent?.type === 'user' && report.relatedContent.contentId) ||
    (report?.targetType === 'user' && report.targetId)
      ? doc(db, 'communityProfiles', report.relatedContent?.contentId || report.targetId!)
      : null
  );

  // Parse related post data
  const relatedPost: ForumPost | null = relatedPostSnapshot?.exists() ? {
    id: relatedPostSnapshot.id,
    ...relatedPostSnapshot.data(),
    createdAt: relatedPostSnapshot.data()?.createdAt?.toDate() || new Date(),
    updatedAt: relatedPostSnapshot.data()?.updatedAt?.toDate(),
  } as ForumPost : null;

  // Parse related comment data
  const relatedComment: Comment | null = relatedCommentSnapshot?.exists() ? {
    id: relatedCommentSnapshot.id,
    ...relatedCommentSnapshot.data(),
    createdAt: relatedCommentSnapshot.data()?.createdAt?.toDate() || new Date(),
    updatedAt: relatedCommentSnapshot.data()?.updatedAt?.toDate(),
  } as Comment : null;

  // Parse related profile data
  const relatedProfile: CommunityProfile | null = relatedProfileSnapshot?.exists() ? {
    id: relatedProfileSnapshot.id,
    ...relatedProfileSnapshot.data(),
    createdAt: relatedProfileSnapshot.data()?.createdAt?.toDate() || new Date(),
    updatedAt: relatedProfileSnapshot.data()?.updatedAt?.toDate(),
  } as CommunityProfile : null;

  // Fetch the parent post for a comment (if the report is for a comment)
  const [parentPostSnapshot] = useDocument(
    relatedComment?.postId 
      ? doc(db, 'forumPosts', relatedComment.postId)
      : null
  );

  // Parse parent post data
  const parentPost: ForumPost | null = parentPostSnapshot?.exists() ? {
    id: parentPostSnapshot.id,
    ...parentPostSnapshot.data(),
    createdAt: parentPostSnapshot.data()?.createdAt?.toDate() || new Date(),
    updatedAt: parentPostSnapshot.data()?.updatedAt?.toDate(),
  } as ForumPost : null;

  // Fetch report types for dynamic display
  const [reportTypesSnapshot] = useCollection(
    query(
      collection(db, 'reportTypes'),
      orderBy('updatedAt', 'desc')
    )
  );

  // Convert report types to a lookup map
  const reportTypesMap = useMemo(() => {
    if (!reportTypesSnapshot) return new Map();
    
    const map = new Map();
    reportTypesSnapshot.docs.forEach(doc => {
      const data = doc.data();
      map.set(doc.id, {
        id: doc.id,
        nameEn: data.nameEn || '',
        nameAr: data.nameAr || '',
        descriptionEn: data.descriptionEn || '',
        descriptionAr: data.descriptionAr || '',
        isActive: data.isActive ?? true,
      });
    });
    return map;
  }, [reportTypesSnapshot]);

  // Function to get report type name based on locale
  const getReportTypeName = (reportTypeId: string) => {
    const reportType = reportTypesMap.get(reportTypeId);
    if (!reportType) {
      return t('modules.userManagement.reports.reportDetails.unknownType') || 'Unknown Type';
    }
    return locale === 'ar' ? reportType.nameAr : reportType.nameEn;
  };

  // Initialize form state when report loads
  useEffect(() => {
    if (report && !selectedStatus) {
      setSelectedStatus(report.status);
    }
  }, [report, selectedStatus]);

  const getStatusBadge = (status: string) => {
    const variants = {
      pending: { variant: 'secondary' as const, icon: Clock, className: 'text-yellow-600' },
      inProgress: { variant: 'default' as const, icon: AlertCircle, className: 'text-blue-600' },
      waitingForAdminResponse: { variant: 'default' as const, icon: AlertCircle, className: 'text-orange-600' },
      closed: { variant: 'outline' as const, icon: CheckCircle, className: 'text-green-600' },
      finalized: { variant: 'default' as const, icon: XCircle, className: 'text-gray-600' },
    };

    const config = variants[status as keyof typeof variants] || variants.pending;
    const Icon = config.icon;

    return (
      <Badge variant={config.variant} className={config.className}>
        <Icon className="h-3 w-3 mr-1" />
        {t(`modules.userManagement.reports.status${status.charAt(0).toUpperCase() + status.slice(1)}`) || status}
      </Badge>
    );
  };

  const formatDate = (timestamp: Timestamp | undefined) => {
    if (!timestamp) return t('common.unknown') || 'Unknown';
    
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(timestamp.toDate());
  };

  const copyToClipboard = async (text: string, label: string) => {
    try {
      await navigator.clipboard.writeText(text);
      toast.success(`${label} ${t('modules.userManagement.reports.reportDetails.copiedToClipboard') || 'copied to clipboard'}`);
    } catch (error) {
      toast.error(t('modules.userManagement.reports.reportDetails.copyToClipboardError') || 'Failed to copy to clipboard');
    }
  };

  const getValidStatusTransitions = (currentStatus: string): string[] => {
    switch (currentStatus) {
      case 'pending':
        return ['inProgress', 'closed'];
      case 'inProgress':
        return ['closed', 'finalized'];
      case 'waitingForAdminResponse':
        return ['inProgress', 'closed'];
      case 'closed':
        return ['finalized'];
      case 'finalized':
        return [];
      default:
        return [];
    }
  };

  const validateStatusUpdate = (newStatus: string): boolean => {
    if (!report) return false;
    
    const validTransitions = getValidStatusTransitions(report.status);
    if (!validTransitions.includes(newStatus)) {
      toast.error(t('modules.userManagement.reports.errors.invalidStatusTransition') || 'Invalid status transition');
      return false;
    }

    return true;
  };

  const sendNotificationToUser = async (newStatus: string) => {
    if (!user?.messagingToken || !user?.locale) {
      console.warn('No messaging token or locale found for user');
      return;
    }

    try {
      const userLocale = user.locale === 'arabic' ? 'ar' : 'en';
      const notificationKey = `body${newStatus.charAt(0).toUpperCase() + newStatus.slice(1)}`;
      
      // Map report type IDs to notification keys
      const getReportTypeKey = (reportTypeId: string): string => {
        const reportTypeMap: { [key: string]: string } = {
          'dataError': 'dataError',
          'technicalIssue': 'technicalIssue',
          'contentIssue': 'contentIssue',
          'accountIssue': 'accountIssue',
          'featureRequest': 'featureRequest',
          'other': 'other'
        };
        return reportTypeMap[reportTypeId] || 'default';
      };

      const reportTypeKey = getReportTypeKey(report?.reportTypeId || '');
      
      const title = t(`modules.userManagement.reports.notifications.statusUpdate.${userLocale}.title`);
      const body = t(`modules.userManagement.reports.notifications.statusUpdate.${userLocale}.${reportTypeKey}.${notificationKey}`);

      // Use the new payload structure with navigation data
      const payload = createReportUpdatePayload(
        title,
        body,
        reportId,
        newStatus,
        userLocale
      );

      const response = await fetch('/api/admin/notifications/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          token: user.messagingToken,
          ...payload
        }),
      });

      if (response.ok) {
        toast.success(t('modules.userManagement.reports.reportDetails.notificationSent') || 'Notification sent to user');
      } else {
        toast.error(t('modules.userManagement.reports.reportDetails.notificationError') || 'Failed to send notification');
      }
    } catch (error) {
      console.error('Error sending notification:', error);
      toast.error(t('modules.userManagement.reports.reportDetails.notificationError') || 'Failed to send notification');
    }
  };

  const handleStatusUpdate = async () => {
    console.log('Attempting to update status from', report?.status, 'to', selectedStatus);
    
    if (!report) {
      toast.error(t('modules.userManagement.reports.reportDetails.reportDataNotAvailable') || 'Report data not available');
      return;
    }

    if (!selectedStatus || selectedStatus === report.status) {
      toast.error(t('modules.userManagement.reports.reportDetails.pleaseSelectDifferentStatus') || 'Please select a different status');
      return;
    }

    if (!validateStatusUpdate(selectedStatus)) {
      return; // Validation already shows error toast
    }

    setIsUpdating(true);
    try {
      console.log('Updating report in Firebase...');
      
      // Update the report using Firebase SDK directly
      await updateDoc(doc(db, 'usersReports', reportId), {
        status: selectedStatus,
        lastUpdated: Timestamp.now(),
      });

      console.log('Report updated successfully, sending notification...');

      // Send notification to user
      await sendNotificationToUser(selectedStatus);

      toast.success(t('modules.userManagement.reports.reportDetails.updateSuccess') || 'Report updated successfully');
      
      // Update local state to reflect change
      setSelectedStatus(selectedStatus);
      
      // Redirect back to reports list if finalized
      if (selectedStatus === 'finalized') {
        setTimeout(() => {
          router.push(`/${locale}/user-management/reports`);
        }, 1500);
      }
    } catch (error) {
      console.error('Error updating report:', error);
      toast.error(t('modules.userManagement.reports.reportDetails.updateError') || 'Failed to update report');
    } finally {
      setIsUpdating(false);
    }
  };

  const headerDictionary = {
    documents: t('appSidebar.reports') || 'Reports',
  };

  if (reportError || userError) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex flex-1 flex-col">
          <div className="@container/main flex flex-1 flex-col gap-2">
            <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
              <div className="flex items-center gap-4">
                <Button variant="outline" size="sm" asChild>
                  <Link href={`/${locale}/user-management/reports`}>
                    <ArrowLeft className="h-4 w-4 mr-2" />
                    {t('common.back') || 'Back'}
                  </Link>
                </Button>
              </div>
              <div className="text-center py-8">
                <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
                <h1 className="text-2xl font-bold">
                  {t('modules.userManagement.reports.errors.reportNotFound') || 'Report Not Found'}
                </h1>
                <p className="text-muted-foreground mt-2">
                  {reportError?.message || userError?.message || t('modules.userManagement.reports.reportDetails.requestedReportNotFound') || 'The requested report could not be found.'}
                </p>
              </div>
            </div>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex flex-1 flex-col">
        <div className="@container/main flex flex-1 flex-col gap-2">
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
            {/* Header */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <Button variant="outline" size="sm" asChild>
                  <Link href={`/${locale}/user-management/reports`}>
                    <ArrowLeft className="h-4 w-4 mr-2" />
                    {t('common.back') || 'Back'}
                  </Link>
                </Button>
                <div>
                  <h1 className="text-3xl font-bold tracking-tight">
                    {t('modules.userManagement.reports.reportDetails.title') || 'Report Details'}
                  </h1>
                  <p className="text-muted-foreground">
                    {t('modules.userManagement.reports.reportDetails.description') || 'Review and manage this user report'}
                  </p>
                </div>
              </div>
            </div>

            {reportLoading || userLoading ? (
              <div className="grid gap-6 lg:grid-cols-3">
                <div className="lg:col-span-2 space-y-6">
                  <Skeleton className="h-64 w-full" />
                  <Skeleton className="h-96 w-full" />
                </div>
                <div className="space-y-6">
                  <Skeleton className="h-64 w-full" />
                </div>
              </div>
            ) : report ? (
              <div className="grid gap-6 lg:grid-cols-3">
                {/* Main Content */}
                <div className="lg:col-span-2 space-y-6">
                  {/* Report Information */}
                  <Card>
                    <CardHeader>
                      <CardTitle className="flex items-center gap-2">
                        <FileText className="h-5 w-5" />
                        {t('modules.userManagement.reports.reportDetails.reportInformation') || 'Report Information'}
                      </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label className="text-sm font-medium">
                            {t('modules.userManagement.reports.reportDetails.reportId') || 'Report ID'}
                          </Label>
                          <div className="flex items-center gap-2 mt-1">
                            <span className="font-mono text-sm bg-muted px-2 py-1 rounded">
                              {report.id}
                            </span>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => copyToClipboard(report.id, 'Report ID')}
                            >
                              <Copy className="h-3 w-3" />
                            </Button>
                          </div>
                        </div>

                        <div>
                          <Label className="text-sm font-medium">
                            {t('modules.userManagement.reports.reportDetails.userId') || 'User ID'}
                          </Label>
                          <div className="flex items-center gap-2 mt-1">
                            <Link 
                              href={`/${locale}/user-management/users/${report.uid}`}
                              className="font-mono text-sm text-blue-600 hover:underline"
                            >
                              {report.uid}
                            </Link>
                            <ExternalLink className="h-3 w-3 text-muted-foreground" />
                          </div>
                        </div>

                        <div>
                          <Label className="text-sm font-medium">
                            {t('modules.userManagement.reports.reportDetails.reportType') || 'Report Type'}
                          </Label>
                          <div className="mt-1">
                            <Badge variant="outline">
                              {getReportTypeName(report.reportTypeId)}
                            </Badge>
                          </div>
                        </div>

                        <div>
                          <Label className="text-sm font-medium">
                            {t('modules.userManagement.reports.reportDetails.status') || 'Status'}
                          </Label>
                          <div className="mt-1">
                            {getStatusBadge(report.status)}
                          </div>
                        </div>

                        <div>
                          <Label className="text-sm font-medium">
                            {t('modules.userManagement.reports.reportDetails.submittedDate') || 'Submitted Date'}
                          </Label>
                          <div className="flex items-center gap-2 mt-1">
                            <Calendar className="h-4 w-4 text-muted-foreground" />
                            <span className="text-sm">{formatDate(report.time)}</span>
                          </div>
                        </div>

                        <div>
                          <Label className="text-sm font-medium">
                            {t('modules.userManagement.reports.reportDetails.lastUpdated') || 'Last Updated'}
                          </Label>
                          <div className="flex items-center gap-2 mt-1">
                            <Clock className="h-4 w-4 text-muted-foreground" />
                            <span className="text-sm">{formatDate(report.lastUpdated)}</span>
                          </div>
                        </div>
                      </div>

                      <Separator />

                      <div>
                        <Label className="text-sm font-medium">
                          {t('modules.userManagement.reports.reportDetails.initialMessage') || 'Initial Message'}
                        </Label>
                        <div className="mt-2 p-3 bg-muted rounded-md">
                          <p className="text-sm whitespace-pre-wrap">{report.initialMessage}</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>

                  {/* Related Content */}
                  {(relatedPost || relatedComment || relatedProfile) && (
                    <Card>
                      <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                          {relatedPost ? (
                            <FileText className="h-5 w-5" />
                          ) : relatedComment ? (
                            <MessageSquare className="h-5 w-5" />
                          ) : (
                            <User className="h-5 w-5" />
                          )}
                          {relatedPost
                            ? (t('modules.userManagement.reports.reportDetails.reportedPost') || 'Reported Post')
                            : relatedComment
                              ? (t('modules.userManagement.reports.reportDetails.reportedComment') || 'Reported Comment')
                              : (t('modules.userManagement.reports.reportDetails.reportedUser') || 'Reported User')}
                        </CardTitle>
                        <CardDescription>
                          {relatedPost 
                            ? (t('modules.userManagement.reports.reportDetails.postReportedDescription') || 'The forum post that was reported')
                            : relatedComment
                              ? (t('modules.userManagement.reports.reportDetails.commentReportedDescription') || 'The comment that was reported')
                              : (t('modules.userManagement.reports.reportDetails.userReportedDescription') || 'The user profile that was reported')}
                        </CardDescription>
                      </CardHeader>
                      <CardContent className="space-y-4">
                        {relatedPost && (
                          <div className="space-y-3">
                            <div>
                              <Label className="text-sm font-medium">
                                {t('modules.community.posts.title') || 'Post Title'}
                              </Label>
                              <div className="mt-1">
                                <h3 className="text-lg font-semibold">{relatedPost.title}</h3>
                              </div>
                            </div>
                            
                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <Label className="text-sm font-medium">
                                  {t('modules.community.posts.author') || 'Author'}
                                </Label>
                                <div className="mt-1">
                                  <span className="text-sm">{relatedPost.authorCPId}</span>
                                </div>
                              </div>
                              
                              <div>
                                <Label className="text-sm font-medium">
                                  {t('modules.community.posts.createdAt') || 'Created'}
                                </Label>
                                <div className="mt-1">
                                  <span className="text-sm">{new Intl.DateTimeFormat(locale, {
                                   year: 'numeric',
                                   month: 'long',
                                   day: 'numeric',
                                   hour: '2-digit',
                                   minute: '2-digit',
                                 }).format(relatedPost.createdAt)}</span>
                                </div>
                              </div>
                            </div>

                            <div>
                              <Label className="text-sm font-medium">
                                {t('modules.community.posts.body') || 'Post Content'}
                              </Label>
                              <div className="mt-2 p-3 bg-muted rounded-md">
                                <p className="text-sm whitespace-pre-wrap">{relatedPost.body}</p>
                              </div>
                            </div>

                            <div className="flex items-center justify-between">
                              <div className="flex items-center space-x-2">
                                {relatedPost.isHidden && (
                                  <Badge variant="destructive">
                                    {t('modules.community.posts.hidden') || 'Hidden'}
                                  </Badge>
                                )}
                                <Badge variant={relatedPost.score >= 0 ? 'default' : 'destructive'}>
                                  {t('modules.community.posts.score')}: {relatedPost.score}
                                </Badge>
                              </div>
                              <Button variant="outline" size="sm" asChild>
                                <Link href={`/${locale}/community/forum/posts/${relatedPost.id}`}>
                                  <ExternalLink className="h-3 w-3 mr-2" />
                                  {t('modules.userManagement.reports.reportDetails.viewPost') || 'View Post'}
                                </Link>
                              </Button>
                            </div>
                          </div>
                        )}

                        {relatedComment && (
                          <div className="space-y-3">
                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <Label className="text-sm font-medium">
                                  {t('modules.community.comments.author') || 'Author'}
                                </Label>
                                <div className="mt-1">
                                  <span className="text-sm">{relatedComment.authorCPId}</span>
                                </div>
                              </div>
                              
                              <div>
                                <Label className="text-sm font-medium">
                                  {t('modules.community.comments.createdAt') || 'Created'}
                                </Label>
                                <div className="mt-1">
                                  <span className="text-sm">{new Intl.DateTimeFormat(locale, {
                                   year: 'numeric',
                                   month: 'long',
                                   day: 'numeric',
                                   hour: '2-digit',
                                   minute: '2-digit',
                                 }).format(relatedComment.createdAt)}</span>
                                </div>
                              </div>
                            </div>

                            <div>
                              <Label className="text-sm font-medium">
                                {t('modules.community.comments.body') || 'Comment Content'}
                              </Label>
                              <div className="mt-2 p-3 bg-muted rounded-md">
                                <p className="text-sm whitespace-pre-wrap">{relatedComment.body}</p>
                              </div>
                            </div>

                            {parentPost && (
                              <div>
                                <Label className="text-sm font-medium">
                                  {t('modules.userManagement.reports.reportDetails.parentPost') || 'Parent Post'}
                                </Label>
                                <div className="mt-2 p-3 bg-secondary rounded-md">
                                  <h4 className="font-medium text-sm mb-2">{parentPost.title}</h4>
                                                                     <p className="text-xs text-muted-foreground">
                                     {t('modules.community.posts.by')} {parentPost.authorCPId} • {new Intl.DateTimeFormat(locale, {
                                       year: 'numeric',
                                       month: 'long',
                                       day: 'numeric',
                                       hour: '2-digit',
                                       minute: '2-digit',
                                     }).format(parentPost.createdAt)}
                                   </p>
                                </div>
                              </div>
                            )}

                            <div className="flex items-center justify-between">
                              <div className="flex items-center space-x-2">
                                {relatedComment.isHidden && (
                                  <Badge variant="destructive">
                                    {t('modules.community.comments.hidden') || 'Hidden'}
                                  </Badge>
                                )}
                                <Badge variant={relatedComment.score >= 0 ? 'default' : 'destructive'}>
                                  {t('modules.community.comments.score')}: {relatedComment.score}
                                </Badge>
                              </div>
                              <div className="flex space-x-2">
                                {parentPost && (
                                  <Button variant="outline" size="sm" asChild>
                                    <Link href={`/${locale}/community/forum/posts/${parentPost.id}`}>
                                      <ExternalLink className="h-3 w-3 mr-2" />
                                      {t('modules.userManagement.reports.reportDetails.viewParentPost') || 'View Parent Post'}
                                    </Link>
                                  </Button>
                                )}
                              </div>
                            </div>
                          </div>
                        )}

                        {relatedProfile && (
                          <div className="space-y-3">
                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <Label className="text-sm font-medium">
                                  {t('modules.community.profiles.displayName') || 'Display Name'}
                                </Label>
                                <div className="mt-1">
                                  <span className="text-sm font-medium">{relatedProfile.displayName}</span>
                                </div>
                              </div>

                              <div>
                                <Label className="text-sm font-medium">
                                  {t('modules.community.profiles.gender') || 'Gender'}
                                </Label>
                                <div className="mt-1">
                                  <Badge variant="outline">
                                    {relatedProfile.gender === 'male' && (t('modules.community.profiles.male') || 'Male')}
                                    {relatedProfile.gender === 'female' && (t('modules.community.profiles.female') || 'Female')}
                                    {relatedProfile.gender === 'other' && (t('modules.community.profiles.other') || 'Other')}
                                  </Badge>
                                </div>
                              </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <Label className="text-sm font-medium">
                                  {t('modules.community.profiles.isAnonymous') || 'Anonymous'}
                                </Label>
                                <div className="mt-1">
                                  <Badge variant={relatedProfile.isAnonymous ? 'secondary' : 'default'}>
                                    {relatedProfile.isAnonymous ? (t('common.yes') || 'Yes') : (t('common.no') || 'No')}
                                  </Badge>
                                </div>
                              </div>

                              <div>
                                <Label className="text-sm font-medium">
                                  {t('modules.community.profiles.memberSince') || 'Member Since'}
                                </Label>
                                <div className="mt-1">
                                  <span className="text-sm">{new Intl.DateTimeFormat(locale, {
                                    year: 'numeric',
                                    month: 'long',
                                    day: 'numeric',
                                    hour: '2-digit',
                                    minute: '2-digit',
                                  }).format(relatedProfile.createdAt)}</span>
                                </div>
                              </div>
                            </div>

                            <div className="flex items-center justify-between">
                              <div className="text-xs text-muted-foreground">
                                ID: <span className="font-mono">{relatedProfile.id}</span>
                              </div>
                              <div className="flex space-x-2">
                                <Button variant="outline" size="sm" asChild>
                                  <Link href={`/${locale}/user-management/users/${(relatedProfile as any).userUID || relatedProfile.id}`}>
                                    <ExternalLink className="h-3 w-3 mr-2" />
                                    {t('modules.userManagement.reports.reportDetails.viewUserProfile') || 'View User Profile'}
                                  </Link>
                                </Button>
                              </div>
                            </div>
                          </div>
                        )}

                        {!relatedPost && !relatedComment && !relatedProfile && (report.relatedContent?.contentId || report.targetId) && (
                          <div className="text-center py-4">
                            <AlertCircle className="h-8 w-8 text-muted-foreground mx-auto mb-2" />
                            <p className="text-sm text-muted-foreground">
                              {t('modules.userManagement.reports.reportDetails.relatedItemNotFound') || 'The reported item could not be found or may have been deleted.'}
                            </p>
                            <p className="text-xs text-muted-foreground mt-1">
                              {report.relatedContent ? (
                                <>Content ID: {report.relatedContent.contentId} ({report.relatedContent.type})</>
                              ) : (
                                <>Target ID: {report.targetId} ({report.targetType})</>
                              )}
                            </p>
                          </div>
                        )}
                      </CardContent>
                    </Card>
                  )}

                  {/* Conversation */}
                  <ConversationView 
                    reportId={reportId}
                    reportStatus={report.status}
                    onStatusChange={() => {
                      // Don't reset selectedStatus here to preserve user selection
                      console.log('Status changed via conversation');
                    }}
                  />

                  {/* Status Update */}
                  {(report.status !== 'finalized') && (
                    <Card>
                      <CardHeader>
                        <CardTitle>
                          {t('modules.userManagement.reports.reportDetails.updateStatus') || 'Update Status'}
                        </CardTitle>
                      </CardHeader>
                      <CardContent className="space-y-4">
                        <div>
                          <Label htmlFor="status">
                            {t('modules.userManagement.reports.reportDetails.selectNewStatus') || 'Select new status'}
                          </Label>
                          <div className="mt-2 space-y-2">
                            <div className="text-sm text-muted-foreground">
                              {t('modules.userManagement.reports.reportDetails.currentStatus') || 'Current status'}: <span className="font-medium">{report.status}</span>
                            </div>
                            <Select 
                              value={selectedStatus} 
                              onValueChange={(value) => {
                                console.log('Status selection changed to:', value);
                                setSelectedStatus(value);
                              }}
                            >
                              <SelectTrigger>
                                <SelectValue placeholder={t('modules.userManagement.reports.reportDetails.selectNewStatusPlaceholder') || 'Select new status'} />
                              </SelectTrigger>
                              <SelectContent>
                                {getValidStatusTransitions(report.status).map((status) => (
                                  <SelectItem key={status} value={status}>
                                    {t(`modules.userManagement.reports.status${status.charAt(0).toUpperCase() + status.slice(1)}`) || status}
                                  </SelectItem>
                                ))}
                              </SelectContent>
                            </Select>
                          </div>
                        </div>

                        <Button
                          onClick={handleStatusUpdate}
                          disabled={isUpdating || !selectedStatus || selectedStatus === report.status}
                          className="w-full"
                        >
                          <MessageSquare className="h-4 w-4 mr-2" />
                          {isUpdating 
                            ? t('modules.userManagement.reports.reportDetails.updating') || 'Updating...'
                            : selectedStatus === report.status
                            ? t('modules.userManagement.reports.reportDetails.selectDifferentStatus') || 'Select a different status to update'
                            : t('modules.userManagement.reports.reportDetails.updateStatusAndNotify') || 'Update Status & Notify User'
                          }
                        </Button>
                      </CardContent>
                    </Card>
                  )}
                </div>

                {/* Sidebar */}
                <div className="space-y-6">
                  {/* User Information */}
                  <Card>
                    <CardHeader>
                      <CardTitle className="flex items-center gap-2">
                        <User className="h-5 w-5" />
                        {t('modules.userManagement.reports.reportDetails.userInformation') || 'User Information'}
                      </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      {user ? (
                        <>
                          <div className="flex items-center gap-3">
                            <Avatar className="h-10 w-10">
                              <AvatarImage src={user.photoURL} />
                              <AvatarFallback>
                                <User className="h-4 w-4" />
                              </AvatarFallback>
                            </Avatar>
                            <div>
                              <p className="font-medium">
                                {user.displayName || t('modules.userManagement.notSpecified') || 'Not specified'}
                              </p>
                              <p className="text-sm text-muted-foreground">
                                {user.email}
                              </p>
                            </div>
                          </div>

                          <Separator />

                          <div className="space-y-3">
                            <div className="flex items-center justify-between">
                              <span className="text-sm text-muted-foreground">
                                {t('modules.userManagement.reports.reportDetails.memberSince') || 'Member Since'}
                              </span>
                              <span className="text-sm">{formatDate(user.createdAt)}</span>
                            </div>

                            <div className="flex items-center justify-between">
                              <span className="text-sm text-muted-foreground">
                                {t('modules.userManagement.reports.reportDetails.lastLogin') || 'Last Login'}
                              </span>
                              <span className="text-sm">{formatDate(user.lastLoginAt)}</span>
                            </div>

                            <div className="flex items-center justify-between">
                              <span className="text-sm text-muted-foreground flex items-center gap-1">
                                <Languages className="h-3 w-3" />
                                {t('modules.userManagement.locale') || 'Language'}
                              </span>
                              <span className="text-sm">
                                {user.locale === 'arabic' ? 'العربية' : 'English'}
                              </span>
                            </div>

                            <div className="flex items-center justify-between">
                              <span className="text-sm text-muted-foreground flex items-center gap-1">
                                <MessageSquare className="h-3 w-3" />
                                {t('modules.userManagement.reports.reportDetails.messagesCount') || 'Messages'}
                              </span>
                              <span className="text-sm">{report.messagesCount}</span>
                            </div>
                          </div>

                          <Separator />

                          <Button variant="outline" size="sm" asChild className="w-full">
                            <Link href={`/${locale}/user-management/users/${report.uid}`}>
                              <ExternalLink className="h-4 w-4 mr-2" />
                              {t('modules.userManagement.reports.reportDetails.viewUserProfile') || 'View User Profile'}
                            </Link>
                          </Button>
                          <Button variant="default" size="sm" className="w-full" onClick={() => setMigrationDialogOpen(true)}>
                            {t('modules.userManagement.reports.reportDetails.quickMigrationCheck') || 'Quick Migration Check'}
                          </Button>
                        </>
                      ) : (
                        <div className="text-center py-4">
                          <p className="text-muted-foreground">
                            {t('modules.userManagement.reports.reportDetails.userDataNotAvailable') || 'User data not available'}
                          </p>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                </div>
              </div>
            ) : (
              <div className="text-center py-8">
                <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
                <h3 className="text-lg font-semibold mb-2">
                  {t('modules.userManagement.reports.errors.reportNotFound') || 'Report Not Found'}
                </h3>
                <p className="text-muted-foreground">
                  {t('modules.userManagement.reports.reportDetails.requestedReportNotFound') || 'The requested report could not be found.'}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      {user && (
        <Dialog open={migrationDialogOpen} onOpenChange={setMigrationDialogOpen}>
          <DialogContent className="max-w-3xl">
            <DialogHeader>
              <DialogTitle>
                {t('modules.userManagement.reports.reportDetails.quickMigrationCheck') || 'Quick Migration Check'}
              </DialogTitle>
            </DialogHeader>
            <MigrationManagementCard userId={user.uid} user={user} />
          </DialogContent>
        </Dialog>
      )}
    </>
  );
} 
