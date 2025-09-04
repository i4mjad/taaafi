'use client';

import React, { useState, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { doc, collection, query, where, orderBy, updateDoc } from 'firebase/firestore';
import { useDocument, useCollection } from 'react-firebase-hooks/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { 
  ArrowLeft, 
  Users, 
  Search, 
  Crown,
  Trophy,
  Calendar,
  UserMinus,
  MoreHorizontal,
  Eye,
  AlertTriangle
} from 'lucide-react';
import { format } from 'date-fns';
import { Group, GroupMember } from '@/types/community';
import { toast } from 'sonner';
import { SiteHeader } from '@/components/site-header';

export default function GroupMembersPage() {
  const params = useParams();
  const router = useRouter();
  const { t, locale } = useTranslation();
  const isRTL = locale === 'ar';
  const groupId = params.groupId as string;
  const [search, setSearch] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Fetch group data
  const [groupDoc] = useDocument(doc(db, 'groups', groupId));
  const group: Group | undefined = useMemo(() => {
    if (!groupDoc || !groupDoc.exists()) return undefined;
    return {
      id: groupDoc.id,
      ...groupDoc.data(),
      createdAt: groupDoc.data().createdAt?.toDate() || new Date(),
      updatedAt: groupDoc.data().updatedAt?.toDate(),
    } as Group;
  }, [groupDoc]);

  // Fetch group members
  const [membersValue, membersLoading, membersError] = useCollection(
    query(
      collection(db, 'group_memberships'),
      where('groupId', '==', groupId),
      where('isActive', '==', true),
      orderBy('joinedAt', 'desc')
    )
  );

  const members: GroupMember[] = useMemo(() => {
    if (!membersValue) return [];
    return membersValue.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      joinedAt: doc.data().joinedAt?.toDate() || new Date(),
    })) as GroupMember[];
  }, [membersValue]);

  // Filter and sort members
  const filteredMembers = useMemo(() => {
    return members.filter(member => {
      const matchesSearch = !search || 
        member.cpId.toLowerCase().includes(search.toLowerCase()) ||
        (member.displayName && member.displayName.toLowerCase().includes(search.toLowerCase()));
      return matchesSearch;
    });
  }, [members, search]);

  const sortedMembers = useMemo(() => {
    return [...filteredMembers].sort((a, b) => {
      // Admins first
      if (a.role === 'admin' && b.role !== 'admin') return -1;
      if (b.role === 'admin' && a.role !== 'admin') return 1;
      
      // Then by points (descending)
      return (b.pointsTotal || 0) - (a.pointsTotal || 0);
    });
  }, [filteredMembers]);

  const stats = useMemo(() => {
    const total = members.length;
    const admins = members.filter(m => m.role === 'admin').length;
    const totalPoints = members.reduce((sum, m) => sum + (m.pointsTotal || 0), 0);
    const averagePoints = total > 0 ? Math.round(totalPoints / total) : 0;

    return { total, admins, totalPoints, averagePoints };
  }, [members]);

  const headerDictionary = {
    documents: `${group?.name} - ${t('modules.groupsManagement.groupDetail.members')}` || 'Group Members',
  };

  const handleRemoveMember = async (member: GroupMember) => {
    if (!confirm(t('modules.groupsManagement.groupDetail.confirmRemoveMember', { member: member.displayName || member.cpId }) || `Are you sure you want to remove ${member.displayName || member.cpId}?`)) {
      return;
    }

    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'group_memberships', member.id), {
        isActive: false,
        leftAt: new Date(),
      });

      toast.success(t('modules.groupsManagement.groupDetail.memberRemoved') || 'Member removed successfully');
    } catch (error) {
      console.error('Error removing member:', error);
      toast.error(t('modules.groupsManagement.groupDetail.memberRemoveError') || 'Error removing member');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handlePromoteUser = async (member: GroupMember) => {
    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'group_memberships', member.id), {
        role: 'admin',
        promotedAt: new Date(),
      });

      toast.success(t('modules.groupsManagement.groupDetail.userPromoted') || 'User promoted to admin');
    } catch (error) {
      console.error('Error promoting user:', error);
      toast.error(t('modules.groupsManagement.groupDetail.promoteError') || 'Error promoting user');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDemoteUser = async (member: GroupMember) => {
    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'group_memberships', member.id), {
        role: 'member',
        demotedAt: new Date(),
      });

      toast.success(t('modules.groupsManagement.groupDetail.userDemoted') || 'User demoted from admin');
    } catch (error) {
      console.error('Error demoting user:', error);
      toast.error(t('modules.groupsManagement.groupDetail.demoteError') || 'Error demoting user');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (membersLoading) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="container mx-auto py-6 px-4">
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4 animate-pulse" />
              <p className="text-muted-foreground">{t('modules.groupsManagement.groupDetail.loading') || 'Loading members...'}</p>
            </div>
          </div>
        </div>
      </>
    );
  }

  if (membersError) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="container mx-auto py-6 px-4">
          <div className="flex items-center justify-center py-12">
            <Card className="w-full max-w-md">
              <CardContent className="flex flex-col items-center justify-center p-8">
                <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
                <p className="text-center text-destructive font-medium">
                  {t('modules.groupsManagement.groupDetail.loadError') || 'Error loading members'}
                </p>
              </CardContent>
            </Card>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="container mx-auto py-6 px-4 max-w-7xl">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-4">
            <Button variant="ghost" onClick={() => router.push(`/${locale}/groups-management/${groupId}`)}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              {t('modules.groupsManagement.groupDetail.backToGroup') || 'Back to Group'}
            </Button>
            <div className={isRTL ? 'text-right' : 'text-left'}>
              <h1 className="text-3xl font-bold tracking-tight">
                {t('modules.groupsManagement.groupDetail.members') || 'Members'}
              </h1>
              <p className="text-muted-foreground">{group?.name || 'Group Members'}</p>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.groupsManagement.stats.totalMembers') || 'Total Members'}
              </CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.total}</div>
              <p className="text-xs text-muted-foreground">
                {group?.memberCapacity ? `${t('modules.groupsManagement.groupDetail.of') || 'of'} ${group.memberCapacity}` : ''}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.groupsManagement.groupDetail.admins') || 'Admins'}
              </CardTitle>
              <Crown className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.admins}</div>
              <p className="text-xs text-muted-foreground">
                {stats.total - stats.admins} {t('modules.groupsManagement.groupDetail.regularMembers') || 'regular members'}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.groupsManagement.groupDetail.averagePoints') || 'Average Points'}
              </CardTitle>
              <Trophy className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.averagePoints}</div>
              <p className="text-xs text-muted-foreground">
                {t('modules.groupsManagement.groupDetail.perMember') || 'per member'}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.groupsManagement.groupDetail.capacity') || 'Capacity Used'}
              </CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {group?.memberCapacity && group.memberCapacity > 0 ? Math.round((stats.total / group.memberCapacity) * 100) : 0}%
              </div>
              <p className="text-xs text-muted-foreground">
                {t('modules.groupsManagement.groupDetail.used') || 'used'}
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Search */}
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>{t('modules.groupsManagement.groupDetail.searchMembers') || 'Search Members'}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className={`relative ${isRTL ? 'rtl' : 'ltr'}`}>
              <Search className={`absolute top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground ${isRTL ? 'right-3' : 'left-3'}`} />
              <Input
                placeholder={t('modules.groupsManagement.groupDetail.searchPlaceholder') || 'Search members by name or ID...'}
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className={isRTL ? 'pr-10' : 'pl-10'}
                dir={isRTL ? 'rtl' : 'ltr'}
              />
            </div>
          </CardContent>
        </Card>

        {/* Members List */}
        <Card>
          <CardHeader>
            <CardTitle>
              {t('modules.groupsManagement.groupDetail.membersList') || 'Members List'} ({sortedMembers.length})
            </CardTitle>
            <CardDescription>
              {t('modules.groupsManagement.groupDetail.membersDescription') || 'View and manage group members'}
            </CardDescription>
          </CardHeader>
          <CardContent>
            {sortedMembers.length === 0 ? (
              <div className="text-center py-8">
                <Users className="mx-auto h-12 w-12 text-muted-foreground/50" />
                <h3 className="mt-4 text-lg font-semibold">
                  {search ? (t('modules.groupsManagement.groupDetail.noSearchResults') || 'No search results') : (t('modules.groupsManagement.groupDetail.noMembers') || 'No members')}
                </h3>
                <p className="text-muted-foreground">
                  {search ? (t('modules.groupsManagement.groupDetail.tryDifferentSearch') || 'Try a different search term') : (t('modules.groupsManagement.groupDetail.noMembersDesc') || 'This group has no members yet')}
                </p>
              </div>
            ) : (
              <div className="space-y-3">
                {sortedMembers.map((member) => (
                  <div key={member.id} className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50 transition-colors">
                    <div className="flex items-center gap-4">
                      <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center">
                        <Users className="h-5 w-5" />
                      </div>
                      
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <p className="font-medium truncate">{member.displayName || member.cpId}</p>
                          <Badge 
                            variant={member.role === 'admin' ? 'default' : 'secondary'}
                            className="text-xs"
                          >
                            {member.role === 'admin' ? (
                              <>
                                <Crown className="h-3 w-3 mr-1" />
                                {t('modules.groupsManagement.groupDetail.admin') || 'Admin'}
                              </>
                            ) : (
                              t('modules.groupsManagement.groupDetail.member') || 'Member'
                            )}
                          </Badge>
                        </div>
                        
                        <div className="flex items-center gap-4 text-sm text-muted-foreground">
                          <div className="flex items-center gap-1">
                            <Calendar className="h-3 w-3" />
                            {t('modules.groupsManagement.groupDetail.joined') || 'Joined'} {format(member.joinedAt, 'MMM dd, yyyy')}
                          </div>
                          <div className="flex items-center gap-1">
                            <Trophy className="h-3 w-3" />
                            {member.pointsTotal || 0} {t('modules.groupsManagement.groupDetail.points') || 'points'}
                          </div>
                        </div>
                      </div>
                    </div>

                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" className="h-8 w-8 p-0">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align={isRTL ? 'start' : 'end'}>
                        <DropdownMenuItem onClick={() => {/* View profile */}}>
                          <Eye className="mr-2 h-4 w-4" />
                          {t('modules.groupsManagement.actions.viewProfile') || 'View Profile'}
                        </DropdownMenuItem>
                        {member.role === 'member' ? (
                          <DropdownMenuItem 
                            onClick={() => handlePromoteUser(member)}
                            disabled={isSubmitting}
                          >
                            <Crown className="mr-2 h-4 w-4" />
                            {t('modules.groupsManagement.groupDetail.promoteUser') || 'Promote to Admin'}
                          </DropdownMenuItem>
                        ) : (
                          <DropdownMenuItem 
                            onClick={() => handleDemoteUser(member)}
                            disabled={isSubmitting}
                          >
                            <Users className="mr-2 h-4 w-4" />
                            {t('modules.groupsManagement.groupDetail.demoteUser') || 'Demote from Admin'}
                          </DropdownMenuItem>
                        )}
                        <DropdownMenuItem 
                          onClick={() => handleRemoveMember(member)}
                          className="text-destructive"
                          disabled={isSubmitting}
                        >
                          <UserMinus className="mr-2 h-4 w-4" />
                          {t('modules.groupsManagement.groupDetail.removeUser') || 'Remove from Group'}
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </>
  );
}
