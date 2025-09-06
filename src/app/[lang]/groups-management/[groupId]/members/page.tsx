'use client';

import React, { useState, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { doc, collection, query, where, orderBy, updateDoc, writeBatch } from 'firebase/firestore';
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
  AlertTriangle,
  Clock,
  Shield,
  Ban,
  Activity,
  User,
  MessageSquare
} from 'lucide-react';
import { format } from 'date-fns';
import { Group, GroupMember } from '@/types/community';
import { toast } from 'sonner';
import { SiteHeader } from '@/components/site-header';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';

export default function GroupMembersPage() {
  const params = useParams();
  const router = useRouter();
  const { t, locale } = useTranslation();
  const isRTL = locale === 'ar';
  const groupId = params.groupId as string;
  const [search, setSearch] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showRemovalModal, setShowRemovalModal] = useState(false);
  const [memberToRemove, setMemberToRemove] = useState<GroupMember | null>(null);
  const [removalForm, setRemovalForm] = useState({
    cooldownDuration: 24,
    reason: '',
    adminNote: '',
    removeFromAllGroups: false
  });

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

  // Fetch current group memberships using react-firebase-hooks
  const [membershipsSnapshot, membershipsLoading, membershipsError] = useCollection(
    query(
      collection(db, 'group_memberships'),
      where('groupId', '==', groupId),
      where('isActive', '==', true),
      orderBy('joinedAt', 'desc')
    )
  );

  // Fetch all community profiles using react-firebase-hooks
  const [profilesSnapshot, profilesLoading] = useCollection(
    collection(db, 'communityProfiles')
  );

  // Fetch all groups for membership history using react-firebase-hooks
  const [groupsSnapshot] = useCollection(
    collection(db, 'groups')
  );

  // Fetch all bans using react-firebase-hooks
  const [bansSnapshot] = useCollection(
    query(
      collection(db, 'bans'),
      where('isActive', '==', true)
    )
  );

  // Fetch all warnings using react-firebase-hooks
  const [warningsSnapshot] = useCollection(
    query(
      collection(db, 'warnings'),
      where('isActive', '==', true)
    )
  );

  // Fetch all memberships for history using react-firebase-hooks
  const [allMembershipsSnapshot] = useCollection(
    collection(db, 'group_memberships')
  );

  // Process and combine data into rich community profiles
  const communityProfiles = useMemo(() => {
    if (!membershipsSnapshot || !profilesSnapshot || !allMembershipsSnapshot) return [];

    const currentMemberships = membershipsSnapshot.docs.map(doc => ({ 
      id: doc.id, 
      ...doc.data(),
      joinedAt: doc.data().joinedAt?.toDate() || new Date(),
      leftAt: doc.data().leftAt?.toDate()
    }));

    const allProfiles = profilesSnapshot.docs.map(doc => ({
      cpId: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      nextJoinAllowedAt: doc.data().nextJoinAllowedAt?.toDate() || null,
      rejoinCooldownOverrideUntil: doc.data().rejoinCooldownOverrideUntil?.toDate() || null,
      lastGroupViolationAt: doc.data().lastGroupViolationAt?.toDate() || null,
    }));

    const allGroups = groupsSnapshot?.docs.map(doc => ({ 
      id: doc.id, 
      ...doc.data() 
    })) || [];

    const allMemberships = allMembershipsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      joinedAt: doc.data().joinedAt?.toDate() || new Date(),
      leftAt: doc.data().leftAt?.toDate()
    }));

    const allBans = bansSnapshot?.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      issuedAt: doc.data().issuedAt?.toDate() || new Date(),
      expiresAt: doc.data().expiresAt?.toDate()
    })) || [];

    const allWarnings = warningsSnapshot?.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      issuedAt: doc.data().issuedAt?.toDate() || new Date()
    })) || [];

    return currentMemberships.map(membership => {
      const profile = allProfiles.find(p => p.cpId === membership.cpId);
      if (!profile) return null;

      // Find all memberships for this profile
      const profileMemberships = allMemberships
        .filter(m => m.cpId === membership.cpId)
        .map(m => {
          const group = allGroups.find(g => g.id === m.groupId);
          return {
            ...m,
            groupName: group?.name || 'Unknown Group'
          };
        });

      // Find active bans for this profile
      const profileBans = allBans.filter(ban => 
        ban.userId === profile.cpId && ban.restrictedFeatures?.some((f: string) => 
          f === 'sending_in_groups' || f === 'create_or_join_a_group'
        )
      );

      // Find active warnings for this profile
      const profileWarnings = allWarnings.filter(warning => 
        warning.userId === profile.cpId && 
        ['group_harassment', 'group_spam', 'group_inappropriate_content', 'group_disruption'].includes(warning.type)
      );

      return {
        ...profile,
        currentMembership: {
          id: membership.id,
          role: membership.role,
          joinedAt: membership.joinedAt,
          pointsTotal: membership.pointsTotal || 0,
          leftAt: membership.leftAt,
          removalReason: membership.removalReason,
          removalNote: membership.removalNote,
          removedBy: membership.removedBy
        },
        allMemberships: profileMemberships,
        activeBans: profileBans,
        activeWarnings: profileWarnings
      };
    }).filter(Boolean);
  }, [membershipsSnapshot, profilesSnapshot, allMembershipsSnapshot, groupsSnapshot, bansSnapshot, warningsSnapshot]);

  // Filter profiles based on search
  const filteredProfiles = useMemo(() => {
    return communityProfiles.filter(profile => {
      const matchesSearch = !search || 
        profile.cpId.toLowerCase().includes(search.toLowerCase()) ||
        profile.displayName.toLowerCase().includes(search.toLowerCase()) ||
        profile.userUID.toLowerCase().includes(search.toLowerCase());
      return matchesSearch;
    });
  }, [communityProfiles, search]);

  // Sort profiles by role then by points
  const sortedProfiles = useMemo(() => {
    return [...filteredProfiles].sort((a, b) => {
      // Admins first
      if (a.currentMembership?.role === 'admin' && b.currentMembership?.role !== 'admin') return -1;
      if (b.currentMembership?.role === 'admin' && a.currentMembership?.role !== 'admin') return 1;
      
      // Then by points (descending)
      return (b.currentMembership?.pointsTotal || 0) - (a.currentMembership?.pointsTotal || 0);
    });
  }, [filteredProfiles]);

  const stats = useMemo(() => {
    const total = communityProfiles.length;
    const admins = communityProfiles.filter(p => p.currentMembership?.role === 'admin').length;
    const totalPoints = communityProfiles.reduce((sum, p) => sum + (p.currentMembership?.pointsTotal || 0), 0);
    const withCooldowns = communityProfiles.filter(p => p.nextJoinAllowedAt && p.nextJoinAllowedAt > new Date()).length;
    const withBans = communityProfiles.filter(p => p.activeBans.length > 0).length;
    const withWarnings = communityProfiles.filter(p => p.activeWarnings.length > 0).length;
    
    return {
      total,
      admins,
      members: total - admins,
      averagePoints: total > 0 ? Math.round(totalPoints / total) : 0,
      totalPoints,
      withCooldowns,
      withBans,
      withWarnings
    };
  }, [communityProfiles]);

  const headerDictionary = {
    documents: `${group?.name} - ${t('modules.groupsManagement.groupDetail.members')}` || 'Group Members',
  };

  const handleRemoveMember = (profile: any) => {
    if (!profile.currentMembership) return;
    
    const memberData: GroupMember = {
      id: profile.currentMembership.id,
      cpId: profile.cpId,
      groupId,
      role: profile.currentMembership.role,
      displayName: profile.displayName,
      isActive: true,
      joinedAt: profile.currentMembership.joinedAt,
      pointsTotal: profile.currentMembership.pointsTotal
    };
    
    setMemberToRemove(memberData);
    setShowRemovalModal(true);
    // Reset form
    setRemovalForm({
      cooldownDuration: 24,
      reason: '',
      adminNote: '',
      removeFromAllGroups: false
    });
  };

  const handleConfirmRemoval = async () => {
    if (!memberToRemove || !removalForm.reason) {
      toast.error('Please select a removal reason');
      return;
    }

    setIsSubmitting(true);
    try {
      const batch = writeBatch(db);
      const now = new Date();
      
      // 1. Update membership to inactive
      const membershipRef = doc(db, 'group_memberships', memberToRemove.id);
      batch.update(membershipRef, {
        isActive: false,
        leftAt: now,
        removalReason: removalForm.reason,
        removalNote: removalForm.adminNote,
        removedAt: now,
      });

      // 2. Set cooldown on community profile
      const cooldownEnd = new Date(now);
      cooldownEnd.setHours(cooldownEnd.getHours() + removalForm.cooldownDuration);
      
      const profileRef = doc(db, 'communityProfiles', memberToRemove.cpId);
      batch.update(profileRef, {
        nextJoinAllowedAt: cooldownEnd,
        customCooldownDuration: removalForm.cooldownDuration,
        cooldownReason: `Removed from group: ${removalForm.reason}`,
        updatedAt: now
      });

      // 3. Optionally ban from all groups
      if (removalForm.removeFromAllGroups) {
        const banRef = doc(db, 'bans', `${memberToRemove.cpId}_groups_ban_${Date.now()}`);
        batch.set(banRef, {
          userId: memberToRemove.cpId,
          type: 'feature_ban',
          scope: 'feature_specific',
          reason: `Removed from group with ban: ${removalForm.reason}`,
          description: removalForm.adminNote,
          severity: 'temporary',
          issuedAt: now,
          isActive: true,
          restrictedFeatures: ['create_or_join_a_group'],
        });
      }

      await batch.commit();

      toast.success(`Member ${memberToRemove.displayName || memberToRemove.cpId} removed successfully`);
      setShowRemovalModal(false);
      setMemberToRemove(null);
      
    } catch (error) {
      console.error('Error removing member:', error);
      toast.error('Failed to remove member');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Note: Promote/Demote functions removed as we focus on comprehensive profile view
  // Role management can be done through individual user management interface

  if (membershipsLoading || profilesLoading) {
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

  if (membershipsError) {
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

        {/* Enhanced Stats Cards for Community Profiles */}
        <div className="grid grid-cols-2 lg:grid-cols-7 gap-4 mb-6">
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
                {t('profile-members.stats.with-cooldowns') || 'With Cooldowns'}
              </CardTitle>
              <Clock className="h-4 w-4 text-orange-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-orange-600">{stats.withCooldowns}</div>
              <p className="text-xs text-orange-600">
                {t('profile-members.stats.active-cooldowns') || 'active cooldowns'}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('profile-members.stats.with-bans') || 'With Bans'}
              </CardTitle>
              <Ban className="h-4 w-4 text-red-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-red-600">{stats.withBans}</div>
              <p className="text-xs text-red-600">
                {t('profile-members.stats.groups-bans') || 'groups bans'}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('profile-members.stats.with-warnings') || 'With Warnings'}
              </CardTitle>
              <AlertTriangle className="h-4 w-4 text-yellow-600" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-yellow-600">{stats.withWarnings}</div>
              <p className="text-xs text-yellow-600">
                {t('profile-members.stats.active-warnings') || 'active warnings'}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('profile-members.stats.capacity-usage') || 'Capacity'}
              </CardTitle>
              <Activity className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {stats.total}/{group?.memberCapacity || 6}
              </div>
              <p className="text-xs text-muted-foreground">
                {stats.total}/{group?.memberCapacity || 6} {t('profile-members.stats.used') || 'used'}
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

        {/* Community Profiles List */}
        <Card>
          <CardHeader>
            <CardTitle>
              {t('profile-members.title') || 'Community Profiles'} ({sortedProfiles.length})
            </CardTitle>
            <CardDescription>
              {t('profile-members.description') || 'Comprehensive view of member community profiles with membership history, cooldowns, and ban status'}
            </CardDescription>
          </CardHeader>
          <CardContent>
            {sortedProfiles.length === 0 ? (
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
              <div className="space-y-4">
                {sortedProfiles.map((profile) => (
                  <Card key={profile.cpId} className="overflow-hidden">
                    <CardContent className="p-6">
                      <div className="flex items-start justify-between">
                        <div className="flex items-start gap-4 flex-1">
                          {/* Profile Avatar */}
                          <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center">
                            <User className="h-6 w-6" />
                          </div>
                          
                          <div className="flex-1 min-w-0">
                            {/* Profile Header */}
                            <div className="flex items-center gap-2 mb-2">
                              <h3 className="font-semibold text-lg truncate">{profile.displayName}</h3>
                              <Badge 
                                variant={profile.currentMembership?.role === 'admin' ? 'default' : 'secondary'}
                                className="text-xs"
                              >
                                {profile.currentMembership?.role === 'admin' ? (
                                  <>
                                    <Crown className="h-3 w-3 mr-1" />
                                    {t('common.admin') || 'Admin'}
                                  </>
                                ) : (
                                  t('common.member') || 'Member'
                                )}
                              </Badge>
                              
                              {/* Status Indicators */}
                              {profile.nextJoinAllowedAt && profile.nextJoinAllowedAt > new Date() && (
                                <Badge variant="outline" className="text-orange-600 border-orange-300">
                                  <Clock className="h-3 w-3 mr-1" />
                                  {t('profile-members.cooldown-active') || 'Cooldown'}
                                </Badge>
                              )}
                              
                              {profile.activeBans.length > 0 && (
                                <Badge variant="destructive" className="text-xs">
                                  <Ban className="h-3 w-3 mr-1" />
                                  {t('profile-members.banned') || 'Banned'}
                                </Badge>
                              )}
                              
                              {profile.activeWarnings.length > 0 && (
                                <Badge variant="outline" className="text-yellow-600 border-yellow-300">
                                  <AlertTriangle className="h-3 w-3 mr-1" />
                                  {profile.activeWarnings.length} {t('profile-members.warnings') || 'warnings'}
                                </Badge>
                              )}
                            </div>

                            {/* Profile Details */}
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                              {/* Basic Info */}
                              <div className="space-y-1">
                                <p className="text-muted-foreground text-xs font-medium uppercase">
                                  {t('profile-members.basic-info') || 'Basic Information'}
                                </p>
                                <p><span className="font-medium">{t('profile-members.cp-id') || 'CP ID'}:</span> {profile.cpId}</p>
                                <p><span className="font-medium">{t('profile-members.user-id') || 'User ID'}:</span> {profile.userUID}</p>
                                <p><span className="font-medium">{t('profile-members.gender') || 'Gender'}:</span> {profile.gender}</p>
                                {profile.isAnonymous && (
                                  <Badge variant="outline" className="text-xs">
                                    {t('profile-members.anonymous') || 'Anonymous'}
                                  </Badge>
                                )}
                              </div>

                              {/* Current Membership */}
                              <div className="space-y-1">
                                <p className="text-muted-foreground text-xs font-medium uppercase">
                                  {t('profile-members.current-membership') || 'Current Membership'}
                                </p>
                                <div className="flex items-center gap-1">
                                  <Trophy className="h-3 w-3 text-yellow-600" />
                                  <span>{profile.currentMembership?.pointsTotal || 0} {t('common.points') || 'points'}</span>
                                </div>
                                <div className="flex items-center gap-1">
                                  <Calendar className="h-3 w-3" />
                                  <span>{format(profile.currentMembership?.joinedAt || new Date(), 'MMM dd, yyyy')}</span>
                                </div>
                              </div>

                              {/* Restrictions & Status */}
                              <div className="space-y-1">
                                <p className="text-muted-foreground text-xs font-medium uppercase">
                                  {t('profile-members.restrictions') || 'Restrictions & Status'}
                                </p>
                                
                                {/* Cooldown Status */}
                                {profile.nextJoinAllowedAt && profile.nextJoinAllowedAt > new Date() ? (
                                  <div className="text-orange-600 text-xs">
                                    <Clock className="h-3 w-3 inline mr-1" />
                                    {t('profile-members.cooldown-until') || 'Cooldown until'} {format(profile.nextJoinAllowedAt, 'MMM dd, HH:mm')}
                                    {profile.customCooldownDuration && (
                                      <p className="text-xs text-orange-500">
                                        ({profile.customCooldownDuration}h {t('profile-members.duration') || 'duration'})
                                      </p>
                                    )}
                                  </div>
                                ) : (
                                  <span className="text-green-600 text-xs">
                                    <Shield className="h-3 w-3 inline mr-1" />
                                    {t('profile-members.no-restrictions') || 'No restrictions'}
                                  </span>
                                )}

                                {/* Active Bans */}
                                {profile.activeBans.length > 0 && (
                                  <div className="text-red-600 text-xs">
                                    <Ban className="h-3 w-3 inline mr-1" />
                                    {profile.activeBans.length} {t('profile-members.active-bans') || 'active bans'}
                                  </div>
                                )}

                                {/* Active Warnings */}
                                {profile.activeWarnings.length > 0 && (
                                  <div className="text-yellow-600 text-xs">
                                    <AlertTriangle className="h-3 w-3 inline mr-1" />
                                    {profile.activeWarnings.length} {t('profile-members.active-warnings') || 'active warnings'}
                                  </div>
                                )}

                                {/* Membership History Count */}
                                <div className="text-gray-600 text-xs">
                                  <MessageSquare className="h-3 w-3 inline mr-1" />
                                  {profile.allMemberships.length} {t('profile-members.total-groups') || 'total groups'}
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>

                        {/* Actions */}
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="h-8 w-8 p-0">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align={isRTL ? 'start' : 'end'}>
                            <DropdownMenuItem onClick={() => {/* Navigate to user profile */
                              window.location.href = `/${locale}/user-management/users/${profile.userUID}`;
                            }}>
                              <Eye className="mr-2 h-4 w-4" />
                              {t('profile-members.view-user-profile') || 'View User Profile'}
                            </DropdownMenuItem>
                            <DropdownMenuItem 
                              onClick={() => handleRemoveMember(profile)}
                              className="text-destructive"
                              disabled={isSubmitting}
                            >
                              <UserMinus className="mr-2 h-4 w-4" />
                              {t('profile-members.remove-from-group') || 'Remove from Group'}
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* System Admin Member Removal Dialog */}
      <Dialog open={showRemovalModal} onOpenChange={setShowRemovalModal}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <UserMinus className="h-5 w-5 text-red-600" />
              Remove Member from Group
            </DialogTitle>
            <DialogDescription>
              Remove {memberToRemove?.displayName || memberToRemove?.cpId} from {group?.name}?
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            {/* Member Info */}
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div>
                <p className="font-medium">{memberToRemove?.displayName || memberToRemove?.cpId}</p>
                <Badge variant={memberToRemove?.role === 'admin' ? 'default' : 'secondary'}>
                  {memberToRemove?.role === 'admin' ? 'Admin' : 'Member'}
                </Badge>
              </div>
              <div className="text-right text-sm text-gray-600">
                <p>Points: {memberToRemove?.pointsTotal || 0}</p>
              </div>
            </div>

            {/* Cooldown Duration */}
            <div className="space-y-2">
              <Label className="font-medium">Cooldown Duration</Label>
              <Select 
                value={removalForm.cooldownDuration.toString()}
                onValueChange={(value) => setRemovalForm(prev => ({ 
                  ...prev, 
                  cooldownDuration: parseInt(value) 
                }))}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="24">24 hours (Default)</SelectItem>
                  <SelectItem value="48">48 hours</SelectItem>
                  <SelectItem value="72">72 hours</SelectItem>
                  <SelectItem value="168">1 week</SelectItem>
                  <SelectItem value="720">1 month</SelectItem>
                </SelectContent>
              </Select>
              <p className="text-xs text-gray-600">
                Member will not be able to join another group for this duration
              </p>
            </div>

            {/* Removal Reason */}
            <div className="space-y-2">
              <Label className="font-medium">Removal Reason *</Label>
              <Select 
                value={removalForm.reason}
                onValueChange={(value) => setRemovalForm(prev => ({ 
                  ...prev, 
                  reason: value 
                }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select reason for removal" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="inappropriate_behavior">Inappropriate Behavior</SelectItem>
                  <SelectItem value="harassment">Harassment of Members</SelectItem>
                  <SelectItem value="spam">Spam or Excessive Messages</SelectItem>
                  <SelectItem value="rule_violation">Group Rules Violation</SelectItem>
                  <SelectItem value="disruption">Group Disruption</SelectItem>
                  <SelectItem value="admin_decision">Admin Decision</SelectItem>
                  <SelectItem value="other">Other</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Admin Notes */}
            <div className="space-y-2">
              <Label className="font-medium">Admin Notes (Optional)</Label>
              <Textarea
                value={removalForm.adminNote}
                onChange={(e) => setRemovalForm(prev => ({ 
                  ...prev, 
                  adminNote: e.target.value 
                }))}
                placeholder="Additional details about the removal..."
                rows={3}
              />
            </div>

            {/* Ban from all groups option */}
            <div className="bg-orange-50 border border-orange-200 rounded-lg p-3">
              <div className="flex items-start space-x-3">
                <input
                  type="checkbox"
                  id="banFromAllGroups"
                  className="mt-1"
                  checked={removalForm.removeFromAllGroups}
                  onChange={(e) => setRemovalForm(prev => ({ 
                    ...prev, 
                    removeFromAllGroups: e.target.checked 
                  }))}
                />
                <div className="flex-1">
                  <Label htmlFor="banFromAllGroups" className="font-medium text-orange-800">
                    Ban from All Groups
                  </Label>
                  <p className="text-xs text-orange-700 mt-1">
                    Prevents user from creating or joining any group indefinitely
                  </p>
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRemovalModal(false)} disabled={isSubmitting}>
              Cancel
            </Button>
            <Button 
              variant="destructive" 
              onClick={handleConfirmRemoval} 
              disabled={isSubmitting || !removalForm.reason}
            >
              {isSubmitting ? 'Removing...' : 'Remove Member'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
