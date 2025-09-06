'use client';

import { useState, useMemo, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  AlertTriangle,
  Plus,
  Eye,
  FileText,
  User,
  Users,
  Clock,
  Loader2,
  ExternalLink,
  ChevronDown,
  ChevronUp,
  AlertCircle,
  CheckCircle,
  XCircle,
} from 'lucide-react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useAuth } from '@/auth/AuthProvider';
import { useCollection, useDocument } from 'react-firebase-hooks/firestore';
import { collection, addDoc, query, where, orderBy, serverTimestamp, Timestamp, doc, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { toast } from 'sonner';

interface RelatedContent {
  type: 'user' | 'report' | 'post' | 'comment' | 'message' | 'group' | 'other';
  id: string;
  title?: string;
  metadata?: {
    [key: string]: any;
  };
}

interface Warning {
  id?: string;
  userId: string;
  type: 'content_violation' | 'inappropriate_behavior' | 'spam' | 'harassment' | 'other';
  reason: string;
  description?: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  issuedBy: string;
  issuedAt: Timestamp | Date;
  isActive: boolean;
  relatedContent?: RelatedContent;
  reportId?: string; // Link to a user report if applicable
  deviceIds?: string[]; // Device tracking
}

interface Ban {
  id?: string;
  userId: string;
  type: string;
  scope: string;
  reason: string;
  description?: string;
  severity: string;
  issuedBy: string;
  issuedAt: Timestamp | Date;
  expiresAt?: Timestamp | Date | null;
  isActive: boolean;
  deviceIds?: string[];
}

interface WarningManagementCardProps {
  userId: string;
  userDisplayName?: string;
  userDevices?: string[];
}

// Utility functions
const convertTimestamp = (timestamp: Timestamp | Date): Date => {
  if (timestamp instanceof Timestamp) {
    return timestamp.toDate();
  }
  return timestamp;
};

// Related Content Viewer Component
interface RelatedContentViewerProps {
  relatedContent: RelatedContent;
}

function RelatedContentViewer({ relatedContent }: RelatedContentViewerProps) {
  const { t, locale } = useTranslation();
  const [isExpanded, setIsExpanded] = useState(false);
  
  // Fetch report data if type is report
  const [reportDoc, reportLoading, reportError] = useDocument(
    relatedContent.type === 'report' ? doc(db, 'usersReports', relatedContent.id) : null
  );

  // Fetch report types for dynamic display (same pattern as report details page)
  const [reportTypesSnapshot] = useCollection(
    relatedContent.type === 'report' ? query(
      collection(db, 'reportTypes'),
      orderBy('updatedAt', 'desc')
    ) : null
  );

  // Convert report types to a lookup map (same as report details page)
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

  // Function to get report type name based on locale (same as report details page)
  const getReportTypeName = (reportTypeId: string) => {
    const reportType = reportTypesMap.get(reportTypeId);
    if (!reportType) {
      return t('modules.userManagement.reports.reportDetails.unknownType') || 'Unknown Type';
    }
    return locale === 'ar' ? reportType.nameAr : reportType.nameEn;
  };

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

  const formatDate = (timestamp: Timestamp | Date | undefined) => {
    if (!timestamp) return t('common.unknown') || 'Unknown';
    
    const dateObj = convertTimestamp(timestamp);
    return new Intl.DateTimeFormat(locale === 'ar' ? 'ar-SA' : 'en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      calendar: 'gregory',
    }).format(dateObj);
  };

  const renderReportDetails = () => {
    if (reportLoading) {
      return (
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Loader2 className="h-4 w-4 animate-spin" />
          {t('common.loading')}...
        </div>
      );
    }

    if (reportError) {
      console.error('Error loading report:', relatedContent.id, reportError);
      return (
        <div className="text-sm text-red-600 space-y-1">
          <p>{t('modules.userManagement.warnings.reportNotFound') || 'Report not found'}</p>
          <details className="text-xs">
            <summary className="cursor-pointer">{t('common.technicalDetails') || 'Technical Details'}</summary>
            <div className="mt-1 p-2 bg-red-50 rounded text-xs">
              <p><strong>{t('modules.userManagement.reports.reportDetails.reportId') || 'Report ID'}:</strong> {relatedContent.id}</p>
              <p><strong>{t('common.error') || 'Error'}:</strong> {reportError.message}</p>
              <p><strong>{t('common.code') || 'Code'}:</strong> {reportError.code}</p>
            </div>
          </details>
        </div>
      );
    }

    if (!reportDoc?.exists()) {
      return (
        <div className="text-sm text-orange-600 space-y-1">
          <p>{t('modules.userManagement.warnings.reportDeleted') || 'Report has been deleted'}</p>
          <p className="text-xs text-muted-foreground">
            {t('modules.userManagement.warnings.reportDeletedDescription') || 'The report may have been removed from the system'}: {relatedContent.id}
          </p>
        </div>
      );
    }

    const reportData = reportDoc.data();
    
    // Parse report data using the same model as report details page
    const report = {
      id: reportDoc.id,
      uid: reportData?.uid || '',
      time: reportData?.time || Timestamp.now(),
      reportTypeId: reportData?.reportTypeId || reportData?.reportType || 'dataError',
      status: reportData?.status || 'pending',
      initialMessage: reportData?.initialMessage || reportData?.userJustification || '',
      lastUpdated: reportData?.lastUpdated || reportData?.time || Timestamp.now(),
      messagesCount: reportData?.messagesCount || 1,
    };

    return (
      <div className="space-y-3 p-3 bg-muted rounded-lg">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <Label className="text-xs font-medium">{t('modules.userManagement.reports.reportDetails.reportType') || 'Report Type'}</Label>
            <Badge variant="outline" className="text-xs">
              {getReportTypeName(report.reportTypeId)}
            </Badge>
          </div>
          <div>
            <Label className="text-xs font-medium">{t('modules.userManagement.reports.reportDetails.status') || 'Status'}</Label>
            <div className="mt-1">
              {getStatusBadge(report.status)}
            </div>
          </div>
        </div>
        
        <div>
          <Label className="text-xs font-medium">{t('modules.userManagement.reports.reportDetails.submittedDate') || 'Submitted'}</Label>
          <p className="text-sm">{formatDate(report.time)}</p>
        </div>

        <div>
          <Label className="text-xs font-medium">{t('modules.userManagement.reports.reportDetails.lastUpdated') || 'Last Updated'}</Label>
          <p className="text-sm">{formatDate(report.lastUpdated)}</p>
        </div>

        {report.initialMessage && (
          <div>
            <Label className="text-xs font-medium">{t('modules.userManagement.reports.reportDetails.initialMessage') || 'Initial Message'}</Label>
            <p className="text-sm text-muted-foreground bg-background p-2 rounded border">
              {report.initialMessage}
            </p>
          </div>
        )}

        <Button
          size="sm"
          variant="outline"
          className="w-full"
          onClick={() => window.open(`/${locale}/user-management/reports/${relatedContent.id}`, '_blank')}
        >
          <ExternalLink className="h-4 w-4 mr-2" />
          {t('modules.userManagement.reports.viewFullReport') || 'View Full Report'}
        </Button>
      </div>
    );
  };

  const renderContentDetails = () => {
    switch (relatedContent.type) {
      case 'report':
        return renderReportDetails();
      
      case 'user':
        return (
          <div className="p-3 bg-muted rounded-lg">
            <p className="text-sm text-muted-foreground">
              User reference: {relatedContent.id}
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              User content viewing will be implemented when user profiles are available
            </p>
          </div>
        );
      
      case 'post':
      case 'comment':
      case 'message':
      case 'group':
        return (
          <div className="p-3 bg-muted rounded-lg">
            <p className="text-sm text-muted-foreground">
              {relatedContent.type.charAt(0).toUpperCase() + relatedContent.type.slice(1)} reference: {relatedContent.id}
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              {relatedContent.type.charAt(0).toUpperCase() + relatedContent.type.slice(1)} content viewing will be implemented when community features are available
            </p>
          </div>
        );
      
      default:
        return (
          <div className="p-3 bg-muted rounded-lg">
            <p className="text-sm text-muted-foreground">
              {relatedContent.title || `${relatedContent.type}: ${relatedContent.id}`}
            </p>
          </div>
        );
    }
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <Label>{t('modules.userManagement.warnings.relatedContent')}</Label>
        <Button
          size="sm"
          variant="ghost"
          onClick={() => setIsExpanded(!isExpanded)}
          className="h-6 px-2"
        >
          {isExpanded ? (
            <>
              <ChevronUp className="h-3 w-3 mr-1" />
              {t('modules.userManagement.warnings.hideDetails')}
            </>
          ) : (
            <>
              <ChevronDown className="h-3 w-3 mr-1" />
              {t('modules.userManagement.warnings.viewDetails')}
            </>
          )}
        </Button>
      </div>
      
      <p className="text-sm">
        {relatedContent.title || `${t(`modules.userManagement.warnings.relatedContentType.${relatedContent.type}`)}: ${relatedContent.id}`}
      </p>
      
      {isExpanded && renderContentDetails()}
    </div>
  );
}

