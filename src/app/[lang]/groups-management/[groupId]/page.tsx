'use client';

import React, { useState, useMemo, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { doc, getDoc, collection, query, where, orderBy, limit as queryLimit, updateDoc, deleteDoc } from 'firebase/firestore';
import { useDocument, useCollection } from 'react-firebase-hooks/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
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
  Globe
} from 'lucide-react';
import { format } from 'date-fns';
import { Group, GroupMember, GroupMessage } from '@/types/community';
import { toast } from 'sonner';
import { SiteHeader } from '@/components/site-header';

export default function GroupDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { t, locale } = useTranslation();
  const isRTL = locale === 'ar';
  const groupId = params.groupId as string;

  const [activeTab, setActiveTab] = useState('overview');
  const [selectedMember, setSelectedMember] = useState<GroupMember | null>(null);
  const [selectedMessage, setSelectedMessage] = useState<GroupMessage | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

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

  // Fetch group messages (using correct schema fields)
  const [messagesValue, messagesLoading, messagesError] = useCollection(
    query(
      collection(db, 'group_messages'),
      where('groupId', '==', groupId),
      orderBy('createdAt', 'desc'),
      queryLimit(100)
    )
  );

  const messages: GroupMessage[] = useMemo(() => {
    if (!messagesValue) return [];
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
      };
    }) as GroupMessage[];
  }, [messagesValue]);

  // Filter out deleted messages for display
  const visibleMessages = useMemo(() => {
    return messages.filter(message => !message.isDeleted);
  }, [messages]);

  // Calculate stats using correct schema fields
  const stats = useMemo(() => {
    const totalMembers = members.length;
    const admins = members.filter(m => m.role === 'admin').length;
    const totalMessages = visibleMessages.length;
    const moderatedMessages = visibleMessages.filter(m => m.moderation?.status === 'blocked' || m.isHidden).length;
    const totalPoints = members.reduce((sum, m) => sum + (m.pointsTotal || 0), 0);
    const averagePoints = totalMembers > 0 ? Math.round(totalPoints / totalMembers) : 0;

    return {
      totalMembers,
      admins,
      totalMessages,
      moderatedMessages,
      totalPoints,
      averagePoints
    };
  }, [members, visibleMessages]);

  const headerDictionary = {
    documents: group?.name || t('modules.groupsManagement.groupDetail.title'),
  };

  // Removed send message functionality - this is for moderation only

  const handleRemoveMember = async (member: GroupMember) => {
    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'group_memberships', member.id), {
        isActive: false,
        leftAt: new Date(),
      });

      toast.success(t('modules.groupsManagement.groupDetail.memberRemoved') || 'Member removed successfully');
      setShowMemberActions(false);
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
      setShowMemberActions(false);
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
                {stats.moderatedMessages} {t('modules.groupsManagement.groupDetail.moderated') || 'moderated'}
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
                      Visibility
                    </h4>
                    <Badge variant="outline" className="flex items-center gap-1 w-fit">
                      {group.visibility === 'public' ? <Globe className="h-3 w-3" /> : <Lock className="h-3 w-3" />}
                      {group.visibility === 'public' ? 'Public' : 'Private'}
                    </Badge>
                  </div>
                  <div>
                    <h4 className="font-medium text-sm text-muted-foreground">
                      Join Method
                    </h4>
                    <p>{group.joinMethod.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}</p>
                  </div>
                  {group.joinCode && (
                    <div>
                      <h4 className="font-medium text-sm text-muted-foreground">
                        Join Code
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
                        Status
                      </h4>
                      <Badge variant="destructive">
                        Paused
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
            {/* Messages List - Moderation Only */}
            <Card>
              <CardHeader>
                <CardTitle>
                  {t('modules.groupsManagement.groupDetail.messagesList') || 'Group Messages'} ({stats.totalMessages})
                </CardTitle>
                <CardDescription>
                  {t('modules.groupsManagement.groupDetail.messagesDescription') || 'View and moderate group messages'}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {visibleMessages.length === 0 ? (
                  <div className="text-center py-8">
                    <MessageSquare className="mx-auto h-12 w-12 text-muted-foreground/50" />
                    <h3 className="mt-4 text-lg font-semibold">
                      {t('modules.groupsManagement.groupDetail.noMessages') || 'No messages'}
                    </h3>
                    <p className="text-muted-foreground">
                      {t('modules.groupsManagement.groupDetail.noMessagesDesc') || 'No messages in this group yet'}
                    </p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {visibleMessages.map((message) => (
                      <div 
                        key={message.id} 
                        className={`p-4 border rounded-lg transition-colors ${
                          message.isHidden || message.moderation?.status === 'blocked'
                            ? 'border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950/20' 
                            : message.moderation?.status === 'pending'
                            ? 'border-yellow-200 bg-yellow-50 dark:border-yellow-800 dark:bg-yellow-950/20'
                            : 'border-gray-200 hover:bg-muted/50'
                        }`}
                      >
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-2">
                              <span className="font-medium">
                                {message.senderDisplayName || message.senderCpId}
                              </span>
                              <span className="text-xs text-muted-foreground">
                                {format(message.createdAt, 'MMM dd, yyyy HH:mm')}
                              </span>
                              {message.isHidden && (
                                <Badge variant="destructive" className="text-xs">
                                  <Shield className="h-3 w-3 mr-1" />
                                  Hidden
                                </Badge>
                              )}
                              {message.moderation?.status === 'blocked' && (
                                <Badge variant="destructive" className="text-xs">
                                  <Shield className="h-3 w-3 mr-1" />
                                  Blocked
                                </Badge>
                              )}
                              {message.moderation?.status === 'pending' && (
                                <Badge variant="outline" className="text-xs bg-yellow-100 text-yellow-800 border-yellow-200">
                                  <Flag className="h-3 w-3 mr-1" />
                                  Pending Review
                                </Badge>
                              )}
                            </div>
                            <p className={`${isRTL ? 'text-right' : 'text-left'} whitespace-pre-wrap mb-2`}>
                              {message.body}
                            </p>
                            {message.quotedPreview && (
                              <div className="text-sm text-muted-foreground italic border-l-2 border-gray-300 pl-2 mb-2">
                                "{message.quotedPreview}"
                              </div>
                            )}
                            {message.moderation?.reason && (
                              <p className="text-xs text-red-600 bg-red-100 p-2 rounded mt-2">
                                <strong>{t('modules.groupsManagement.groupDetail.moderationReason') || 'Moderation reason:'}</strong> {message.moderation.reason}
                              </p>
                            )}
                          </div>

                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" className="h-8 w-8 p-0">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align={isRTL ? 'start' : 'end'}>
                              <DropdownMenuItem onClick={() => {/* View sender profile */}}>
                                <Eye className="mr-2 h-4 w-4" />
                                {t('modules.groupsManagement.groupDetail.viewAuthor') || 'View Author'}
                              </DropdownMenuItem>
                              {!message.isHidden && message.moderation?.status !== 'blocked' && (
                                <DropdownMenuItem 
                                  onClick={() => handleModerateMessage(message)}
                                  disabled={isSubmitting}
                                >
                                  <Flag className="mr-2 h-4 w-4" />
                                  {t('modules.groupsManagement.groupDetail.moderateMessage') || 'Moderate'}
                                </DropdownMenuItem>
                              )}
                              <DropdownMenuItem 
                                onClick={() => handleDeleteMessage(message)}
                                className="text-destructive"
                                disabled={isSubmitting}
                              >
                                <Trash2 className="mr-2 h-4 w-4" />
                                {t('modules.groupsManagement.groupDetail.deleteMessage') || 'Delete Message'}
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </>
  );
}
