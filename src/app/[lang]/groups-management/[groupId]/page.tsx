'use client';

import React, { useState, useMemo, useEffect, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { doc, getDoc, collection, query, where, orderBy, limit as queryLimit, startAfter, endBefore, updateDoc, deleteDoc, QueryDocumentSnapshot, DocumentData } from 'firebase/firestore';
import { useDocument, useCollection } from 'react-firebase-hooks/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { 
  ArrowLeft, 
  Users, 
  MessageSquare, 
  Settings, 
  Calendar, 
  Crown,
  Trophy,
  UserMinus,
  Shield,
  MoreHorizontal,
  Trash2,
  AlertTriangle,
  Eye,
  Flag,
  Key,
  Lock,
  Globe,
  Clock,
  Search,
  ChevronLeft,
  ChevronRight,
  RefreshCw,
  CheckCheck
} from 'lucide-react';
import { format, isToday, isYesterday } from 'date-fns';
import { Group, GroupMember, GroupMessage } from '@/types/community';
import { toast } from 'sonner';
import { SiteHeader } from '@/components/site-header';

const MESSAGES_PER_PAGE = 25;

export default function GroupDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { t, locale } = useTranslation();
  const isRTL = locale === 'ar';
  const groupId = params.groupId as string;
  
  // Log groupId to make sure we have it
  console.log('📱 Group ID from params:', { groupId, params });

  const [activeTab, setActiveTab] = useState('overview');
  const [selectedMember, setSelectedMember] = useState<GroupMember | null>(null);
  const [selectedMessage, setSelectedMessage] = useState<GroupMessage | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  // Messages filtering state - simplified
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | 'pending' | 'approved' | 'blocked' | 'deleted'>('all');

  // Fetch group data
  const [groupDoc, groupLoading, groupError] = useDocument(doc(db, 'groups', groupId));
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

  // Simple messages query without complex pagination
  const [messagesValue, messagesLoading, messagesError] = useCollection(
    groupId ? query(
      collection(db, 'group_messages'),
      where('groupId', '==', groupId),
      orderBy('createdAt', 'desc'),
      queryLimit(100) // Get more messages at once, simpler approach
    ) : null
  );

  const messages: GroupMessage[] = useMemo(() => {
    if (!messagesValue?.docs) return [];
    
    return messagesValue.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        groupId: data.groupId,
        senderCpId: data.senderCpId,
        body: data.body,
        replyToMessageId: data.replyToMessageId,
        quotedPreview: data.quotedPreview,
        mentions: data.mentions || [],
        mentionHandles: data.mentionHandles || [],
        tokens: data.tokens || [],
        isDeleted: data.isDeleted || false,
        isHidden: data.isHidden || false,
        moderation: data.moderation,
        createdAt: data.createdAt?.toDate() || new Date(),
        senderDisplayName: data.senderDisplayName,
      } as GroupMessage;
    });
  }, [messagesValue]);


  // Filter messages with search and status filters
  const filteredMessages = useMemo(() => {
    let filtered = messages;

    // Search filter
    if (search.trim()) {
      const searchLower = search.toLowerCase();
      filtered = filtered.filter(message => 
        message.body?.toLowerCase().includes(searchLower) ||
        message.senderCpId?.toLowerCase().includes(searchLower) ||
        message.senderDisplayName?.toLowerCase().includes(searchLower)
      );
    }

    // Status filter
    if (filterStatus !== 'all') {
      filtered = filtered.filter(message => {
        switch (filterStatus) {
          case 'deleted': return message.isDeleted;
          case 'pending': return message.moderation?.status === 'pending';
          case 'approved': return message.moderation?.status === 'approved';
          case 'blocked': return message.moderation?.status === 'blocked' || message.isHidden;
          default: return true;
        }
      });
    }

    return filtered;
  }, [messages, search, filterStatus]);

  // Calculate stats using correct schema fields
  const stats = useMemo(() => {
    const totalMembers = members.length;
    const admins = members.filter(m => m.role === 'admin').length;
    const totalMessages = messages.filter(m => !m.isDeleted).length;
    const moderated = messages.filter(m => (m.isHidden || m.moderation?.status === 'blocked') && !m.isDeleted).length;
    const pending = messages.filter(m => m.moderation?.status === 'pending' && !m.isDeleted).length;
    const deleted = messages.filter(m => m.isDeleted).length;
    const totalPoints = members.reduce((sum, m) => sum + (m.pointsTotal || 0), 0);
    const averagePoints = totalMembers > 0 ? Math.round(totalPoints / totalMembers) : 0;

    return {
      totalMembers,
      admins,
      totalMessages,
      moderated,
      pending,
      deleted,
      totalPoints,
      averagePoints
    };
  }, [members, messages]);

  const headerDictionary = {
    documents: group?.name || t('modules.groupsManagement.groupDetail.title'),
  };

  // Format date for chat-like display
  const formatMessageDate = (date: Date) => {
    if (isToday(date)) {
      return format(date, 'HH:mm');
    } else if (isYesterday(date)) {
      return `${t('common.yesterday')} ${format(date, 'HH:mm')}`;
    } else {
      return format(date, 'MMM dd, HH:mm');
    }
  };

  // Get user initials for avatar
  const getUserInitials = (name: string) => {
    if (!name) return 'U';
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  };

  // Reset filters when groupId changes
  useEffect(() => {
    setSearch('');
    setFilterStatus('all');
  }, [groupId]);

  // Removed send message functionality - this is for moderation only

  const handleRemoveMember = async (member: GroupMember) => {
    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'group_memberships', member.id), {
        isActive: false,
        leftAt: new Date(),
      });

      toast.success(t('modules.groupsManagement.groupDetail.memberRemoved') || 'Member removed successfully');
      // setShowMemberActions // Removed unused state(false);
      setSelectedMember(null);
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
      // setShowMemberActions // Removed unused state(false);
      setSelectedMember(null);
    } catch (error) {
      console.error('Error promoting user:', error);
      toast.error(t('modules.groupsManagement.groupDetail.promoteError') || 'Error promoting user');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleModerateMessage = async (message: GroupMessage, reason?: string) => {
    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'group_messages', message.id), {
        isHidden: true,
        moderation: {
          status: 'blocked',
          reason: reason || 'Content moderated by admin',
          moderatedBy: 'admin', // Replace with actual admin CP ID
          moderatedAt: new Date(),
        }
      });

      toast.success(t('modules.groupsManagement.groupDetail.messageModerated') || 'Message moderated successfully');
      setSelectedMessage(null);
    } catch (error) {
      console.error('Error moderating message:', error);
      toast.error(t('modules.groupsManagement.groupDetail.moderateError') || 'Error moderating message');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteMessage = async (message: GroupMessage) => {
    if (!confirm(t('modules.groupsManagement.groupDetail.confirmDeleteMessage') || 'Are you sure you want to delete this message?')) {
      return;
    }

    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'group_messages', message.id), {
        isDeleted: true,
        deletedAt: new Date(),
        deletedBy: 'admin',
      });

      toast.success(t('modules.groupsManagement.groupDetail.messageDeleted') || 'Message deleted successfully');
      setSelectedMessage(null);
    } catch (error) {
      console.error('Error deleting message:', error);
      toast.error(t('modules.groupsManagement.groupDetail.deleteError') || 'Error deleting message');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleUnmoderateMessage = async (message: GroupMessage) => {
    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'group_messages', message.id), {
        isHidden: false,
        moderation: {
          status: 'approved',
          reason: 'Unmoderated by admin',
          moderatedBy: 'admin',
          moderatedAt: new Date(),
        }
      });

      toast.success(t('modules.groupsManagement.groupDetail.messageUnmoderated') || 'Message unmoderated successfully');
      setSelectedMessage(null);
    } catch (error) {
      console.error('Error unmoderating message:', error);
      toast.error(t('modules.groupsManagement.groupDetail.unmoderateError') || 'Error unmoderating message');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (groupLoading) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="container mx-auto py-6 px-4">
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4 animate-pulse" />
              <p className="text-muted-foreground">{t('modules.groupsManagement.groupDetail.loading') || 'Loading group...'}</p>
            </div>
          </div>
        </div>
      </>
    );
  }

  if (groupError || !group) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="container mx-auto py-6 px-4">
          <div className="flex items-center justify-center py-12">
            <Card className="w-full max-w-md">
              <CardContent className="flex flex-col items-center justify-center p-8">
                <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
                <p className="text-center text-destructive font-medium">
                  {t('modules.groupsManagement.groupDetail.loadError') || 'Error loading group'}
                </p>
                <Button 
                  onClick={() => router.back()} 
                  variant="outline" 
                  className="mt-4"
                >
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  {t('modules.groupsManagement.groupDetail.backToGroups') || 'Back to Groups'}
                </Button>
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
            <Button variant="ghost" onClick={() => router.push(`/${locale}/groups-management`)}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              {t('modules.groupsManagement.groupDetail.backToGroups') || 'Back to Groups'}
            </Button>
            <div className={isRTL ? 'text-right' : 'text-left'}>
              <h1 className="text-3xl font-bold tracking-tight">{group.name}</h1>
              <p className="text-muted-foreground">{group.description}</p>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            <Badge variant={group.isActive ? 'default' : 'secondary'}>
              {group.isActive 
                ? t('modules.groupsManagement.status.active') || 'Active'
                : t('modules.groupsManagement.status.inactive') || 'Inactive'
              }
            </Badge>
            <Badge variant="outline">
              {stats.totalMembers}/{group.memberCapacity} {t('modules.groupsManagement.table.members') || 'members'}
            </Badge>
            <Badge variant="outline">
              {t('modules.groupsManagement.gender.' + group.gender) || group.gender}
            </Badge>
            <Badge variant="outline" className="flex items-center gap-1">
              {group.visibility === 'public' ? <Globe className="h-3 w-3" /> : <Lock className="h-3 w-3" />}
              {group.visibility === 'public' ? 'Public' : 'Private'}
            </Badge>
            {group.joinCode && (
              <Badge variant="secondary" className="flex items-center gap-1">
                <Key className="h-3 w-3" />
                Code: {group.joinCode}
              </Badge>
            )}
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
              <div className="text-2xl font-bold">{stats.totalMembers}</div>
              <p className="text-xs text-muted-foreground">
                {stats.admins} {t('modules.groupsManagement.groupDetail.admins') || 'admins'}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.groupsManagement.groupDetail.totalMessages') || 'Total Messages'}
              </CardTitle>
              <MessageSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.totalMessages}</div>
              <p className="text-xs text-muted-foreground">
                {stats.moderated} {t('modules.groupsManagement.groupDetail.moderated') || 'moderated'}
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
                {group.memberCapacity > 0 ? Math.round((stats.totalMembers / group.memberCapacity) * 100) : 0}%
              </div>
              <p className="text-xs text-muted-foreground">
                {t('modules.groupsManagement.groupDetail.ofCapacity') || 'of capacity'}
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Tabs */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="overview">
              <Settings className="h-4 w-4 mr-2" />
              {t('modules.groupsManagement.groupDetail.overview') || 'Overview'}
            </TabsTrigger>
            <TabsTrigger value="members">
              <Users className="h-4 w-4 mr-2" />
              {t('modules.groupsManagement.groupDetail.members') || 'Members'} ({stats.totalMembers})
            </TabsTrigger>
            <TabsTrigger value="messages">
              <MessageSquare className="h-4 w-4 mr-2" />
              {t('modules.groupsManagement.groupDetail.messages') || 'Messages'} ({stats.totalMessages})
            </TabsTrigger>
          </TabsList>

          {/* Overview Tab */}
          <TabsContent value="overview" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>{t('modules.groupsManagement.groupDetail.groupInfo') || 'Group Information'}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">
                      {t('modules.groupsManagement.table.name') || 'Name'}
                    </h4>
                    <p className="font-medium">{group.name}</p>
                  </div>
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">
                      {t('modules.groupsManagement.form.description') || 'Description'}
                    </h4>
                    <p>{group.description}</p>
                  </div>
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">
                      {t('modules.groupsManagement.form.capacity') || 'Capacity'}
                    </h4>
                    <p>{group.memberCapacity} {t('modules.groupsManagement.table.members') || 'members'}</p>
                  </div>
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">
                      {t('modules.groupsManagement.form.visibility') || 'Visibility'}
                    </h4>
                    <Badge variant="outline" className="flex items-center gap-1 w-fit">
                      {group.visibility === 'public' ? <Globe className="h-3 w-3" /> : <Lock className="h-3 w-3" />}
                      {group.visibility === 'public' 
                        ? t('modules.groupsManagement.form.public') || 'Public'
                        : t('modules.groupsManagement.form.private') || 'Private'
                      }
                    </Badge>
                  </div>
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">
                      {t('modules.groupsManagement.form.joinMethod') || 'Join Method'}
                    </h4>
                    <p>{
                      group.joinMethod === 'any' 
                        ? t('modules.groupsManagement.form.anyMethod') || 'Any Method'
                        : group.joinMethod === 'admin_only' 
                        ? t('modules.groupsManagement.form.adminOnly') || 'Admin Only'
                        : group.joinMethod === 'code_only'
                        ? t('modules.groupsManagement.form.codeOnly') || 'Code Only'
                        : group.joinMethod
                    }</p>
                  </div>
                  {group.joinCode && (
                    <div>
                      <h4 className="font-medium text-sm text-muted-foreground">
                        {t('modules.groupsManagement.form.joinCode') || 'Join Code'}
                      </h4>
                      <Badge variant="secondary" className="flex items-center gap-1 w-fit">
                        <Key className="h-3 w-3" />
                        {group.joinCode}
                      </Badge>
                    </div>
                  )}
                  {group.isPaused && (
                    <div>
                      <h4 className="font-medium text-sm text-muted-foreground">
                        {t('modules.groupsManagement.form.status') || 'Status'}
                      </h4>
                      <Badge variant="destructive">
                        {t('modules.groupsManagement.form.paused') || 'Paused'}
                        {group.pauseReason && <span className="ml-2">({group.pauseReason})</span>}
                      </Badge>
                    </div>
                  )}
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">
                      {t('modules.groupsManagement.table.gender') || 'Gender'}
                    </h4>
                    <p>{t('modules.groupsManagement.gender.' + group.gender) || group.gender}</p>
                  </div>
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">
                      {t('modules.groupsManagement.table.created') || 'Created'}
                    </h4>
                    <p>{format(group.createdAt, 'MMMM dd, yyyy')}</p>
                  </div>
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">
                      {t('modules.groupsManagement.table.status') || 'Status'}
                    </h4>
                    <Badge variant={group.isActive ? 'default' : 'secondary'}>
                      {group.isActive 
                        ? t('modules.groupsManagement.status.active') || 'Active'
                        : t('modules.groupsManagement.status.inactive') || 'Inactive'
                      }
                    </Badge>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Members Tab */}
          <TabsContent value="members" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle>
                  {t('modules.groupsManagement.groupDetail.membersList') || 'Group Members'} ({stats.totalMembers})
                </CardTitle>
                <CardDescription>
                  {t('modules.groupsManagement.groupDetail.membersDescription') || 'View and manage group members'}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {members.length === 0 ? (
                  <div className="text-center py-8">
                    <Users className="mx-auto h-12 w-12 text-muted-foreground/50" />
                    <h3 className="mt-4 text-lg font-semibold">
                      {t('modules.groupsManagement.groupDetail.noMembers') || 'No members'}
                    </h3>
                    <p className="text-muted-foreground">
                      {t('modules.groupsManagement.groupDetail.noMembersDesc') || 'This group has no members yet'}
                    </p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {members.map((member) => (
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
                                onClick={() => {/* Demote from admin */}}
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
          </TabsContent>

          {/* Messages Tab */}
          <TabsContent value="messages" className="space-y-4">
            {/* Compact Stats Row */}
            <div className="grid grid-cols-4 gap-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-blue-600">{stats.totalMessages}</div>
                <div className="text-xs text-muted-foreground">{t('modules.groupsManagement.messagesTable.headers.message') || 'Messages'}</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-orange-600">{stats.pending}</div>
                <div className="text-xs text-muted-foreground">{t('modules.groupsManagement.messagesTable.statuses.pending') || 'Pending'}</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-red-600">{stats.moderated}</div>
                <div className="text-xs text-muted-foreground">{t('modules.groupsManagement.messagesTable.statuses.blocked') || 'Blocked'}</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-gray-600">{stats.deleted}</div>
                <div className="text-xs text-muted-foreground">{t('modules.groupsManagement.messagesTable.statuses.deleted') || 'Deleted'}</div>
              </div>
            </div>

            {/* Search and Filter - Compact */}
            <div className="flex gap-4">
              <div className="flex-1 relative">
                <Search className={`absolute top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground ${isRTL ? 'right-3' : 'left-3'}`} />
                <Input
                  placeholder={t('modules.groupsManagement.messagesTable.search') || 'Search messages...'}
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className={isRTL ? 'pr-10' : 'pl-10'}
                  dir={isRTL ? 'rtl' : 'ltr'}
                />
              </div>
              <Select value={filterStatus} onValueChange={(value) => setFilterStatus(value as 'all' | 'pending' | 'approved' | 'blocked' | 'deleted')}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('modules.groupsManagement.messagesTable.filters.all') || 'All Messages'}</SelectItem>
                  <SelectItem value="pending">{t('modules.groupsManagement.messagesTable.filters.pending') || 'Pending Review'}</SelectItem>
                  <SelectItem value="approved">{t('modules.groupsManagement.messagesTable.filters.approved') || 'Approved'}</SelectItem>
                  <SelectItem value="blocked">{t('modules.groupsManagement.messagesTable.filters.blocked') || 'Blocked/Hidden'}</SelectItem>
                  <SelectItem value="deleted">{t('modules.groupsManagement.messagesTable.filters.deleted') || 'Deleted'}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Messages Table */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="flex items-center text-base">
                  <MessageSquare className="h-4 w-4 mr-2" />
                  {t('modules.groupsManagement.messagesTable.headers.message') || 'Messages'} ({filteredMessages.length})
                </CardTitle>
              </CardHeader>
              
              <CardContent className="p-0">
                {messagesLoading ? (
                  <div className="flex flex-col items-center justify-center py-12 text-center">
                    <RefreshCw className="h-8 w-8 animate-spin text-primary mb-4" />
                    <h3 className="text-lg font-semibold mb-2">
                      {t('modules.groupsManagement.messagesTable.loading') || 'Loading messages...'}
                    </h3>
                  </div>
                ) : messagesError ? (
                  <div className="flex flex-col items-center justify-center py-12 text-center">
                    <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
                    <h3 className="text-lg font-semibold mb-2 text-destructive">
                      {t('modules.groupsManagement.messagesTable.loading') || 'Error loading messages'}
                    </h3>
                    <p className="text-muted-foreground mb-4">
                      {messagesError.message || 'Failed to load messages from database'}
                    </p>
                    <Button 
                      variant="outline" 
                      onClick={() => window.location.reload()}
                      className="mt-2"
                    >
                      <RefreshCw className="h-4 w-4 mr-2" />
                      {t('common.retry') || 'Retry'}
                    </Button>
                  </div>
                ) : filteredMessages.length === 0 ? (
                  <div className="flex flex-col items-center justify-center py-12 text-center">
                    <MessageSquare className="h-12 w-12 text-muted-foreground/50 mb-4" />
                    <h3 className="text-lg font-semibold mb-2">
                      {t('modules.groupsManagement.messagesTable.noMessages') || 'No messages found'}
                    </h3>
                  </div>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead className={isRTL ? 'text-right' : 'text-left'}>
                          {t('modules.groupsManagement.messagesTable.headers.sender') || 'Sender'}
                        </TableHead>
                        <TableHead className={isRTL ? 'text-right' : 'text-left'}>
                          {t('modules.groupsManagement.messagesTable.headers.message') || 'Message'}
                        </TableHead>
                        <TableHead className={isRTL ? 'text-right' : 'text-left'}>
                          {t('modules.groupsManagement.messagesTable.headers.status') || 'Status'}
                        </TableHead>
                        <TableHead className={isRTL ? 'text-right' : 'text-left'}>
                          {t('modules.groupsManagement.messagesTable.headers.timestamp') || 'Time'}
                        </TableHead>
                        <TableHead className={isRTL ? 'text-right' : 'text-left'}>
                          {t('modules.groupsManagement.messagesTable.headers.actions') || 'Actions'}
                        </TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredMessages.map((message) => {
                        const getStatusBadge = () => {
                          if (message.isDeleted) {
                            return <Badge variant="secondary">{t('modules.groupsManagement.messagesTable.statuses.deleted') || 'Deleted'}</Badge>;
                          }
                          if (message.isHidden) {
                            return <Badge variant="destructive">{t('modules.groupsManagement.messagesTable.statuses.hidden') || 'Hidden'}</Badge>;
                          }
                          if (message.moderation?.status === 'blocked') {
                            return <Badge variant="destructive">{t('modules.groupsManagement.messagesTable.statuses.blocked') || 'Blocked'}</Badge>;
                          }
                          if (message.moderation?.status === 'pending') {
                            return <Badge variant="outline">{t('modules.groupsManagement.messagesTable.statuses.pending') || 'Pending'}</Badge>;
                          }
                          if (message.moderation?.status === 'approved') {
                            return <Badge variant="default">{t('modules.groupsManagement.messagesTable.statuses.approved') || 'Approved'}</Badge>;
                          }
                          return <Badge variant="outline">-</Badge>;
                        };

                        return (
                          <TableRow key={message.id} className={
                            message.isHidden || message.moderation?.status === 'blocked'
                              ? 'bg-red-50 dark:bg-red-950/20'
                              : message.moderation?.status === 'pending'
                              ? 'bg-yellow-50 dark:bg-yellow-950/20'
                              : ''
                          }>
                            <TableCell className={`font-medium ${isRTL ? 'text-right' : 'text-left'}`}>
                              <div className="flex items-center gap-2">
                                <Avatar className="h-6 w-6">
                                  <AvatarFallback className="text-xs">
                                    {getUserInitials(message.senderDisplayName || message.senderCpId)}
                                  </AvatarFallback>
                                </Avatar>
                                <span className="truncate">
                                  {message.senderDisplayName || message.senderCpId}
                                </span>
                              </div>
                            </TableCell>
                            <TableCell className={`max-w-md ${isRTL ? 'text-right' : 'text-left'}`}>
                              <div className="space-y-1">
                                {message.quotedPreview && (
                                  <div className="text-xs text-muted-foreground italic border-l-2 border-gray-300 pl-2 bg-gray-50 dark:bg-gray-900 rounded p-1">
                                    "{message.quotedPreview}"
                                  </div>
                                )}
                                <p className="text-sm truncate" title={message.body}>
                                  {message.body}
                                </p>
                                {message.moderation?.reason && (
                                  <div className="text-xs text-red-700 bg-red-100 dark:bg-red-900/30 p-1 rounded">
                                    <strong>Reason:</strong> {message.moderation.reason}
                                  </div>
                                )}
                              </div>
                            </TableCell>
                            <TableCell className={isRTL ? 'text-right' : 'text-left'}>
                              {getStatusBadge()}
                            </TableCell>
                            <TableCell className={`text-sm text-muted-foreground ${isRTL ? 'text-right' : 'text-left'}`}>
                              {formatMessageDate(message.createdAt)}
                            </TableCell>
                            <TableCell className={isRTL ? 'text-right' : 'text-left'}>
                              <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                  <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                                    <MoreHorizontal className="h-4 w-4" />
                                  </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align={isRTL ? 'start' : 'end'}>
                                  {!message.isHidden && message.moderation?.status !== 'blocked' ? (
                                    <DropdownMenuItem 
                                      onClick={() => handleModerateMessage(message)}
                                      disabled={isSubmitting}
                                    >
                                      <Flag className="mr-2 h-4 w-4" />
                                      {t('modules.groupsManagement.messagesTable.actions.block') || 'Block'}
                                    </DropdownMenuItem>
                                  ) : (
                                    <DropdownMenuItem 
                                      onClick={() => handleUnmoderateMessage(message)}
                                      disabled={isSubmitting}
                                    >
                                      <CheckCheck className="mr-2 h-4 w-4" />
                                      {t('modules.groupsManagement.messagesTable.actions.approve') || 'Approve'}
                                    </DropdownMenuItem>
                                  )}
                                  <DropdownMenuItem 
                                    onClick={() => handleDeleteMessage(message)}
                                    className="text-destructive"
                                    disabled={isSubmitting}
                                  >
                                    <Trash2 className="mr-2 h-4 w-4" />
                                    {t('modules.groupsManagement.messagesTable.actions.delete') || 'Delete'}
                                  </DropdownMenuItem>
                                </DropdownMenuContent>
                              </DropdownMenu>
                            </TableCell>
                          </TableRow>
                        );
                      })}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </>
  );
}