export default function WarningManagementCard({ userId, userDisplayName, userDevices = [] }: WarningManagementCardProps) {
  const { t, locale } = useTranslation();
  const { user: currentUser } = useAuth();
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [selectedWarning, setSelectedWarning] = useState<Warning | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [deviceHistory, setDeviceHistory] = useState<{
    bans: Ban[];
    warnings: Warning[];
    loading: boolean;
  }>({ bans: [], warnings: [], loading: false });

  // Helper function to get admin display name from UID
  const getAdminDisplayName = (adminUid: string) => {
    if (adminUid === currentUser?.uid) {
      return currentUser?.displayName || currentUser?.email || 'Current Admin';
    }
    return `Admin (${adminUid.slice(0, 8)}...)`;
  };
  
  // Firestore hooks (simplified query to avoid index requirements)
  const warningsCollection = collection(db, 'warnings');
  const warningsQuery = query(
    warningsCollection, 
    where('userId', '==', userId)
  );
  const [warningsSnapshot, warningsLoading, warningsError] = useCollection(warningsQuery);

  // Log errors for debugging
  if (warningsError) {
    console.error('Warnings query error:', warningsError);
    console.error('Error code:', warningsError.code);
    console.error('Error message:', warningsError.message);
  }

  // Log successful data fetching
  if (warningsSnapshot && !warningsLoading) {
    console.log('Warnings loaded successfully:', warningsSnapshot.docs.length, 'documents');
    console.log('Warning documents:', warningsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
  }

  // Convert Firestore data to Warning array with client-side sorting
  const warnings: Warning[] = warningsSnapshot?.docs
    .map(doc => ({
      id: doc.id,
      ...doc.data()
    } as Warning))
    .sort((a, b) => {
      // Handle sorting by issuedAt timestamp
      const aTime = a.issuedAt instanceof Date ? a.issuedAt.getTime() : 
                   (a.issuedAt as any)?.toDate?.()?.getTime?.() || 0;
      const bTime = b.issuedAt instanceof Date ? b.issuedAt.getTime() : 
                   (b.issuedAt as any)?.toDate?.()?.getTime?.() || 0;
      return bTime - aTime; // desc order
    }) || [];

  const [formData, setFormData] = useState({
    type: 'other' as Warning['type'],
    reason: '',
    description: '',
    severity: 'medium' as Warning['severity'],
    relatedContentType: 'other' as RelatedContent['type'],
    relatedContentId: '',
    relatedContentTitle: '',
    reportId: '',
  });

  const warningTypes = [
    { value: 'content_violation', labelKey: 'contentViolation', category: 'general' },
    { value: 'inappropriate_behavior', labelKey: 'inappropriateBehavior', category: 'general' },
    { value: 'spam', labelKey: 'spam', category: 'general' },
    { value: 'harassment', labelKey: 'harassment', category: 'general' },
    { value: 'other', labelKey: 'other', category: 'general' },
    // Groups-specific warning types
    { value: 'group_harassment', labelKey: 'groupHarassment', category: 'groups' },
    { value: 'group_spam', labelKey: 'groupSpam', category: 'groups' },
    { value: 'group_inappropriate_content', labelKey: 'groupInappropriateContent', category: 'groups' },
    { value: 'group_disruption', labelKey: 'groupDisruption', category: 'groups' },
  ];

  const groupsWarningTypes = warningTypes.filter(type => type.category === 'groups');
  const generalWarningTypes = warningTypes.filter(type => type.category === 'general');

  const severityLevels = [
    { value: 'low', labelKey: 'low', color: 'text-blue-600' },
    { value: 'medium', labelKey: 'medium', color: 'text-yellow-600' },
    { value: 'high', labelKey: 'high', color: 'text-orange-600' },
    { value: 'critical', labelKey: 'critical', color: 'text-red-600' },
  ];

  // Check device history for existing bans/warnings
  const checkDeviceHistory = async (deviceIds: string[]) => {
    if (!deviceIds || deviceIds.length === 0) {
      setDeviceHistory({ bans: [], warnings: [], loading: false });
      return;
    }

    setDeviceHistory(prev => ({ ...prev, loading: true }));

    try {
      // Query bans with matching device IDs
      const bansQuery = query(
        collection(db, 'bans'),
        where('deviceIds', 'array-contains-any', deviceIds.slice(0, 10)) // Firestore limit
      );
      const bansSnapshot = await getDocs(bansQuery);
      const allBans = bansSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Ban));

      // Query warnings with matching device IDs
      const warningsQuery = query(
        collection(db, 'warnings'),
        where('deviceIds', 'array-contains-any', deviceIds.slice(0, 10))
      );
      const warningsSnapshot = await getDocs(warningsQuery);
      const allWarnings = warningsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Warning));

      // Separate current user's violations from other users' violations
      const currentUserBans = allBans.filter(ban => ban.userId === userId);
      const otherUsersBans = allBans.filter(ban => ban.userId !== userId);
      const currentUserWarnings = allWarnings.filter(warning => warning.userId === userId);
      const otherUsersWarnings = allWarnings.filter(warning => warning.userId !== userId);

      // Combine them with current user's violations first
      const combinedBans = [...currentUserBans, ...otherUsersBans];
      const combinedWarnings = [...currentUserWarnings, ...otherUsersWarnings];

      setDeviceHistory({
        bans: combinedBans,
        warnings: combinedWarnings,
        loading: false
      });
    } catch (error) {
      console.error('Error checking device history:', error);
      setDeviceHistory({ bans: [], warnings: [], loading: false });
    }
  };

  // Check device history when dialog opens
  useEffect(() => {
    if (isCreateDialogOpen && userDevices.length > 0) {
      checkDeviceHistory(userDevices);
    }
  }, [isCreateDialogOpen, userDevices]);

  // Filter warnings - warnings don't expire, they're just active or inactive
  const activeWarnings = warnings.filter(w => w.isActive);
  const inactiveWarnings = warnings.filter(w => !w.isActive);

  const resetForm = () => {
    setFormData({
      type: 'other',
      reason: '',
      description: '',
      severity: 'medium',
      relatedContentType: 'other',
      relatedContentId: '',
      relatedContentTitle: '',
      reportId: '',
    });
  };

  const handleCreateWarning = async () => {
    if (!formData.reason.trim()) {
      toast.error(t('modules.userManagement.warnings.errors.reasonRequired'));
      return;
    }

    setIsSubmitting(true);
    try {
      const warningData = {
        userId,
        type: formData.type,
        reason: formData.reason.trim(),
        description: formData.description.trim() || null,
        severity: formData.severity,
        issuedBy: currentUser?.uid || 'unknown-admin',
        issuedAt: serverTimestamp(),
        isActive: true,
        deviceIds: userDevices.length > 0 ? userDevices : null, // Track device IDs
        relatedContent: formData.relatedContentId.trim() ? {
          type: formData.relatedContentType,
          id: formData.relatedContentId.trim(),
          ...(formData.relatedContentTitle.trim() && { title: formData.relatedContentTitle.trim() }),
        } : null,
        reportId: formData.reportId.trim() || null,
      };

      await addDoc(warningsCollection, warningData);
      toast.success(t('modules.userManagement.warnings.createSuccess'));
      setIsCreateDialogOpen(false);
      resetForm();
    } catch (error) {
      console.error('Error creating warning:', error);
      toast.error(t('modules.userManagement.warnings.createError'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const getSeverityBadge = (severity: string) => {
    const config = severityLevels.find(s => s.value === severity);
    return (
      <Badge variant="outline" className={config?.color}>
        <AlertTriangle className="h-3 w-3 mr-1" />
        {t(`modules.userManagement.warnings.severity.${severity}`) || severity}
      </Badge>
    );
  };

  const getTypeBadge = (type: string) => {
    return (
      <Badge variant="secondary">
        {t(`modules.userManagement.warnings.type.${type}`) || type}
      </Badge>
    );
  };

  const formatDate = (date: Timestamp | Date) => {
    const dateObj = convertTimestamp(date);
    return new Intl.DateTimeFormat(locale === 'ar' ? 'ar-SA' : 'en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      calendar: 'gregory',
    }).format(dateObj);
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-orange-600" />
            <CardTitle>{t('modules.userManagement.warnings.title')}</CardTitle>
          </div>
          <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
            <DialogTrigger asChild>
              <Button size="sm" onClick={resetForm} disabled={warningsLoading}>
                {warningsLoading ? (
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Plus className="h-4 w-4 mr-2" />
                )}
                {t('modules.userManagement.warnings.issueWarning')}
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-2xl">
              <DialogHeader>
                <DialogTitle>{t('modules.userManagement.warnings.issueWarning')}</DialogTitle>
                <DialogDescription>
                  {t('modules.userManagement.warnings.issueWarningDescription', { user: userDisplayName || userId })}
                </DialogDescription>
              </DialogHeader>
              <div className="grid gap-4 py-4">
                {/* Device History Warning */}
                {(deviceHistory.bans.length > 0 || deviceHistory.warnings.length > 0) && (
                  <div className="bg-amber-50 border border-amber-200 p-4 rounded-lg space-y-3">
                    <div className="flex items-center gap-2">
                      <AlertTriangle className="h-5 w-5 text-amber-600" />
                      <h4 className="font-semibold text-amber-800">{t('modules.userManagement.warnings.deviceHistory.title')}</h4>
                    </div>
                    <p className="text-sm text-amber-700">
                      {t('modules.userManagement.warnings.deviceHistory.description')}
                    </p>
                    
                    {deviceHistory.bans.length > 0 && (
                      <div className="space-y-2">
                        <p className="text-sm font-medium text-amber-800">
                          {t('modules.userManagement.warnings.deviceHistory.previousBans')} ({deviceHistory.bans.length}):
                        </p>
                        <div className="space-y-1 max-h-24 overflow-y-auto">
                          {deviceHistory.bans.slice(0, 3).map((ban) => (
                            <div key={ban.id} className={`text-xs p-2 rounded border ${ban.userId === userId ? 'bg-blue-50 border-blue-200' : 'bg-white border-gray-200'}`}>
                              <div className="flex justify-between">
                                <span className="font-medium">
                                  {ban.userId === userId ? (
                                    <span className="text-blue-700">👤 {t('modules.userManagement.warnings.deviceHistory.thisUser')}</span>
                                  ) : (
                                    <span>{t('modules.userManagement.warnings.deviceHistory.userIdLabel')} {ban.userId.slice(0, 8)}...</span>
                                  )}
                                </span>
                                <span className={ban.isActive ? 'text-red-600' : 'text-gray-500'}>
                                  {ban.isActive ? t('common.active') : t('common.inactive')}
                                </span>
                              </div>
                              <div className="text-gray-600 mt-1">{ban.reason}</div>
                              <div className="text-gray-500">
                                {ban.issuedAt && formatDate(ban.issuedAt)}
                              </div>
                            </div>
                          ))}
                          {deviceHistory.bans.length > 3 && (
                            <div className="text-xs text-amber-600 font-medium">
                              +{deviceHistory.bans.length - 3} {t('modules.userManagement.warnings.deviceHistory.moreBans')}
                            </div>
                          )}
                        </div>
                      </div>
                    )}

                    {deviceHistory.warnings.length > 0 && (
                      <div className="space-y-2">
                        <p className="text-sm font-medium text-amber-800">
                          {t('modules.userManagement.warnings.deviceHistory.previousWarnings')} ({deviceHistory.warnings.length}):
                        </p>
                        <div className="space-y-1 max-h-24 overflow-y-auto">
                          {deviceHistory.warnings.slice(0, 3).map((warning) => (
                            <div key={warning.id} className={`text-xs p-2 rounded border ${warning.userId === userId ? 'bg-blue-50 border-blue-200' : 'bg-white border-gray-200'}`}>
                              <div className="flex justify-between">
                                <span className="font-medium">
                                  {warning.userId === userId ? (
                                    <span className="text-blue-700">👤 {t('modules.userManagement.warnings.deviceHistory.thisUser')}</span>
                                  ) : (
                                    <span>{t('modules.userManagement.warnings.deviceHistory.userIdLabel')} {warning.userId.slice(0, 8)}...</span>
                                  )}
                                </span>
                                <span className={warning.isActive ? 'text-orange-600' : 'text-gray-500'}>
                                  {warning.isActive ? t('common.active') : t('common.inactive')}
                                </span>
                              </div>
                              <div className="text-gray-600 mt-1">{warning.reason}</div>
                              <div className="text-gray-500">
                                {warning.issuedAt && formatDate(warning.issuedAt)}
                              </div>
                            </div>
                          ))}
                          {deviceHistory.warnings.length > 3 && (
                            <div className="text-xs text-amber-600 font-medium">
                              +{deviceHistory.warnings.length - 3} {t('modules.userManagement.warnings.deviceHistory.moreWarnings')}
                            </div>
                          )}
                        </div>
                      </div>
                    )}

                    <div className="text-xs text-amber-700 bg-amber-100 p-2 rounded">
                      <strong>{t('modules.userManagement.warnings.deviceHistory.recommendation')}</strong> {t('modules.userManagement.warnings.deviceHistory.recommendEscalation')}
                    </div>
                  </div>
                )}

                {/* Loading Device History */}
                {deviceHistory.loading && (
                  <div className="bg-blue-50 border border-blue-200 p-4 rounded-lg">
                    <div className="flex items-center gap-2">
                      <Loader2 className="h-4 w-4 animate-spin text-blue-600" />
                      <span className="text-sm text-blue-700">{t('modules.userManagement.warnings.deviceHistory.checkingHistory')}</span>
                    </div>
                  </div>
                )}
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="type">{t('modules.userManagement.warnings.type.label')}</Label>
                    <Select value={formData.type} onValueChange={(value) => setFormData({ ...formData, type: value as Warning['type'] })}>
                      <SelectTrigger>
                        <SelectValue placeholder={t('modules.userManagement.warnings.type.selectType')} />
                      </SelectTrigger>
                      <SelectContent>
                        {/* Groups Warning Types */}
                        <div className="px-2 py-1.5 text-xs font-semibold text-orange-700 bg-orange-50">
                          {t('modules.userManagement.groups-ban.groups-warnings') || 'Groups Warnings'}
                        </div>
                        {groupsWarningTypes.map((type) => (
                          <SelectItem key={type.value} value={type.value}>
                            <div className="flex items-center gap-2">
                              <Users className="h-3 w-3 text-orange-600" />
                              {t(`modules.userManagement.warnings.type.${type.labelKey}`) || type.value}
                            </div>
                          </SelectItem>
                        ))}
                        
                        {/* General Warning Types */}
                        <div className="px-2 py-1.5 text-xs font-semibold text-blue-700 bg-blue-50 mt-1">
                          {t('modules.userManagement.warnings.generalWarnings') || 'General Warnings'}
                        </div>
                        {generalWarningTypes.map((type) => (
                          <SelectItem key={type.value} value={type.value}>
                            {t(`modules.userManagement.warnings.type.${type.labelKey}`)}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="severity">{t('modules.userManagement.warnings.severity.label')}</Label>
                    <Select value={formData.severity} onValueChange={(value) => setFormData({ ...formData, severity: value as Warning['severity'] })}>
                      <SelectTrigger>
                        <SelectValue placeholder={t('modules.userManagement.warnings.severity.selectSeverity')} />
                      </SelectTrigger>
                      <SelectContent>
                        {severityLevels.map((level) => (
                          <SelectItem key={level.value} value={level.value}>
                            {t(`modules.userManagement.warnings.severity.${level.labelKey}`)}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="reason">{t('modules.userManagement.warnings.reason')}</Label>
                  <Input
                    id="reason"
                    value={formData.reason}
                    onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                    placeholder={t('modules.userManagement.warnings.reasonPlaceholder')}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="description">{t('modules.userManagement.warnings.description')}</Label>
                  <Textarea
                    id="description"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    placeholder={t('modules.userManagement.warnings.descriptionPlaceholder')}
                  />
                </div>
                <div className="grid grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="relatedContentType">{t('modules.userManagement.warnings.relatedContentType.label')}</Label>
                    <Select 
                      value={formData.relatedContentType} 
                      onValueChange={(value) => setFormData({ ...formData, relatedContentType: value as RelatedContent['type'] })}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Select type" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="user">{t('modules.userManagement.warnings.relatedContentType.user')}</SelectItem>
                        <SelectItem value="report">{t('modules.userManagement.warnings.relatedContentType.report')}</SelectItem>
                        <SelectItem value="post">{t('modules.userManagement.warnings.relatedContentType.post')}</SelectItem>
                        <SelectItem value="comment">{t('modules.userManagement.warnings.relatedContentType.comment')}</SelectItem>
                        <SelectItem value="message">{t('modules.userManagement.warnings.relatedContentType.message')}</SelectItem>
                        <SelectItem value="group">{t('modules.userManagement.warnings.relatedContentType.group')}</SelectItem>
                        <SelectItem value="other">{t('modules.userManagement.warnings.relatedContentType.other')}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="relatedContentId">{t('modules.userManagement.warnings.relatedContentId')}</Label>
                    <Input
                      id="relatedContentId"
                      value={formData.relatedContentId}
                      onChange={(e) => setFormData({ ...formData, relatedContentId: e.target.value })}
                      placeholder="ID or reference"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="relatedContentTitle">{t('modules.userManagement.warnings.relatedContentTitle')}</Label>
                    <Input
                      id="relatedContentTitle"
                      value={formData.relatedContentTitle}
                      onChange={(e) => setFormData({ ...formData, relatedContentTitle: e.target.value })}
                      placeholder="Description (optional)"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="reportId">{t('modules.userManagement.warnings.reportId')}</Label>
                  <Input
                    id="reportId"
                    value={formData.reportId}
                    onChange={(e) => setFormData({ ...formData, reportId: e.target.value })}
                    placeholder={t('modules.userManagement.warnings.reportIdPlaceholder')}
                  />
                  <p className="text-xs text-muted-foreground">
                    {t('modules.userManagement.warnings.reportIdHelp')}
                  </p>
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)} disabled={isSubmitting}>
                  {t('common.cancel')}
                </Button>
                <Button onClick={handleCreateWarning} disabled={isSubmitting}>
                  {isSubmitting ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      {t('common.creating')}
                    </>
                  ) : (
                    t('modules.userManagement.warnings.issueWarning')
                  )}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
        <CardDescription>
          {t('modules.userManagement.warnings.description')}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Loading and Error States */}
        {warningsError && (
          <div className="text-center py-8">
            <div className="text-red-600 mb-4">
              <p className="text-lg font-medium">{t('common.errors.loadingFailed')}</p>
              <p className="text-sm">{t('modules.userManagement.warnings.errors.loadingFailed')}</p>
              <details className="mt-2 text-xs">
                <summary className="cursor-pointer">Technical Details</summary>
                <div className="mt-2 p-2 bg-red-50 rounded">
                  <p><strong>Error Code:</strong> {warningsError.code}</p>
                  <p><strong>Error Message:</strong> {warningsError.message}</p>
                </div>
              </details>
            </div>
            <Button onClick={() => window.location.reload()}>
              {t('common.retry')}
            </Button>
          </div>
        )}

        {warningsLoading && (
          <div className="text-center py-8">
            <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4" />
            <p className="text-muted-foreground">{t('common.loading')}</p>
          </div>
        )}

        {!warningsError && !warningsLoading && (
          <>
            {/* Warning Statistics */}
            <div className="grid grid-cols-3 gap-4">
              <div className="text-center p-4 bg-muted rounded-lg">
                <p className="text-2xl font-bold text-orange-600">{activeWarnings.length}</p>
                <p className="text-sm text-muted-foreground">{t('modules.userManagement.warnings.activeWarnings')}</p>
              </div>
              <div className="text-center p-4 bg-muted rounded-lg">
                <p className="text-2xl font-bold">{warnings.length}</p>
                <p className="text-sm text-muted-foreground">{t('modules.userManagement.warnings.totalWarnings')}</p>
              </div>
              <div className="text-center p-4 bg-muted rounded-lg">
                <p className="text-2xl font-bold text-gray-600">{inactiveWarnings.length}</p>
                <p className="text-sm text-muted-foreground">{t('modules.userManagement.warnings.inactiveWarnings')}</p>
              </div>
            </div>
          </>
        )}

        {/* Active Warnings */}
        {!warningsError && !warningsLoading && activeWarnings.length > 0 && (
          <div className="space-y-4">
            <h4 className="text-lg font-semibold">{t('modules.userManagement.warnings.activeWarnings')}</h4>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t('modules.userManagement.warnings.type.label')}</TableHead>
                  <TableHead>{t('modules.userManagement.warnings.reason')}</TableHead>
                  <TableHead>{t('modules.userManagement.warnings.severity.label')}</TableHead>
                  <TableHead>{t('modules.userManagement.warnings.issued')}</TableHead>
                  <TableHead>{t('modules.userManagement.warnings.reportRef')}</TableHead>
                  <TableHead className="text-right">{t('common.actions')}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {activeWarnings.map((warning) => (
                  <TableRow key={warning.id}>
                    <TableCell>{getTypeBadge(warning.type)}</TableCell>
                    <TableCell>
                      <div className="space-y-1">
                        <p className="text-sm font-medium">{warning.reason}</p>
                        {warning.relatedContent && (
                          <p className="text-xs text-muted-foreground">
                            {warning.relatedContent.title || `${warning.relatedContent.type}: ${warning.relatedContent.id}`}
                          </p>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>{getSeverityBadge(warning.severity)}</TableCell>
                    <TableCell>
                      <div className="space-y-1">
                        <p className="text-sm">{formatDate(warning.issuedAt)}</p>
                        <p className="text-xs text-muted-foreground">{t('modules.userManagement.warnings.by')} {getAdminDisplayName(warning.issuedBy)}</p>
                      </div>
                    </TableCell>
                    <TableCell>
                      {warning.reportId ? (
                        <Badge variant="outline" className="text-blue-600">
                          <FileText className="h-3 w-3 mr-1" />
                          {warning.reportId}
                        </Badge>
                      ) : (
                        <span className="text-xs text-muted-foreground">—</span>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => setSelectedWarning(warning)}
                      >
                        <Eye className="h-4 w-4 mr-2" />
                        {t('modules.userManagement.warnings.viewDetails')}
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {/* No Warnings Message */}
        {!warningsError && !warningsLoading && warnings.length === 0 && (
          <div className="text-center py-8">
            <AlertTriangle className="h-12 w-12 text-muted-foreground mx-auto mb-4 opacity-50" />
            <p className="text-lg font-medium">{t('modules.userManagement.warnings.noWarnings')}</p>
            <p className="text-muted-foreground">{t('modules.userManagement.warnings.noWarningsDescription')}</p>
          </div>
        )}
      </CardContent>

      {/* Warning Details Dialog */}
      <Dialog open={!!selectedWarning} onOpenChange={() => setSelectedWarning(null)}>
        <DialogContent className="max-w-2xl">
          {selectedWarning && (
            <>
              <DialogHeader>
                <DialogTitle>{t('modules.userManagement.warnings.warningDetails')}</DialogTitle>
                <DialogDescription>
                  {t('modules.userManagement.warnings.warningId')}: {selectedWarning.id}
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label>{t('modules.userManagement.warnings.type.label')}</Label>
                    <div className="mt-1">{getTypeBadge(selectedWarning.type)}</div>
                  </div>
                  <div>
                    <Label>{t('modules.userManagement.warnings.severity.label')}</Label>
                    <div className="mt-1">{getSeverityBadge(selectedWarning.severity)}</div>
                  </div>
                </div>
                <div>
                  <Label>{t('modules.userManagement.warnings.reason')}</Label>
                  <p className="mt-1 text-sm">{selectedWarning.reason}</p>
                </div>
                {selectedWarning.description && (
                  <div>
                    <Label>{t('modules.userManagement.warnings.description')}</Label>
                    <p className="mt-1 text-sm text-muted-foreground">{selectedWarning.description}</p>
                  </div>
                )}
                {selectedWarning.relatedContent && (
                  <RelatedContentViewer relatedContent={selectedWarning.relatedContent} />
                )}
                {selectedWarning.reportId && (
                  <div>
                    <Label>{t('modules.userManagement.warnings.reportId')}</Label>
                    <div className="mt-1">
                      <Badge variant="outline" className="text-blue-600">
                        <FileText className="h-3 w-3 mr-1" />
                        {selectedWarning.reportId}
                      </Badge>
                    </div>
                  </div>
                )}
                <div>
                  <Label>{t('modules.userManagement.warnings.issued')}</Label>
                  <p className="mt-1 text-sm">{formatDate(selectedWarning.issuedAt)}</p>
                  <p className="text-xs text-muted-foreground">{t('modules.userManagement.warnings.by')} {getAdminDisplayName(selectedWarning.issuedBy)}</p>
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setSelectedWarning(null)}>
                  {t('common.close')}
                </Button>
              </DialogFooter>
            </>
          )}
        </DialogContent>
      </Dialog>
    </Card>
  );
} 