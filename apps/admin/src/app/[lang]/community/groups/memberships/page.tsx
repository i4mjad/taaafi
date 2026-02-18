'use client';

import { useState, useMemo } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { SiteHeader } from '@/components/site-header';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { format } from 'date-fns';
import { toast } from 'sonner';
import { doc, writeBatch } from 'firebase/firestore';
import { CommunityProfilesTable } from '@/components/CommunityProfilesTable';
import { 
  Users, 
  Search, 
  Crown, 
  UserCheck,
  Building,
  X,
  Clock,
  Shield,
  Ban,
  Activity,
  User,
  MessageSquare,
  Trophy,
  AlertTriangle,
  Calendar,
  UserMinus,
  MoreHorizontal,
  Eye
} from 'lucide-react';

export default function GroupMembershipsPage() {
  const params = useParams();
  const lang = params.lang as string;
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [activeSearch, setActiveSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [roleFilter, setRoleFilter] = useState<string>('all');
  const [showRemovalModal, setShowRemovalModal] = useState(false);
  const [memberToRemove, setMemberToRemove] = useState<any>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [removalForm, setRemovalForm] = useState({
    cooldownDuration: 24,
    reason: '',
    adminNote: '',
    removeFromAllGroups: false
  });

  // Helper function to safely convert Firestore timestamps to dates
  const safeToDate = (timestamp: any): Date | null => {
    if (!timestamp) return null;
    try {
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return (date instanceof Date && !isNaN(date.getTime())) ? date : null;
    } catch (error) {
      console.warn('Invalid timestamp:', timestamp, error);
      return null;
    }
  };

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

  // Fetch all groups for lookup using react-firebase-hooks
  const [groupsSnapshot] = useCollection(
    query(collection(db, 'groups'), orderBy('createdAt', 'desc'))
  );

  // Fetch all community profiles using react-firebase-hooks
  const [profilesSnapshot, profilesLoading] = useCollection(
    collection(db, 'communityProfiles')
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

  const groups = useMemo(() => {
    if (!groupsSnapshot) return [];
    return groupsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
      id: doc.id,
        name: data.name || 'Unknown Group',
        description: data.description,
        memberCapacity: data.memberCapacity,
        isActive: data.isActive,
        createdAt: safeToDate(data.createdAt) || new Date(),
        ...data
      };
    });
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

  // Fetch all memberships using react-firebase-hooks
  const [membershipsSnapshot, membershipsLoading, membershipsError] = useCollection(
    query(collection(db, 'group_memberships'), orderBy('joinedAt', 'desc'))
  );

  // Community profiles processing complete

  const memberships = useMemo(() => {
    if (!membershipsSnapshot) return [];
    return membershipsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
      id: doc.id,
        cpId: data.cpId,
        groupId: data.groupId,
        userUID: data.userUID,
        role: data.role,
        isActive: data.isActive,
        pointsTotal: data.pointsTotal || 0,
        joinedAt: safeToDate(data.joinedAt) || new Date(),
        leftAt: safeToDate(data.leftAt),
        removalReason: data.removalReason,
        removalNote: data.removalNote,
        removedBy: data.removedBy,
        removedAt: safeToDate(data.removedAt),
        ...data
      };
    });
  }, [membershipsSnapshot]);

  // START WITH COMMUNITY PROFILES AS BASE (correct approach)
  const communityProfiles = useMemo(() => {
    if (!profilesSnapshot) return [];

    // 1. Get all community profiles as the BASE
    const allProfiles = profilesSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        cpId: doc.id,
        userUID: data.userUID,
        displayName: data.displayName || 'Unknown User',
        gender: data.gender,
        isAnonymous: data.isAnonymous || false,
        avatarUrl: data.avatarUrl,
        referralCode: data.referralCode,
        createdAt: safeToDate(data.createdAt) || new Date(),
        updatedAt: safeToDate(data.updatedAt),
        nextJoinAllowedAt: safeToDate(data.nextJoinAllowedAt),
        rejoinCooldownOverrideUntil: safeToDate(data.rejoinCooldownOverrideUntil),
        lastGroupViolationAt: safeToDate(data.lastGroupViolationAt),
        customCooldownDuration: data.customCooldownDuration,
        cooldownReason: data.cooldownReason,
        cooldownIssuedBy: data.cooldownIssuedBy,
        isGroupsBanned: data.isGroupsBanned || false,
        groupsBanExpiresAt: safeToDate(data.groupsBanExpiresAt),
        groupsWarningCount: data.groupsWarningCount || 0,
        ...data
      };
    });

    // 2. Get all memberships to link to profiles
    const allMemberships = memberships;

    // 3. Get all bans for profiles  
    const allBans = bansSnapshot?.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        userId: data.userId,
        type: data.type,
        reason: data.reason,
        restrictedFeatures: data.restrictedFeatures || [],
        issuedAt: safeToDate(data.issuedAt) || new Date(),
        expiresAt: safeToDate(data.expiresAt),
        ...data
      };
    }) || [];

    // 4. Get all warnings for profiles
    const allWarnings = warningsSnapshot?.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        userId: data.userId,
        type: data.type,
        reason: data.reason,
        severity: data.severity,
        issuedAt: safeToDate(data.issuedAt) || new Date(),
        ...data
      };
    }) || [];

    // 5. For each COMMUNITY PROFILE, attach their memberships/bans/warnings
    const profilesWithData = allProfiles.map(profile => {
      // Find all memberships for this profile
      const profileMemberships = allMemberships
        .filter(membership => membership.cpId === profile.cpId)
        .map(membership => {
          const group = groups.find(g => g.id === membership.groupId);
          return {
            ...membership,
            groupName: group?.name || 'Unknown Group',
            leftAt: membership.leftAt || undefined // Convert null to undefined for TypeScript compatibility
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
        memberships: profileMemberships,
        activeBans: profileBans,
        activeWarnings: profileWarnings
      };
    });

    console.log('✅ Community Profiles (BASE) Debug:', {
      totalProfiles: allProfiles.length,
      totalMemberships: allMemberships.length,
      profilesWithMemberships: profilesWithData.length,
      profilesWithActiveMemberships: profilesWithData.filter(p => p.memberships.some((m: any) => m.isActive)).length,
      sampleProfile: profilesWithData[0] ? {
        cpId: profilesWithData[0].cpId,
        displayName: profilesWithData[0].displayName,
        totalMemberships: profilesWithData[0].memberships?.length || 0,
        activeMemberships: profilesWithData[0].memberships?.filter((m: any) => m.isActive).length || 0
      } : null
    });

    return profilesWithData;
  }, [profilesSnapshot, memberships, bansSnapshot, warningsSnapshot, groups]);

  // Filter profiles based on search (profiles are the BASE)
  const filteredProfiles = useMemo(() => {
    return communityProfiles.filter((profile: any) => {
      // Apply search filter across profile data
      if (activeSearch.trim()) {
        const searchTerm = activeSearch.trim().toLowerCase();
        const matchesProfile = 
          profile.cpId.toLowerCase().includes(searchTerm) ||
          profile.displayName?.toLowerCase().includes(searchTerm) ||
          profile.userUID?.toLowerCase().includes(searchTerm);
        
        const matchesGroupName = profile.memberships?.some((m: any) => 
          m.groupName?.toLowerCase().includes(searchTerm)
        );
        
        if (!matchesProfile && !matchesGroupName) return false;
      }
      
      // Apply status filter (based on active memberships)
      if (statusFilter !== 'all') {
        const hasActiveMembership = profile.memberships?.some((m: any) => m.isActive) || false;
        if (statusFilter === 'active' && !hasActiveMembership) return false;
        if (statusFilter === 'inactive' && hasActiveMembership) return false;
      }
      
      // Apply role filter (check if profile has any membership with this role)
      if (roleFilter !== 'all') {
        const hasRoleMatch = profile.memberships?.some((m: any) => m.role === roleFilter) || false;
        if (!hasRoleMatch) return false;
      }
      
      return true;
    });
  }, [communityProfiles, activeSearch, statusFilter, roleFilter]);

  // Create a lookup for group names (for display purposes)
  const groupsLookup = useMemo(() => {
    return groups.reduce((acc, group) => {
      acc[group.id] = group;
      return acc;
    }, {} as Record<string, any>);
  }, [groups]);

  // Remove old memberships table data processing as we now focus on community profiles

  const stats = useMemo(() => {
    const totalProfiles = filteredProfiles.length;
    const withCooldowns = filteredProfiles.filter((p: any) => p.nextJoinAllowedAt && p.nextJoinAllowedAt > new Date()).length;
    const withBans = filteredProfiles.filter((p: any) => p.activeBans.length > 0).length;
    const withWarnings = filteredProfiles.filter((p: any) => p.activeWarnings.length > 0).length;
    const totalMemberships = filteredProfiles.reduce((sum: number, p: any) => sum + p.memberships.length, 0);
    const activeMembers = filteredProfiles.filter((p: any) => p.memberships.some((m: any) => m.isActive)).length;
    const groupAdmins = filteredProfiles.filter((p: any) => p.memberships.some((m: any) => m.role === 'admin' && m.isActive)).length;

    return {
      totalProfiles,
      totalMemberships,
      activeMembers,
      groupAdmins,
      withCooldowns,
      withBans,
      withWarnings,
      uniqueGroups: [...new Set(filteredProfiles.flatMap((p: any) => p.memberships.map((m: any) => m.groupId)))].length
    };
  }, [filteredProfiles]);

  console.log('📊 Final Community Profiles Table Data:', {
    totalCommunityProfiles: communityProfiles.length,
    filteredProfiles: filteredProfiles.length,
    profilesWithActiveMemberships: filteredProfiles.filter(p => p.memberships?.some((m: any) => m.isActive)).length,
    profilesWithCooldowns: filteredProfiles.filter(p => p.nextJoinAllowedAt && p.nextJoinAllowedAt > new Date()).length,
    profilesWithBans: filteredProfiles.filter(p => p.activeBans?.length > 0).length,
    sampleDisplayProfile: filteredProfiles[0] ? {
      cpId: filteredProfiles[0].cpId,
      displayName: filteredProfiles[0].displayName,
      userUID: filteredProfiles[0].userUID,
      totalMemberships: filteredProfiles[0].memberships?.length || 0,
      activeMemberships: filteredProfiles[0].memberships?.filter((m: any) => m.isActive).length || 0,
      hasCooldown: !!(filteredProfiles[0].nextJoinAllowedAt && filteredProfiles[0].nextJoinAllowedAt > new Date()),
      bansCount: filteredProfiles[0].activeBans?.length || 0,
      warningsCount: filteredProfiles[0].activeWarnings?.length || 0
    } : 'No profiles found'
  });

  // Add removal handling functions
  const handleRemoveMember = (profile: any) => {
    const activeMembership = profile.memberships.find((m: any) => m.isActive);
    if (!activeMembership) return;
    
    setMemberToRemove({
      id: activeMembership.id,
      cpId: profile.cpId,
      groupId: activeMembership.groupId,
      role: activeMembership.role,
      displayName: profile.displayName,
      isActive: true,
      joinedAt: activeMembership.joinedAt,
      pointsTotal: activeMembership.pointsTotal
    });
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

      toast.success(`Profile ${memberToRemove.displayName || memberToRemove.cpId} removed successfully`);
      setShowRemovalModal(false);
      setMemberToRemove(null);
      
    } catch (error) {
      console.error('Error removing member:', error);
      toast.error('Failed to remove member');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (membershipsLoading || profilesLoading) {
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
    documents: t('modules.admin.profiles.title') || 'Community Profiles',
  };

  const tableDictionary = {
    searchPlaceholder: t('modules.admin.profiles.search-placeholder') || 'Search community profiles...',
    headers: {
      profileInfo: t('modules.admin.profiles.headers.profileInfo') || 'Profile Info',
      activeMemberships: t('modules.admin.profiles.headers.activeMemberships') || 'Active Memberships',
      status: t('modules.admin.profiles.headers.status') || 'Status & Restrictions',
      membershipStats: t('modules.admin.profiles.headers.membershipStats') || 'Membership Stats',
    },
    memberships: {
      noActiveMemberships: t('modules.admin.profiles.memberships.noActiveMemberships') || 'No active memberships',
      groups: t('modules.admin.profiles.memberships.groups') || 'groups',
      totalPoints: t('modules.admin.profiles.memberships.totalPoints') || 'total points',
    },
    status: {
      cooldownUntil: t('modules.admin.profiles.status.cooldownUntil') || 'Cooldown until',
      noRestrictions: t('modules.admin.profiles.status.noRestrictions') || 'No restrictions',
      bans: t('modules.admin.profiles.status.bans') || 'bans',
      warnings: t('modules.admin.profiles.status.warnings') || 'warnings',
    },
    roles: {
      admin: t('modules.admin.profiles.roles.admin') || 'admin',
      member: t('modules.admin.profiles.roles.member') || 'member',
    },
    actions: {
      openMenu: t('modules.admin.profiles.actions.openMenu') || 'Open menu',
      viewUserProfile: t('modules.admin.profiles.actions.viewUserProfile') || 'View User Profile',
      removeFromGroup: t('modules.admin.profiles.actions.removeFromGroup') || 'Remove from Group',
    },
    columnsText: t('common.columns') || 'Columns',
    noDataText: t('modules.admin.profiles.no-profiles') || 'No community profiles found.',
    pagination: {
      selected: t('modules.admin.profiles.pagination.selected') || 'row(s) selected.',
      rowsPerPage: t('modules.admin.profiles.pagination.rows-per-page') || 'Rows per page',
      page: t('modules.admin.profiles.pagination.page') || 'Page',
      of: t('modules.admin.profiles.pagination.of') || 'of',
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
              {t('modules.admin.profiles.title') || 'Community Profiles'}
            </h1>
            <p className="text-muted-foreground">
              {t('modules.admin.profiles.description') || 'Comprehensive view of member community profiles with membership history, cooldowns, and ban status'}
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
                  <div className="text-2xl font-bold">{stats.totalProfiles}</div>
                  <p className="text-xs text-muted-foreground">
                    {t('modules.admin.profiles.stats.community-profiles') || 'community profiles'}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.admin.profiles.stats.with-cooldowns') || 'With Cooldowns'}
                  </CardTitle>
                  <Clock className="h-4 w-4 text-orange-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.withCooldowns}</div>
                  <p className="text-xs text-muted-foreground">
                    {t('modules.admin.profiles.stats.active-cooldowns') || 'active cooldowns'}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.admin.profiles.stats.with-bans') || 'With Bans'}
                  </CardTitle>
                  <Ban className="h-4 w-4 text-red-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.withBans}</div>
                  <p className="text-xs text-muted-foreground">
                    {t('modules.admin.profiles.stats.groups-bans') || 'groups bans'}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.admin.profiles.stats.with-warnings') || 'With Warnings'}
                  </CardTitle>
                  <AlertTriangle className="h-4 w-4 text-yellow-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-yellow-600">{stats.withWarnings}</div>
                  <p className="text-xs text-yellow-600">
                    {t('modules.admin.profiles.stats.active-warnings') || 'active warnings'}
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

            {/* Community Profiles View */}
            <Card>
              <CardHeader>
                <CardTitle>
                  {t('modules.admin.profiles.title') || 'Community Profiles'} ({filteredProfiles.length})
                </CardTitle>
                <CardDescription>
                  {t('modules.admin.profiles.description') || 'Comprehensive view of member community profiles with membership history, cooldowns, and ban status'}
                </CardDescription>
              </CardHeader>
              <CardContent>
                <CommunityProfilesTable
                  data={filteredProfiles}
                  groups={groups}
                  dictionary={{
                    searchPlaceholder: t('modules.admin.profiles.search-placeholder') || 'Search community profiles...',
                    headers: {
                      profileInfo: t('modules.admin.profiles.headers.profileInfo') || 'Profile Info',
                      activeMemberships: t('modules.admin.profiles.headers.activeMemberships') || 'Active Memberships',
                      status: t('modules.admin.profiles.headers.status') || 'Status & Restrictions',
                      membershipStats: t('modules.admin.profiles.headers.membershipStats') || 'Membership Stats'
                    },
                    memberships: {
                      noActiveMemberships: t('modules.admin.profiles.memberships.noActiveMemberships') || 'No active memberships',
                      groups: t('modules.admin.profiles.memberships.groups') || 'groups',
                      totalPoints: t('modules.admin.profiles.memberships.totalPoints') || 'total points'
                    },
                    status: {
                      cooldownUntil: t('modules.admin.profiles.status.cooldownUntil') || 'Cooldown until',
                      noRestrictions: t('modules.admin.profiles.status.noRestrictions') || 'No restrictions',
                      bans: t('modules.admin.profiles.status.bans') || 'bans',
                      warnings: t('modules.admin.profiles.status.warnings') || 'warnings',
                      unknownDate: t('modules.admin.profiles.status.unknownDate') || 'Unknown date'
                    },
                    roles: {
                      admin: t('modules.admin.profiles.roles.admin') || 'admin',
                      member: t('modules.admin.profiles.roles.member') || 'member'
                    },
                    actions: {
                      openMenu: t('modules.admin.profiles.actions.openMenu') || 'Open menu',
                      viewUserProfile: t('modules.admin.profiles.actions.viewUserProfile') || 'View User Profile',
                      removeFromGroup: t('modules.admin.profiles.actions.removeFromGroup') || 'Remove from Group'
                    },
                    columnsText: t('common.columns') || 'Columns',
                    noDataText: t('modules.admin.profiles.no-profiles') || 'No community profiles found.',
                    pagination: {
                      selected: t('modules.admin.profiles.pagination.selected') || 'row(s) selected.',
                      rowsPerPage: t('modules.admin.profiles.pagination.rows-per-page') || 'Rows per page',
                      page: t('modules.admin.profiles.pagination.page') || 'Page',
                      of: t('modules.admin.profiles.pagination.of') || 'of',
                    }
                  }}
                  lang={lang}
                  onRemoveProfile={handleRemoveMember}
                />
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Enhanced Member Removal Modal */}
      <Dialog open={showRemovalModal} onOpenChange={setShowRemovalModal}>
        <DialogContent className="sm:max-w-[500px]">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <UserMinus className="h-5 w-5 text-red-600" />
              {t('modules.userManagement.groups-removal.title') || 'Remove Member from Group'}
            </DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.groups-removal.description', { 
                member: memberToRemove?.displayName || memberToRemove?.cpId,
                group: groups.find(g => g.id === memberToRemove?.groupId)?.name 
              }) || `Remove ${memberToRemove?.displayName || memberToRemove?.cpId} from group?`}
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
              <Label className="font-medium">{t('modules.userManagement.groups-removal.cooldown-duration') || 'Cooldown Duration'}</Label>
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
                  <SelectItem value="24">{t('modules.userManagement.groups-removal.cooldown-24h') || '24 hours (Default)'}</SelectItem>
                  <SelectItem value="48">{t('modules.userManagement.groups-removal.cooldown-48h') || '48 hours'}</SelectItem>
                  <SelectItem value="72">{t('modules.userManagement.groups-removal.cooldown-72h') || '72 hours'}</SelectItem>
                  <SelectItem value="168">{t('modules.userManagement.groups-removal.cooldown-1w') || '1 week'}</SelectItem>
                  <SelectItem value="720">{t('modules.userManagement.groups-removal.cooldown-1m') || '1 month'}</SelectItem>
                </SelectContent>
              </Select>
              <p className="text-xs text-gray-600">
                {t('modules.userManagement.groups-removal.cooldown-explanation') || 'Member will not be able to join another group for this duration'}
              </p>
            </div>

            {/* Removal Reason */}
            <div className="space-y-2">
              <Label className="font-medium">{t('modules.userManagement.groups-removal.removal-reason') || 'Removal Reason'} *</Label>
              <Select 
                value={removalForm.reason}
                onValueChange={(value) => setRemovalForm(prev => ({ 
                  ...prev, 
                  reason: value 
                }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder={t('modules.userManagement.groups-removal.select-reason') || 'Select reason for removal'} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="inappropriate_behavior">{t('modules.userManagement.groups-removal.reason.inappropriate-behavior') || 'Inappropriate Behavior'}</SelectItem>
                  <SelectItem value="harassment">{t('modules.userManagement.groups-removal.reason.harassment') || 'Harassment of Members'}</SelectItem>
                  <SelectItem value="spam">{t('modules.userManagement.groups-removal.reason.spam') || 'Spam or Excessive Messages'}</SelectItem>
                  <SelectItem value="rule_violation">{t('modules.userManagement.groups-removal.reason.rule-violation') || 'Group Rules Violation'}</SelectItem>
                  <SelectItem value="disruption">{t('modules.userManagement.groups-removal.reason.disruption') || 'Group Disruption'}</SelectItem>
                  <SelectItem value="admin_decision">{t('modules.userManagement.groups-removal.reason.admin-decision') || 'Admin Decision'}</SelectItem>
                  <SelectItem value="other">{t('modules.userManagement.groups-removal.reason.other') || 'Other'}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Admin Notes */}
            <div className="space-y-2">
              <Label className="font-medium">{t('modules.userManagement.groups-removal.admin-notes') || 'Admin Notes (Optional)'}</Label>
              <Textarea
                value={removalForm.adminNote}
                onChange={(e) => setRemovalForm(prev => ({ 
                  ...prev, 
                  adminNote: e.target.value 
                }))}
                placeholder={t('modules.userManagement.groups-removal.admin-notes-placeholder') || 'Additional details about the removal...'}
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
                    {t('modules.userManagement.groups-removal.ban-from-all-groups') || 'Ban from All Groups'}
                  </Label>
                  <p className="text-xs text-orange-700 mt-1">
                    {t('modules.userManagement.groups-removal.ban-explanation') || 'Prevents user from creating or joining any group indefinitely'}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRemovalModal(false)} disabled={isSubmitting}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button 
              variant="destructive" 
              onClick={handleConfirmRemoval} 
              disabled={isSubmitting || !removalForm.reason}
            >
              {isSubmitting ? (t('modules.admin.profiles.removing') || 'Removing...') : (t('modules.userManagement.groups-removal.confirm-remove') || 'Remove Member')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
