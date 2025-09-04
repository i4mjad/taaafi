'use client';

import React, { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where, doc, deleteDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { 
  Search, 
  Users, 
  Plus, 
  Eye, 
  Edit, 
  Trash2, 
  MoreHorizontal, 
  UserPlus, 
  Settings,
  MessageSquareIcon,
  Filter,
  SortAsc,
  SortDesc
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { format } from 'date-fns';
import { Group } from '@/types/community';
import { toast } from 'sonner';

interface GroupsManagementPageProps {
  t: (key: string, interpolations?: Record<string, string | number>) => string;
  locale: string;
}

export default function GroupsManagementPage({ t, locale }: GroupsManagementPageProps) {
  const router = useRouter();
  const isRTL = locale === 'ar';
  const [search, setSearch] = useState('');
  const [genderFilter, setGenderFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [sortField, setSortField] = useState<'name' | 'memberCount' | 'createdAt' | 'memberCapacity'>('createdAt');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc');
  const [selectedGroup, setSelectedGroup] = useState<Group | null>(null);
  const [showDetails, setShowDetails] = useState(false);

  // Fetch groups using react-firebase-hooks
  const [value, loading, error] = useCollection(
    query(collection(db, 'groups'), orderBy('createdAt', 'desc'))
  );

  const groups = useMemo(() => {
    if (!value) return [];
    
    return value.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as Group[];
  }, [value]);

  // Get group IDs for member count fetching
  const groupIds = useMemo(() => groups.map(g => g.id), [groups]);
  
  // Fetch all active group memberships using react-firebase-hooks
  // Since we need all memberships, we'll query without filtering by groupId first
  const [membershipsValue, membershipsLoading] = useCollection(
    query(
      collection(db, 'group_memberships'),
      where('isActive', '==', true)
    )
  );

  // Calculate member counts for each group
  const memberCounts = useMemo(() => {
    if (!membershipsValue) return {};
    
    const counts: Record<string, number> = {};
    const groupIdSet = new Set(groupIds);
    
    // Initialize all group IDs with 0
    groupIds.forEach(id => {
      counts[id] = 0;
    });
    
    // Count memberships for each group (only for groups we're displaying)
    membershipsValue.docs.forEach(doc => {
      const data = doc.data();
      const groupId = data.groupId;
      if (groupId && groupIdSet.has(groupId)) {
        counts[groupId] = (counts[groupId] || 0) + 1;
      }
    });
    
    return counts;
  }, [membershipsValue, groupIds]);

  // Enhance groups with actual member counts
  const groupsWithMemberCounts = useMemo(() => {
    return groups.map(group => ({
      ...group,
      memberCount: memberCounts[group.id] || 0
    }));
  }, [groups, memberCounts]);

  // Enhanced filtering with search by name AND ID
  const filteredGroups = useMemo(() => {
    return groupsWithMemberCounts.filter(group => {
      const matchesSearch = !search || 
        group.name.toLowerCase().includes(search.toLowerCase()) ||
        group.description?.toLowerCase().includes(search.toLowerCase()) ||
        group.id.toLowerCase().includes(search.toLowerCase());
      
      const matchesGender = genderFilter === 'all' || group.gender === genderFilter;
      const matchesStatus = statusFilter === 'all' || 
        (statusFilter === 'active' && group.isActive) ||
        (statusFilter === 'inactive' && !group.isActive);
      
      return matchesSearch && matchesGender && matchesStatus;
    });
  }, [groupsWithMemberCounts, search, genderFilter, statusFilter]);

  // Enhanced sorting
  const sortedGroups = useMemo(() => {
    const sorted = [...filteredGroups].sort((a, b) => {
      let aVal, bVal;
      
      switch (sortField) {
        case 'name':
          aVal = a.name.toLowerCase();
          bVal = b.name.toLowerCase();
          break;
        case 'memberCount':
          aVal = a.memberCount || 0;
          bVal = b.memberCount || 0;
          break;
        case 'memberCapacity':
          aVal = a.memberCapacity || 0;
          bVal = b.memberCapacity || 0;
          break;
        case 'createdAt':
        default:
          aVal = a.createdAt.getTime();
          bVal = b.createdAt.getTime();
          break;
      }

      if (sortDirection === 'asc') {
        return aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
      } else {
        return aVal > bVal ? -1 : aVal < bVal ? 1 : 0;
      }
    });

    return sorted;
  }, [filteredGroups, sortField, sortDirection]);

  // Calculate stats using enhanced groups with real member counts
  const stats = useMemo(() => {
    const total = groupsWithMemberCounts.length || 0;
    const active = groupsWithMemberCounts.filter(g => g.isActive).length || 0;
    const full = groupsWithMemberCounts.filter(g => (g.memberCount || 0) >= (g.memberCapacity || 1)).length || 0;
    const totalMembers = groupsWithMemberCounts.reduce((sum, g) => sum + (g.memberCount || 0), 0) || 0;

    return { total, active, full, totalMembers };
  }, [groupsWithMemberCounts]);

  const handleDeleteGroup = async (group: Group) => {
    if (!confirm(t('modules.community.supportGroups.deleteDescription') || 'Are you sure you want to delete this group?')) {
      return;
    }

    try {
      await deleteDoc(doc(db, 'groups', group.id));
      toast.success(t('modules.community.supportGroups.deleteSuccess') || 'Group deleted successfully');
    } catch (error) {
      console.error('Error deleting group:', error);
      toast.error(t('modules.community.supportGroups.deleteError') || 'Error deleting group');
    }
  };

  const handleRowClick = (group: Group) => {
    // Navigate to group detail screen
    router.push(`/${locale}/groups-management/${group.id}`);
  };

  const handleSort = (field: typeof sortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('desc');
    }
  };

  const getSortIcon = (field: typeof sortField) => {
    if (sortField !== field) return null;
    return sortDirection === 'asc' ? 
      <SortAsc className="h-3 w-3 inline ml-1" /> : 
      <SortDesc className="h-3 w-3 inline ml-1" />;
  };

  if (loading || membershipsLoading) {
    return (
      <div className="h-full flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <div className="h-8 w-48 bg-muted rounded animate-pulse mb-2" />
            <div className="h-4 w-64 bg-muted rounded animate-pulse" />
          </div>
        </div>
        <div className="flex-1 overflow-auto">
          <div className="p-6 space-y-6">
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              {[...Array(4)].map((_, i) => (
                <Card key={i}>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <div className="h-4 w-24 bg-muted rounded animate-pulse" />
                    <div className="h-4 w-4 bg-muted rounded animate-pulse" />
                  </CardHeader>
                  <CardContent>
                    <div className="h-8 w-16 bg-muted rounded animate-pulse mb-2" />
                    <div className="h-3 w-20 bg-muted rounded animate-pulse" />
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="h-full flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t('modules.groupsManagement.title') || 'Groups Management'}</h1>
            <p className="text-muted-foreground">
              {t('modules.groupsManagement.description') || 'Manage community support groups and membership'}
            </p>
          </div>
        </div>
        <div className="flex-1 overflow-auto">
          <div className="p-6">
            <div className="text-center py-8">
              <p className="text-destructive">{t('common.error') || 'Error loading groups'}</p>
              <Button 
                onClick={() => window.location.reload()} 
                variant="outline" 
                className="mt-4"
              >
                {t('common.retry') || 'Retry'}
              </Button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* Header - full width with padding */}
      <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{t('modules.groupsManagement.title') || 'Groups Management'}</h1>
          <p className="text-muted-foreground">
            {t('modules.groupsManagement.description') || 'Manage community support groups and membership'}
          </p>
        </div>
      </div>

      {/* Content area - full width with internal padding */}
      <div className="flex-1 overflow-auto">
        <div className="p-6 space-y-6 max-w-none">
          {/* Stats Cards */}
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('modules.groupsManagement.stats.totalGroups') || 'Total Groups'}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.total}</div>
                <p className="text-xs text-muted-foreground">
                  {t('modules.groupsManagement.stats.allGroups') || 'All groups'}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('modules.groupsManagement.stats.activeGroups') || 'Active Groups'}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.active}</div>
                <p className="text-xs text-muted-foreground">
                  {stats.total > 0 
                    ? `${Math.round((stats.active / stats.total) * 100)}% ${t('modules.groupsManagement.stats.ofTotal') || 'of total'}`
                    : '0%'
                  }
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('modules.groupsManagement.stats.fullGroups') || 'Full Groups'}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.full}</div>
                <p className="text-xs text-muted-foreground">
                  {t('modules.groupsManagement.stats.atCapacity') || 'At capacity'}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('modules.groupsManagement.stats.totalMembers') || 'Total Members'}
                </CardTitle>
                <UserPlus className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.totalMembers}</div>
                <p className="text-xs text-muted-foreground">
                  {t('modules.groupsManagement.stats.acrossAllGroups') || 'Across all groups'}
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Enhanced Filters and Search */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center">
                <Filter className="h-5 w-5 mr-2" />
                {t('modules.groupsManagement.filters.title') || 'Search & Filters'}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="space-y-2 md:col-span-2">
                  <label className="text-sm font-medium">{t('common.search') || 'Search'}</label>
                  <div className={`relative ${isRTL ? 'rtl' : 'ltr'}`}>
                    <Search className={`absolute top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground ${isRTL ? 'right-3' : 'left-3'}`} />
                    <Input
                      placeholder={t('modules.groupsManagement.searchPlaceholder') || 'Search by name, description, or ID...'}
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      className={isRTL ? 'pr-10' : 'pl-10'}
                      dir={isRTL ? 'rtl' : 'ltr'}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('modules.groupsManagement.filters.gender') || 'Gender'}</label>
                  <Select value={genderFilter} onValueChange={setGenderFilter}>
                    <SelectTrigger>
                      <SelectValue placeholder={t('modules.groupsManagement.filters.selectGender') || 'All genders'} />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">{t('common.all') || 'All'}</SelectItem>
                      <SelectItem value="male">{t('modules.groupsManagement.gender.male') || 'Male'}</SelectItem>
                      <SelectItem value="female">{t('modules.groupsManagement.gender.female') || 'Female'}</SelectItem>
                      <SelectItem value="mixed">{t('modules.groupsManagement.gender.mixed') || 'Mixed'}</SelectItem>
                      <SelectItem value="other">{t('modules.groupsManagement.gender.other') || 'Other'}</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('modules.groupsManagement.filters.status') || 'Status'}</label>
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger>
                      <SelectValue placeholder={t('modules.groupsManagement.filters.allStatuses') || 'All statuses'} />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">{t('common.all') || 'All'}</SelectItem>
                      <SelectItem value="active">{t('modules.groupsManagement.status.active') || 'Active'}</SelectItem>
                      <SelectItem value="inactive">{t('modules.groupsManagement.status.inactive') || 'Inactive'}</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Enhanced Groups Table */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>{t('modules.groupsManagement.table.title') || 'Groups'} ({sortedGroups.length})</CardTitle>
                  <CardDescription>
                    {t('modules.groupsManagement.table.description') || 'Click on a group to view details'}
                  </CardDescription>
                </div>
                <div className="text-sm text-muted-foreground">
                  {t('modules.groupsManagement.table.clickToView') || 'Click row to view details'}
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {sortedGroups.length === 0 ? (
                <div className="text-center py-8">
                  <Users className="mx-auto h-12 w-12 text-muted-foreground/50" />
                  <h3 className="mt-4 text-lg font-semibold">
                    {t('modules.groupsManagement.table.noGroupsFound') || 'No groups found'}
                  </h3>
                  <p className="text-muted-foreground">
                    {groups.length === 0 
                      ? (t('modules.groupsManagement.table.noGroupsYet') || 'No groups have been created yet')
                      : (t('modules.groupsManagement.table.adjustFilters') || 'Try adjusting your search or filter criteria')
                    }
                  </p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className={`w-full border-collapse ${isRTL ? 'dir-rtl' : 'dir-ltr'}`} dir={isRTL ? 'rtl' : 'ltr'}>
                    <thead>
                      <tr className="border-b">
                        <th 
                          className={`${isRTL ? 'text-right' : 'text-left'} py-3 px-4 font-medium cursor-pointer hover:bg-muted/50 transition-colors`}
                          onClick={() => handleSort('name')}
                        >
                          {t('modules.groupsManagement.table.name') || 'Name'}
                          {getSortIcon('name')}
                        </th>
                        <th 
                          className={`${isRTL ? 'text-right' : 'text-left'} py-3 px-4 font-medium cursor-pointer hover:bg-muted/50 transition-colors`}
                          onClick={() => handleSort('memberCount')}
                        >
                          {t('modules.groupsManagement.table.members') || 'Members'}
                          {getSortIcon('memberCount')}
                        </th>
                        <th className={`${isRTL ? 'text-right' : 'text-left'} py-3 px-4 font-medium`}>
                          {t('modules.groupsManagement.table.gender') || 'Gender'}
                        </th>
                        <th className={`${isRTL ? 'text-right' : 'text-left'} py-3 px-4 font-medium`}>
                          {t('modules.groupsManagement.table.status') || 'Status'}
                        </th>
                        <th 
                          className={`${isRTL ? 'text-right' : 'text-left'} py-3 px-4 font-medium cursor-pointer hover:bg-muted/50 transition-colors`}
                          onClick={() => handleSort('createdAt')}
                        >
                          {t('modules.groupsManagement.table.created') || 'Created'}
                          {getSortIcon('createdAt')}
                        </th>
                        <th className={`${isRTL ? 'text-right' : 'text-left'} py-3 px-4 font-medium`}>
                          {t('modules.groupsManagement.table.actions') || 'Actions'}
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {sortedGroups.map((group) => (
                        <tr 
                          key={group.id} 
                          className="border-b hover:bg-muted/50 cursor-pointer transition-colors"
                          onClick={() => handleRowClick(group)}
                        >
                          <td className="py-3 px-4">
                            <div className={isRTL ? 'text-right' : 'text-left'}>
                              <div className="font-medium">{group.name}</div>
                              <div className="text-sm text-muted-foreground line-clamp-1">
                                {group.description}
                              </div>
                              <div className="text-xs text-muted-foreground/70 mt-1">
                                ID: {group.id}
                              </div>
                            </div>
                          </td>
                          <td className="py-3 px-4">
                            <div className="flex items-center space-x-2">
                              <span>{group.memberCount || 0} / {group.memberCapacity || 0}</span>
                              {(group.memberCount || 0) >= (group.memberCapacity || 1) && (
                                <Badge variant="destructive" className="text-xs">
                                  {t('modules.groupsManagement.status.full') || 'Full'}
                                </Badge>
                              )}
                            </div>
                          </td>
                          <td className="py-3 px-4">
                            <Badge variant="outline">
                              {group.gender === 'male' && (t('modules.groupsManagement.gender.male') || 'Male')}
                              {group.gender === 'female' && (t('modules.groupsManagement.gender.female') || 'Female')}
                            </Badge>
                          </td>
                          <td className="py-3 px-4">
                            <Badge variant={group.isActive ? 'default' : 'secondary'}>
                              {group.isActive 
                                ? (t('modules.groupsManagement.status.active') || 'Active') 
                                : (t('modules.groupsManagement.status.inactive') || 'Inactive')
                              }
                            </Badge>
                          </td>
                          <td className="py-3 px-4">
                            <div className="text-sm">
                              {format(group.createdAt, 'MMM dd, yyyy')}
                            </div>
                          </td>
                          <td className="py-3 px-4">
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild onClick={(e) => e.stopPropagation()}>
                                <Button variant="ghost" className="h-8 w-8 p-0">
                                  <MoreHorizontal className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align={isRTL ? 'start' : 'end'}>
                                <DropdownMenuItem onClick={(e) => {
                                  e.stopPropagation();
                                  handleRowClick(group);
                                }}>
                                  <Eye className="mr-2 h-4 w-4" />
                                  {t('modules.groupsManagement.actions.viewDetails') || 'View Details'}
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={(e) => {
                                  e.stopPropagation();
                                  router.push(`/${locale}/groups-management/${group.id}/members`);
                                }}>
                                  <Users className="mr-2 h-4 w-4" />
                                  {t('modules.groupsManagement.actions.viewMembers') || 'View Members'}
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={(e) => {
                                  e.stopPropagation();
                                  router.push(`/${locale}/groups-management/${group.id}/messages`);
                                }}>
                                  <MessageSquareIcon className="mr-2 h-4 w-4" />
                                  {t('modules.groupsManagement.actions.viewMessages') || 'View Messages'}
                                </DropdownMenuItem>
                                {/* Edit functionality removed as requested */}
                                <DropdownMenuItem 
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleDeleteGroup(group);
                                  }}
                                  className="text-destructive"
                                >
                                  <Trash2 className="mr-2 h-4 w-4" />
                                  {t('modules.groupsManagement.actions.delete') || 'Delete'}
                                </DropdownMenuItem>
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>

        </div>
      </div>
    </div>
  );
}
