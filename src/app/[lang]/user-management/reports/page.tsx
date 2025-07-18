'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from "@/contexts/TranslationContext";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
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
  CheckSquare,
  Square,
  RotateCw,
  Shield,
  User,
} from 'lucide-react';

// Import the report types management component
import ReportTypesManagement from './components/ReportTypesManagement';
import Link from 'next/link';
import { toast } from 'sonner';

// Firebase imports - using react-firebase-hooks
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where, Timestamp, deleteDoc, doc, limit, startAfter, getDocs, QueryDocumentSnapshot, DocumentData, updateDoc, writeBatch } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';

// Import notification payload utilities
import { createReportUpdatePayload } from '@/utils/notificationPayloads';

interface UserReport {
  id: string;
  uid: string;
  time: Timestamp;
  reportTypeId: string;
  status: 'pending' | 'inProgress' | 'waitingForAdminResponse' | 'closed' | 'finalized';
  initialMessage: string;
  lastUpdated: Timestamp;
  messagesCount: number;
  lastMessageFrom?: 'user' | 'admin';
  lastMessageTime?: Timestamp;
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
  
  // Bulk update state
  const [selectedReports, setSelectedReports] = useState<Set<string>>(new Set());
  const [bulkUpdateStatus, setBulkUpdateStatus] = useState<string>('');
  const [isBulkUpdating, setIsBulkUpdating] = useState(false);
  const [bulkUpdateDialogOpen, setBulkUpdateDialogOpen] = useState(false);
  
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
  const [lastMessagesLoading, setLastMessagesLoading] = useState(false);
  
  // Status counts state
  const [statusCounts, setStatusCounts] = useState({
    total: 0,
    pending: 0,
    inProgress: 0,
    waitingForAdmin: 0,
    closed: 0,
    finalized: 0
  });
  const [statusCountsLoading, setStatusCountsLoading] = useState(true);

  // Fetch report types for dynamic display
  const [reportTypesSnapshot, reportTypesLoading] = useCollection(
    query(
      collection(db, 'reportTypes'),
      orderBy('updatedAt', 'desc')
    )
  );

  // Function to fetch actual status counts from database
  const fetchStatusCounts = async () => {
    setStatusCountsLoading(true);
    try {
      // Fetch total count
      const totalQuery = query(collection(db, 'usersReports'));
      const totalSnapshot = await getDocs(totalQuery);
      const total = totalSnapshot.size;

      // Fetch counts for each status
      const statusQueries = [
        { status: 'pending', query: query(collection(db, 'usersReports'), where('status', '==', 'pending')) },
        { status: 'inProgress', query: query(collection(db, 'usersReports'), where('status', '==', 'inProgress')) },
        { status: 'waitingForAdminResponse', query: query(collection(db, 'usersReports'), where('status', '==', 'waitingForAdminResponse')) },
        { status: 'closed', query: query(collection(db, 'usersReports'), where('status', '==', 'closed')) },
        { status: 'finalized', query: query(collection(db, 'usersReports'), where('status', '==', 'finalized')) },
      ];

      const statusResults = await Promise.all(
        statusQueries.map(async ({ status, query: statusQuery }) => {
          const snapshot = await getDocs(statusQuery);
          return { status, count: snapshot.size };
        })
      );

      // Build status counts object
      const newStatusCounts = {
        total,
        pending: 0,
        inProgress: 0,
        waitingForAdmin: 0,
        closed: 0,
        finalized: 0
      };

      statusResults.forEach(({ status, count }) => {
        switch (status) {
          case 'pending':
            newStatusCounts.pending = count;
            break;
          case 'inProgress':
            newStatusCounts.inProgress = count;
            break;
          case 'waitingForAdminResponse':
            newStatusCounts.waitingForAdmin = count;
            break;
          case 'closed':
            newStatusCounts.closed = count;
            break;
          case 'finalized':
            newStatusCounts.finalized = count;
            break;
        }
      });

      setStatusCounts(newStatusCounts);
      setTotalCount(total); // Update the existing totalCount state as well
    } catch (error) {
      console.error('Error fetching status counts:', error);
    } finally {
      setStatusCountsLoading(false);
    }
  };

