'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  type ColumnDef,
  type ColumnFiltersState,
  type PaginationState,
  type SortingState,
  type VisibilityState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  ResponsiveDialog as Dialog,
  ResponsiveDialogContent as DialogContent,
  ResponsiveDialogDescription as DialogDescription,
  ResponsiveDialogFooter as DialogFooter,
  ResponsiveDialogHeader as DialogHeader,
  ResponsiveDialogTitle as DialogTitle,
} from '@/components/ui/responsive-dialog';
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  ChevronsLeftIcon,
  ChevronsRightIcon,
  MoreHorizontal,
  Edit,
  Trash2,
  UserCheck,
  Users,
  UserPlus,
  Shield,
  Eye,
  Search,
  AlertTriangle,
  User,
  Loader2,
} from 'lucide-react';
import Link from 'next/link';
import { toast } from 'sonner';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from "@/contexts/TranslationContext";
import { useDeletionRequests, useDeletionRequestStats, useUserDeletion } from '@/hooks/useDeletionRequests';

interface UserProfile {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  role: 'admin' | 'moderator' | 'user';
  status: 'active' | 'inactive' | 'suspended';
  createdAt: Date;
  updatedAt: Date;
  lastLoginAt?: Date | null;
  emailVerified: boolean;
  provider?: string;
  isRequestedToBeDeleted?: boolean;
  metadata: {
    loginCount: number;
    lastIpAddress?: string;
    userAgent?: string;
  };
}

interface AccountDeleteRequest {
  id: string;
  userId: string;
  userEmail: string;
  userName: string;
  requestedAt: Date;
  reasonId: string;
  reasonDetails?: string;
  reasonCategory: string;
  isCanceled: boolean;
  isProcessed: boolean;
  canceledAt?: Date;
  processedAt?: Date;
  processedBy?: string;
  adminNotes?: string;
}

interface DeletionReason {
  id: string;
  translationKey: string;
  category: 'privacy' | 'experience' | 'personal' | 'features' | 'content' | 'support' | 'other';
  requiresDetails: boolean;
}

interface PaginationInfo {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
  hasNext: boolean;
  hasPrev: boolean;
}

interface UserStats {
  total: number;
  active: number;
  admins: number;
  moderators: number;
}

