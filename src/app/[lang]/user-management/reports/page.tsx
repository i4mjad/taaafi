'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from "@/contexts/TranslationContext";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Search,
  Filter,
  Download,
  MoreHorizontal,
  Eye,
  Edit,
  FileText,
  AlertCircle,
  CheckCircle,
  Clock,
  XCircle,
  Copy,
  ExternalLink,
  BarChart3,
  Settings,
  Trash2,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
} from 'lucide-react';

// Import the report types management component
import ReportTypesManagement from './components/ReportTypesManagement';
import Link from 'next/link';
import { toast } from 'sonner';

// Firebase imports - using react-firebase-hooks
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where, Timestamp, deleteDoc, doc, limit, startAfter, getDocs, QueryDocumentSnapshot, DocumentData } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';

interface UserReport {
  id: string;
  uid: string;
  time: Timestamp;
  reportTypeId: string;
  status: 'pending' | 'inProgress' | 'waitingForAdminResponse' | 'closed' | 'finalized';
  initialMessage: string;
  lastUpdated: Timestamp;
  messagesCount: number;
}

interface ReportMessage {
  id: string;
  reportId: string;
  senderId: string;
  senderRole: 'user' | 'admin';
  message: string;
  timestamp: Timestamp;
  isRead: boolean;
}