  // Function to fetch last message information for reports
  const fetchLastMessagesForReports = async (reports: UserReport[]): Promise<UserReport[]> => {
    if (reports.length === 0) return reports;
    
    setLastMessagesLoading(true);
    try {
      const reportsWithLastMessages = await Promise.all(
        reports.map(async (report) => {
          try {
            // Fetch the last message from the conversation
            const lastMessageQuery = query(
              collection(db, 'usersReports', report.id, 'messages'),
              orderBy('timestamp', 'desc'),
              limit(1)
            );
            
            const lastMessageSnapshot = await getDocs(lastMessageQuery);
            
            if (!lastMessageSnapshot.empty) {
              const lastMessageDoc = lastMessageSnapshot.docs[0];
              const lastMessageData = lastMessageDoc.data();
              
              return {
                ...report,
                lastMessageFrom: lastMessageData.senderRole as 'user' | 'admin',
                lastMessageTime: lastMessageData.timestamp as Timestamp,
              };
            }
            
            // If no messages in conversation, the initial message is from user
            return {
              ...report,
              lastMessageFrom: 'user' as const,
              lastMessageTime: report.time,
            };
          } catch (error) {
            console.error(`Error fetching last message for report ${report.id}:`, error);
            // Return report with default values on error
            return {
              ...report,
              lastMessageFrom: 'user' as const,
              lastMessageTime: report.time,
            };
          }
        })
      );
      
      return reportsWithLastMessages;
    } catch (error) {
      console.error('Error fetching last messages:', error);
      return reports; // Return original reports on error
    } finally {
      setLastMessagesLoading(false);
    }
  };

  // Bulk update helper functions
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

  const validateBulkStatusUpdate = (reports: UserReport[], newStatus: string): { valid: UserReport[], invalid: UserReport[] } => {
    const valid: UserReport[] = [];
    const invalid: UserReport[] = [];

    reports.forEach(report => {
      const validTransitions = getValidStatusTransitions(report.status);
      if (validTransitions.includes(newStatus) && report.status !== newStatus) {
        valid.push(report);
      } else {
        invalid.push(report);
      }
    });

    return { valid, invalid };
  };

