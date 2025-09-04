'use client';

import React, { useState, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { doc, collection, query, where, orderBy, limit as queryLimit, updateDoc, addDoc } from 'firebase/firestore';
import { useDocument, useCollection } from 'react-firebase-hooks/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { 
  ArrowLeft, 
  MessageSquare, 
  Search, 
  Send,
  Shield,
  Flag,
  Trash2,
  MoreHorizontal,
  AlertTriangle,
  Filter,
  Eye
} from 'lucide-react';
import { format } from 'date-fns';
import { Group, GroupMessage } from '@/types/community';
import { toast } from 'sonner';
import { SiteHeader } from '@/components/site-header';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

export default function GroupMessagesPage() {
  const params = useParams();
  const router = useRouter();
  const { t, locale } = useTranslation();
  const isRTL = locale === 'ar';
  const groupId = params.groupId as string;
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
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

  // Fetch group messages
  const [messagesValue, messagesLoading, messagesError] = useCollection(
    query(
      collection(db, 'group_messages'),
      where('groupId', '==', groupId),
      orderBy('createdAt', 'desc'),
      queryLimit(200)
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

  // Filter messages (only show non-deleted messages for moderation)
  const filteredMessages = useMemo(() => {
    return messages.filter(message => {
      if (message.isDeleted) return false;
      
      const matchesSearch = !search || 
        message.body.toLowerCase().includes(search.toLowerCase()) ||
        message.senderCpId.toLowerCase().includes(search.toLowerCase()) ||
        (message.senderDisplayName && message.senderDisplayName.toLowerCase().includes(search.toLowerCase()));
      
      const matchesFilter = filterStatus === 'all' || 
        (filterStatus === 'moderated' && (message.isHidden || message.moderation?.status === 'blocked')) ||
        (filterStatus === 'unmoderated' && !message.isHidden && message.moderation?.status !== 'blocked');
      
      return matchesSearch && matchesFilter;
    });
  }, [messages, search, filterStatus]);

  const stats = useMemo(() => {
    const total = messages.filter(m => !m.isDeleted).length;
    const moderated = messages.filter(m => (m.isHidden || m.moderation?.status === 'blocked') && !m.isDeleted).length;
    const pending = messages.filter(m => m.moderation?.status === 'pending' && !m.isDeleted).length;
    const deleted = messages.filter(m => m.isDeleted).length;

    return { total, moderated, pending, deleted };
  }, [messages]);

  const headerDictionary = {
    documents: `${group?.name} - ${t('modules.groupsManagement.groupDetail.messages')}` || 'Group Messages',
  };

  // Removed send message functionality - this is for moderation only
  
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
          reason: 'Moderation removed by admin',
          moderatedBy: 'admin',
          moderatedAt: new Date(),
        }
      });

      toast.success(t('modules.groupsManagement.groupDetail.messageUnmoderated') || 'Message unmoderated successfully');
    } catch (error) {
      console.error('Error unmoderating message:', error);
      toast.error(t('modules.groupsManagement.groupDetail.unmoderateError') || 'Error unmoderating message');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (messagesLoading) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="container mx-auto py-6 px-4">
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <MessageSquare className="h-12 w-12 text-muted-foreground mx-auto mb-4 animate-pulse" />
              <p className="text-muted-foreground">{t('modules.groupsManagement.groupDetail.loading') || 'Loading messages...'}</p>
            </div>
          </div>
        </div>
      </>
    );
  }

  if (messagesError) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="container mx-auto py-6 px-4">
          <div className="flex items-center justify-center py-12">
            <Card className="w-full max-w-md">
              <CardContent className="flex flex-col items-center justify-center p-8">
                <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
                <p className="text-center text-destructive font-medium">
                  {t('modules.groupsManagement.groupDetail.loadError') || 'Error loading messages'}
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
                {t('modules.groupsManagement.groupDetail.messages') || 'Messages'}
              </h1>
              <p className="text-muted-foreground">{group?.name || 'Group Messages'}</p>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.groupsManagement.groupDetail.totalMessages') || 'Total Messages'}
              </CardTitle>
              <MessageSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.total}</div>
              <p className="text-xs text-muted-foreground">
                {t('modules.groupsManagement.groupDetail.active') || 'Active'}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.groupsManagement.groupDetail.moderated') || 'Moderated'}
              </CardTitle>
              <Shield className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.moderated}</div>
              <p className="text-xs text-muted-foreground">
                {stats.total > 0 ? Math.round((stats.moderated / stats.total) * 100) : 0}% {t('modules.groupsManagement.groupDetail.ofTotal') || 'of total'}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.groupsManagement.groupDetail.pending') || 'Pending Review'}
              </CardTitle>
              <Flag className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.pending}</div>
              <p className="text-xs text-muted-foreground">
                {t('modules.groupsManagement.groupDetail.needsReview') || 'Needs review'}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.groupsManagement.groupDetail.deleted') || 'Deleted'}
              </CardTitle>
              <Trash2 className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stats.deleted}</div>
              <p className="text-xs text-muted-foreground">
                {t('modules.groupsManagement.groupDetail.removed') || 'Removed'}
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Removed send message - this is for moderation only */}

        {/* Search and Filter */}
        <Card className="mb-6">
          <CardHeader>
            <CardTitle className="flex items-center">
              <Filter className="h-5 w-5 mr-2" />
              {t('modules.groupsManagement.groupDetail.searchAndFilter') || 'Search & Filter'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="md:col-span-2">
                <div className={`relative ${isRTL ? 'rtl' : 'ltr'}`}>
                  <Search className={`absolute top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground ${isRTL ? 'right-3' : 'left-3'}`} />
                  <Input
                    placeholder={t('modules.groupsManagement.groupDetail.searchMessagesPlaceholder') || 'Search messages or authors...'}
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className={isRTL ? 'pr-10' : 'pl-10'}
                    dir={isRTL ? 'rtl' : 'ltr'}
                  />
                </div>
              </div>
              <div>
                <Select value={filterStatus} onValueChange={setFilterStatus}>
                  <SelectTrigger>
                    <SelectValue placeholder={t('modules.groupsManagement.groupDetail.filterByStatus') || 'Filter by status'} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">{t('common.all') || 'All Messages'}</SelectItem>
                    <SelectItem value="unmoderated">{t('modules.groupsManagement.groupDetail.unmoderated') || 'Unmoderated'}</SelectItem>
                    <SelectItem value="moderated">{t('modules.groupsManagement.groupDetail.moderated') || 'Moderated'}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Messages List */}
        <Card>
          <CardHeader>
            <CardTitle>
              {t('modules.groupsManagement.groupDetail.messagesList') || 'Messages'} ({filteredMessages.length})
            </CardTitle>
            <CardDescription>
              {t('modules.groupsManagement.groupDetail.messagesDescription') || 'View and moderate group messages'}
            </CardDescription>
          </CardHeader>
          <CardContent>
            {filteredMessages.length === 0 ? (
              <div className="text-center py-8">
                <MessageSquare className="mx-auto h-12 w-12 text-muted-foreground/50" />
                <h3 className="mt-4 text-lg font-semibold">
                  {search || filterStatus !== 'all' 
                    ? (t('modules.groupsManagement.groupDetail.noSearchResults') || 'No messages found') 
                    : (t('modules.groupsManagement.groupDetail.noMessages') || 'No messages')
                  }
                </h3>
                <p className="text-muted-foreground">
                  {search || filterStatus !== 'all'
                    ? (t('modules.groupsManagement.groupDetail.tryDifferentSearch') || 'Try adjusting your search or filter')
                    : (t('modules.groupsManagement.groupDetail.noMessagesDesc') || 'No messages in this group yet')
                  }
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                                    {filteredMessages.map((message) => (
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
                              <DropdownMenuItem onClick={() => {/* View author profile */}}>
                                <Eye className="mr-2 h-4 w-4" />
                                {t('modules.groupsManagement.groupDetail.viewAuthor') || 'View Author'}
                              </DropdownMenuItem>
                              {!message.isHidden && message.moderation?.status !== 'blocked' ? (
                                <DropdownMenuItem 
                                  onClick={() => handleModerateMessage(message)}
                                  disabled={isSubmitting}
                                >
                                  <Flag className="mr-2 h-4 w-4" />
                                  {t('modules.groupsManagement.groupDetail.moderateMessage') || 'Moderate'}
                                </DropdownMenuItem>
                              ) : (
                                <DropdownMenuItem 
                                  onClick={() => handleUnmoderateMessage(message)}
                                  disabled={isSubmitting}
                                >
                                  <Shield className="mr-2 h-4 w-4" />
                                  {t('modules.groupsManagement.groupDetail.unmoderateMessage') || 'Remove Moderation'}
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
      </div>
    </>
  );
}