export default function UserReportsPage() {
  const { t, locale } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [dateRangeFilter, setDateRangeFilter] = useState<string>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  
  // Pagination state for Firestore
  const [lastVisible, setLastVisible] = useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [firstVisible, setFirstVisible] = useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [pageCache, setPageCache] = useState<Map<number, {
    docs: QueryDocumentSnapshot<DocumentData>[],
    lastDoc: QueryDocumentSnapshot<DocumentData> | null,
    firstDoc: QueryDocumentSnapshot<DocumentData> | null
  }>>(new Map());
  const [totalCount, setTotalCount] = useState<number>(0);
  const [isLoadingPage, setIsLoadingPage] = useState(false);

  // Delete dialog state
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [reportToDelete, setReportToDelete] = useState<UserReport | null>(null);

  // Custom state for paginated data fetching
  const [allReports, setAllReports] = useState<UserReport[]>([]);
  const [reportsLoading, setReportsLoading] = useState(true);
  const [reportsError, setReportsError] = useState<Error | null>(null);

  // Fetch report types for dynamic display
  const [reportTypesSnapshot, reportTypesLoading] = useCollection(
    query(
      collection(db, 'reportTypes'),
      orderBy('updatedAt', 'desc')
    )
  );

  // Build Firestore query based on filters
  const buildQuery = () => {
    let q = query(
      collection(db, 'usersReports'),
      orderBy('time', 'desc'),
      limit(itemsPerPage)
    );

    // Add status filter if not 'all'
    if (statusFilter !== 'all') {
      q = query(
        collection(db, 'usersReports'),
        where('status', '==', statusFilter),
        orderBy('time', 'desc'),
        limit(itemsPerPage)
      );
    }

    // For pagination, add startAfter if we have a cursor
    if (currentPage > 1 && lastVisible) {
      const cachedPage = pageCache.get(currentPage - 1);
      if (cachedPage?.lastDoc) {
        if (statusFilter !== 'all') {
          q = query(
            collection(db, 'usersReports'),
            where('status', '==', statusFilter),
            orderBy('time', 'desc'),
            startAfter(cachedPage.lastDoc),
            limit(itemsPerPage)
          );
        } else {
          q = query(
            collection(db, 'usersReports'),
            orderBy('time', 'desc'),
            startAfter(cachedPage.lastDoc),
            limit(itemsPerPage)
          );
        }
      }
    }

    return q;
  };

  // Fetch reports with pagination
  const fetchReports = async (page: number, reset: boolean = false) => {
    if (reset) {
      setPageCache(new Map());
      setCurrentPage(1);
      page = 1;
    }

    setIsLoadingPage(true);
    setReportsError(null);

    try {
      // Check if page is already cached
      const cachedPage = pageCache.get(page);
      if (cachedPage && !reset) {
        const reports = cachedPage.docs.map(doc => ({
          id: doc.id,
          uid: doc.data().uid || '',
          time: doc.data().time || Timestamp.now(),
          reportTypeId: doc.data().reportTypeId || doc.data().reportType || 'dataError',
          status: doc.data().status || 'pending',
          initialMessage: doc.data().initialMessage || doc.data().userJustification || '',
          lastUpdated: doc.data().lastUpdated || doc.data().time || Timestamp.now(),
          messagesCount: doc.data().messagesCount || 1,
        }));
        setAllReports(reports);
        setIsLoadingPage(false);
        return;
      }

      const q = buildQuery();
      const snapshot = await getDocs(q);
      
      const reports: UserReport[] = snapshot.docs.map(doc => ({
        id: doc.id,
        uid: doc.data().uid || '',
        time: doc.data().time || Timestamp.now(),
        reportTypeId: doc.data().reportTypeId || doc.data().reportType || 'dataError',
        status: doc.data().status || 'pending',
        initialMessage: doc.data().initialMessage || doc.data().userJustification || '',
        lastUpdated: doc.data().lastUpdated || doc.data().time || Timestamp.now(),
        messagesCount: doc.data().messagesCount || 1,
      }));

      // Cache the page
      const newPageCache = new Map(pageCache);
      newPageCache.set(page, {
        docs: snapshot.docs,
        lastDoc: snapshot.docs[snapshot.docs.length - 1] || null,
        firstDoc: snapshot.docs[0] || null
      });
      setPageCache(newPageCache);

      if (snapshot.docs.length > 0) {
        setLastVisible(snapshot.docs[snapshot.docs.length - 1]);
        setFirstVisible(snapshot.docs[0]);
      }

      setAllReports(reports);
      
      // Get total count for the first page or when filters change
      if (page === 1 || reset) {
        const countQuery = statusFilter !== 'all' 
          ? query(collection(db, 'usersReports'), where('status', '==', statusFilter))
          : query(collection(db, 'usersReports'));
        const countSnapshot = await getDocs(countQuery);
        setTotalCount(countSnapshot.size);
      }
      
    } catch (error) {
      console.error('Error fetching reports:', error);
      setReportsError(error as Error);
    } finally {
      setIsLoadingPage(false);
      setReportsLoading(false);
    }
  };

  // Effect to fetch reports when page, filters, or itemsPerPage changes
  useEffect(() => {
    const shouldReset = currentPage === 1;
    fetchReports(currentPage, shouldReset);
  }, [currentPage, statusFilter, itemsPerPage]);

  // Reset to first page when filters change
  useEffect(() => {
    if (currentPage !== 1) {
      setCurrentPage(1);
    } else {
      fetchReports(1, true);
    }
  }, [statusFilter, dateRangeFilter]);

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
      return t('modules.userManagement.reports.reportTypeDataError') || 'Unknown Type';
    }
    return locale === 'ar' ? reportType.nameAr : reportType.nameEn;
  };

  // Filter reports based on search and date range (client-side for current page)
  const filteredReports = useMemo(() => {
    let filtered = allReports;

    // Search filter (client-side on current page)
    if (searchQuery.trim()) {
      filtered = filtered.filter(report => 
        report.uid.toLowerCase().includes(searchQuery.toLowerCase()) ||
        report.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
        report.initialMessage.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    // Date range filter (client-side on current page)
    if (dateRangeFilter !== 'all') {
      const now = new Date();
      let startDate: Date;

      switch (dateRangeFilter) {
        case 'today':
          startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
          break;
        case 'week':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case 'month':
          startDate = new Date(now.getFullYear(), now.getMonth(), 1);
          break;
        default:
          startDate = new Date(0);
      }

      filtered = filtered.filter(report => 
        report.time.toDate() >= startDate
      );
    }

    return filtered;
  }, [allReports, searchQuery, dateRangeFilter]);

  // Calculate stats (needs to be updated for server-side pagination)
  const stats = useMemo(() => {
    // For now, show stats based on total count and current page
    // In a real implementation, you might want to fetch these separately
    const currentPageTotal = allReports.length;
    const pending = allReports.filter(r => r.status === 'pending').length;
    const inProgress = allReports.filter(r => r.status === 'inProgress').length;
    const waitingForAdmin = allReports.filter(r => r.status === 'waitingForAdminResponse').length;
    const closed = allReports.filter(r => r.status === 'closed').length;
    const finalized = allReports.filter(r => r.status === 'finalized').length;

    return {
      total: totalCount,
      pending,
      inProgress,
      waitingForAdmin,
      closed,
      finalized,
      averageResponseTime: 0, // Would need separate calculation
    };
  }, [allReports, totalCount]);

  // Calculate pagination info
  const totalPages = Math.ceil(totalCount / itemsPerPage);
  const hasNextPage = currentPage < totalPages;
  const hasPrevPage = currentPage > 1;

  // Handle page changes
  const handlePageChange = (newPage: number) => {
    if (newPage >= 1 && newPage <= totalPages && newPage !== currentPage) {
      setCurrentPage(newPage);
    }
  };

  const handleItemsPerPageChange = (newItemsPerPage: number) => {
    setItemsPerPage(newItemsPerPage);
    setCurrentPage(1);
    setPageCache(new Map()); // Clear cache when page size changes
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

  const formatDate = (timestamp: Timestamp) => {
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(timestamp.toDate());
  };

  const truncateText = (text: string, maxLength: number = 50) => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  const copyToClipboard = async (text: string, label: string) => {
    try {
      await navigator.clipboard.writeText(text);
      toast.success(`${label} ${t('modules.userManagement.reports.reportDetails.reportIdCopied') || 'copied to clipboard'}`);
    } catch (error) {
      toast.error('Failed to copy to clipboard');
    }
  };

  const exportReports = (format: 'csv' | 'excel') => {
    // Implementation for export functionality
    toast.info(`${format.toUpperCase()} export feature coming soon`);
  };

  // Handle report deletion
  const handleDeleteReport = async () => {
    if (!reportToDelete) return;
    try {
      await deleteDoc(doc(db, 'usersReports', reportToDelete.id));
      toast.success(t('modules.userManagement.reports.deleteSuccess') || 'Report deleted successfully');
    } catch (error) {
      toast.error(t('modules.userManagement.reports.deleteError') || 'Failed to delete report');
    } finally {
      setDeleteDialogOpen(false);
      setReportToDelete(null);
    }
  };

  const headerDictionary = {
    documents: t('appSidebar.reports') || 'Reports',
  };

  if (reportsError) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex flex-1 flex-col">
          <div className="@container/main flex flex-1 flex-col gap-2">
            <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
              <div className="text-center py-8">
                <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
                <h1 className="text-2xl font-bold">
                  {t('modules.userManagement.reports.errors.loadingFailed') || 'Failed to load reports'}
                </h1>
                <p className="text-muted-foreground mt-2">
                  {reportsError.message}
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
              <div>
                <h1 className="text-3xl font-bold tracking-tight">
                  {t('modules.userManagement.reports.title') || 'User Reports'}
                </h1>
                <p className="text-muted-foreground">
                  {t('modules.userManagement.reports.description') || 'Review and manage user-submitted data error reports'}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <ReportTypesManagement 
                  trigger={
                    <Button variant="outline">
                      <Settings className="h-4 w-4 mr-2" />
                      {t('modules.userManagement.reports.manageReportTypes') || 'Manage Report Types'}
                    </Button>
                  }
                />
                <Button variant="outline" onClick={() => exportReports('csv')}>
                  <Download className="h-4 w-4 mr-2" />
                  {t('modules.userManagement.reports.exportCsv') || 'Export CSV'}
                </Button>
                <Button asChild>
                  <Link href={`/${locale}/user-management/reports/analytics`}>
                    <BarChart3 className="h-4 w-4 mr-2" />
                    {t('modules.userManagement.reports.analytics.title') || 'Analytics'}
                  </Link>
                </Button>
              </div>
            </div>

            {/* Stats Cards */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-6">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.totalReports') || 'Total Reports'}
                  </CardTitle>
                  <FileText className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.total}</div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.pendingReports') || 'Pending Reports'}
                  </CardTitle>
                  <Clock className="h-4 w-4 text-yellow-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.pending}</div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.statusWaitingForAdminResponse') || 'Waiting for Admin'}
                  </CardTitle>
                  <AlertCircle className="h-4 w-4 text-orange-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.waitingForAdmin}</div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.closedReports') || 'Closed Reports'}
                  </CardTitle>
                  <CheckCircle className="h-4 w-4 text-green-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.closed}</div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.finalizedReports') || 'Finalized Reports'}
                  </CardTitle>
                  <XCircle className="h-4 w-4 text-gray-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.finalized}</div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.averageResponseTime') || 'Average Response Time'}
                  </CardTitle>
                  <BarChart3 className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">
                    {stats.averageResponseTime}{' '}
                    <span className="text-sm font-normal text-muted-foreground">
                      {t('modules.userManagement.reports.analytics.averageResponseHours') || 'hours'}
                    </span>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Filters */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Filter className="h-5 w-5" />
                  {t('common.search') || 'Search & Filters'}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex flex-col gap-4 md:flex-row md:items-end">
                  <div className="flex-1">
                    <Input
                      placeholder={t('modules.userManagement.reports.searchPlaceholder') || 'Search by User ID...'}
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="w-full"
                    />
                  </div>
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder={t('modules.userManagement.reports.filterByStatus') || 'Filter by Status'} />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">{t('modules.userManagement.reports.statusAll') || 'All'}</SelectItem>
                      <SelectItem value="pending">{t('modules.userManagement.reports.statusPending') || 'Pending'}</SelectItem>
                      <SelectItem value="inProgress">{t('modules.userManagement.reports.statusInProgress') || 'In Progress'}</SelectItem>
                      <SelectItem value="waitingForAdminResponse">{t('modules.userManagement.reports.statusWaitingForAdminResponse') || 'Waiting for Admin Response'}</SelectItem>
                      <SelectItem value="closed">{t('modules.userManagement.reports.statusClosed') || 'Closed'}</SelectItem>
                      <SelectItem value="finalized">{t('modules.userManagement.reports.statusFinalized') || 'Finalized'}</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select value={dateRangeFilter} onValueChange={setDateRangeFilter}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder={t('modules.userManagement.reports.filterByDateRange') || 'Filter by Date Range'} />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">{t('modules.userManagement.reports.statusAll') || 'All Time'}</SelectItem>
                      <SelectItem value="today">{t('modules.userManagement.reports.analytics.today') || 'Today'}</SelectItem>
                      <SelectItem value="week">{t('modules.userManagement.reports.analytics.last7Days') || 'Last 7 Days'}</SelectItem>
                      <SelectItem value="month">{t('modules.userManagement.reports.analytics.thisMonth') || 'This Month'}</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>

            {/* Reports Table */}
            <Card>
              <CardHeader>
                <CardTitle>{t('modules.userManagement.reports.title') || 'User Reports'}</CardTitle>
                <CardDescription>
                  {filteredReports.length > 0 
                    ? `${filteredReports.length} ${filteredReports.length === 1 ? 'report' : 'reports'} found`
                    : t('modules.userManagement.reports.noReportsFound') || 'No reports found'
                  }
                </CardDescription>
              </CardHeader>
              <CardContent>
                {reportsLoading ? (
                  <div className="space-y-3">
                    {[...Array(5)].map((_, i) => (
                      <Skeleton key={i} className="h-16 w-full" />
                    ))}
                  </div>
                ) : filteredReports.length === 0 ? (
                  <div className="text-center py-8">
                    <FileText className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                    <h3 className="text-lg font-semibold mb-2">
                      {t('modules.userManagement.reports.noReportsFound') || 'No reports found'}
                    </h3>
                    <p className="text-muted-foreground">
                      {searchQuery || statusFilter !== 'all' || dateRangeFilter !== 'all'
                        ? 'Try adjusting your search criteria or filters.'
                        : 'No user reports have been submitted yet.'
                      }
                    </p>
                  </div>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>{t('modules.userManagement.reports.reportId') || 'Report ID'}</TableHead>
                        <TableHead>{t('modules.userManagement.reports.userId') || 'User ID'}</TableHead>
                        <TableHead>{t('modules.userManagement.reports.reportType') || 'Report Type'}</TableHead>
                        <TableHead>{t('modules.userManagement.reports.status') || 'Status'}</TableHead>
                        <TableHead>{t('modules.userManagement.reports.submittedDate') || 'Submitted Date'}</TableHead>
                        <TableHead>{t('modules.userManagement.reports.initialMessage') || 'Initial Message'}</TableHead>
                        <TableHead>{t('modules.userManagement.reports.messagesCount') || 'Messages'}</TableHead>
                        <TableHead className="text-right">{t('modules.userManagement.reports.actions') || 'Actions'}</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {isLoadingPage ? (
                        // Show loading skeletons during page transitions
                        [...Array(itemsPerPage)].map((_, i) => (
                          <TableRow key={i}>
                            <TableCell><Skeleton className="h-4 w-24" /></TableCell>
                            <TableCell><Skeleton className="h-4 w-20" /></TableCell>
                            <TableCell><Skeleton className="h-4 w-16" /></TableCell>
                            <TableCell><Skeleton className="h-4 w-16" /></TableCell>
                            <TableCell><Skeleton className="h-4 w-32" /></TableCell>
                            <TableCell><Skeleton className="h-4 w-40" /></TableCell>
                            <TableCell><Skeleton className="h-4 w-12" /></TableCell>
                            <TableCell><Skeleton className="h-4 w-16" /></TableCell>
                          </TableRow>
                        ))
                      ) : (
                        filteredReports.map((report) => (
                          <TableRow key={report.id}>
                          <TableCell>
                            <div className="flex items-center gap-2">
                              <span className="font-mono text-sm max-w-[120px] truncate">
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
                          </TableCell>
                          <TableCell>
                            <Link 
                              href={`/${locale}/user-management/users/${report.uid}`}
                              className="text-blue-600 hover:underline font-mono text-sm"
                            >
                              {truncateText(report.uid, 12)}
                              <ExternalLink className="h-3 w-3 inline ml-1" />
                            </Link>
                          </TableCell>
                          <TableCell>
                            <Badge variant="outline">
                              {getReportTypeName(report.reportTypeId)}
                            </Badge>
                          </TableCell>
                          <TableCell>{getStatusBadge(report.status)}</TableCell>
                          <TableCell>{formatDate(report.time)}</TableCell>
                          <TableCell>
                            <span className="max-w-[200px] truncate block" title={report.initialMessage}>
                              {truncateText(report.initialMessage, 60)}
                            </span>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-1">
                              <span className="text-sm">{report.messagesCount}</span>
                              <FileText className="h-3 w-3 text-muted-foreground" />
                            </div>
                          </TableCell>
                          <TableCell className="text-right">
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" className="h-8 w-8 p-0">
                                  <MoreHorizontal className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                <DropdownMenuItem asChild>
                                  <Link href={`/${locale}/user-management/reports/${report.id}`}>
                                    <Eye className="h-4 w-4 mr-2" />
                                    {t('modules.userManagement.reports.viewDetails') || 'View Details'}
                                  </Link>
                                </DropdownMenuItem>
                                <DropdownMenuSeparator />
                                <DropdownMenuItem asChild>
                                  <Link href={`/${locale}/user-management/users/${report.uid}`}>
                                    <ExternalLink className="h-4 w-4 mr-2" />
                                    {t('modules.userManagement.reports.reportDetails.viewUserProfile') || 'View User Profile'}
                                  </Link>
                                </DropdownMenuItem>
                                <DropdownMenuSeparator />
                                <DropdownMenuItem
                                  onClick={() => {
                                    setReportToDelete(report);
                                    setDeleteDialogOpen(true);
                                  }}
                                  className="text-red-600"
                                >
                                  <Trash2 className="h-4 w-4 mr-2" />
                                  {t('common.delete') || 'Delete'}
                                </DropdownMenuItem>
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </TableCell>
                        </TableRow>
                        ))
                      )}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>

            {/* Pagination Controls */}
            {!reportsLoading && totalCount > 0 && (
              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-center justify-between">
                    <div className="text-sm text-muted-foreground">
                      {t('modules.userManagement.reports.showing')} {((currentPage - 1) * itemsPerPage) + 1} - {Math.min(currentPage * itemsPerPage, totalCount)} {t('modules.userManagement.reports.of')} {totalCount}
                    </div>
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handlePageChange(1)}
                        disabled={!hasPrevPage || isLoadingPage}
                      >
                        <ChevronsLeft className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handlePageChange(currentPage - 1)}
                        disabled={!hasPrevPage || isLoadingPage}
                      >
                        <ChevronLeft className="h-4 w-4" />
                      </Button>
                      <span className="text-sm font-medium px-2">
                        {t('modules.userManagement.reports.page')} {currentPage} {t('modules.userManagement.reports.of')} {totalPages}
                      </span>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handlePageChange(currentPage + 1)}
                        disabled={!hasNextPage || isLoadingPage}
                      >
                        <ChevronRight className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handlePageChange(totalPages)}
                        disabled={!hasNextPage || isLoadingPage}
                      >
                        <ChevronsRight className="h-4 w-4" />
                      </Button>
                    </div>
                    <Select 
                      value={itemsPerPage.toString()} 
                      onValueChange={(value) => handleItemsPerPageChange(Number(value))}
                      disabled={isLoadingPage}
                    >
                      <SelectTrigger className="w-[100px]">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="10">10</SelectItem>
                        <SelectItem value="20">20</SelectItem>
                        <SelectItem value="50">50</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </div>

      {/* Delete Report Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.userManagement.reports.deleteTitle') || 'Delete Report'}</DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.reports.deleteDescription') || 'Are you sure you want to delete this report? This action cannot be undone.'}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button variant="destructive" onClick={handleDeleteReport}>
              {t('common.delete') || 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
} 