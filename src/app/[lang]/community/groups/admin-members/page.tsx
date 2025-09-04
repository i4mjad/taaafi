'use client';

import { useState, useMemo } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { SiteHeader } from '@/components/site-header';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { MembershipsTable } from '@/components/memberships-table';
import { 
  Users, 
  Search, 
  Crown, 
  UserCheck,
  Building
} from 'lucide-react';

export default function GroupMembershipsPage() {
  const params = useParams();
  const lang = params.lang as string;
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [groupFilter, setGroupFilter] = useState<string>('all');
  const [roleFilter, setRoleFilter] = useState<string>('all');

  // Fetch all groups
  const [groupsSnapshot] = useCollection(
    query(collection(db, 'groups'), orderBy('createdAt', 'desc'))
  );

  // Fetch all memberships
  const [membershipsSnapshot, membershipsLoading, membershipsError] = useCollection(
    query(collection(db, 'group_memberships'), orderBy('joinedAt', 'desc'))
  );

  const groups = useMemo(() => {
    if (!groupsSnapshot) return [];
    return groupsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    }));
  }, [groupsSnapshot]);

  const memberships = useMemo(() => {
    if (!membershipsSnapshot) return [];
    return membershipsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      joinedAt: doc.data().joinedAt?.toDate() || new Date(),
      leftAt: doc.data().leftAt?.toDate(),
    }));
  }, [membershipsSnapshot]);

  // Create a lookup for group names
  const groupsLookup = useMemo(() => {
    return groups.reduce((acc, group) => {
      acc[group.id] = group;
      return acc;
    }, {} as Record<string, any>);
  }, [groups]);

  // Process memberships data for table
  const tableData = useMemo(() => {
    return memberships
      .filter(m => m.isActive)
      .map(membership => ({
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

  // Filter table data
  const filteredTableData = useMemo(() => {
    let filtered = tableData;

    if (search) {
      filtered = filtered.filter(m => 
        m.cpId.toLowerCase().includes(search.toLowerCase()) ||
        m.groupName.toLowerCase().includes(search.toLowerCase())
      );
    }

    if (groupFilter !== 'all') {
      filtered = filtered.filter(m => m.groupId === groupFilter);
    }

    if (roleFilter !== 'all') {
      filtered = filtered.filter(m => m.role === roleFilter);
    }

    return filtered;
  }, [tableData, search, groupFilter, roleFilter]);

  const stats = {
    totalMemberships: memberships.filter(m => m.isActive).length,
    admins: memberships.filter(m => m.role === 'admin' && m.isActive).length,
    regularMembers: memberships.filter(m => m.role === 'member' && m.isActive).length,
    totalGroups: groups.length,
    activeGroups: groups.filter(g => g.isActive).length,
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
                    <div className="relative">
                      <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                      <Input
                        placeholder={t('modules.admin.memberships.searchPlaceholder')}
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        className="pl-10"
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">
                      {t('modules.admin.memberships.filterByGroup')}
                    </label>
                    <Select value={groupFilter} onValueChange={setGroupFilter}>
                      <SelectTrigger>
                        <SelectValue placeholder={t('modules.admin.memberships.selectGroup')} />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">{t('modules.admin.memberships.allGroups')}</SelectItem>
                        {groups.map((group) => (
                          <SelectItem key={group.id} value={group.id}>
                            {group.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
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
