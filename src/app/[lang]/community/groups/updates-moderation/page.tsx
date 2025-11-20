'use client';

import { useState, useMemo, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  limit, 
  doc, 
  updateDoc, 
  writeBatch,
  getDocs,
  startAfter,
  QueryDocumentSnapshot,
  DocumentData,
  Timestamp
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/auth/AuthProvider';
import { SiteHeader } from '@/components/site-header';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Separator } from '@/components/ui/separator';
import {
  Search,
  Eye,
  CheckCircle,
  XCircle,
  Clock,
  ChevronLeft,
  ChevronRight,
  AlertTriangle,
  FileText,
  Shield,
  TrendingUp,
  Users,
  Flag,
  Loader2
} from 'lucide-react';
import { format } from 'date-fns';
import { toast } from 'sonner';
import { StatusBadge } from '@/components/group-updates/StatusBadge';
import { SeverityBadge } from '@/components/group-updates/SeverityBadge';
import { UpdateTypeBadge } from '@/components/group-updates/UpdateTypeBadge';
import type { GroupUpdate, UpdatesFilterState, ModerationAction } from '@/types/groupUpdates';

export default function GroupUpdatesModerationPage() {
  const params = useParams();
  const lang = params.lang as string;
  const { t } = useTranslation();
  const { user } = useAuth();

  // Filter states
  const [activeTab, setActiveTab] = useState<'manual_review' | 'approved' | 'blocked' | 'all'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [languageFilter, setLanguageFilter] = useState<'all' | 'en' | 'ar'>('all');
  const [updateTypeFilter, setUpdateTypeFilter] = useState<'all' | 'general' | 'achievement' | 'milestone' | 'support'>('all');
  const [violationTypeFilter, setViolationTypeFilter] = useState('all');

  // Pagination states
  const [pageSize, setPageSize] = useState(20);
  const [currentPage, setCurrentPage] = useState(1);
  const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [hasNextPage, setHasNextPage] = useState(false);
  const [totalCount, setTotalCount] = useState(0);

  // Selection and bulk actions
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [showBulkDialog, setShowBulkDialog] = useState(false);
  const [bulkAction, setBulkAction] = useState<'approve' | 'block'>('approve');
  const [bulkReason, setBulkReason] = useState('');
  const [isProcessingBulk, setIsProcessingBulk] = useState(false);

  // Detail sheet
  const [selectedUpdate, setSelectedUpdate] = useState<GroupUpdate | null>(null);
  const [showDetailSheet, setShowDetailSheet] = useState(false);
  const [moderationAction, setModerationAction] = useState<'approve' | 'block' | 'keep_under_review'>('approve');
  const [moderationReason, setModerationReason] = useState('');
  const [moderationNotes, setModerationNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Related data
  const [authorProfile, setAuthorProfile] = useState<any>(null);
  const [groupData, setGroupData] = useState<any>(null);

  // Global stats (independent of active tab)
  const [globalStats, setGlobalStats] = useState({
    total: 0,
    pendingReview: 0,
    approved: 0,
    blocked: 0,
    today: 0
  });

  const headerDictionary = {
    documents: t('modules.community.groupUpdates.title') || 'Updates Moderation',
  };

  // Build Firestore query with pagination
  const updatesQuery = useMemo(() => {
    let constraints: any[] = [];

    // Filter by status based on active tab
    if (activeTab !== 'all') {
      constraints.push(where('moderation.status', '==', activeTab));
    }

    // Filter by language
    if (languageFilter !== 'all') {
      constraints.push(where('locale', '==', languageFilter));
    }

    // Filter by update type
    if (updateTypeFilter !== 'all') {
      constraints.push(where('type', '==', updateTypeFilter));
    }

    // Filter by violation type
    if (violationTypeFilter !== 'all' && violationTypeFilter !== 'none') {
      constraints.push(where('moderation.ai.violationType', '==', violationTypeFilter));
    }

    constraints.push(orderBy('createdAt', 'desc'));

    // Add pagination
    if (currentPage > 1 && lastDoc) {
      constraints.push(startAfter(lastDoc));
    }

    constraints.push(limit(pageSize + 1)); // +1 to check if there's a next page

    return query(collection(db, 'group_updates'), ...constraints);
  }, [activeTab, languageFilter, updateTypeFilter, violationTypeFilter, pageSize, currentPage, lastDoc]);

  const [snapshot, loading, error] = useCollection(updatesQuery);

  // Extract data from snapshot and handle pagination
  const updates = useMemo(() => {
    if (!snapshot) return [];

    const docs = snapshot.docs;

    // Check if there's a next page
    if (docs.length > pageSize) {
      setHasNextPage(true);
      const displayDocs = docs.slice(0, pageSize);

      if (displayDocs.length > 0) {
        setLastDoc(displayDocs[displayDocs.length - 1]);
      }

      return displayDocs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as GroupUpdate[];
    } else {
      setHasNextPage(false);

      if (docs.length > 0) {
        setLastDoc(docs[docs.length - 1]);
      }

      return docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })) as GroupUpdate[];
    }
  }, [snapshot, pageSize]);

  // Get total count for current filters
  useEffect(() => {
    const fetchTotalCount = async () => {
      try {
        let constraints: any[] = [];

        if (activeTab !== 'all') {
          constraints.push(where('moderation.status', '==', activeTab));
        }

        if (languageFilter !== 'all') {
          constraints.push(where('locale', '==', languageFilter));
        }

        if (updateTypeFilter !== 'all') {
          constraints.push(where('type', '==', updateTypeFilter));
        }

        const countQuery = query(collection(db, 'group_updates'), ...constraints);
        const countSnapshot = await getDocs(countQuery);
        setTotalCount(countSnapshot.size);
      } catch (error) {
        console.error('Error fetching total count:', error);
      }
    };

    fetchTotalCount();
  }, [activeTab, languageFilter, updateTypeFilter]);

  // Fetch global stats (independent of filters and active tab)
  useEffect(() => {
    const fetchGlobalStats = async () => {
      try {
        // Get all updates
        const allQuery = query(collection(db, 'group_updates'));
        const allSnapshot = await getDocs(allQuery);
        
        // Calculate today's date range
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayTimestamp = Timestamp.fromDate(today);
        
        // Get today's updates
        const todayQuery = query(
          collection(db, 'group_updates'),
          where('createdAt', '>=', todayTimestamp)
        );
        const todaySnapshot = await getDocs(todayQuery);
        
        // Calculate stats from all updates
        let pendingReview = 0;
        let approved = 0;
        let blocked = 0;
        
        allSnapshot.forEach((doc) => {
          const data = doc.data();
          const status = data.moderation?.status;
          
          if (status === 'manual_review' || status === 'pending') {
            pendingReview++;
          } else if (status === 'approved') {
            approved++;
          } else if (status === 'blocked') {
            blocked++;
          }
        });
        
        setGlobalStats({
          total: allSnapshot.size,
          pendingReview,
          approved,
          blocked,
          today: todaySnapshot.size
        });
      } catch (error) {
        console.error('Error fetching global stats:', error);
      }
    };

    fetchGlobalStats();
  }, []); // Only fetch once on mount

  // Client-side filtering for search
  const filteredUpdates = useMemo(() => {
    if (!updates) return [];
    if (!searchTerm) return updates;

    return updates.filter((update: GroupUpdate) =>
      update.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      update.content?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      update.authorCpId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      update.groupId?.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [updates, searchTerm]);

  // Pagination handlers
  const handleNextPage = () => {
    if (hasNextPage) {
      setCurrentPage(prev => prev + 1);
      setSelectedIds([]);
    }
  };

  const handlePreviousPage = () => {
    if (currentPage > 1) {
      setCurrentPage(prev => prev - 1);
      setLastDoc(null);
      setSelectedIds([]);
    }
  };

  const handlePageSizeChange = (newSize: string) => {
    setPageSize(parseInt(newSize));
    setCurrentPage(1);
    setLastDoc(null);
    setSelectedIds([]);
  };

  // Reset to first page when filters change
  useEffect(() => {
    setCurrentPage(1);
    setLastDoc(null);
    setSelectedIds([]);
  }, [activeTab, languageFilter, updateTypeFilter, violationTypeFilter]);

  // Handle view update detail
  const handleViewUpdate = async (update: GroupUpdate) => {
    setSelectedUpdate(update);
    setShowDetailSheet(true);
    setModerationReason('');
    setModerationNotes('');
    setModerationAction('approve');

    // Fetch author profile
    try {
      const authorDoc = await getDocs(query(collection(db, 'communityProfiles'), where('__name__', '==', update.authorCpId)));
      if (!authorDoc.empty) {
        setAuthorProfile(authorDoc.docs[0].data());
      }
    } catch (error) {
      console.error('Error fetching author:', error);
    }

    // Fetch group data
    try {
      const groupDoc = await getDocs(query(collection(db, 'groups'), where('__name__', '==', update.groupId)));
      if (!groupDoc.empty) {
        setGroupData(groupDoc.docs[0].data());
      }
    } catch (error) {
      console.error('Error fetching group:', error);
    }
  };

  // Handle moderation action
  const handleSubmitModeration = async () => {
    if (!selectedUpdate) return;

    setIsSubmitting(true);
    try {
      const updateRef = doc(db, 'group_updates', selectedUpdate.id);
      const updates: any = {
        'moderation.status': moderationAction === 'approve' ? 'approved' : moderationAction === 'block' ? 'blocked' : 'manual_review',
        'moderation.moderatedBy': user?.uid,
        'moderation.moderatedAt': Timestamp.now(),
      };

      if (moderationReason) {
        updates['moderation.reason'] = moderationReason;
      }

      if (moderationAction === 'approve') {
        updates.isHidden = false;
      } else if (moderationAction === 'block') {
        updates.isHidden = true;
      }

      if (moderationNotes) {
        updates['moderation.adminAction'] = {
          moderatorId: user?.uid,
          action: moderationAction,
          notes: moderationNotes,
          timestamp: Timestamp.now(),
        };
      }

      await updateDoc(updateRef, updates);

      toast.success(
        moderationAction === 'approve'
          ? t('modules.community.groupUpdates.notifications.approved')
          : moderationAction === 'block'
          ? t('modules.community.groupUpdates.notifications.blocked')
          : t('modules.community.groupUpdates.notifications.keptUnderReview')
      );

      setShowDetailSheet(false);
      setSelectedUpdate(null);
    } catch (error: any) {
      console.error('Error moderating update:', error);
      toast.error(error.message || t('modules.community.groupUpdates.notifications.error'));
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle bulk actions
  const handleBulkAction = () => {
    if (selectedIds.length === 0) {
      toast.error('Please select at least one update');
      return;
    }
    setShowBulkDialog(true);
  };

  const executeBulkAction = async () => {
    setIsProcessingBulk(true);
    try {
      const batch = writeBatch(db);

      selectedIds.forEach(updateId => {
        const updateRef = doc(db, 'group_updates', updateId);
        const updates: any = {
          'moderation.status': bulkAction === 'approve' ? 'approved' : 'blocked',
          'moderation.moderatedBy': user?.uid,
          'moderation.moderatedAt': Timestamp.now(),
        };

        if (bulkReason) {
          updates['moderation.reason'] = bulkReason;
        }

        if (bulkAction === 'approve') {
          updates.isHidden = false;
        } else if (bulkAction === 'block') {
          updates.isHidden = true;
        }

        batch.update(updateRef, updates);
      });

      await batch.commit();

      toast.success(t('modules.community.groupUpdates.notifications.bulkActionComplete'));
      setShowBulkDialog(false);
      setSelectedIds([]);
      setBulkReason('');
    } catch (error: any) {
      console.error('Error executing bulk action:', error);
      toast.error(error.message || t('modules.community.groupUpdates.notifications.error'));
    } finally {
      setIsProcessingBulk(false);
    }
  };

  // Selection handlers
  const toggleSelection = (id: string) => {
    setSelectedIds(prev =>
      prev.includes(id) ? prev.filter(item => item !== id) : [...prev, id]
    );
  };

  const toggleSelectAll = () => {
    if (selectedIds.length === filteredUpdates.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(filteredUpdates.map((u: GroupUpdate) => u.id));
    }
  };

  if (loading && !updates.length) {
    return (
      <div className="min-h-screen flex flex-col">
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex-1 flex flex-col">
          <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
            <div>
              <h1 className="text-3xl font-bold tracking-tight">{t('modules.community.groupUpdates.title')}</h1>
              <p className="text-muted-foreground">{t('modules.community.groupUpdates.description')}</p>
            </div>
          </div>
          <div className="flex-1 overflow-auto">
            <div className="p-6 space-y-4">
              <Skeleton className="h-32 w-full" />
              <Skeleton className="h-12 w-full" />
              <Skeleton className="h-64 w-full" />
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex flex-col">
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex-1 flex flex-col">
          <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
            <div>
              <h1 className="text-3xl font-bold tracking-tight">{t('modules.community.groupUpdates.title')}</h1>
              <p className="text-muted-foreground">{t('modules.community.groupUpdates.description')}</p>
            </div>
          </div>
          <div className="flex-1 overflow-auto">
            <div className="p-6">
              <Alert variant="destructive">
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  {t('modules.community.groupUpdates.notifications.loadError')}: {error.message}
                </AlertDescription>
              </Alert>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t('modules.community.groupUpdates.title')}</h1>
            <p className="text-muted-foreground">{t('modules.community.groupUpdates.description')}</p>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto">
          <div className="p-6 space-y-6 max-w-none">
            {/* Stats Cards */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-5">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.community.groupUpdates.stats.totalUpdates')}
                  </CardTitle>
                  <FileText className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{globalStats.total}</div>
                  <p className="text-xs text-muted-foreground">{t('modules.community.groupUpdates.stats.allTime')}</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.community.groupUpdates.stats.todaysUpdates')}
                  </CardTitle>
                  <TrendingUp className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{globalStats.today}</div>
                  <p className="text-xs text-muted-foreground">{t('modules.community.groupUpdates.stats.last24Hours')}</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.community.groupUpdates.stats.pendingReview')}
                  </CardTitle>
                  <Clock className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{globalStats.pendingReview}</div>
                  <p className="text-xs text-muted-foreground">{t('modules.community.groupUpdates.stats.requiresActionLabel')}</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.community.groupUpdates.stats.approvedTotal')}
                  </CardTitle>
                  <CheckCircle className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{globalStats.approved}</div>
                  <p className="text-xs text-muted-foreground">{t('modules.community.groupUpdates.stats.allApprovals')}</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.community.groupUpdates.stats.blockedTotal')}
                  </CardTitle>
                  <XCircle className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{globalStats.blocked}</div>
                  <p className="text-xs text-muted-foreground">{t('modules.community.groupUpdates.stats.actionsTaken')}</p>
                </CardContent>
              </Card>
            </div>

            {/* Filters and Tabs */}
            <Card>
              <CardHeader>
                <div className="space-y-4">
                  {/* Tabs */}
                  <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as any)}>
                    <TabsList className="grid w-full grid-cols-4">
                      <TabsTrigger value="all">
                        {t('modules.community.groupUpdates.tabs.all')}
                      </TabsTrigger>
                      <TabsTrigger value="manual_review">
                        {t('modules.community.groupUpdates.tabs.pending')}
                      </TabsTrigger>
                      <TabsTrigger value="approved">
                        {t('modules.community.groupUpdates.tabs.approved')}
                      </TabsTrigger>
                      <TabsTrigger value="blocked">
                        {t('modules.community.groupUpdates.tabs.blocked')}
                      </TabsTrigger>
                    </TabsList>
                  </Tabs>

                  {/* Filters */}
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div className="space-y-2">
                      <label className="text-sm font-medium">{t('common.search')}</label>
                      <div className="relative">
                        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                          placeholder={t('modules.community.groupUpdates.filters.searchPlaceholder')}
                          value={searchTerm}
                          onChange={(e) => setSearchTerm(e.target.value)}
                          className="pl-10"
                        />
                      </div>
                    </div>

                    <div className="space-y-2">
                      <label className="text-sm font-medium">{t('modules.community.groupUpdates.filters.language')}</label>
                      <Select value={languageFilter} onValueChange={(v) => setLanguageFilter(v as any)}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">{t('modules.community.groupUpdates.filters.allLanguages')}</SelectItem>
                          <SelectItem value="en">English</SelectItem>
                          <SelectItem value="ar">العربية</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="space-y-2">
                      <label className="text-sm font-medium">{t('modules.community.groupUpdates.filters.updateType')}</label>
                      <Select value={updateTypeFilter} onValueChange={(v) => setUpdateTypeFilter(v as any)}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">{t('modules.community.groupUpdates.filters.allTypes')}</SelectItem>
                          <SelectItem value="general">{t('modules.community.groupUpdates.updateTypes.general')}</SelectItem>
                          <SelectItem value="achievement">{t('modules.community.groupUpdates.updateTypes.achievement')}</SelectItem>
                          <SelectItem value="milestone">{t('modules.community.groupUpdates.updateTypes.milestone')}</SelectItem>
                          <SelectItem value="support">{t('modules.community.groupUpdates.updateTypes.support')}</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="space-y-2">
                      <label className="text-sm font-medium">{t('modules.community.groupUpdates.filters.violationType')}</label>
                      <Select value={violationTypeFilter} onValueChange={setViolationTypeFilter}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">{t('modules.community.groupUpdates.filters.allViolations')}</SelectItem>
                          <SelectItem value="none">{t('modules.community.groupUpdates.violationTypes.none')}</SelectItem>
                          <SelectItem value="social_media_sharing">{t('modules.community.groupUpdates.violationTypes.social_media_sharing')}</SelectItem>
                          <SelectItem value="sexual_content">{t('modules.community.groupUpdates.violationTypes.sexual_content')}</SelectItem>
                          <SelectItem value="harassment">{t('modules.community.groupUpdates.violationTypes.harassment')}</SelectItem>
                          <SelectItem value="spam">{t('modules.community.groupUpdates.violationTypes.spam')}</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  {selectedIds.length > 0 && (
                    <div className="flex justify-end">
                      <Button onClick={handleBulkAction} variant="outline">
                        {t('modules.community.groupUpdates.bulkActions.title')} ({selectedIds.length})
                      </Button>
                    </div>
                  )}
                </div>
              </CardHeader>

              <CardContent>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="w-12">
                        <Checkbox
                          checked={selectedIds.length === filteredUpdates.length && filteredUpdates.length > 0}
                          onCheckedChange={toggleSelectAll}
                        />
                      </TableHead>
                      <TableHead>{t('modules.community.groupUpdates.table.columns.update')}</TableHead>
                      <TableHead>{t('modules.community.groupUpdates.table.columns.author')}</TableHead>
                      <TableHead>{t('modules.community.groupUpdates.table.columns.type')}</TableHead>
                      <TableHead>{t('modules.community.groupUpdates.table.columns.language')}</TableHead>
                      <TableHead>{t('modules.community.groupUpdates.table.columns.status')}</TableHead>
                      <TableHead>{t('modules.community.groupUpdates.table.columns.confidence')}</TableHead>
                      <TableHead>{t('modules.community.groupUpdates.table.columns.createdAt')}</TableHead>
                      <TableHead>{t('modules.community.groupUpdates.table.columns.actions')}</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredUpdates.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={9} className="text-center text-muted-foreground py-8">
                          {t('modules.community.groupUpdates.table.emptyState')}
                        </TableCell>
                      </TableRow>
                    ) : (
                      filteredUpdates.map((update: GroupUpdate) => (
                        <TableRow key={update.id}>
                          <TableCell>
                            <Checkbox
                              checked={selectedIds.includes(update.id)}
                              onCheckedChange={() => toggleSelection(update.id)}
                            />
                          </TableCell>
                          <TableCell>
                            <div className="max-w-md">
                              <div className="font-medium truncate">{update.title}</div>
                              <div className="text-sm text-muted-foreground truncate">{update.content?.substring(0, 60)}...</div>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="text-sm">
                              {update.isAnonymous ? 'Anonymous' : update.authorCpId?.substring(0, 8)}
                            </div>
                          </TableCell>
                          <TableCell>
                            <UpdateTypeBadge type={update.type} />
                          </TableCell>
                          <TableCell>
                            <Badge variant="outline">{update.locale === 'ar' ? 'العربية' : 'English'}</Badge>
                          </TableCell>
                          <TableCell>
                            <StatusBadge status={update.moderation?.status || 'pending'} />
                          </TableCell>
                          <TableCell>
                            {update.moderation?.ai?.confidence ? (
                              <div className="space-y-1">
                                <Progress value={update.moderation.ai.confidence * 100} className="h-2" />
                                <div className="text-xs text-muted-foreground">
                                  {Math.round(update.moderation.ai.confidence * 100)}%
                                </div>
                              </div>
                            ) : (
                              <span className="text-muted-foreground text-sm">N/A</span>
                            )}
                          </TableCell>
                          <TableCell>
                            <div className="text-sm text-muted-foreground">
                              {update.createdAt ? format(update.createdAt.toDate(), 'PPp') : 'N/A'}
                            </div>
                          </TableCell>
                          <TableCell>
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => handleViewUpdate(update)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>

            {/* Pagination Controls */}
            <Card>
              <CardContent className="py-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-muted-foreground">
                        {t('modules.community.groupUpdates.pagination.itemsPerPage')}:
                      </span>
                      <Select value={pageSize.toString()} onValueChange={handlePageSizeChange}>
                        <SelectTrigger className="w-20">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="10">10</SelectItem>
                          <SelectItem value="20">20</SelectItem>
                          <SelectItem value="50">50</SelectItem>
                          <SelectItem value="100">100</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="text-sm text-muted-foreground">
                      {t('modules.community.groupUpdates.pagination.showing')} {(currentPage - 1) * pageSize + 1}{' '}
                      {t('modules.community.groupUpdates.pagination.to')} {Math.min(currentPage * pageSize, totalCount)}{' '}
                      {t('modules.community.groupUpdates.pagination.of')} {totalCount}{' '}
                      {t('modules.community.groupUpdates.pagination.items')}
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handlePreviousPage}
                      disabled={currentPage === 1 || loading}
                    >
                      <ChevronLeft className="h-4 w-4 mr-1" />
                      {t('modules.community.groupUpdates.pagination.previous')}
                    </Button>

                    <div className="text-sm font-medium">
                      {t('modules.community.groupUpdates.pagination.page')} {currentPage}
                    </div>

                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handleNextPage}
                      disabled={!hasNextPage || loading}
                    >
                      {t('modules.community.groupUpdates.pagination.next')}
                      <ChevronRight className="h-4 w-4 ml-1" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Detail Sheet */}
            <Sheet open={showDetailSheet} onOpenChange={setShowDetailSheet}>
              <SheetContent className="w-full sm:max-w-2xl overflow-y-auto">
                {selectedUpdate && (
              <>
                <SheetHeader>
                  <SheetTitle>{t('modules.community.groupUpdates.detailSheet.title')}</SheetTitle>
                  <SheetDescription>
                    {format(selectedUpdate.createdAt.toDate(), 'PPpp')}
                  </SheetDescription>
                </SheetHeader>

                <div className="space-y-6 py-6">
                  {/* Update Content */}
                  <div className="space-y-4">
                    <h3 className="font-semibold">{t('modules.community.groupUpdates.detailSheet.sections.content')}</h3>
                    <div className="space-y-2">
                      <div>
                        <Label className="text-xs text-muted-foreground">
                          {t('modules.community.groupUpdates.detailSheet.content.title')}
                        </Label>
                        <p className="font-medium">{selectedUpdate.title}</p>
                      </div>
                      <div>
                        <Label className="text-xs text-muted-foreground">
                          {t('modules.community.groupUpdates.detailSheet.content.body')}
                        </Label>
                        <p className="whitespace-pre-wrap">{selectedUpdate.content}</p>
                      </div>
                      <div className="flex gap-2">
                        <UpdateTypeBadge type={selectedUpdate.type} />
                        <Badge variant="outline">{selectedUpdate.locale === 'ar' ? 'العربية' : 'English'}</Badge>
                        {selectedUpdate.isAnonymous && (
                          <Badge variant="secondary">
                            {t('modules.community.groupUpdates.detailSheet.content.anonymous')}
                          </Badge>
                        )}
                      </div>
                    </div>
                  </div>

                  <Separator />

                  {/* AI Analysis */}
                  {selectedUpdate.moderation?.ai && (
                    <>
                      <div className="space-y-4">
                        <h3 className="font-semibold">{t('modules.community.groupUpdates.detailSheet.sections.aiAnalysis')}</h3>
                        <div className="space-y-2">
                          <div>
                            <Label className="text-xs text-muted-foreground">
                              {t('modules.community.groupUpdates.detailSheet.aiAnalysis.confidence')}
                            </Label>
                            <div className="flex items-center gap-2">
                              <Progress value={selectedUpdate.moderation.ai.confidence * 100} className="h-2 flex-1" />
                              <span className="text-sm font-medium">
                                {Math.round(selectedUpdate.moderation.ai.confidence * 100)}%
                              </span>
                            </div>
                          </div>
                          {selectedUpdate.moderation.ai.violationType && (
                            <div>
                              <Label className="text-xs text-muted-foreground">
                                {t('modules.community.groupUpdates.detailSheet.aiAnalysis.violationType')}
                              </Label>
                              <p>{selectedUpdate.moderation.ai.violationType}</p>
                            </div>
                          )}
                          {selectedUpdate.moderation.ai.severity && (
                            <div>
                              <Label className="text-xs text-muted-foreground">
                                {t('modules.community.groupUpdates.detailSheet.aiAnalysis.severity')}
                              </Label>
                              <div>
                                <SeverityBadge severity={selectedUpdate.moderation.ai.severity} />
                              </div>
                            </div>
                          )}
                          {selectedUpdate.moderation.ai.reason && (
                            <div>
                              <Label className="text-xs text-muted-foreground">
                                {t('modules.community.groupUpdates.detailSheet.aiAnalysis.reason')}
                              </Label>
                              <p className="text-sm">{selectedUpdate.moderation.ai.reason}</p>
                            </div>
                          )}
                          {selectedUpdate.moderation.ai.detectedContent && selectedUpdate.moderation.ai.detectedContent.length > 0 && (
                            <div>
                              <Label className="text-xs text-muted-foreground">
                                {t('modules.community.groupUpdates.detailSheet.aiAnalysis.detectedContent')}
                              </Label>
                              <ul className="list-disc list-inside text-sm space-y-1">
                                {selectedUpdate.moderation.ai.detectedContent.map((content, idx) => (
                                  <li key={idx}>{content}</li>
                                ))}
                              </ul>
                            </div>
                          )}
                        </div>
                      </div>
                      <Separator />
                    </>
                  )}

                  {/* Admin Action Panel */}
                  <div className="space-y-4">
                    <h3 className="font-semibold">{t('modules.community.groupUpdates.detailSheet.sections.adminAction')}</h3>
                    <RadioGroup value={moderationAction} onValueChange={(v) => setModerationAction(v as any)}>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="approve" id="approve" />
                        <Label htmlFor="approve" className="cursor-pointer">
                          ✅ {t('modules.community.groupUpdates.detailSheet.actions.approve')}
                        </Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="block" id="block" />
                        <Label htmlFor="block" className="cursor-pointer">
                          🚫 {t('modules.community.groupUpdates.detailSheet.actions.block')}
                        </Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="keep_under_review" id="keep_under_review" />
                        <Label htmlFor="keep_under_review" className="cursor-pointer">
                          ⚠️ {t('modules.community.groupUpdates.detailSheet.actions.keepUnderReview')}
                        </Label>
                      </div>
                    </RadioGroup>

                    <div className="space-y-2">
                      <Label htmlFor="reason">{t('modules.community.groupUpdates.detailSheet.actions.reason')}</Label>
                      <Textarea
                        id="reason"
                        placeholder={t('modules.community.groupUpdates.detailSheet.actions.reasonPlaceholder')}
                        value={moderationReason}
                        onChange={(e) => setModerationReason(e.target.value)}
                        rows={3}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="notes">{t('modules.community.groupUpdates.detailSheet.actions.notes')}</Label>
                      <Textarea
                        id="notes"
                        placeholder={t('modules.community.groupUpdates.detailSheet.actions.notesPlaceholder')}
                        value={moderationNotes}
                        onChange={(e) => setModerationNotes(e.target.value)}
                        rows={3}
                      />
                    </div>

                    <div className="flex gap-2">
                      <Button onClick={handleSubmitModeration} disabled={isSubmitting} className="flex-1">
                        {isSubmitting ? (
                          <>
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            {t('modules.community.groupUpdates.detailSheet.actions.submitting')}
                          </>
                        ) : (
                          t('modules.community.groupUpdates.detailSheet.actions.submit')
                        )}
                      </Button>
                      <Button
                        variant="outline"
                        onClick={() => setShowDetailSheet(false)}
                        disabled={isSubmitting}
                      >
                        {t('modules.community.groupUpdates.detailSheet.actions.cancel')}
                      </Button>
                    </div>
                  </div>
                </div>
              </>
            )}
          </SheetContent>
            </Sheet>

            {/* Bulk Action Dialog */}
            <Dialog open={showBulkDialog} onOpenChange={setShowBulkDialog}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>{t('modules.community.groupUpdates.bulkActions.confirmTitle')}</DialogTitle>
              <DialogDescription>
                {t('modules.community.groupUpdates.bulkActions.selected').replace('{count}', selectedIds.length.toString())}
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4">
              <div className="space-y-2">
                <Label>{t('modules.community.groupUpdates.detailSheet.actions.reason')}</Label>
                <Select value={bulkAction} onValueChange={(v) => setBulkAction(v as any)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="approve">{t('modules.community.groupUpdates.bulkActions.approve')}</SelectItem>
                    <SelectItem value="block">{t('modules.community.groupUpdates.bulkActions.block')}</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>{t('modules.community.groupUpdates.bulkActions.reason')}</Label>
                <Textarea
                  placeholder={t('modules.community.groupUpdates.bulkActions.reasonPlaceholder')}
                  value={bulkReason}
                  onChange={(e) => setBulkReason(e.target.value)}
                  rows={3}
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setShowBulkDialog(false)} disabled={isProcessingBulk}>
                {t('modules.community.groupUpdates.detailSheet.actions.cancel')}
              </Button>
              <Button onClick={executeBulkAction} disabled={isProcessingBulk}>
                {isProcessingBulk ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    {t('modules.community.groupUpdates.detailSheet.actions.submitting')}
                  </>
                ) : (
                  t('modules.community.groupUpdates.detailSheet.actions.submit')
                )}
              </Button>
            </DialogFooter>
          </DialogContent>
            </Dialog>
          </div>
        </div>
      </div>
    </div>
  );
}