export default function UsersRoute() {
  const { t, locale } = useTranslation();
  
  // Fetch deletion requests and stats
  const { 
    deletionRequests, 
    loading: deletionRequestsLoading,
    processing: requestProcessing,
    approveRequest,
    refetch: refetchDeletionRequests
  } = useDeletionRequests();
  const { executeUserDeletion, processing: deletionProcessing, progress } = useUserDeletion();
  const { stats: deletionStats, loading: statsLoading } = useDeletionRequestStats();
  
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [bulkActionLoading, setBulkActionLoading] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [usersToDelete, setUsersToDelete] = useState<string[]>([]);
  const [userStats, setUserStats] = useState<UserStats>({
    total: 0,
    active: 0,
    admins: 0,
    moderators: 0,
  });
  const [pagination, setPagination] = useState<PaginationInfo>({
    page: 1,
    limit: 50,
    total: 0,
    totalPages: 0,
    hasNext: false,
    hasPrev: false,
  });

  

  // Table state
  const [rowSelection, setRowSelection] = useState({});
  const [columnVisibility, setColumnVisibility] = useState<VisibilityState>({});
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);
  const [sorting, setSorting] = useState<SortingState>([]);
  const [tablePagination, setTablePagination] = useState({
    pageIndex: 0,
    pageSize: 50,
  });

  // Filters
  const [providerFilter, setProviderFilter] = useState('all');
  const [deletionStatusFilter, setDeletionStatusFilter] = useState('all');
  
  // Deletion requests filters
  const [deletionRequestStatusFilter, setDeletionRequestStatusFilter] = useState('all');
  
  // Deletion requests pagination
  const [deletionRequestsPagination, setDeletionRequestsPagination] = useState({
    pageIndex: 0,
    pageSize: 20,
  });

  // Deletion requests actions state
  const [showApproveDeletionDialog, setShowApproveDeletionDialog] = useState(false);
  const [selectedDeletionRequest, setSelectedDeletionRequest] = useState<AccountDeleteRequest | null>(null);
  const [adminNotes, setAdminNotes] = useState('');

  // Deletion requests bulk selection and processing
  const [selectedDeletionRequestIds, setSelectedDeletionRequestIds] = useState<string[]>([]);
  const [bulkApproveOpen, setBulkApproveOpen] = useState(false);
  const [bulkAdminNotes, setBulkAdminNotes] = useState('');
  const [bulkProcessing, setBulkProcessing] = useState(false);

  const headerDictionary = {
    documents: t('appSidebar.users') || 'Users',
  };

    const loadUsers = useCallback(async () => {
    try {
      setLoading(true);
      const effectiveLimit = Math.max(pagination.limit, 50); // Ensure minimum 50
      
      
      
      
      
      const params = new URLSearchParams({
        page: pagination.page.toString(),
        limit: effectiveLimit.toString(),
      });
      
      

      if (searchQuery.trim()) params.append('search', searchQuery.trim());
      if (providerFilter && providerFilter !== 'all') params.append('provider', providerFilter);
      if (deletionStatusFilter && deletionStatusFilter !== 'all') params.append('deletionStatus', deletionStatusFilter);

      const response = await fetch(`/api/admin/users?${params}`);
      if (!response.ok) {
        throw new Error('Failed to fetch users');
      }

      const data = await response.json();
      
      
      
      
      
      // Convert date strings back to Date objects
      const usersWithDates = data.users.map((user: any) => ({
        ...user,
        createdAt: new Date(user.createdAt),
        updatedAt: new Date(user.updatedAt),
        lastLoginAt: user.lastLoginAt ? new Date(user.lastLoginAt) : null,
      }));
      
      const newPagination = {
        ...data.pagination,
        limit: effectiveLimit, // Use the effective limit we actually requested
      };
      
      
      
      setUsers(usersWithDates);
      setPagination(newPagination);
      
      // Set Firestore-based user stats if available
      if (data.stats) {
        setUserStats(data.stats);
      }
          } catch (error) {
        toast.error(t('modules.userManagement.errors.loadingFailed') || 'Failed to load users');
      } finally {
        setLoading(false);
      }
  }, [pagination.page, pagination.limit, providerFilter, deletionStatusFilter, t]);

  // Debug: Log when loadUsers dependencies change
  useEffect(() => {
    
    
    
    
  }, [pagination.page, pagination.limit, providerFilter, deletionStatusFilter]);

  // Force pagination limit to 50 on component mount
  useEffect(() => {
    
    setPagination(prev => {
      
      const newPagination = { ...prev, limit: 50 };
      
      return newPagination;
    });
  }, []); // Empty dependency array means this runs only once on mount

  useEffect(() => {
    
    loadUsers();
  }, [loadUsers]);

  // Sync table pagination with backend pagination
  useEffect(() => {
    setTablePagination({
      pageIndex: pagination.page - 1, // React Table uses 0-based indexing
      pageSize: pagination.limit,
    });
  }, [pagination.page, pagination.limit]);

  const handleSearch = () => {
    setPagination(prev => ({ ...prev, page: 1 }));
    
    const effectiveLimit = Math.max(pagination.limit, 50); // Ensure minimum 50
    const searchParams = new URLSearchParams({
      page: '1',
      limit: effectiveLimit.toString(),
    });

    if (searchQuery.trim()) searchParams.append('search', searchQuery.trim());
    if (providerFilter && providerFilter !== 'all') searchParams.append('provider', providerFilter);
    if (deletionStatusFilter && deletionStatusFilter !== 'all') searchParams.append('deletionStatus', deletionStatusFilter);

    setLoading(true);
    fetch(`/api/admin/users?${searchParams}`)
      .then(async (response) => {
        if (!response.ok) {
          throw new Error('Failed to fetch users');
        }
        const data = await response.json();
        
        const usersWithDates = data.users.map((user: any) => ({
          ...user,
          createdAt: new Date(user.createdAt),
          updatedAt: new Date(user.updatedAt),
          lastLoginAt: user.lastLoginAt ? new Date(user.lastLoginAt) : null,
        }));
        
        setUsers(usersWithDates);
        setPagination({
          ...data.pagination,
          limit: effectiveLimit, // Use the effective limit we actually requested
        });
        
        // Set Firestore-based user stats if available
        if (data.stats) {
          setUserStats(data.stats);
        }
      })
      .catch((error) => {
        console.error('Error searching users:', error);
        toast.error(t('modules.userManagement.errors.loadingFailed') || 'Failed to search users');
      })
      .finally(() => {
        setLoading(false);
      });
  };

  const handleClearSearch = () => {
    setSearchQuery('');
    setProviderFilter('all');
    setDeletionStatusFilter('all');
    setPagination(prev => ({ ...prev, page: 1 }));
    // This will trigger loadUsers due to the filter changes
  };

  const handleClearDeletionFilters = () => {
    setDeletionRequestStatusFilter('all');
    setDeletionRequestsPagination({
      pageIndex: 0,
      pageSize: 20
    });
  };

  const formatDeletionDate = (date: Date | string | null | undefined) => {
    if (!date) return t('common.never') || 'Never';
    
    const dateObj = date instanceof Date ? date : new Date(date);
    
    if (isNaN(dateObj.getTime())) {
      return t('common.unknown') || 'Unknown';
    }
    
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      calendar: 'gregory',
    }).format(dateObj);
  };

  const getDeletionReasonText = (reasonId: string) => {
    return t(`modules.userManagement.accountDeletion.reasons.${reasonId}`) || reasonId;
  };

  const getDeletionCategoryText = (category: string) => {
    return t(`modules.userManagement.accountDeletion.categories.${category}`) || category;
  };

  const getDeletionRequestStatusBadge = (request: AccountDeleteRequest) => {
    if (request.isCanceled) {
      return (
        <Badge variant="secondary">
          {t('modules.userManagement.accountDeletion.isCanceled') || 'Canceled'}
        </Badge>
      );
    }
    if (request.isProcessed) {
      return (
        <Badge variant="outline">
          {t('modules.userManagement.accountDeletion.isProcessed') || 'Processed'}
        </Badge>
      );
    }
    return (
      <Badge variant="destructive">
        {t('modules.userManagement.accountDeletion.pendingDeletion') || 'Pending'}
      </Badge>
    );
  };

  // Filter deletion requests based on status
  const filteredDeletionRequests = deletionRequests.filter(request => {
    if (deletionRequestStatusFilter === 'all') return true;
    if (deletionRequestStatusFilter === 'pending') return !request.isProcessed && !request.isCanceled;
    if (deletionRequestStatusFilter === 'processed') return request.isProcessed;
    if (deletionRequestStatusFilter === 'canceled') return request.isCanceled;
    return true;
  });

  // Paginate deletion requests
  const totalDeletionRequests = filteredDeletionRequests.length;
  const totalDeletionPages = Math.ceil(totalDeletionRequests / deletionRequestsPagination.pageSize);
  const paginatedDeletionRequests = filteredDeletionRequests.slice(
    deletionRequestsPagination.pageIndex * deletionRequestsPagination.pageSize,
    (deletionRequestsPagination.pageIndex + 1) * deletionRequestsPagination.pageSize
  );

  const handleDeletionPageChange = (newPageIndex: number) => {
    setDeletionRequestsPagination(prev => ({
      ...prev,
      pageIndex: newPageIndex
    }));
  };

  const handleDeletionPageSizeChange = (newPageSize: number) => {
    setDeletionRequestsPagination({
      pageIndex: 0, // Reset to first page
      pageSize: newPageSize
    });
  };

  const openApproveDeletion = (request: AccountDeleteRequest) => {
    setSelectedDeletionRequest(request);
    setAdminNotes(request.adminNotes || '');
    setShowApproveDeletionDialog(true);
  };

  const confirmApproveDeletion = async () => {
    if (!selectedDeletionRequest) return;
    try {
      await approveRequest(selectedDeletionRequest.id, adminNotes, 'admin-user');
      await executeUserDeletion(selectedDeletionRequest.userId, 'admin-user');
      toast.success(t('modules.userManagement.accountDeletion.approveSuccess') || 'Deletion request approved and user deleted successfully');
      setShowApproveDeletionDialog(false);
      setSelectedDeletionRequest(null);
      setAdminNotes('');
      await refetchDeletionRequests();
    } catch (error) {
      console.error('Error approving & deleting user:', error);
      toast.error(t('modules.userManagement.accountDeletion.approveError') || 'Failed to approve deletion request');
    }
  };

  const handlePageChange = (newPage: number) => {
    setPagination(prev => ({ ...prev, page: newPage }));
    setTablePagination(prev => ({ ...prev, pageIndex: newPage - 1 }));
  };

  const handlePageSizeChange = (newPageSize: number) => {
    setPagination(prev => ({ 
      ...prev, 
      limit: newPageSize, 
      page: 1 // Reset to first page when changing page size
    }));
    setTablePagination(prev => ({
      ...prev,
      pageSize: newPageSize,
      pageIndex: 0 // Reset to first page
    }));
  };

  const handleDeleteUsers = async (userIds: string[]) => {
    try {
      setBulkActionLoading(true);
      const response = await fetch('/api/admin/users', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userIds }),
      });

      if (!response.ok) {
        throw new Error('Failed to delete users');
      }

      const result = await response.json();
      toast.success(result.message || `Deleted ${userIds.length} users`);
      setRowSelection({});
      await loadUsers();
    } catch (error) {
      console.error('Error deleting users:', error);
      toast.error(t('modules.userManagement.errors.deleteFailed') || 'Failed to delete users');
    } finally {
      setBulkActionLoading(false);
      setShowDeleteDialog(false);
      setUsersToDelete([]);
    }
  };

  const getStatusBadge = (status: string) => {
    const variants = {
      active: 'default',
      inactive: 'secondary',
      suspended: 'destructive',
    } as const;

    return (
      <Badge variant={variants[status as keyof typeof variants] || 'secondary'}>
        {t(`modules.userManagement.userStatus.${status}`) || status}
      </Badge>
    );
  };

  const getRoleBadge = (role: string) => {
    const variants = {
      admin: 'default',
      moderator: 'secondary',
      user: 'outline',
    } as const;

    return (
      <Badge variant={variants[role as keyof typeof variants] || 'outline'}>
        <Shield className="h-3 w-3 mr-1" />
        {t(`modules.userManagement.userRole.${role}`) || role}
      </Badge>
    );
  };

  const getDeletionStatusBadge = (isRequestedToBeDeleted?: boolean) => {
    if (isRequestedToBeDeleted) {
      return (
        <Badge variant="destructive">
          <AlertTriangle className="h-3 w-3 mr-1" />
          {t('modules.userManagement.accountDeletion.pendingDeletion') || 'Pending Deletion'}
        </Badge>
      );
    }
    return (
      <Badge variant="outline">
        {t('modules.userManagement.accountDeletion.normal') || 'Normal'}
      </Badge>
    );
  };

  const formatDate = (date: Date | string | null | undefined) => {
    if (!date) return t('common.never') || 'Never';
    
    // Handle both Date objects and date strings
    const dateObj = date instanceof Date ? date : new Date(date);
    
    // Check if the date is valid
    if (isNaN(dateObj.getTime())) {
      return t('common.unknown') || 'Unknown';
    }
    
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      calendar: 'gregory',
    }).format(dateObj);
  };

  // Define table columns
  const columns: ColumnDef<UserProfile>[] = [
    {
      id: "select",
      header: ({ table }) => (
        <div className="flex items-center justify-center">
          <Checkbox
            checked={table.getIsAllPageRowsSelected() || (table.getIsSomePageRowsSelected() && "indeterminate")}
            onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
            aria-label="Select all"
          />
        </div>
      ),
      cell: ({ row }) => (
        <div className="flex items-center justify-center">
          <Checkbox
            checked={row.getIsSelected()}
            onCheckedChange={(value) => row.toggleSelected(!!value)}
            aria-label="Select row"
          />
        </div>
      ),
      enableSorting: false,
      enableHiding: false,
    },
    {
      accessorKey: "uid",
      header: t('modules.userManagement.userId') || 'User ID',
      cell: ({ row }) => (
        <div className="font-mono text-sm text-muted-foreground max-w-[120px] truncate">
          {row.original.uid}
        </div>
      ),
    },
    {
      accessorKey: "user",
      header: t('modules.userManagement.user') || 'User',
      cell: ({ row }) => {
        const user = row.original;
        return (
          <div className="flex items-center gap-3">
            <Avatar className="h-9 w-9">
              <AvatarImage src={user.photoURL || undefined} alt={user.displayName} />
              <AvatarFallback>
                {user.displayName?.charAt(0) || user.email.charAt(0).toUpperCase()}
              </AvatarFallback>
            </Avatar>
            <div className="space-y-1">
              <p className="text-sm font-medium">{user.displayName || user.email}</p>
              <p className="text-xs text-muted-foreground">{user.email}</p>
            </div>
          </div>
        );
      },
      enableHiding: false,
    },
    {
      accessorKey: "role",
      header: t('modules.userManagement.role') || 'Role',
      cell: ({ row }) => getRoleBadge(row.original.role),
    },
    {
      accessorKey: "status",
      header: t('modules.userManagement.status') || 'Status',
      cell: ({ row }) => getStatusBadge(row.original.status),
    },
    {
      accessorKey: "lastLoginAt",
      header: t('modules.userManagement.lastLogin') || 'Last Login',
      cell: ({ row }) => formatDate(row.original.lastLoginAt),
    },

    {
      accessorKey: "provider",
      header: t('modules.userManagement.provider') || 'Sign-in Provider',
      cell: ({ row }) => {
        const provider = row.original.provider || t('common.unknown') || 'Unknown';
        
        // Get provider-specific styling
        const getProviderStyle = (provider: string) => {
          switch (provider) {
            case 'Google':
              return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300';
            case 'Apple':
              return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300';
            case 'Facebook':
              return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300';
            case 'Microsoft':
              return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300';
            case 'Twitter':
              return 'bg-sky-100 text-sky-800 dark:bg-sky-900 dark:text-sky-300';
            case 'GitHub':
              return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300';
            case 'Yahoo':
              return 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300';
            case 'Email':
              return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
            case 'Google Play Games':
              return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-300';
            case 'Apple Game Center':
              return 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300';
            default:
              return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300';
          }
        };

        return (
          <Badge 
            variant="secondary" 
            className={`px-2 py-1 font-medium ${getProviderStyle(provider)}`}
          >
            {provider}
          </Badge>
        );
      },
    },
    {
      accessorKey: "createdAt",
      header: t('modules.userManagement.createdAt') || 'Created',
      cell: ({ row }) => formatDate(row.original.createdAt),
    },
    {
      accessorKey: "deletionStatus",
      header: t('modules.userManagement.accountDeletion.status') || 'Deletion Status',
      cell: ({ row }) => getDeletionStatusBadge(row.original.isRequestedToBeDeleted),
    },
    {
      id: "actions",
      cell: ({ row }) => {
        const user = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="h-8 w-8 p-0">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem asChild>
                <Link href={`/${locale}/user-management/users/${user.uid}`}>
                  <Eye className="h-4 w-4 mr-2" />
                  {t('modules.userManagement.viewDetails') || 'View Details'}
                </Link>
              </DropdownMenuItem>
              {user.isRequestedToBeDeleted && (
                <DropdownMenuItem asChild>
                  <Link href={`/${locale}/user-management/users/${user.uid}?tab=deletion`}>
                    <AlertTriangle className="h-4 w-4 mr-2" />
                    {t('modules.userManagement.accountDeletion.viewDeletionRequest') || 'View Deletion Request'}
                  </Link>
                </DropdownMenuItem>
              )}
              <DropdownMenuItem>
                <Edit className="h-4 w-4 mr-2" />
                {t('common.edit')}
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem
                onClick={() => {
                  setUsersToDelete([user.uid]);
                  setShowDeleteDialog(true);
                }}
                className="text-red-600"
              >
                <Trash2 className="h-4 w-4 mr-2" />
                {t('common.delete')}
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const table = useReactTable({
    data: users,
    columns,
    state: {
      sorting,
      columnVisibility,
      rowSelection,
      columnFilters,
      pagination: tablePagination,
    },
    enableRowSelection: true,
    onRowSelectionChange: setRowSelection,
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onColumnVisibilityChange: setColumnVisibility,
    onPaginationChange: setTablePagination,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getSortedRowModel: getSortedRowModel(),
    manualPagination: true,
    pageCount: pagination.totalPages,
  });

  // Get selected user IDs
  const selectedUserIds = table.getFilteredSelectedRowModel().rows.map(row => row.original.uid);

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex flex-1 flex-col">
        <div className="@container/main flex flex-1 flex-col gap-2">
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
            {/* Main Tabs */}
            <Tabs defaultValue="users" className="space-y-6">
              <TabsList>
                <TabsTrigger value="users">{t('modules.userManagement.users') || 'Users'}</TabsTrigger>
                <TabsTrigger value="deletion-requests">
                  {t('modules.userManagement.accountDeletion.title') || 'Deletion Requests'}
                  {!statsLoading && deletionStats.pending > 0 && (
                    <Badge variant="destructive" className="ml-2 text-xs">
                      {deletionStats.pending}
                    </Badge>
                  )}
                </TabsTrigger>
              </TabsList>

              {/* Users Tab */}
              <TabsContent value="users" className="space-y-6">
                {/* Stats Cards */}
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.totalUsers') || 'Total Users'}
                      </CardTitle>
                      <Users className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{userStats.total.toLocaleString()}</div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.activeUsers') || 'Active Users'}
                      </CardTitle>
                      <UserCheck className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{userStats.active.toLocaleString()}</div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.admins') || 'Administrators'}
                      </CardTitle>
                      <Shield className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{userStats.admins.toLocaleString()}</div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.moderators') || 'Moderators'}
                      </CardTitle>
                      <UserCheck className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{userStats.moderators.toLocaleString()}</div>
                    </CardContent>
                  </Card>
                </div>

            {/* Users Table */}
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle>{t('modules.userManagement.users') || 'Users'}</CardTitle>
                    <CardDescription>
                      {t('modules.userManagement.usersDescription') || 'Manage user accounts and permissions'}
                    </CardDescription>
                  </div>
                  <div className="flex items-center gap-2">
                    {selectedUserIds.length > 0 && (
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => {
                          setUsersToDelete(selectedUserIds);
                          setShowDeleteDialog(true);
                        }}
                        disabled={bulkActionLoading}
                      >
                        <Trash2 className="h-4 w-4 mr-2" />
                        {t('modules.userManagement.deleteSelected')} ({selectedUserIds.length})
                      </Button>
                    )}
                    <Button>
                      <UserPlus className="h-4 w-4 mr-2" />
                      {t('modules.userManagement.createUser') || 'Create User'}
                    </Button>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                {/* Search and Filters */}
                <div className="flex flex-col gap-4 md:flex-row md:items-end mb-6">
                  <div className="flex-1 relative">
                    <Input
                      placeholder={t('modules.userManagement.searchPlaceholder') || 'Search by user ID, email, or name...'}
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                      className="pr-16"
                    />
                    {searchQuery && (
                      <Button
                        variant="ghost"
                        size="sm"
                        className="absolute right-1 top-1/2 -translate-y-1/2 h-7 w-7 p-0"
                        onClick={() => setSearchQuery('')}
                      >
                        ×
                      </Button>
                    )}
                  </div>
                  <Select value={providerFilter} onValueChange={setProviderFilter}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder={t('modules.userManagement.filterByProvider') || 'Filter by provider'} />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">{t('common.all')} {t('modules.userManagement.providers') || 'Providers'}</SelectItem>
                      <SelectItem value="Google">Google</SelectItem>
                      <SelectItem value="Apple">Apple</SelectItem>
                      <SelectItem value="Facebook">Facebook</SelectItem>
                      <SelectItem value="Microsoft">Microsoft</SelectItem>
                      <SelectItem value="Twitter">Twitter</SelectItem>
                      <SelectItem value="GitHub">GitHub</SelectItem>
                      <SelectItem value="Yahoo">Yahoo</SelectItem>
                      <SelectItem value="Email">Email</SelectItem>
                      <SelectItem value="Google Play Games">Google Play Games</SelectItem>
                      <SelectItem value="Apple Game Center">Apple Game Center</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select value={deletionStatusFilter} onValueChange={setDeletionStatusFilter}>
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder={t('modules.userManagement.accountDeletion.filterByStatus') || 'Filter by deletion status'} />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">{t('common.all')} {t('modules.userManagement.accountDeletion.statuses') || 'Users'}</SelectItem>
                      <SelectItem value="pending">{t('modules.userManagement.accountDeletion.pendingDeletion') || 'Pending Deletion'}</SelectItem>
                      <SelectItem value="normal">{t('modules.userManagement.accountDeletion.normal') || 'Normal'}</SelectItem>
                    </SelectContent>
                  </Select>
                  <div className="flex gap-2">
                    <Button onClick={handleSearch}>
                      <Search className="h-4 w-4 mr-2" />
                      {t('common.search')}
                    </Button>
                    {(searchQuery || providerFilter !== 'all' || deletionStatusFilter !== 'all') && (
                      <Button variant="outline" onClick={handleClearSearch}>
                        {t('modules.userManagement.clearFilters') || 'Clear Filters'}
                      </Button>
                    )}
                  </div>
                </div>

                {/* Selection Info */}
                {selectedUserIds.length > 0 && (
                  <div className="flex items-center justify-between p-2 bg-muted rounded-md mb-4">
                    <p className="text-sm text-muted-foreground">
                      {t('modules.userManagement.selectedUsers').replace('{count}', selectedUserIds.length.toString())}
                    </p>
                    <Button variant="ghost" size="sm" onClick={() => setRowSelection({})}>
                      {t('modules.userManagement.clearSelection') || 'Clear selection'}
                    </Button>
                  </div>
                )}

                {/* Users Table */}
                {loading ? (
                  <div className="space-y-3">
                    {[...Array(5)].map((_, i) => (
                      <Skeleton key={i} className="h-16 w-full" />
                    ))}
                  </div>
                ) : (
                  <>
                    <div className="rounded-md border overflow-x-auto">
                      <Table>
                        <TableHeader>
                          {table.getHeaderGroups().map((headerGroup) => (
                            <TableRow key={headerGroup.id}>
                              {headerGroup.headers.map((header) => (
                                <TableHead key={header.id}>
                                  {header.isPlaceholder
                                    ? null
                                    : flexRender(header.column.columnDef.header, header.getContext())}
                                </TableHead>
                              ))}
                            </TableRow>
                          ))}
                        </TableHeader>
                        <TableBody>
                          {table.getRowModel().rows?.length ? (
                            table.getRowModel().rows.map((row) => (
                              <TableRow
                                key={row.id}
                                data-state={row.getIsSelected() && "selected"}
                              >
                                {row.getVisibleCells().map((cell) => (
                                  <TableCell key={cell.id}>
                                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                                  </TableCell>
                                ))}
                              </TableRow>
                            ))
                          ) : (
                            <TableRow>
                              <TableCell colSpan={columns.length} className="h-24 text-center">
                                <div className="flex flex-col items-center justify-center">
                                  <Users className="h-12 w-12 text-muted-foreground mb-4" />
                                  <p className="text-lg font-medium">{t('common.noData')}</p>
                                  <p className="text-muted-foreground">
                                    {t('modules.userManagement.noUsersFound') || 'No users found matching your criteria'}
                                  </p>
                                </div>
                              </TableCell>
                            </TableRow>
                          )}
                        </TableBody>
                      </Table>
                    </div>

                    {/* Pagination */}
                    <div className="flex items-center justify-between space-x-2 py-4">
                      <div className="text-sm text-muted-foreground">
                        {t('modules.userManagement.rowsSelected')
                          .replace('{selected}', selectedUserIds.length.toString())
                          .replace('{total}', users.length.toString())}
                      </div>
                      <div className="flex items-center space-x-4">
                        <div className="flex items-center space-x-2">
                          <p className="text-sm font-medium">{t('modules.userManagement.rowsPerPage') || 'Rows per page'}</p>
                          <Select
                            value={`${pagination.limit}`}
                            onValueChange={(value) => handlePageSizeChange(Number(value))}
                          >
                            <SelectTrigger className="w-20">
                              <SelectValue placeholder={pagination.limit} />
                            </SelectTrigger>
                            <SelectContent side="top">
                              {[50, 100, 200, 250, 500].map((pageSize) => (
                                <SelectItem key={pageSize} value={`${pageSize}`}>
                                  {pageSize}
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        </div>
                        <div className="flex items-center space-x-2">
                          <p className="text-sm font-medium">{t('modules.userManagement.page') || 'Page'}</p>
                          <span className="text-sm text-muted-foreground">
                            {pagination.page} {t('modules.userManagement.of') || 'of'} {pagination.totalPages}
                          </span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handlePageChange(1)}
                            disabled={!pagination.hasPrev}
                          >
                            <ChevronsLeftIcon className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handlePageChange(pagination.page - 1)}
                            disabled={!pagination.hasPrev}
                          >
                            <ChevronLeftIcon className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handlePageChange(pagination.page + 1)}
                            disabled={!pagination.hasNext}
                          >
                            <ChevronRightIcon className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handlePageChange(pagination.totalPages)}
                            disabled={!pagination.hasNext}
                          >
                            <ChevronsRightIcon className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  </>
                )}
              </CardContent>
            </Card>
              </TabsContent>

              {/* Deletion Requests Tab */}
              <TabsContent value="deletion-requests" className="space-y-6">
                {/* Deletion Stats Cards */}
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.accountDeletion.pendingDeletion') || 'Pending Requests'}
                      </CardTitle>
                      <AlertTriangle className="h-4 w-4 text-destructive" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold text-destructive">
                        {statsLoading ? '...' : deletionStats.pending.toLocaleString()}
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.accountDeletion.isProcessed') || 'Processed'}
                      </CardTitle>
                      <UserCheck className="h-4 w-4 text-green-600" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold text-green-600">
                        {statsLoading ? '...' : deletionStats.processed.toLocaleString()}
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.accountDeletion.isCanceled') || 'Canceled'}
                      </CardTitle>
                      <Users className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">
                        {statsLoading ? '...' : deletionStats.canceled.toLocaleString()}
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.accountDeletion.totalRequests') || 'Total Requests'}
                      </CardTitle>
                      <Users className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">
                        {statsLoading ? '...' : deletionStats.total.toLocaleString()}
                      </div>
                    </CardContent>
                  </Card>
                </div>

                {/* Deletion Requests Table */}
                <Card>
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div>
                        <CardTitle>{t('modules.userManagement.accountDeletion.title') || 'Account Deletion Requests'}</CardTitle>
                        <CardDescription>
                          {t('modules.userManagement.accountDeletion.description') || 'Manage account deletion requests from users'}
                        </CardDescription>
                      </div>
                      {selectedDeletionRequestIds.length > 0 && (
                        <div className="flex items-center gap-2">
                          <Button 
                            variant="destructive" 
                            size="sm"
                            onClick={() => setBulkApproveOpen(true)}
                            disabled={bulkProcessing || requestProcessing || deletionProcessing}
                          >
                            <AlertTriangle className="h-4 w-4 mr-2" />
                            {t('modules.userManagement.accountDeletion.approveRequest') || 'Approve & Delete'} ({selectedDeletionRequestIds.length})
                          </Button>
                          <Button variant="ghost" size="sm" onClick={() => setSelectedDeletionRequestIds([])}>
                            {t('modules.userManagement.clearSelection') || 'Clear selection'}
                          </Button>
                        </div>
                      )}
                    </div>
                  </CardHeader>
                  <CardContent>
                    {/* Deletion Requests Filters */}
                    <div className="flex flex-col gap-4 md:flex-row md:items-end mb-6">
                      <Select value={deletionRequestStatusFilter} onValueChange={setDeletionRequestStatusFilter}>
                        <SelectTrigger className="w-[200px]">
                          <SelectValue placeholder={t('modules.userManagement.accountDeletion.filterByStatus') || 'Filter by status'} />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">{t('common.all')} {t('modules.userManagement.accountDeletion.statuses') || 'Requests'}</SelectItem>
                          <SelectItem value="pending">{t('modules.userManagement.accountDeletion.pendingDeletion') || 'Pending'}</SelectItem>
                          <SelectItem value="processed">{t('modules.userManagement.accountDeletion.isProcessed') || 'Processed'}</SelectItem>
                          <SelectItem value="canceled">{t('modules.userManagement.accountDeletion.isCanceled') || 'Canceled'}</SelectItem>
                        </SelectContent>
                      </Select>
                      <div className="flex gap-2">
                        {deletionRequestStatusFilter !== 'all' && (
                          <Button variant="outline" onClick={handleClearDeletionFilters}>
                            {t('modules.userManagement.clearFilters') || 'Clear Filters'}
                          </Button>
                        )}
                      </div>
                    </div>

                    {/* Deletion Requests Table */}
                    {deletionRequestsLoading ? (
                      <div className="space-y-3">
                        {[...Array(5)].map((_, i) => (
                          <Skeleton key={i} className="h-16 w-full" />
                        ))}
                      </div>
                    ) : paginatedDeletionRequests.length > 0 ? (
                      <div className="rounded-md border overflow-x-auto">
                        <Table>
                          <TableHeader>
                            <TableRow>
                              <TableHead>
                                <Checkbox
                                  checked={
                                    paginatedDeletionRequests.length > 0 &&
                                    selectedDeletionRequestIds.length === paginatedDeletionRequests.filter(r => !r.isProcessed && !r.isCanceled).length
                                  }
                                  onCheckedChange={(value) => {
                                    if (value) {
                                      setSelectedDeletionRequestIds(
                                        paginatedDeletionRequests
                                          .filter(r => !r.isProcessed && !r.isCanceled)
                                          .map(r => r.id)
                                      );
                                    } else {
                                      setSelectedDeletionRequestIds([]);
                                    }
                                  }}
                                  aria-label="Select all"
                                />
                              </TableHead>
                              <TableHead>{t('modules.userManagement.accountDeletion.requestId') || 'Request ID'}</TableHead>
                              <TableHead>{t('modules.userManagement.user') || 'User'}</TableHead>
                              <TableHead>{t('modules.userManagement.accountDeletion.reasonCategory') || 'Reason'}</TableHead>
                              <TableHead>{t('modules.userManagement.accountDeletion.requestedAt') || 'Requested At'}</TableHead>
                              <TableHead>{t('modules.userManagement.accountDeletion.daysSinceRequest') || 'Days Since'}</TableHead>
                              <TableHead>{t('modules.userManagement.accountDeletion.status') || 'Status'}</TableHead>
                              <TableHead>{t('common.actions') || 'Actions'}</TableHead>
                            </TableRow>
                          </TableHeader>
                          <TableBody>
                            {paginatedDeletionRequests.map((request) => (
                              <TableRow key={request.id}>
                                <TableCell>
                                  {!request.isProcessed && !request.isCanceled ? (
                                    <Checkbox
                                      checked={selectedDeletionRequestIds.includes(request.id)}
                                      onCheckedChange={(value) => {
                                        setSelectedDeletionRequestIds(prev => {
                                          if (value) {
                                            return Array.from(new Set([...prev, request.id]));
                                          } else {
                                            return prev.filter(id => id !== request.id);
                                          }
                                        });
                                      }}
                                      aria-label="Select row"
                                    />
                                  ) : (
                                    <div className="w-4" />
                                  )}
                                </TableCell>
                                <TableCell>
                                  <div className="font-mono text-sm max-w-[120px] truncate">
                                    {request.id}
                                  </div>
                                </TableCell>
                                <TableCell>
                                  <div className="space-y-1">
                                    <p className="text-sm font-medium">{request.userName || request.userEmail}</p>
                                    <p className="text-xs text-muted-foreground">{request.userEmail}</p>
                                  </div>
                                </TableCell>
                                <TableCell className="align-top">
                                  <div className="space-y-1 max-w-[320px] md:max-w-none">
                                    <p className="text-sm">{getDeletionCategoryText(request.reasonCategory)}</p>
                                    <p className="text-xs text-muted-foreground">{getDeletionReasonText(request.reasonId)}</p>
                                    {request.reasonDetails && request.reasonDetails.trim().length > 0 && (
                                      <p className="text-xs text-muted-foreground whitespace-pre-wrap break-words break-anywhere">
                                        <span className="font-medium">{t('modules.userManagement.accountDeletion.reasonDetails') || 'Reason Details'}: </span>
                                        <span>{request.reasonDetails}</span>
                                      </p>
                                    )}
                                  </div>
                                </TableCell>
                                <TableCell>
                                  <div className="text-sm">{formatDeletionDate(request.requestedAt)}</div>
                                </TableCell>
                                <TableCell>
                                  <div className="text-sm font-medium">
                                    {(() => {
                                      const startDate = request.requestedAt instanceof Date ? request.requestedAt : new Date(request.requestedAt);
                                      const endDate = request.isCanceled && request.canceledAt
                                        ? (request.canceledAt instanceof Date ? request.canceledAt : new Date(request.canceledAt))
                                        : request.isProcessed && request.processedAt
                                          ? (request.processedAt instanceof Date ? request.processedAt : new Date(request.processedAt))
                                          : new Date();
                                      const diffMs = Math.max(0, endDate.getTime() - startDate.getTime());
                                      const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));
                                      return t('modules.userManagement.accountDeletion.daysSince', { count: days });
                                    })()}
                                  </div>
                                </TableCell>
                                <TableCell>
                                  {getDeletionRequestStatusBadge(request)}
                                </TableCell>
                                <TableCell>
                                  <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                      <Button variant="ghost" className="h-8 w-8 p-0">
                                        <MoreHorizontal className="h-4 w-4" />
                                      </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end">
                                      <DropdownMenuItem asChild>
                                        <Link href={`/${locale}/user-management/users/${request.userId}?tab=deletion`}>
                                          <Eye className="h-4 w-4 mr-2" />
                                          {t('modules.userManagement.accountDeletion.viewDeletionRequest') || 'View Request'}
                                        </Link>
                                      </DropdownMenuItem>
                                      <DropdownMenuItem asChild>
                                        <Link href={`/${locale}/user-management/users/${request.userId}`}>
                                          <User className="h-4 w-4 mr-2" />
                                          {t('modules.userManagement.viewDetails') || 'View User'}
                                        </Link>
                                      </DropdownMenuItem>
                                      {!request.isProcessed && !request.isCanceled && (
                                        <>
                                          <DropdownMenuSeparator />
                                          <DropdownMenuItem
                                            onClick={() => openApproveDeletion(request)}
                                            className="text-red-600"
                                          >
                                            <AlertTriangle className="h-4 w-4 mr-2" />
                                            {t('modules.userManagement.accountDeletion.approveRequest') || 'Approve & Delete'}
                                          </DropdownMenuItem>
                                        </>
                                      )}
                                    </DropdownMenuContent>
                                  </DropdownMenu>
                                </TableCell>
                              </TableRow>
                            ))}
                          </TableBody>
                        </Table>
                      </div>
                    ) : (
                      <div className="text-center py-8">
                        <div className="flex flex-col items-center justify-center">
                          <AlertTriangle className="h-12 w-12 text-muted-foreground mb-4" />
                          <p className="text-lg font-medium">{t('common.noData')}</p>
                          <p className="text-muted-foreground">
                            {t('modules.userManagement.accountDeletion.noDeletionRequest') || 'No deletion requests found'}
                          </p>
                        </div>
                      </div>
                    )}

                    {/* Deletion Requests Pagination */}
                    {paginatedDeletionRequests.length > 0 && (
                      <div className="flex items-center justify-between space-x-2 py-4">
                        <div className="text-sm text-muted-foreground">
                          {t('modules.userManagement.showingResults')
                            ?.replace('{start}', (deletionRequestsPagination.pageIndex * deletionRequestsPagination.pageSize + 1).toString())
                            ?.replace('{end}', Math.min((deletionRequestsPagination.pageIndex + 1) * deletionRequestsPagination.pageSize, totalDeletionRequests).toString())
                            ?.replace('{total}', totalDeletionRequests.toString()) || 
                            `Showing ${deletionRequestsPagination.pageIndex * deletionRequestsPagination.pageSize + 1} to ${Math.min((deletionRequestsPagination.pageIndex + 1) * deletionRequestsPagination.pageSize, totalDeletionRequests)} of ${totalDeletionRequests} results`}
                        </div>
                        <div className="flex items-center space-x-4">
                          <div className="flex items-center space-x-2">
                            <p className="text-sm font-medium">{t('modules.userManagement.rowsPerPage') || 'Rows per page'}</p>
                            <Select
                              value={`${deletionRequestsPagination.pageSize}`}
                              onValueChange={(value) => handleDeletionPageSizeChange(Number(value))}
                            >
                              <SelectTrigger className="w-20">
                                <SelectValue placeholder={deletionRequestsPagination.pageSize} />
                              </SelectTrigger>
                              <SelectContent side="top">
                                {[10, 20, 50, 100].map((pageSize) => (
                                  <SelectItem key={pageSize} value={`${pageSize}`}>
                                    {pageSize}
                                  </SelectItem>
                                ))}
                              </SelectContent>
                            </Select>
                          </div>
                          <div className="flex items-center space-x-2">
                            <p className="text-sm font-medium">{t('modules.userManagement.page') || 'Page'}</p>
                            <span className="text-sm text-muted-foreground">
                              {deletionRequestsPagination.pageIndex + 1} {t('modules.userManagement.of') || 'of'} {totalDeletionPages}
                            </span>
                          </div>
                          <div className="flex items-center space-x-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleDeletionPageChange(0)}
                              disabled={deletionRequestsPagination.pageIndex === 0}
                            >
                              <ChevronsLeftIcon className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleDeletionPageChange(deletionRequestsPagination.pageIndex - 1)}
                              disabled={deletionRequestsPagination.pageIndex === 0}
                            >
                              <ChevronLeftIcon className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleDeletionPageChange(deletionRequestsPagination.pageIndex + 1)}
                              disabled={deletionRequestsPagination.pageIndex >= totalDeletionPages - 1}
                            >
                              <ChevronRightIcon className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleDeletionPageChange(totalDeletionPages - 1)}
                              disabled={deletionRequestsPagination.pageIndex >= totalDeletionPages - 1}
                            >
                              <ChevronsRightIcon className="h-4 w-4" />
                            </Button>
                          </div>
                        </div>
                      </div>
                    )}
                  </CardContent>
                </Card>
              </TabsContent>
            </Tabs>

            {/* Approve & Delete Deletion Request Dialog */}
            <Dialog open={showApproveDeletionDialog} onOpenChange={setShowApproveDeletionDialog}>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle className="flex items-center gap-2">
                    <AlertTriangle className="h-5 w-5 text-destructive" />
                    {t('modules.userManagement.accountDeletion.approveDeletionTitle') || 'Approve Account Deletion'}
                  </DialogTitle>
                  <DialogDescription>
                    {t('modules.userManagement.accountDeletion.approveDeletionDescription') || "Are you sure you want to approve this account deletion request? This action will permanently delete the user's account and cannot be undone."}
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div>
                    <label className="text-sm font-medium mb-2 block">
                      {t('modules.userManagement.accountDeletion.adminNotes') || 'Admin Notes'} ({t('common.optional') || 'Optional'})
                    </label>
                    <Textarea
                      value={adminNotes}
                      onChange={(e) => setAdminNotes(e.target.value)}
                      placeholder={t('modules.userManagement.accountDeletion.addNotesPlaceholder') || 'Add any notes about this approval...'}
                      className="min-h-[80px]"
                    />
                  </div>
                </div>
                <DialogFooter>
                  <Button variant="outline" onClick={() => setShowApproveDeletionDialog(false)} disabled={requestProcessing || deletionProcessing}>
                    {t('common.cancel')}
                  </Button>
                  <Button 
                    variant="destructive" 
                    onClick={confirmApproveDeletion}
                    disabled={requestProcessing || deletionProcessing}
                  >
                    {(requestProcessing || deletionProcessing) && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                    {t('common.approve') || 'Approve'}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>

            {/* Bulk Approve & Delete Dialog */}
            <Dialog open={bulkApproveOpen} onOpenChange={setBulkApproveOpen}>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle className="flex items-center gap-2">
                    <AlertTriangle className="h-5 w-5 text-destructive" />
                    {t('modules.userManagement.accountDeletion.approveDeletionTitle') || 'Approve Account Deletion'}
                  </DialogTitle>
                  <DialogDescription>
                    {t('modules.userManagement.deleteUsersConfirmation')
                      ? t('modules.userManagement.deleteUsersConfirmation').replace('{count}', selectedDeletionRequestIds.length.toString())
                      : `Approve & delete ${selectedDeletionRequestIds.length} account(s)? This cannot be undone.`}
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div>
                    <label className="text-sm font-medium mb-2 block">
                      {t('modules.userManagement.accountDeletion.adminNotes') || 'Admin Notes'} ({t('common.optional') || 'Optional'})
                    </label>
                    <Textarea
                      value={bulkAdminNotes}
                      onChange={(e) => setBulkAdminNotes(e.target.value)}
                      placeholder={t('modules.userManagement.accountDeletion.addNotesPlaceholder') || 'Add any notes about this approval...'}
                      className="min-h-[80px]"
                    />
                  </div>
                </div>
                <DialogFooter>
                  <Button variant="outline" onClick={() => setBulkApproveOpen(false)} disabled={bulkProcessing || requestProcessing || deletionProcessing}>
                    {t('common.cancel')}
                  </Button>
                  <Button 
                    variant="destructive" 
                    onClick={async () => {
                      try {
                        setBulkProcessing(true);
                        for (const requestId of selectedDeletionRequestIds) {
                          const req = deletionRequests.find(r => r.id === requestId);
                          if (!req) continue;
                          await approveRequest(requestId, bulkAdminNotes, 'admin-user');
                          await executeUserDeletion(req.userId, 'admin-user');
                        }
                        toast.success(t('modules.userManagement.accountDeletion.approveSuccess') || 'Deletion requests approved and users deleted successfully');
                        setSelectedDeletionRequestIds([]);
                        setBulkAdminNotes('');
                        setBulkApproveOpen(false);
                        await refetchDeletionRequests();
                      } catch (error) {
                        console.error('Bulk approve & delete error:', error);
                        toast.error(t('modules.userManagement.accountDeletion.approveError') || 'Bulk approval failed');
                      } finally {
                        setBulkProcessing(false);
                      }
                    }}
                    disabled={bulkProcessing || requestProcessing || deletionProcessing || selectedDeletionRequestIds.length === 0}
                  >
                    {(bulkProcessing || requestProcessing || deletionProcessing) && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                    {t('modules.userManagement.accountDeletion.approveRequest') || 'Approve & Delete'}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>

            {/* Delete Confirmation Dialog */}
            <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle className="flex items-center gap-2">
                    <AlertTriangle className="h-5 w-5 text-destructive" />
                    {t('modules.userManagement.deleteUsers') || 'Delete Users'}
                  </DialogTitle>
                  <DialogDescription>
                    {t('modules.userManagement.deleteUsersConfirmation').replace('{count}', usersToDelete.length.toString())}
                  </DialogDescription>
                </DialogHeader>
                <DialogFooter>
                  <Button variant="outline" onClick={() => setShowDeleteDialog(false)}>
                    {t('common.cancel')}
                  </Button>
                  <Button
                    onClick={() => handleDeleteUsers(usersToDelete)}
                    disabled={bulkActionLoading}
                    className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                  >
                    {bulkActionLoading ? (t('modules.userManagement.deleting') || 'Deleting...') : (t('common.delete') || 'Delete')}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </div>
        </div>
      </div>
    </>
  );
} 