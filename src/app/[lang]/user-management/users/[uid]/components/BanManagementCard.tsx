'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Checkbox } from '@/components/ui/checkbox';
import { Calendar } from '@/components/ui/calendar';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Shield,
  Plus,
  Eye,
  MoreHorizontal,
  Trash2,
  Edit,
  Smartphone,
  User,
  CalendarIcon,
  AlertTriangle,
  Settings,
  MessageSquare,
  Users,
  FileText,
  Video,
  Loader2,
  ExternalLink,
  ChevronDown,
  ChevronUp,
  ChevronDownIcon,
} from 'lucide-react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useAuth } from '@/auth/AuthProvider';
import { useCollection, useDocument } from 'react-firebase-hooks/firestore';
import { collection, addDoc, query, where, orderBy, serverTimestamp, Timestamp, updateDoc, doc, getDocs } from 'firebase/firestore';
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
  type: string;
  severity: string;
  reason: string;
  description?: string;
  issuedBy: string;
  issuedAt: Timestamp | Date;
  isActive: boolean;
  relatedContent?: RelatedContent;
  deviceIds?: string[];
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

  const renderReportDetails = () => {
    if (reportLoading) {
      return (
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Loader2 className="h-4 w-4 animate-spin" />
          Loading report details...
        </div>
      );
    }

    if (reportError || !reportDoc?.exists()) {
      return (
        <div className="text-sm text-red-600">
          Report not found or error loading report details
        </div>
      );
    }

    const reportData = reportDoc.data();
    return (
      <div className="space-y-3 p-3 bg-muted rounded-lg">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <Label className="text-xs font-medium">Report Type</Label>
            <p className="text-sm">{reportData?.reportType || 'Unknown'}</p>
          </div>
          <div>
            <Label className="text-xs font-medium">Status</Label>
            <Badge variant="outline" className="text-xs">
              {reportData?.status || 'Unknown'}
            </Badge>
          </div>
        </div>
        
        <div>
          <Label className="text-xs font-medium">Submitted</Label>
          <p className="text-sm">{reportData?.submittedAt ? formatDate(reportData.submittedAt) : 'Unknown'}</p>
        </div>

        {reportData?.initialMessage && (
          <div>
            <Label className="text-xs font-medium">Initial Message</Label>
            <p className="text-sm text-muted-foreground bg-background p-2 rounded border">
              {reportData.initialMessage}
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
          View Full Report
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
        <Label>{t('modules.userManagement.bans.relatedContent')}</Label>
        <Button
          size="sm"
          variant="ghost"
          onClick={() => setIsExpanded(!isExpanded)}
          className="h-6 px-2"
        >
          {isExpanded ? (
            <>
              <ChevronUp className="h-3 w-3 mr-1" />
              Hide Details
            </>
          ) : (
            <>
              <ChevronDown className="h-3 w-3 mr-1" />
              View Details
            </>
          )}
        </Button>
      </div>
      
      <p className="text-sm">
        {relatedContent.title || `${t(`modules.userManagement.bans.relatedContentType.${relatedContent.type}`)}: ${relatedContent.id}`}
      </p>
      
      {isExpanded && renderContentDetails()}
    </div>
  );
}

interface Ban {
  id?: string;
  userId: string;
  type: 'user_ban' | 'device_ban' | 'feature_ban';
  scope: 'app_wide' | 'feature_specific';
  reason: string;
  description?: string;
  severity: 'temporary' | 'permanent';
  issuedBy: string;
  issuedAt: Timestamp | Date;
  expiresAt?: Timestamp | Date | null;
  isActive: boolean;
  // For feature-specific bans
  restrictedFeatures?: string[];
  // For device bans
  restrictedDevices?: string[];
  relatedContent?: RelatedContent;
  // Device tracking
  deviceIds?: string[];
}

interface AppFeature {
  id?: string;
  uniqueName: string;
  nameEn: string;
  nameAr: string;
  descriptionEn: string;
  descriptionAr: string;
  category: 'core' | 'social' | 'content' | 'communication' | 'settings';
  iconName: string;
  isActive: boolean;
  isBannable: boolean;
  createdAt: Timestamp | Date;
  updatedAt: Timestamp | Date;
}

interface BanManagementCardProps {
  userId: string;
  userDisplayName?: string;
  userDevices?: string[];
}

export default function BanManagementCard({ userId, userDisplayName, userDevices = [] }: BanManagementCardProps) {
  const { t, locale } = useTranslation();
  const { user: currentUser } = useAuth();
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [selectedBan, setSelectedBan] = useState<Ban | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isDatePickerOpen, setIsDatePickerOpen] = useState(false);
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
  
  // Firestore hooks for bans (simplified query to avoid index requirements)
  const bansCollection = collection(db, 'bans');
  const bansQuery = query(
    bansCollection, 
    where('userId', '==', userId)
  );
  const [bansSnapshot, bansLoading, bansError] = useCollection(bansQuery);

  // Firestore hooks for features (simplified query to avoid index requirements)
  const featuresCollection = collection(db, 'features');
  const featuresQuery = query(featuresCollection);
  const [featuresSnapshot, featuresLoading, featuresError] = useCollection(featuresQuery);

  // Log errors for debugging
  if (bansError) {
    console.error('Bans query error:', bansError);
    console.error('Error code:', bansError.code);
    console.error('Error message:', bansError.message);
  }
  if (featuresError) {
    console.error('Features query error:', featuresError);
    console.error('Error code:', featuresError.code);
    console.error('Error message:', featuresError.message);
  }

  // Log successful data fetching
  if (bansSnapshot && !bansLoading) {
    console.log('Bans loaded successfully:', bansSnapshot.docs.length, 'documents');
  }
  if (featuresSnapshot && !featuresLoading) {
    console.log('Features loaded successfully:', featuresSnapshot.docs.length, 'documents');
  }

  // Convert Firestore data to arrays with client-side filtering and sorting
  const bans: Ban[] = bansSnapshot?.docs
    .map(doc => ({
      id: doc.id,
      ...doc.data()
    } as Ban))
    .sort((a, b) => {
      // Handle sorting by issuedAt timestamp
      const aTime = a.issuedAt instanceof Date ? a.issuedAt.getTime() : 
                   (a.issuedAt as any)?.toDate?.()?.getTime?.() || 0;
      const bTime = b.issuedAt instanceof Date ? b.issuedAt.getTime() : 
                   (b.issuedAt as any)?.toDate?.()?.getTime?.() || 0;
      return bTime - aTime; // desc order
    }) || [];

  const appFeatures: AppFeature[] = featuresSnapshot?.docs
    .map(doc => ({
      id: doc.id,
      ...doc.data()
    } as AppFeature))
    .filter(feature => feature.isActive && feature.isBannable)
    .sort((a, b) => {
      if (a.category !== b.category) {
        return a.category.localeCompare(b.category);
      }
      return a.nameEn.localeCompare(b.nameEn);
    }) || [];

  const [formData, setFormData] = useState({
    type: 'user_ban' as Ban['type'],
    scope: 'app_wide' as Ban['scope'],
    reason: '',
    description: '',
    severity: 'temporary' as Ban['severity'],
    expiresDate: undefined as Date | undefined,
    expiresTime: '',
    restrictedFeatures: [] as string[],
    restrictedDevices: [] as string[],
    relatedContentType: 'other' as RelatedContent['type'],
    relatedContentId: '',
    relatedContentTitle: '',
  });

  const banTypes = [
    { value: 'feature_ban', labelKey: 'featureBan', icon: Settings },
    { value: 'user_ban', labelKey: 'userBan', icon: User },
    { value: 'device_ban', labelKey: 'deviceBan', icon: Smartphone },
  ];

  const banScopes = [
    { value: 'feature_specific', labelKey: 'featureSpecific' },
    { value: 'app_wide', labelKey: 'appWide' },
  ];

  const severityLevels = [
    { value: 'temporary', labelKey: 'temporary', color: 'text-yellow-600' },
    { value: 'permanent', labelKey: 'permanent', color: 'text-red-600' },
  ];

  // Will be defined after helper functions

  const resetForm = () => {
    setFormData({
      type: 'user_ban',
      scope: 'app_wide',
      reason: '',
      description: '',
      severity: 'temporary',
      expiresDate: undefined,
      expiresTime: '',
      restrictedFeatures: [],
      restrictedDevices: [],
      relatedContentType: 'other',
      relatedContentId: '',
      relatedContentTitle: '',
    });
    setIsDatePickerOpen(false);
  };

  const handleCreateBan = async () => {
    if (!formData.reason.trim()) {
      toast.error(t('modules.userManagement.bans.errors.reasonRequired'));
      return;
    }

    // Validation for feature bans
    if ((formData.type === 'feature_ban' || formData.scope === 'feature_specific') && 
        formData.restrictedFeatures.length === 0) {
      toast.error(t('modules.userManagement.bans.errors.featuresRequired'));
      return;
    }

    // Validation for device bans
    if (formData.type === 'device_ban' && userDevices.length === 0) {
      toast.error(t('modules.userManagement.bans.errors.devicesRequired'));
      return;
    }

    // Validation for temporary bans
    if (formData.severity === 'temporary') {
      if (!formData.expiresDate) {
        toast.error(t('modules.userManagement.bans.dateRequired'));
        return;
      }
      if (!formData.expiresTime.trim()) {
        toast.error(t('modules.userManagement.bans.timeRequired'));
        return;
      }
    }

    setIsSubmitting(true);
    try {
      // Combine date and time for expiration
      let expiresAt = null;
      if (formData.severity === 'temporary' && formData.expiresDate && formData.expiresTime) {
        const [hours, minutes] = formData.expiresTime.split(':').map(Number);
        const expirationDate = new Date(formData.expiresDate);
        expirationDate.setHours(hours, minutes, 0, 0);
        expiresAt = Timestamp.fromDate(expirationDate);
      }

      const banData = {
        userId,
        type: formData.type,
        scope: formData.scope,
        reason: formData.reason.trim(),
        description: formData.description.trim() || null,
        severity: formData.severity,
        issuedBy: currentUser?.uid || 'unknown-admin',
        issuedAt: serverTimestamp(),
        expiresAt,
        isActive: true,
        restrictedFeatures: formData.scope === 'feature_specific' ? formData.restrictedFeatures : null,
        deviceIds: userDevices.length > 0 ? userDevices : null, // Track device IDs
        relatedContent: formData.relatedContentId.trim() ? {
          type: formData.relatedContentType,
          id: formData.relatedContentId.trim(),
          title: formData.relatedContentTitle.trim() || undefined,
        } : null,
      };

      await addDoc(bansCollection, banData);
      toast.success(t('modules.userManagement.bans.createSuccess'));
      setIsCreateDialogOpen(false);
      resetForm();
    } catch (error) {
      console.error('Error creating ban:', error);
      toast.error(t('modules.userManagement.bans.createError'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRevokeBan = async (ban: Ban) => {
    if (!ban.id) return;
    
    try {
      const banRef = doc(db, 'bans', ban.id);
      await updateDoc(banRef, {
        isActive: false,
        updatedAt: serverTimestamp(),
      });
      toast.success(t('modules.userManagement.bans.revokeSuccess'));
    } catch (error) {
      console.error('Error revoking ban:', error);
      toast.error(t('modules.userManagement.bans.revokeError'));
    }
  };

  const getSeverityBadge = (severity: string) => {
    const config = severityLevels.find(s => s.value === severity);
    return (
      <Badge variant="outline" className={config?.color}>
        <Shield className="h-3 w-3 mr-1" />
        {t(`modules.userManagement.bans.severity.${severity}`) || severity}
      </Badge>
    );
  };

  const getTypeBadge = (type: string) => {
    const config = banTypes.find(t => t.value === type);
    const Icon = config?.icon || Shield;
    return (
      <Badge variant="secondary">
        <Icon className="h-3 w-3 mr-1" />
        {t(`modules.userManagement.bans.type.${type}`) || type}
      </Badge>
    );
  };

  const getScopeBadge = (scope: string) => {
    return (
      <Badge variant="outline">
        {t(`modules.userManagement.bans.scope.${scope}`) || scope}
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

  const formatDateOnly = (date: Timestamp | Date) => {
    const dateObj = convertTimestamp(date);
    return new Intl.DateTimeFormat(locale === 'ar' ? 'ar-SA' : 'en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      calendar: 'gregory',
    }).format(dateObj);
  };

  const isBanExpired = (ban: Ban) => {
    if (!ban.expiresAt) return false;
    const expiryDate = convertTimestamp(ban.expiresAt);
    return expiryDate < new Date();
  };

  const getFeatureName = (featureUniqueName: string) => {
    const feature = appFeatures.find(f => f.uniqueName === featureUniqueName);
    if (!feature) return featureUniqueName;
    return locale === 'ar' ? feature.nameAr : feature.nameEn;
  };

  const handleFeatureToggle = (featureUniqueName: string) => {
    const updatedFeatures = formData.restrictedFeatures.includes(featureUniqueName)
      ? formData.restrictedFeatures.filter(f => f !== featureUniqueName)
      : [...formData.restrictedFeatures, featureUniqueName];
    
    setFormData({ ...formData, restrictedFeatures: updatedFeatures });
  };

  const handleDeviceToggle = (deviceId: string) => {
    const updatedDevices = formData.restrictedDevices.includes(deviceId)
      ? formData.restrictedDevices.filter(d => d !== deviceId)
      : [...formData.restrictedDevices, deviceId];
    
    setFormData({ ...formData, restrictedDevices: updatedDevices });
  };

  // Auto-set scope based on ban type
  useEffect(() => {
    if (formData.type === 'device_ban' || formData.type === 'user_ban') {
      // Device bans and user bans should always be app-wide
      setFormData(prev => ({ ...prev, scope: 'app_wide' }));
    } else if (formData.type === 'feature_ban') {
      // Feature bans should be feature-specific
      setFormData(prev => ({ ...prev, scope: 'feature_specific' }));
    }
  }, [formData.type]);

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

  // Computed values that depend on helper functions
  const activeBans = bans.filter(ban => ban.isActive && !isBanExpired(ban));
  const expiredBans = bans.filter(ban => isBanExpired(ban));

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="h-5 w-5 text-red-600" />
            <CardTitle>{t('modules.userManagement.bans.title')}</CardTitle>
          </div>
          <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
            <DialogTrigger asChild>
              <Button size="sm" variant="destructive" onClick={resetForm}>
                <Plus className="h-4 w-4 mr-2" />
                {t('modules.userManagement.bans.issueBan')}
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-5xl max-h-[90vh] overflow-y-auto">
              <DialogHeader className="space-y-2 pb-4">
                <div className="flex items-center gap-2">
                  <Shield className="h-5 w-5 text-red-600" />
                  <DialogTitle className="text-xl">{t('modules.userManagement.bans.issueBan')}</DialogTitle>
                </div>
                <DialogDescription className="text-sm">
                  {t('modules.userManagement.bans.issueBanDescription', { user: userDisplayName || userId })}
                </DialogDescription>
              </DialogHeader>
              <div className="grid gap-4 py-2">
                {/* Device History Warning */}
                {(deviceHistory.bans.length > 0 || deviceHistory.warnings.length > 0) && (
                  <div className="bg-amber-50 border border-amber-200 p-4 rounded-lg space-y-3">
                    <div className="flex items-center gap-2">
                      <AlertTriangle className="h-5 w-5 text-amber-600" />
                      <h4 className="font-semibold text-amber-800">{t('modules.userManagement.bans.deviceHistory.title')}</h4>
                    </div>
                    <p className="text-sm text-amber-700">
                      {t('modules.userManagement.bans.deviceHistory.description')}
                    </p>
                    
                    {deviceHistory.bans.length > 0 && (
                      <div className="space-y-2">
                        <p className="text-sm font-medium text-amber-800">
                          {t('modules.userManagement.bans.deviceHistory.previousBans')} ({deviceHistory.bans.length}):
                        </p>
                        <div className="space-y-1 max-h-24 overflow-y-auto">
                          {deviceHistory.bans.slice(0, 3).map((ban) => (
                            <div key={ban.id} className={`text-xs p-2 rounded border ${ban.userId === userId ? 'bg-blue-50 border-blue-200' : 'bg-white border-gray-200'}`}>
                              <div className="flex justify-between">
                                <span className="font-medium">
                                  {ban.userId === userId ? (
                                    <span className="text-blue-700">👤 {t('modules.userManagement.bans.deviceHistory.thisUser')}</span>
                                  ) : (
                                    <span>{t('modules.userManagement.bans.deviceHistory.userIdLabel')} {ban.userId.slice(0, 8)}...</span>
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
                              +{deviceHistory.bans.length - 3} {t('modules.userManagement.bans.deviceHistory.showMore')}
                            </div>
                          )}
                        </div>
                      </div>
                    )}

                    {deviceHistory.warnings.length > 0 && (
                      <div className="space-y-2">
                        <p className="text-sm font-medium text-amber-800">
                          {t('modules.userManagement.bans.deviceHistory.previousWarnings')} ({deviceHistory.warnings.length}):
                        </p>
                        <div className="space-y-1 max-h-24 overflow-y-auto">
                          {deviceHistory.warnings.slice(0, 3).map((warning) => (
                            <div key={warning.id} className={`text-xs p-2 rounded border ${warning.userId === userId ? 'bg-blue-50 border-blue-200' : 'bg-white border-gray-200'}`}>
                              <div className="flex justify-between">
                                <span className="font-medium">
                                  {warning.userId === userId ? (
                                    <span className="text-blue-700">👤 {t('modules.userManagement.bans.deviceHistory.thisUser')}</span>
                                  ) : (
                                    <span>{t('modules.userManagement.bans.deviceHistory.userIdLabel')} {warning.userId.slice(0, 8)}...</span>
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
                              +{deviceHistory.warnings.length - 3} {t('modules.userManagement.bans.deviceHistory.showMore')}
                            </div>
                          )}
                        </div>
                      </div>
                    )}

                    <div className="text-xs text-amber-700 bg-amber-100 p-2 rounded">
                      <strong>{t('modules.userManagement.bans.deviceHistory.recommendation')}</strong> {t('modules.userManagement.bans.deviceHistory.recommendPermanentBan')}
                    </div>
                  </div>
                )}

                {/* Loading Device History */}
                {deviceHistory.loading && (
                  <div className="bg-blue-50 border border-blue-200 p-4 rounded-lg">
                    <div className="flex items-center gap-2">
                      <Loader2 className="h-4 w-4 animate-spin text-blue-600" />
                      <span className="text-sm text-blue-700">{t('modules.userManagement.bans.deviceHistory.checkingHistory')}</span>
                    </div>
                  </div>
                )}

                {/* Ban Configuration */}
                <div className="bg-slate-50 p-4 rounded-lg space-y-4">
                  <div className="flex items-center gap-2 mb-3">
                    <Settings className="h-4 w-4 text-slate-600" />
                    <h4 className="font-medium text-sm">{t('modules.userManagement.bans.banConfiguration')}</h4>
                  </div>
                  <div className={`grid gap-3 ${formData.type === 'feature_ban' ? 'grid-cols-3' : 'grid-cols-2'}`}>
                    <div className="space-y-1.5">
                      <Label htmlFor="type" className="text-xs font-medium">{t('modules.userManagement.bans.type.label')}</Label>
                      <Select value={formData.type} onValueChange={(value) => setFormData({ ...formData, type: value as Ban['type'] })}>
                        <SelectTrigger className="h-8 text-sm">
                          <SelectValue placeholder={t('modules.userManagement.bans.type.selectType')} />
                        </SelectTrigger>
                        <SelectContent>
                          {banTypes.map((type) => (
                            <SelectItem key={type.value} value={type.value}>
                              <div className="flex items-center gap-2">
                                <type.icon className="h-3 w-3" />
                                {t(`modules.userManagement.bans.type.${type.labelKey}`)}
                              </div>
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {formData.type === 'device_ban' && (
                        <p className="text-xs text-muted-foreground mt-1">
                          📱 {t('modules.userManagement.bans.deviceBanNote')}
                        </p>
                      )}
                      {formData.type === 'user_ban' && (
                        <p className="text-xs text-muted-foreground mt-1">
                          👤 {t('modules.userManagement.bans.userBanNote')}
                        </p>
                      )}
                    </div>
                    {/* Only show scope for feature_ban */}
                    {formData.type === 'feature_ban' && (
                      <div className="space-y-1.5">
                        <Label htmlFor="scope" className="text-xs font-medium">{t('modules.userManagement.bans.scope.label')}</Label>
                        <Select value={formData.scope} onValueChange={(value) => setFormData({ ...formData, scope: value as Ban['scope'] })}>
                          <SelectTrigger className="h-8 text-sm">
                            <SelectValue placeholder={t('modules.userManagement.bans.scope.selectScope')} />
                          </SelectTrigger>
                          <SelectContent>
                            {banScopes.map((scope) => (
                              <SelectItem key={scope.value} value={scope.value}>
                                {t(`modules.userManagement.bans.scope.${scope.labelKey}`)}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    )}
                    <div className="space-y-1.5">
                      <Label htmlFor="severity" className="text-xs font-medium">{t('modules.userManagement.bans.severity.label')}</Label>
                      <Select value={formData.severity} onValueChange={(value) => setFormData({ ...formData, severity: value as Ban['severity'] })}>
                        <SelectTrigger className="h-8 text-sm">
                          <SelectValue placeholder={t('modules.userManagement.bans.severity.selectSeverity')} />
                        </SelectTrigger>
                        <SelectContent>
                          {severityLevels.map((level) => (
                            <SelectItem key={level.value} value={level.value}>
                              <span className={level.color}>
                                {t(`modules.userManagement.bans.severity.${level.labelKey}`)}
                              </span>
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                </div>

                {/* Reason and Description */}
                <div className="bg-red-50 p-4 rounded-lg space-y-3">
                  <div className="flex items-center gap-2 mb-2">
                    <AlertTriangle className="h-4 w-4 text-red-600" />
                    <h4 className="font-medium text-sm">{t('modules.userManagement.bans.banDetails')}</h4>
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="reason" className="text-xs font-medium">{t('modules.userManagement.bans.reason')}</Label>
                    <Input
                      id="reason"
                      value={formData.reason}
                      onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                      placeholder={t('modules.userManagement.bans.reasonPlaceholder')}
                      className="h-8 text-sm"
                    />
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="description" className="text-xs font-medium">{t('modules.userManagement.bans.description')}</Label>
                    <Textarea
                      id="description"
                      value={formData.description}
                      onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                      placeholder={t('modules.userManagement.bans.descriptionPlaceholder')}
                      className="text-sm min-h-[60px] resize-none"
                      rows={2}
                    />
                  </div>
                </div>

                {/* Feature-specific restrictions */}
                {(formData.type === 'feature_ban' || formData.scope === 'feature_specific') && (
                  <div className="bg-blue-50 p-4 rounded-lg space-y-3">
                    <div className="flex items-center gap-2 mb-2">
                      <Settings className="h-4 w-4 text-blue-600" />
                      <Label className="font-medium text-sm">{t('modules.userManagement.bans.restrictedFeatures')}</Label>
                    </div>
                    <div className="grid grid-cols-3 gap-2 max-h-32 overflow-y-auto p-2 border rounded bg-white">
                      {appFeatures.filter(f => f.isBannable).map((feature) => (
                        <div key={feature.uniqueName} className="flex items-center space-x-2 p-1.5 hover:bg-gray-50 rounded">
                          <Checkbox
                            id={`feature-${feature.uniqueName}`}
                            checked={formData.restrictedFeatures.includes(feature.uniqueName)}
                            onCheckedChange={() => handleFeatureToggle(feature.uniqueName)}
                            className="h-3 w-3"
                          />
                          <Label 
                            htmlFor={`feature-${feature.uniqueName}`}
                            className="text-xs font-normal cursor-pointer flex-1"
                          >
                            {locale === 'ar' ? feature.nameAr : feature.nameEn}
                          </Label>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Device-specific restrictions */}
                {formData.type === 'device_ban' && userDevices.length > 0 && (
                  <div className="bg-orange-50 p-4 rounded-lg space-y-3">
                    <div className="flex items-center gap-2 mb-2">
                      <Smartphone className="h-4 w-4 text-orange-600" />
                      <Label className="font-medium text-sm">{t('modules.userManagement.bans.restrictedDevices')}</Label>
                    </div>
                    <div className="grid grid-cols-2 gap-2 max-h-28 overflow-y-auto p-2 border rounded bg-white">
                      {userDevices.map((deviceId) => (
                        <div key={deviceId} className="flex items-center space-x-2 p-1.5 hover:bg-gray-50 rounded">
                          <Checkbox
                            id={`device-${deviceId}`}
                            checked={formData.restrictedDevices.includes(deviceId)}
                            onCheckedChange={() => handleDeviceToggle(deviceId)}
                            className="h-3 w-3"
                          />
                          <Label 
                            htmlFor={`device-${deviceId}`}
                            className="text-xs font-normal cursor-pointer font-mono flex-1 truncate"
                          >
                            {deviceId}
                          </Label>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Duration and Expiration */}
                {formData.severity === 'temporary' && (
                  <div className="bg-yellow-50 p-4 rounded-lg space-y-3">
                    <div className="flex items-center gap-2 mb-2">
                      <CalendarIcon className="h-4 w-4 text-yellow-600" />
                      <h4 className="font-medium text-sm">{t('modules.userManagement.bans.expirationSettings')}</h4>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="flex flex-col gap-3">
                        <Label htmlFor="date-picker" className="text-xs font-medium px-1">
                          {t('modules.userManagement.bans.expiresDate')}
                        </Label>
                        <Popover open={isDatePickerOpen} onOpenChange={setIsDatePickerOpen}>
                          <PopoverTrigger asChild>
                            <Button
                              variant="outline"
                              id="date-picker"
                              className="w-full justify-between font-normal h-8 text-sm"
                            >
                              {formData.expiresDate ? formData.expiresDate.toLocaleDateString() : t('modules.userManagement.bans.selectDate')}
                              <ChevronDownIcon className="h-4 w-4" />
                            </Button>
                          </PopoverTrigger>
                          <PopoverContent className="w-auto overflow-hidden p-0" align="start">
                            <Calendar
                              mode="single"
                              selected={formData.expiresDate}
                              captionLayout="dropdown"
                              fromYear={new Date().getFullYear()}
                              toYear={new Date().getFullYear() + 10}
                              disabled={(date) => {
                                const today = new Date();
                                today.setHours(0, 0, 0, 0); // Reset time to start of day
                                return date <= today; // Disable today and all past dates
                              }}
                              onSelect={(date) => {
                                setFormData({ ...formData, expiresDate: date });
                                setIsDatePickerOpen(false);
                              }}
                            />
                          </PopoverContent>
                        </Popover>
                      </div>
                      <div className="flex flex-col gap-3">
                        <Label htmlFor="time-picker" className="text-xs font-medium px-1">
                          {t('modules.userManagement.bans.expiresTime')}
                        </Label>
                        <Input
                          type="time"
                          id="time-picker"
                          step="1"
                          value={formData.expiresTime}
                          onChange={(e) => setFormData({ ...formData, expiresTime: e.target.value })}
                          className="w-full h-8 text-sm bg-background appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
                        />
                      </div>
                    </div>
                    {formData.expiresDate && formData.expiresTime && (
                      <div className="text-xs text-muted-foreground mt-2 p-2 bg-white border rounded">
                        <strong>{t('modules.userManagement.bans.expires')}:</strong> {formData.expiresDate.toLocaleDateString()} at {formData.expiresTime}
                      </div>
                    )}
                  </div>
                )}

                {/* Related Content */}
                <div className="bg-purple-50 p-4 rounded-lg space-y-3">
                  <div className="flex items-center gap-2 mb-2">
                    <FileText className="h-4 w-4 text-purple-600" />
                    <h4 className="font-medium text-sm">{t('modules.userManagement.bans.relatedContentOptional')}</h4>
                  </div>
                  <div className="grid grid-cols-3 gap-3">
                    <div className="space-y-1.5">
                      <Label htmlFor="relatedContentType" className="text-xs font-medium">{t('modules.userManagement.bans.relatedContentType.label')}</Label>
                      <Select value={formData.relatedContentType} onValueChange={(value) => setFormData({ ...formData, relatedContentType: value as RelatedContent['type'] })}>
                        <SelectTrigger className="h-8 text-sm">
                          <SelectValue placeholder={t('modules.userManagement.bans.relatedContentTypePlaceholder')} />
                        </SelectTrigger>
                        <SelectContent>
                          {['user', 'report', 'post', 'comment', 'message', 'group', 'other'].map((type) => (
                            <SelectItem key={type} value={type}>
                              {t(`modules.userManagement.bans.relatedContentType.${type}`)}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="space-y-1.5">
                      <Label htmlFor="relatedContentId" className="text-xs font-medium">{t('modules.userManagement.bans.relatedContentId')}</Label>
                      <Input
                        id="relatedContentId"
                        value={formData.relatedContentId}
                        onChange={(e) => setFormData({ ...formData, relatedContentId: e.target.value })}
                        placeholder={t('modules.userManagement.bans.relatedContentIdPlaceholder')}
                        className="h-8 text-sm"
                      />
                    </div>
                    <div className="space-y-1.5">
                      <Label htmlFor="relatedContentTitle" className="text-xs font-medium">{t('modules.userManagement.bans.relatedContentTitle')}</Label>
                      <Input
                        id="relatedContentTitle"
                        value={formData.relatedContentTitle}
                        onChange={(e) => setFormData({ ...formData, relatedContentTitle: e.target.value })}
                        placeholder={t('modules.userManagement.bans.relatedContentTitlePlaceholder')}
                        className="h-8 text-sm"
                      />
                    </div>
                  </div>
                </div>
              </div>
              <DialogFooter className="border-t pt-4 mt-4">
                <div className="flex items-center justify-between w-full">
                  <div className="text-xs text-muted-foreground">
                    {formData.severity === 'permanent' && (
                      <span className="text-red-600 font-medium">{t('modules.userManagement.bans.permanentWarning')}</span>
                    )}
                  </div>
                  <div className="flex gap-2">
                    <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)} className="h-8 px-4">
                      {t('common.cancel')}
                    </Button>
                    <Button 
                      variant="destructive" 
                      onClick={handleCreateBan}
                      disabled={isSubmitting}
                      className="h-8 px-4"
                    >
                      {isSubmitting ? (
                        <>
                          <Loader2 className="h-3 w-3 mr-2 animate-spin" />
                          {t('common.creating')}
                        </>
                      ) : (
                        <>
                          <Shield className="h-3 w-3 mr-2" />
                          {t('modules.userManagement.bans.issueBan')}
                        </>
                      )}
                    </Button>
                  </div>
                </div>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
        <CardDescription>
          {t('modules.userManagement.bans.description')}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Loading and Error States */}
        {bansError && (
          <div className="text-center py-8">
            <div className="text-red-600 mb-4">
              <p className="text-lg font-medium">{t('common.errors.loadingFailed')}</p>
              <p className="text-sm">{t('modules.userManagement.bans.errors.loadingFailed')}</p>
              <details className="mt-2 text-xs">
                <summary className="cursor-pointer">Technical Details</summary>
                <div className="mt-2 p-2 bg-red-50 rounded">
                  <p><strong>Error Code:</strong> {bansError.code}</p>
                  <p><strong>Error Message:</strong> {bansError.message}</p>
                </div>
              </details>
            </div>
            <Button onClick={() => window.location.reload()}>
              {t('common.retry')}
            </Button>
          </div>
        )}

        {featuresError && (
          <div className="text-center py-4">
            <p className="text-sm text-muted-foreground">
              {t('modules.features.appFeatures.errors.loadingFailed')}
            </p>
            <details className="mt-2 text-xs">
              <summary className="cursor-pointer">Technical Details</summary>
              <div className="mt-2 p-2 bg-yellow-50 rounded">
                <p><strong>Error Code:</strong> {featuresError.code}</p>
                <p><strong>Error Message:</strong> {featuresError.message}</p>
              </div>
            </details>
          </div>
        )}

        {!bansError && !bansLoading && (
          <>
            {/* Ban Statistics */}
            <div className="grid grid-cols-3 gap-4">
              <div className="text-center p-4 bg-muted rounded-lg">
                <p className="text-2xl font-bold text-red-600">{activeBans.length}</p>
                <p className="text-sm text-muted-foreground">{t('modules.userManagement.bans.activeBans')}</p>
              </div>
              <div className="text-center p-4 bg-muted rounded-lg">
                <p className="text-2xl font-bold">{bans.length}</p>
                <p className="text-sm text-muted-foreground">{t('modules.userManagement.bans.totalBans')}</p>
              </div>
              <div className="text-center p-4 bg-muted rounded-lg">
                <p className="text-2xl font-bold text-gray-600">{expiredBans.length}</p>
                <p className="text-sm text-muted-foreground">{t('modules.userManagement.bans.expiredBans')}</p>
              </div>
            </div>
          </>
        )}

        {bansLoading && (
          <div className="text-center py-8">
            <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4" />
            <p className="text-muted-foreground">{t('common.loading')}</p>
          </div>
        )}

        {/* Active Bans */}
        {activeBans.length > 0 && (
          <div className="space-y-4">
            <h4 className="text-lg font-semibold">{t('modules.userManagement.bans.activeBans')}</h4>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t('modules.userManagement.bans.type.label')}</TableHead>
                  <TableHead>{t('modules.userManagement.bans.scope.label')}</TableHead>
                  <TableHead>{t('modules.userManagement.bans.reason')}</TableHead>
                  <TableHead>{t('modules.userManagement.bans.severity.label')}</TableHead>
                  <TableHead>{t('modules.userManagement.bans.issued')}</TableHead>
                  <TableHead>{t('modules.userManagement.bans.expires')}</TableHead>
                  <TableHead className="text-right">{t('common.actions')}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {activeBans.map((ban) => (
                  <TableRow key={ban.id}>
                    <TableCell>{getTypeBadge(ban.type)}</TableCell>
                    <TableCell>{getScopeBadge(ban.scope)}</TableCell>
                    <TableCell>
                      <div className="space-y-1">
                        <p className="text-sm font-medium">{ban.reason}</p>
                        {ban.relatedContent && (
                          <p className="text-xs text-muted-foreground">
                            {ban.relatedContent.title || `${ban.relatedContent.type}: ${ban.relatedContent.id}`}
                          </p>
                        )}
                        {ban.restrictedFeatures && ban.restrictedFeatures.length > 0 && (
                          <div className="flex flex-wrap gap-1 mt-1">
                            {ban.restrictedFeatures.map(featureId => (
                              <Badge key={featureId} variant="outline" className="text-xs">
                                {getFeatureName(featureId)}
                              </Badge>
                            ))}
                          </div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>{getSeverityBadge(ban.severity)}</TableCell>
                    <TableCell>
                      <div className="space-y-1">
                        <p className="text-sm">{formatDate(ban.issuedAt)}</p>
                        <p className="text-xs text-muted-foreground">{t('modules.userManagement.bans.by')} {getAdminDisplayName(ban.issuedBy)}</p>
                      </div>
                    </TableCell>
                    <TableCell>
                      {ban.expiresAt ? (
                        <div className="space-y-1">
                          <p className="text-sm">{formatDateOnly(ban.expiresAt)}</p>
                          {isBanExpired(ban) && (
                            <Badge variant="outline" className="text-red-600">
                              {t('modules.userManagement.bans.expired')}
                            </Badge>
                          )}
                        </div>
                      ) : (
                        <Badge variant="outline" className="text-red-600">{t('modules.userManagement.bans.permanent')}</Badge>
                      )}
                    </TableCell>
                    <TableCell className="text-right">
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button size="sm" variant="outline">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem onClick={() => setSelectedBan(ban)}>
                            <Eye className="h-4 w-4 mr-2" />
                            {t('modules.userManagement.bans.viewDetails')}
                          </DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem 
                            className="text-green-600"
                            onClick={() => handleRevokeBan(ban)}
                          >
                            <Shield className="h-4 w-4 mr-2" />
                            {t('modules.userManagement.bans.revokeBan')}
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {/* No Bans Message */}
        {bans.length === 0 && (
          <div className="text-center py-8">
            <Shield className="h-12 w-12 text-muted-foreground mx-auto mb-4 opacity-50" />
            <p className="text-lg font-medium">{t('modules.userManagement.bans.noBans')}</p>
            <p className="text-muted-foreground">{t('modules.userManagement.bans.noBansDescription')}</p>
          </div>
        )}
      </CardContent>

      {/* Ban Details Dialog */}
      <Dialog open={!!selectedBan} onOpenChange={() => setSelectedBan(null)}>
        <DialogContent className="max-w-2xl">
          {selectedBan && (
            <>
              <DialogHeader>
                <DialogTitle>{t('modules.userManagement.bans.banDetails')}</DialogTitle>
                <DialogDescription>
                  {t('modules.userManagement.bans.banId')}: {selectedBan.id}
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <Label>{t('modules.userManagement.bans.type.label')}</Label>
                    <div className="mt-1">{getTypeBadge(selectedBan.type)}</div>
                  </div>
                  <div>
                    <Label>{t('modules.userManagement.bans.scope.label')}</Label>
                    <div className="mt-1">{getScopeBadge(selectedBan.scope)}</div>
                  </div>
                  <div>
                    <Label>{t('modules.userManagement.bans.severity.label')}</Label>
                    <div className="mt-1">{getSeverityBadge(selectedBan.severity)}</div>
                  </div>
                </div>
                <div>
                  <Label>{t('modules.userManagement.bans.reason')}</Label>
                  <p className="mt-1 text-sm">{selectedBan.reason}</p>
                </div>
                {selectedBan.description && (
                  <div>
                    <Label>{t('modules.userManagement.bans.description')}</Label>
                    <p className="mt-1 text-sm text-muted-foreground">{selectedBan.description}</p>
                  </div>
                )}
                {selectedBan.restrictedFeatures && selectedBan.restrictedFeatures.length > 0 && (
                  <div>
                    <Label>{t('modules.userManagement.bans.restrictedFeatures')}</Label>
                    <div className="flex flex-wrap gap-2 mt-1">
                      {selectedBan.restrictedFeatures.map(featureId => (
                        <Badge key={featureId} variant="outline">
                          {getFeatureName(featureId)}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
                {selectedBan.relatedContent && (
                  <RelatedContentViewer relatedContent={selectedBan.relatedContent} />
                )}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label>{t('modules.userManagement.bans.issued')}</Label>
                    <p className="mt-1 text-sm">{formatDate(selectedBan.issuedAt)}</p>
                    <p className="text-xs text-muted-foreground">{t('modules.userManagement.bans.by')} {getAdminDisplayName(selectedBan.issuedBy)}</p>
                  </div>
                  <div>
                    <Label>{t('modules.userManagement.bans.expires')}</Label>
                    <p className="mt-1 text-sm">
                      {selectedBan.expiresAt ? formatDate(selectedBan.expiresAt) : t('modules.userManagement.bans.permanent')}
                    </p>
                  </div>
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setSelectedBan(null)}>
                  {t('common.close')}
                </Button>
                <Button 
                  variant="destructive" 
                  onClick={() => {
                    handleRevokeBan(selectedBan);
                    setSelectedBan(null);
                  }}
                >
                  {t('modules.userManagement.bans.revokeBan')}
                </Button>
              </DialogFooter>
            </>
          )}
        </DialogContent>
      </Dialog>
    </Card>
  );
} 