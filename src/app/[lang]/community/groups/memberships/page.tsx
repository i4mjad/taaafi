'use client';

import { useState, useMemo } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { SiteHeader } from '@/components/site-header';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { MembershipsTable } from '@/components/memberships-table';
import { 
  Users, 
  Search, 
  Crown, 
  UserCheck,
  Building,
  X
} from 'lucide-react';

export default function GroupMembershipsPage() {
  const params = useParams();
  const lang = params.lang as string;
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [activeSearch, setActiveSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [roleFilter, setRoleFilter] = useState<string>('all');

  // Handle search button click
  const handleSearch = () => {
    setActiveSearch(search.trim());
  };

  // Handle clear search
  const handleClearSearch = () => {
    setSearch('');
    setActiveSearch('');
  };

  // Handle Enter key in search input
  const handleSearchKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      handleSearch();
    }
  };

  // Fetch all groups for lookup
  const [groupsSnapshot] = useCollection(
    query(collection(db, 'groups'), orderBy('createdAt', 'desc'))
  );

  const groups = useMemo(() => {
    if (!groupsSnapshot) return [];
    return groupsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    }));
  }, [groupsSnapshot]);

  // Determine matching group IDs for search (searches both group ID and group name)
  const searchMatchingGroupIds = useMemo(() => {
    if (!activeSearch.trim() || !groups.length) return [];
    
    const searchTerm = activeSearch.trim().toLowerCase();
    
    // Find groups that match the search term in EITHER ID or name
    const matchingGroups = groups.filter((group: any) => 
      group.id.toLowerCase().includes(searchTerm) || 
      group.name?.toLowerCase().includes(searchTerm)
    );
    
    return matchingGroups.map((group: any) => group.id);
  }, [activeSearch, groups]);

  // Build memberships query based on filters
  const membershipsQuery = useMemo(() => {
    try {
      let constraints: any[] = [];
      
      // If we have an active search term, search both group IDs and group names
      if (activeSearch.trim()) {
        const searchTerm = activeSearch.trim().toLowerCase();
        
        // Always search by both group ID and group name using the matching group IDs
        if (searchMatchingGroupIds.length > 0) {
          // Firestore 'in' operator supports up to 10 values
          const groupIdBatch = searchMatchingGroupIds.slice(0, 10);
          constraints.push(where('groupId', 'in', groupIdBatch));
        } else {
          // No matching groups found, return empty query
          constraints.push(where('groupId', '==', '__NO_MATCHES__'));
        }
        
        // Use default ordering when searching
        constraints.push(orderBy('joinedAt', 'desc'));
        
        // Add other filters if compatible
        if (statusFilter !== 'all') {
          const isActive = statusFilter === 'active';
          constraints.push(where('isActive', '==', isActive));
        }
        
        if (roleFilter !== 'all') {
          constraints.push(where('role', '==', roleFilter));
        }
      } else {
        // No search term - apply filters and default ordering
        
        // Filter by active status
        if (statusFilter !== 'all') {
          const isActive = statusFilter === 'active';
          constraints.push(where('isActive', '==', isActive));
        }
        
        // Filter by role
        if (roleFilter !== 'all') {
          constraints.push(where('role', '==', roleFilter));
        }
        
        // Default ordering by joinedAt
        constraints.push(orderBy('joinedAt', 'desc'));
      }
      
      const q = query(collection(db, 'group_memberships'), ...constraints);
      console.log('Query built successfully with constraints:', constraints.length);
      return q;
    } catch (error) {
      console.error('Error building query:', error);
      // Return basic query as fallback
      return query(collection(db, 'group_memberships'), orderBy('joinedAt', 'desc'));
    }
  }, [statusFilter, roleFilter, activeSearch, searchMatchingGroupIds]);

  // Fetch memberships based on filters
  const [membershipsSnapshot, membershipsLoading, membershipsError] = useCollection(membershipsQuery);

  // Debug logging
  console.log('Memberships Debug:', {
    loading: membershipsLoading,
    error: membershipsError?.message || null,
    snapshotExists: !!membershipsSnapshot,
    docsCount: membershipsSnapshot?.docs?.length || 0,
    statusFilter,
    roleFilter,
    inputSearch: search,
    activeSearch: activeSearch,
    hasActiveSearch: !!activeSearch.trim(),
    searchTerm: activeSearch.trim() ? activeSearch.trim().toLowerCase() : 'none',
    searchMode: activeSearch.trim() ? 'active' : 'inactive',
    matchingGroupIds: searchMatchingGroupIds,
    matchingGroupsCount: searchMatchingGroupIds.length,
    totalGroupsCount: groups.length
  });

  // Log first few docs for debugging
  if (membershipsSnapshot && membershipsSnapshot.docs && membershipsSnapshot.docs.length > 0) {
    console.log('Sample membership docs:', membershipsSnapshot.docs.slice(0, 3).map(doc => ({
      id: doc.id,
      groupId: doc.data().groupId,
      role: doc.data().role,
      isActive: doc.data().isActive
    })));
  } else if (!membershipsLoading && activeSearch.trim()) {
    console.log('🔍 No results for search term:', activeSearch.trim().toLowerCase());
    if (searchMatchingGroupIds.length > 0) {
      console.log('📋 Found matching groups by ID/name:', searchMatchingGroupIds);
      console.log('🤔 But no memberships found for these groups');
      
      // Show which groups matched for debugging
      const matchingGroupDetails = groups.filter((g: any) => searchMatchingGroupIds.includes(g.id))
        .map((g: any) => ({ id: g.id, name: g.name || 'No name' }));
      console.log('📋 Matching group details:', matchingGroupDetails);
    } else {
      console.log('❌ No groups found matching the search term in either ID or name');
    }
  }

  // Log all unique groupIds when not searching (to help debug search terms)  
  if (!activeSearch.trim() && membershipsSnapshot && membershipsSnapshot.docs && membershipsSnapshot.docs.length > 0) {
    const uniqueGroupIds = [...new Set(membershipsSnapshot.docs.map(doc => doc.data().groupId))];
    console.log('📋 Available groupIds in database:', uniqueGroupIds.slice(0, 10)); // Show first 10
  }

  // Log available group names when not searching
  if (!activeSearch.trim() && groups.length > 0) {
    const groupNames = groups.filter((g: any) => g.name).map((g: any) => g.name).slice(0, 10);
    console.log('📋 Available group names:', groupNames);
  }

  const memberships = useMemo(() => {
    if (!membershipsSnapshot) return [];
    return membershipsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      joinedAt: doc.data().joinedAt?.toDate() || new Date(),
      leftAt: doc.data().leftAt?.toDate(),
    }));
  }, [membershipsSnapshot]);

  // Create a lookup for group names (for display purposes)
  const groupsLookup = useMemo(() => {
    return groups.reduce((acc, group) => {
      acc[group.id] = group;
      return acc;
    }, {} as Record<string, any>);
  }, [groups]);

  // Process memberships data for table (already filtered from server)
  const tableData = useMemo(() => {
    return memberships.map((membership: any) => ({
      id: membership.id,
      cpId: membership.cpId,
      groupId: membership.groupId,
      groupName: groupsLookup[membership.groupId]?.name || membership.groupId,
      role: membership.role as 'admin' | 'member',
      isActive: membership.isActive,
      joinedAt: membership.joinedAt,
      leftAt: membership.leftAt,
      pointsTotal: membership.pointsTotal || 0,
    }));
  }, [memberships, groupsLookup]);

  // All filtering is now handled server-side, no need for client-side filtering
  const filteredTableData = tableData;

  const stats = {
    totalMemberships: tableData.length, // Server-filtered memberships
    admins: tableData.filter(m => m.role === 'admin').length,
    regularMembers: tableData.filter(m => m.role === 'member').length,
    totalGroups: groups.length, // All groups for total count
    activeGroups: groups.filter((g: any) => g.isActive).length,
  };

  if (membershipsLoading) {
    return (
      <div className="h-full flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t('modules.admin.memberships.title')}</h1>
            <p className="text-muted-foreground">{t('modules.admin.memberships.description')}</p>
          </div>
        </div>
        <div className="flex-1 overflow-auto">
          <div className="p-6">
            <div className="flex items-center justify-center py-12">
              <Users className="h-12 w-12 text-muted-foreground animate-pulse" />
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (membershipsError) {
    console.error('Memberships Error:', membershipsError);
    return (
      <div className="h-full flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t('modules.admin.memberships.title')}</h1>
            <p className="text-muted-foreground">{t('modules.admin.memberships.description')}</p>
          </div>
        </div>
        <div className="flex-1 overflow-auto">
          <div className="p-6">
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <h2 className="text-red-800 font-medium mb-2">Error loading memberships</h2>
              <p className="text-red-600">{membershipsError.message}</p>
              <p className="text-sm text-red-500 mt-2">Check the console for more details.</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const headerDictionary = {
    documents: t('modules.admin.memberships.title') || 'Group Memberships',
  };

  const tableDictionary = {
    searchPlaceholder: t('modules.admin.memberships.searchPlaceholder') || 'Search memberships...',
    headers: {
      userId: t('modules.admin.memberships.userId') || 'User ID',
      groupName: t('modules.admin.memberships.groupName') || 'Group Name',
      role: t('modules.admin.memberships.role') || 'Role',
      status: t('modules.admin.memberships.status') || 'Status',
      joinedAt: t('modules.admin.memberships.joinedAt') || 'Joined',
      points: t('modules.admin.memberships.points') || 'Points',
    },
    roleLabels: {
      admin: t('modules.admin.memberships.admin') || 'Admin',
      member: t('modules.admin.memberships.member') || 'Member',
    },
    statusLabels: {
      active: t('common.active') || 'Active',
      inactive: t('common.inactive') || 'Inactive',
    },
    actions: {
      viewDetails: t('modules.admin.memberships.viewDetails') || 'View Details',
      manageGroup: t('modules.admin.memberships.manageGroup') || 'Manage Group',
    },
    columnsText: t('modules.admin.memberships.columns') || 'Columns',
    noDataText: t('modules.admin.memberships.noData') || 'No memberships found.',
    pagination: {
      selected: t('modules.admin.memberships.pagination.selected') || 'row(s) selected.',
      rowsPerPage: t('modules.admin.memberships.pagination.rowsPerPage') || 'Rows per page',
      page: t('modules.admin.memberships.pagination.page') || 'Page',
      of: t('modules.admin.memberships.pagination.of') || 'of',
    },
  };

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">
              {t('modules.admin.memberships.title')}
            </h1>
            <p className="text-muted-foreground">
              {t('modules.admin.memberships.description')}
            </p>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto">
          <div className="p-6 space-y-6 max-w-none">
            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.admin.memberships.totalMemberships')}
                  </CardTitle>
                  <UserCheck className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.totalMemberships}</div>
                  <p className="text-xs text-muted-foreground">
                    {t('modules.admin.memberships.acrossGroups', { count: stats.totalGroups })}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.admin.memberships.groupAdmins')}
                  </CardTitle>
                  <Crown className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.admins}</div>
                  <p className="text-xs text-muted-foreground">
                    {stats.regularMembers} {t('modules.admin.memberships.regularMembers')}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.admin.memberships.activeGroups')}
                  </CardTitle>
                  <Building className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.activeGroups}</div>
                  <p className="text-xs text-muted-foreground">
                    {t('modules.admin.memberships.ofTotal', { total: stats.totalGroups })}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.admin.memberships.filteredResults')}
                  </CardTitle>
                  <Search className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{filteredTableData.length}</div>
                  <p className="text-xs text-muted-foreground">
                    {t('modules.admin.memberships.matchingCriteria')}
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Filters */}
            <Card>
              <CardHeader>
                <CardTitle>{t('modules.admin.memberships.searchAndFilter')}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium">
                      {t('modules.admin.memberships.searchLabel')}
                    </label>
                    <div className="flex gap-2">
                      <div className="relative flex-1">
                        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                          placeholder={t('modules.admin.memberships.searchPlaceholder')}
                          value={search}
                          onChange={(e) => setSearch(e.target.value)}
                          onKeyDown={handleSearchKeyDown}
                          className="pl-10"
                        />
                      </div>
                      <Button 
                        onClick={handleSearch} 
                        disabled={!search.trim()}
                        variant="default"
                        size="default"
                      >
                        <Search className="h-4 w-4" />
                      </Button>
                      {activeSearch && (
                        <Button 
                          onClick={handleClearSearch} 
                          variant="outline"
                          size="default"
                        >
                          <X className="h-4 w-4" />
                        </Button>
                      )}
                    </div>
                    {activeSearch && (
                      <p className="text-xs text-muted-foreground">
                        🔍 Searching for: "{activeSearch}"
                      </p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">
                      {t('modules.admin.memberships.filterByRole')}
                    </label>
                    <Select value={roleFilter} onValueChange={setRoleFilter}>
                      <SelectTrigger>
                        <SelectValue placeholder={t('modules.admin.memberships.selectRole')} />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">{t('modules.admin.memberships.allRoles')}</SelectItem>
                        <SelectItem value="admin">{t('modules.admin.memberships.admin')}</SelectItem>
                        <SelectItem value="member">{t('modules.admin.memberships.member')}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">
                      {t('modules.admin.memberships.filterByStatus')}
                    </label>
                    <Select value={statusFilter} onValueChange={setStatusFilter}>
                      <SelectTrigger>
                        <SelectValue placeholder={t('modules.admin.memberships.selectStatus')} />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">{t('modules.admin.memberships.allStatuses')}</SelectItem>
                        <SelectItem value="active">{t('common.active')}</SelectItem>
                        <SelectItem value="inactive">{t('common.inactive')}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Memberships Table */}
            <Card>
              <CardHeader>
                <CardTitle>
                  {t('modules.admin.memberships.membershipsList')} ({filteredTableData.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <MembershipsTable
                  data={filteredTableData}
                  groups={groups}
                  dictionary={tableDictionary}
                  lang={lang}
                />
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}