  const sendBulkNotificationsToUsers = async (reports: UserReport[], newStatus: string) => {
    const notificationPromises = reports.map(async (report) => {
      try {
        // Fetch user data for messaging token and locale
        const userSnapshot = await getDocs(query(collection(db, 'users'), where('__name__', '==', report.uid)));
        if (userSnapshot.empty) return;

        const userData = userSnapshot.docs[0].data();
        if (!userData.messagingToken || !userData.locale) return;

        const userLocale = userData.locale === 'arabic' ? 'ar' : 'en';
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

        const reportTypeKey = getReportTypeKey(report.reportTypeId);
        
        const title = t(`modules.userManagement.reports.notifications.statusUpdate.${userLocale}.title`);
        const body = t(`modules.userManagement.reports.notifications.statusUpdate.${userLocale}.${reportTypeKey}.${notificationKey}`);

        const payload = createReportUpdatePayload(
          title,
          body,
          report.id,
          newStatus,
          userLocale
        );

        return fetch('/api/admin/notifications/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            token: userData.messagingToken,
            ...payload
          }),
        });
      } catch (error) {
        console.error(`Error sending notification for report ${report.id}:`, error);
      }
    });

    await Promise.allSettled(notificationPromises);
  };

  const handleBulkStatusUpdate = async () => {
    if (!bulkUpdateStatus || selectedReports.size === 0) {
      toast.error(t('modules.userManagement.reports.bulkUpdate.selectStatusAndReports') || 'Please select reports and a status');
      return;
    }

    const selectedReportsList = filteredReports.filter(report => selectedReports.has(report.id));
    const { valid, invalid } = validateBulkStatusUpdate(selectedReportsList, bulkUpdateStatus);

    if (invalid.length > 0) {
      toast.warning(
        `${invalid.length} report(s) cannot be updated to ${bulkUpdateStatus} due to invalid status transitions. Proceeding with ${valid.length} valid updates.`
      );
    }

    if (valid.length === 0) {
      toast.error(t('modules.userManagement.reports.bulkUpdate.noValidUpdates') || 'No reports can be updated to the selected status');
      return;
    }

    setIsBulkUpdating(true);
    try {
      // Use batch write for efficiency
      const batch = writeBatch(db);
      const now = Timestamp.now();

      valid.forEach(report => {
        const reportRef = doc(db, 'usersReports', report.id);
        batch.update(reportRef, {
          status: bulkUpdateStatus,
          lastUpdated: now,
        });
      });

      await batch.commit();

      // Send notifications to users
      await sendBulkNotificationsToUsers(valid, bulkUpdateStatus);

      toast.success(
        `Successfully updated ${valid.length} report(s) to ${bulkUpdateStatus}${invalid.length > 0 ? `. ${invalid.length} report(s) were skipped due to invalid transitions.` : ''}`
      );

      // Clear selections and refresh data
      setSelectedReports(new Set());
      setBulkUpdateStatus('');
      setBulkUpdateDialogOpen(false);
      
      // Refresh the current page and status counts
      fetchReports(currentPage, false);
      fetchStatusCounts(); // Refresh status counts after bulk update
    } catch (error) {
      console.error('Error updating reports:', error);
      toast.error(t('modules.userManagement.reports.bulkUpdate.updateError') || 'Failed to update reports');
    } finally {
      setIsBulkUpdating(false);
    }
  };

  const handleSelectAll = () => {
    if (selectedReports.size === filteredReports.length) {
      setSelectedReports(new Set());
    } else {
      setSelectedReports(new Set(filteredReports.map(report => report.id)));
    }
  };

  const handleSelectReport = (reportId: string) => {
    const newSelected = new Set(selectedReports);
    if (newSelected.has(reportId)) {
      newSelected.delete(reportId);
    } else {
      newSelected.add(reportId);
    }
    setSelectedReports(newSelected);
  };

  // Build queries to prioritize pending reports from the source
  const buildQueriesWithPriorityFetch = async (): Promise<UserReport[]> => {
    const reports: UserReport[] = [];
    
    // For specific status filters, use simple query
    if (statusFilter !== 'all') {
      let q = query(
        collection(db, 'usersReports'),
        where('status', '==', statusFilter),
        orderBy('time', 'desc'),
        limit(itemsPerPage)
      );

      if (currentPage > 1 && lastVisible) {
        const cachedPage = pageCache.get(currentPage - 1);
        if (cachedPage?.lastDoc) {
          q = query(
            collection(db, 'usersReports'),
            where('status', '==', statusFilter),
            orderBy('time', 'desc'),
            startAfter(cachedPage.lastDoc),
            limit(itemsPerPage)
          );
        }
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        uid: doc.data().uid || '',
        time: doc.data().time || Timestamp.now(),
        reportTypeId: doc.data().reportTypeId || doc.data().reportType || 'dataError',
        status: doc.data().status || 'pending',
        initialMessage: doc.data().initialMessage || doc.data().userJustification || '',
        lastUpdated: doc.data().lastUpdated || doc.data().time || Timestamp.now(),
        messagesCount: doc.data().messagesCount || 1,
      }));
    }

    // For 'all' status, fetch pending first, then others to fill the page
    const statusPriority = ['pending', 'inProgress', 'waitingForAdminResponse', 'closed', 'finalized'];
    let remainingSlots = itemsPerPage;
    let skipCount = (currentPage - 1) * itemsPerPage;

    for (const status of statusPriority) {
      if (remainingSlots <= 0) break;

      const statusQuery = query(
        collection(db, 'usersReports'),
        where('status', '==', status),
        orderBy('time', 'desc'),
        limit(Math.max(remainingSlots + skipCount, 50)) // Fetch more to handle skipping
      );

      const statusSnapshot = await getDocs(statusQuery);
      const statusReports = statusSnapshot.docs.map(doc => ({
        id: doc.id,
        uid: doc.data().uid || '',
        time: doc.data().time || Timestamp.now(),
        reportTypeId: doc.data().reportTypeId || doc.data().reportType || 'dataError',
        status: doc.data().status || 'pending',
        initialMessage: doc.data().initialMessage || doc.data().userJustification || '',
        lastUpdated: doc.data().lastUpdated || doc.data().time || Timestamp.now(),
        messagesCount: doc.data().messagesCount || 1,
      }));

      // Handle pagination by skipping already shown reports
      const reportsToAdd = statusReports.slice(Math.max(0, skipCount), skipCount + remainingSlots);
      reports.push(...reportsToAdd);
      
      remainingSlots -= reportsToAdd.length;
      skipCount = Math.max(0, skipCount - statusReports.length);
    }

    return reports;
  };

  // Fetch reports with pagination using priority fetch
  const fetchReports = async (page: number, reset: boolean = false) => {
    if (reset) {
      setPageCache(new Map());
      setCurrentPage(1);
      page = 1;
    }

    setIsLoadingPage(true);
    setReportsError(null);

    try {
      // Use the new priority fetch approach
      const reports = await buildQueriesWithPriorityFetch();
      
      // Fetch last message information for each report
      const reportsWithLastMessages = await fetchLastMessagesForReports(reports);
      setAllReports(reportsWithLastMessages);
      
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

  // Effect to fetch status counts on component mount and when bulk updates happen
  useEffect(() => {
    fetchStatusCounts();
  }, []); // Only run on mount

  // Reset to first page when filters change
  useEffect(() => {
    if (currentPage !== 1) {
      setCurrentPage(1);
    } else {
      fetchReports(1, true);
    }
  }, [statusFilter, dateRangeFilter]);

  // Clear selections when page changes or filters change
  useEffect(() => {
    setSelectedReports(new Set());
  }, [currentPage, statusFilter, dateRangeFilter]);

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

    // Reports are already sorted by priority at the database level
    // Only apply additional sorting if needed for search/filter results

    return filtered;
  }, [allReports, searchQuery, dateRangeFilter]);

  // Use actual database counts for stats
  const stats = useMemo(() => {
    return {
      ...statusCounts,
      averageResponseTime: 0, // Would need separate calculation
    };
  }, [statusCounts]);

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
            <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
              <div className="min-w-0 flex-1">
                <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">
                  {t('modules.userManagement.reports.title') || 'User Reports'}
                </h1>
                <p className="text-sm sm:text-base text-muted-foreground mt-1">
                  {t('modules.userManagement.reports.description') || 'Review and manage user-submitted data error reports'}
                </p>
              </div>
              <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-2 w-full sm:w-auto">
                <ReportTypesManagement 
                  trigger={
                    <Button variant="outline" className="h-9 text-sm w-full sm:w-auto">
                      <Settings className="h-4 w-4 mr-2" />
                      <span className="hidden sm:inline">{t('modules.userManagement.reports.manageReportTypes') || 'Manage Report Types'}</span>
                      <span className="sm:hidden">Manage Types</span>
                    </Button>
                  }
                />
                <Button variant="outline" onClick={() => exportReports('csv')} className="h-9 text-sm w-full sm:w-auto">
                  <Download className="h-4 w-4 mr-2" />
                  <span className="hidden sm:inline">{t('modules.userManagement.reports.exportCsv') || 'Export CSV'}</span>
                  <span className="sm:hidden">Export</span>
                </Button>
                <Button asChild className="h-9 text-sm w-full sm:w-auto">
                  <Link href={`/${locale}/user-management/reports/analytics`}>
                    <BarChart3 className="h-4 w-4 mr-2" />
                    <span className="hidden sm:inline">{t('modules.userManagement.reports.analytics.title') || 'Analytics'}</span>
                    <span className="sm:hidden">Analytics</span>
                  </Link>
                </Button>
              </div>
            </div>

            {/* Stats Cards */}
            <div className="grid gap-3 grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 2xl:grid-cols-7">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.totalReports') || 'Total Reports'}
                  </CardTitle>
                  <FileText className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  {statusCountsLoading ? (
                    <Skeleton className="h-8 w-16" />
                  ) : (
                    <div className="text-2xl font-bold">{stats.total}</div>
                  )}
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
                  {statusCountsLoading ? (
                    <Skeleton className="h-8 w-16" />
                  ) : (
                    <div className="text-2xl font-bold">{stats.pending}</div>
                  )}
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.inProgressReports') || 'In Progress'}
                  </CardTitle>
                  <AlertCircle className="h-4 w-4 text-blue-600" />
                </CardHeader>
                <CardContent>
                  {statusCountsLoading ? (
                    <Skeleton className="h-8 w-16" />
                  ) : (
                    <div className="text-2xl font-bold">{stats.inProgress}</div>
                  )}
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
                  {statusCountsLoading ? (
                    <Skeleton className="h-8 w-16" />
                  ) : (
                    <div className="text-2xl font-bold">{stats.waitingForAdmin}</div>
                  )}
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
                  {statusCountsLoading ? (
                    <Skeleton className="h-8 w-16" />
                  ) : (
                    <div className="text-2xl font-bold">{stats.closed}</div>
                  )}
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
                  {statusCountsLoading ? (
                    <Skeleton className="h-8 w-16" />
                  ) : (
                    <div className="text-2xl font-bold">{stats.finalized}</div>
                  )}
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
                <div className="flex flex-col gap-3 sm:gap-4">
                  {/* Search Input */}
                  <div className="w-full">
                    <Input
                      placeholder={t('modules.userManagement.reports.searchPlaceholder') || 'Search by User ID...'}
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="w-full h-10 text-base"
                    />
                  </div>
                  
                  {/* Filters Row */}
                  <div className="flex flex-col sm:flex-row gap-3 sm:gap-4">
                    <Select value={statusFilter} onValueChange={setStatusFilter}>
                      <SelectTrigger className="w-full sm:w-[200px] h-10">
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
                      <SelectTrigger className="w-full sm:w-[200px] h-10">
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
                </div>
              </CardContent>
            </Card>

            {/* Bulk Actions */}
            {selectedReports.size > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <CheckSquare className="h-5 w-5" />
                      {t('modules.userManagement.reports.bulkActions.title') || 'Bulk Actions'}
                      <Badge variant="secondary">{selectedReports.size} selected</Badge>
                    </div>
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => setSelectedReports(new Set())}
                    >
                      {t('common.clearSelection') || 'Clear Selection'}
                    </Button>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:gap-4">
                    {/* Status Selection */}
                    <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-2 flex-1">
                      <label className="text-sm font-medium whitespace-nowrap">
                        {t('modules.userManagement.reports.bulkActions.updateStatusTo') || 'Update status to:'}
                      </label>
                      <Select value={bulkUpdateStatus} onValueChange={setBulkUpdateStatus}>
                        <SelectTrigger className="w-full sm:w-[200px] h-10">
                          <SelectValue placeholder={t('modules.userManagement.reports.selectStatus') || 'Select status'} />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="pending">{t('modules.userManagement.reports.statusPending') || 'Pending'}</SelectItem>
                          <SelectItem value="inProgress">{t('modules.userManagement.reports.statusInProgress') || 'In Progress'}</SelectItem>
                          <SelectItem value="waitingForAdminResponse">{t('modules.userManagement.reports.statusWaitingForAdminResponse') || 'Waiting for Admin Response'}</SelectItem>
                          <SelectItem value="closed">{t('modules.userManagement.reports.statusClosed') || 'Closed'}</SelectItem>
                          <SelectItem value="finalized">{t('modules.userManagement.reports.statusFinalized') || 'Finalized'}</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                    
                    {/* Action Button */}
                    <Button
                      onClick={() => setBulkUpdateDialogOpen(true)}
                      disabled={!bulkUpdateStatus || isBulkUpdating}
                      className="flex items-center justify-center gap-2 h-10 w-full sm:w-auto min-w-[140px] text-sm"
                    >
                      {isBulkUpdating ? (
                        <>
                          <RotateCw className="h-4 w-4 animate-spin" />
                          <span className="hidden sm:inline">{t('modules.userManagement.reports.bulkActions.updating') || 'Updating...'}</span>
                          <span className="sm:hidden">Updating...</span>
                        </>
                      ) : (
                        <>
                          <CheckCircle className="h-4 w-4" />
                          <span className="hidden sm:inline">{t('modules.userManagement.reports.bulkActions.updateSelected') || 'Update Selected'}</span>
                          <span className="sm:hidden">Update</span>
                        </>
                      )}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            )}

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
                  <div className="overflow-x-auto">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead className="w-12">
                            <Checkbox
                              checked={selectedReports.size === filteredReports.length && filteredReports.length > 0}
                              onCheckedChange={handleSelectAll}
                              aria-label="Select all reports"
                            />
                          </TableHead>
                          <TableHead>{t('modules.userManagement.reports.reportId') || 'Report ID'}</TableHead>
                          <TableHead>{t('modules.userManagement.reports.userId') || 'User ID'}</TableHead>
                          <TableHead className="hidden md:table-cell">{t('modules.userManagement.reports.reportType') || 'Report Type'}</TableHead>
                          <TableHead>{t('modules.userManagement.reports.status') || 'Status'}</TableHead>
                          <TableHead className="hidden lg:table-cell">{t('modules.userManagement.reports.submittedDate') || 'Submitted Date'}</TableHead>
                          <TableHead className="hidden xl:table-cell">{t('modules.userManagement.reports.initialMessage') || 'Initial Message'}</TableHead>
                          <TableHead className="hidden sm:table-cell">{t('modules.userManagement.reports.messagesCount') || 'Messages'}</TableHead>
                          <TableHead className="hidden lg:table-cell">{t('modules.userManagement.reports.lastMessageFrom') || 'Last Message From'}</TableHead>
                          <TableHead className="text-right">{t('modules.userManagement.reports.actions') || 'Actions'}</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {isLoadingPage ? (
                          // Show loading skeletons during page transitions
                          [...Array(itemsPerPage)].map((_, i) => (
                            <TableRow key={i}>
                              <TableCell><Skeleton className="h-4 w-4" /></TableCell>
                              <TableCell><Skeleton className="h-4 w-24" /></TableCell>
                              <TableCell><Skeleton className="h-4 w-20" /></TableCell>
                              <TableCell className="hidden md:table-cell"><Skeleton className="h-4 w-16" /></TableCell>
                              <TableCell><Skeleton className="h-4 w-16" /></TableCell>
                              <TableCell className="hidden lg:table-cell"><Skeleton className="h-4 w-32" /></TableCell>
                              <TableCell className="hidden xl:table-cell"><Skeleton className="h-4 w-40" /></TableCell>
                              <TableCell className="hidden sm:table-cell"><Skeleton className="h-4 w-12" /></TableCell>
                              <TableCell className="hidden lg:table-cell"><Skeleton className="h-4 w-16" /></TableCell>
                              <TableCell><Skeleton className="h-4 w-16" /></TableCell>
                            </TableRow>
                          ))
                        ) : (
                          filteredReports.map((report) => (
                            <TableRow key={report.id}>
                              <TableCell>
                                <Checkbox
                                  checked={selectedReports.has(report.id)}
                                  onCheckedChange={() => handleSelectReport(report.id)}
                                  aria-label={`Select report ${report.id}`}
                                />
                              </TableCell>
                              <TableCell>
                                <div className="flex items-center gap-1 min-w-0">
                                  <span className="font-mono text-xs sm:text-sm max-w-[80px] sm:max-w-[120px] truncate">
                                    {report.id}
                                  </span>
                                  <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => copyToClipboard(report.id, 'Report ID')}
                                    className="hidden sm:flex h-6 w-6 p-0"
                                  >
                                    <Copy className="h-3 w-3" />
                                  </Button>
                                </div>
                              </TableCell>
                              <TableCell>
                                <Link 
                                  href={`/${locale}/user-management/users/${report.uid}`}
                                  className="text-blue-600 hover:underline font-mono text-xs sm:text-sm block"
                                >
                                  <span className="max-w-[80px] sm:max-w-[120px] truncate block">
                                    {truncateText(report.uid, 8)}
                                  </span>
                                  <ExternalLink className="h-3 w-3 inline ml-1" />
                                </Link>
                              </TableCell>
                              <TableCell className="hidden md:table-cell">
                                <Badge variant="outline" className="text-xs">
                                  {getReportTypeName(report.reportTypeId)}
                                </Badge>
                              </TableCell>
                              <TableCell>{getStatusBadge(report.status)}</TableCell>
                              <TableCell className="hidden lg:table-cell">
                                <span className="text-xs sm:text-sm">{formatDate(report.time)}</span>
                              </TableCell>
                              <TableCell className="hidden xl:table-cell">
                                <span className="max-w-[150px] xl:max-w-[200px] truncate block text-xs sm:text-sm" title={report.initialMessage}>
                                  {truncateText(report.initialMessage, 40)}
                                </span>
                              </TableCell>
                              <TableCell className="hidden sm:table-cell">
                                <div className="flex items-center gap-1">
                                  <span className="text-xs sm:text-sm">{report.messagesCount}</span>
                                  <FileText className="h-3 w-3 text-muted-foreground" />
                                </div>
                              </TableCell>
                              <TableCell className="hidden lg:table-cell">
                                {lastMessagesLoading ? (
                                  <Skeleton className="h-5 w-12" />
                                ) : (
                                  <div className="flex items-center gap-1">
                                    {report.lastMessageFrom === 'admin' ? (
                                      <Badge variant="secondary" className="text-xs">
                                        <Shield className="h-3 w-3 mr-1" />
                                        <span className="hidden xl:inline">{t('modules.userManagement.reports.admin') || 'Admin'}</span>
                                        <span className="xl:hidden">A</span>
                                      </Badge>
                                    ) : (
                                      <Badge variant="outline" className="text-xs">
                                        <User className="h-3 w-3 mr-1" />
                                        <span className="hidden xl:inline">{t('modules.userManagement.reports.user') || 'User'}</span>
                                        <span className="xl:hidden">U</span>
                                      </Badge>
                                    )}
                                  </div>
                                )}
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
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Pagination Controls */}
            {!reportsLoading && totalCount > 0 && (
              <Card>
                <CardContent className="pt-6">
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                    {/* Results Info */}
                    <div className="text-xs sm:text-sm text-muted-foreground text-center sm:text-left">
                      {t('modules.userManagement.reports.showing')} {((currentPage - 1) * itemsPerPage) + 1} - {Math.min(currentPage * itemsPerPage, totalCount)} {t('modules.userManagement.reports.of')} {totalCount}
                    </div>
                    
                    {/* Navigation Controls */}
                    <div className="flex items-center justify-center gap-1 sm:gap-2 flex-wrap">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handlePageChange(1)}
                        disabled={!hasPrevPage || isLoadingPage}
                        className="h-8 w-8 p-0 sm:h-9 sm:w-auto sm:px-3"
                      >
                        <ChevronsLeft className="h-3 w-3 sm:h-4 sm:w-4" />
                        <span className="sr-only">First page</span>
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handlePageChange(currentPage - 1)}
                        disabled={!hasPrevPage || isLoadingPage}
                        className="h-8 w-8 p-0 sm:h-9 sm:w-auto sm:px-3"
                      >
                        <ChevronLeft className="h-3 w-3 sm:h-4 sm:w-4" />
                        <span className="sr-only">Previous page</span>
                      </Button>
                      
                      <div className="flex items-center px-2 sm:px-3">
                        <span className="text-xs sm:text-sm font-medium whitespace-nowrap">
                          <span className="hidden sm:inline">{t('modules.userManagement.reports.page')} </span>
                          {currentPage} / {totalPages}
                        </span>
                      </div>
                      
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handlePageChange(currentPage + 1)}
                        disabled={!hasNextPage || isLoadingPage}
                        className="h-8 w-8 p-0 sm:h-9 sm:w-auto sm:px-3"
                      >
                        <ChevronRight className="h-3 w-3 sm:h-4 sm:w-4" />
                        <span className="sr-only">Next page</span>
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handlePageChange(totalPages)}
                        disabled={!hasNextPage || isLoadingPage}
                        className="h-8 w-8 p-0 sm:h-9 sm:w-auto sm:px-3"
                      >
                        <ChevronsRight className="h-3 w-3 sm:h-4 sm:w-4" />
                        <span className="sr-only">Last page</span>
                      </Button>
                    </div>

                    {/* Items Per Page Selector */}
                    <Select 
                      value={itemsPerPage.toString()} 
                      onValueChange={(value) => handleItemsPerPageChange(Number(value))}
                      disabled={isLoadingPage}
                    >
                      <SelectTrigger className="w-full sm:w-[100px] h-8 sm:h-9 text-xs sm:text-sm">
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

      {/* Bulk Update Confirmation Dialog */}
      <Dialog open={bulkUpdateDialogOpen} onOpenChange={setBulkUpdateDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.userManagement.reports.bulkUpdate.confirmTitle') || 'Confirm Bulk Update'}</DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.reports.bulkUpdate.confirmDescription') || 
                `Are you sure you want to update ${selectedReports.size} selected report(s) to "${bulkUpdateStatus}" status? This will also send notifications to all affected users.`}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setBulkUpdateDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button onClick={handleBulkStatusUpdate} disabled={isBulkUpdating}>
              {isBulkUpdating ? (
                <>
                  <RotateCw className="h-4 w-4 mr-2 animate-spin" />
                  {t('modules.userManagement.reports.bulkUpdate.updating') || 'Updating...'}
                </>
              ) : (
                <>
                  <CheckCircle className="h-4 w-4 mr-2" />
                  {t('modules.userManagement.reports.bulkUpdate.confirmUpdate') || 'Confirm Update'}
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

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