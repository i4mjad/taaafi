'use client';

import React, { useState, useMemo, useRef, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { doc, collection, query, where, orderBy, limit as queryLimit, startAfter, endBefore, updateDoc, QueryDocumentSnapshot, DocumentData } from 'firebase/firestore';
import { useDocument, useCollection } from 'react-firebase-hooks/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { 
  ArrowLeft, 
  MessageSquare, 
  Search, 
  Shield,
  Flag,
  Trash2,
  MoreHorizontal,
  AlertTriangle,
  Filter,
  Eye,
  ChevronLeft,
  ChevronRight,
  RefreshCw,
  CheckCheck,
  Clock
} from 'lucide-react';
import { format, isToday, isYesterday } from 'date-fns';
import { Group, GroupMessage } from '@/types/community';
import { toast } from 'sonner';
import { SiteHeader } from '@/components/site-header';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ScrollArea } from '@/components/ui/scroll-area';

const MESSAGES_PER_PAGE = 25;

export default function GroupMessagesPage() {
  const params = useParams();
  const router = useRouter();
  const { t, locale } = useTranslation();
  const isRTL = locale === 'ar';
  const groupId = params.groupId as string;
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [lastVisible, setLastVisible] = useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [firstVisible, setFirstVisible] = useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

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

  // Build paginated query
  const buildQuery = (direction: 'next' | 'prev' = 'next') => {
    let baseQuery = query(
      collection(db, 'group_messages'),
      where('groupId', '==', groupId),
      orderBy('createdAt', 'desc'),
      queryLimit(MESSAGES_PER_PAGE)
    );

    if (direction === 'next' && lastVisible) {
      baseQuery = query(
        collection(db, 'group_messages'),
        where('groupId', '==', groupId),
        orderBy('createdAt', 'desc'),
        startAfter(lastVisible),
        queryLimit(MESSAGES_PER_PAGE)
      );
    } else if (direction === 'prev' && firstVisible) {
      baseQuery = query(
        collection(db, 'group_messages'),
        where('groupId', '==', groupId),
        orderBy('createdAt', 'desc'),
        endBefore(firstVisible),
        queryLimit(MESSAGES_PER_PAGE)
      );
    }

    return baseQuery;
  };

  // Fetch current page messages
  const [messagesValue, messagesLoading, messagesError] = useCollection(
    buildQuery()
  );

  const messages: GroupMessage[] = useMemo(() => {
    if (!messagesValue) return [];
    
    // Update pagination cursors
    if (messagesValue.docs.length > 0) {
      setFirstVisible(messagesValue.docs[0]);
      setLastVisible(messagesValue.docs[messagesValue.docs.length - 1]);
    }

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
        (filterStatus === 'unmoderated' && !message.isHidden && message.moderation?.status !== 'blocked') ||
        (filterStatus === 'pending' && message.moderation?.status === 'pending');
      
      return matchesSearch && matchesFilter;
    });
  }, [messages, search, filterStatus]);

  // Calculate stats
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

  // Moderation actions
  const handleModerateMessage = async (message: GroupMessage, reason?: string) => {
    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'group_messages', message.id), {
        isHidden: true,
        moderation: {
          status: 'blocked',
          reason: reason || 'Content moderated by admin',
          moderatedBy: 'admin',
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
        deletedAt: new Date(),
        deletedBy: 'admin',
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
          reason: 'Unmoderated by admin',
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

  // Pagination handlers
  const handleNextPage = () => {
    if (lastVisible) {
      setCurrentPage(prev => prev + 1);
      setIsLoadingMore(true);
    }
  };

  const handlePrevPage = () => {
    if (currentPage > 1) {
      setCurrentPage(prev => prev - 1);
      setIsLoadingMore(true);
    }
  };

  // Auto-scroll to bottom on new messages
  useEffect(() => {
    if (messagesEndRef.current && currentPage === 1) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
    setIsLoadingMore(false);
  }, [filteredMessages, currentPage]);

  if (messagesLoading && currentPage === 1) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="container mx-auto py-6 px-4">
          <div className="flex items-center justify-center py-12">
            <RefreshCw className="h-8 w-8 animate-spin text-primary" />
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
      <div className="container mx-auto py-6 px-4 max-w-5xl">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-4">
            <Button variant="ghost" onClick={() => router.push(`/${locale}/groups-management/${groupId}`)}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              {t('modules.groupsManagement.groupDetail.backToGroup') || 'Back to Group'}
            </Button>
            <div className={isRTL ? 'text-right' : 'text-left'}>
              <h1 className="text-2xl font-bold tracking-tight">
                {t('modules.groupsManagement.groupDetail.messages') || 'Messages'}
              </h1>
              <p className="text-muted-foreground">{group?.name || 'Group Messages'}</p>
            </div>
          </div>
        </div>

        {/* Stats Row - Compact */}
        <div className="grid grid-cols-4 gap-4 mb-6">
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">{stats.total}</div>
            <div className="text-xs text-muted-foreground">{t('modules.groupsManagement.groupDetail.totalMessages') || 'Total'}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-orange-600">{stats.pending}</div>
            <div className="text-xs text-muted-foreground">{t('modules.groupsManagement.groupDetail.pending') || 'Pending'}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-red-600">{stats.moderated}</div>
            <div className="text-xs text-muted-foreground">{t('modules.groupsManagement.groupDetail.moderated') || 'Moderated'}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-600">{stats.deleted}</div>
            <div className="text-xs text-muted-foreground">{t('modules.groupsManagement.groupDetail.deleted') || 'Deleted'}</div>
          </div>
        </div>

        {/* Search and Filter - Compact */}
        <div className="flex gap-4 mb-6">
          <div className="flex-1 relative">
            <Search className={`absolute top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground ${isRTL ? 'right-3' : 'left-3'}`} />
            <Input
              placeholder={t('modules.groupsManagement.groupDetail.searchMessagesPlaceholder') || 'Search messages or authors...'}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className={isRTL ? 'pr-10' : 'pl-10'}
              dir={isRTL ? 'rtl' : 'ltr'}
            />
          </div>
          <Select value={filterStatus} onValueChange={setFilterStatus}>
            <SelectTrigger className="w-[180px]">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">{t('common.all') || 'All Messages'}</SelectItem>
              <SelectItem value="unmoderated">{t('modules.groupsManagement.groupDetail.unmoderated') || 'Unmoderated'}</SelectItem>
              <SelectItem value="pending">{t('modules.groupsManagement.groupDetail.pending') || 'Pending Review'}</SelectItem>
              <SelectItem value="moderated">{t('modules.groupsManagement.groupDetail.moderated') || 'Moderated'}</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {/* Chat-like Messages Container */}
        <Card className="h-[600px] flex flex-col">
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="flex items-center text-base">
                <MessageSquare className="h-4 w-4 mr-2" />
                {t('modules.groupsManagement.groupDetail.messagesList') || 'Messages'} ({filteredMessages.length})
              </CardTitle>
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">
                  {t('common.page')} {currentPage}
                </span>
                <div className="flex gap-1">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={handlePrevPage}
                    disabled={currentPage === 1 || isLoadingMore}
                  >
                    <ChevronLeft className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={handleNextPage}
                    disabled={filteredMessages.length < MESSAGES_PER_PAGE || isLoadingMore}
                  >
                    {isLoadingMore ? <RefreshCw className="h-4 w-4 animate-spin" /> : <ChevronRight className="h-4 w-4" />}
                  </Button>
                </div>
              </div>
            </div>
          </CardHeader>
          
          <CardContent className="flex-1 p-0">
            <ScrollArea className="h-full px-4">
              {filteredMessages.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-center">
                  <MessageSquare className="h-12 w-12 text-muted-foreground/50 mb-4" />
                  <h3 className="text-lg font-semibold mb-2">
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
                <div className="space-y-3 py-4">
                  {filteredMessages.map((message) => {
                    const showModerationStatus = message.isHidden || message.moderation?.status === 'blocked' || message.moderation?.status === 'pending';
                    
                    return (
                      <div 
                        key={message.id} 
                        className={`group flex gap-3 p-3 rounded-lg transition-all hover:bg-muted/30 ${
                          message.isHidden || message.moderation?.status === 'blocked'
                            ? 'bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800' 
                            : message.moderation?.status === 'pending'
                            ? 'bg-yellow-50 dark:bg-yellow-950/20 border border-yellow-200 dark:border-yellow-800'
                            : 'hover:bg-gray-50'
                        }`}
                      >
                        {/* Avatar */}
                        <Avatar className="h-8 w-8 shrink-0 mt-1">
                          <AvatarFallback className="text-xs font-medium">
                            {getUserInitials(message.senderDisplayName || message.senderCpId)}
                          </AvatarFallback>
                        </Avatar>

                        {/* Message Content */}
                        <div className="flex-1 min-w-0">
                          {/* Header */}
                          <div className="flex items-baseline gap-2 mb-1">
                            <span className="font-medium text-sm truncate">
                              {message.senderDisplayName || message.senderCpId}
                            </span>
                            <span className="text-xs text-muted-foreground shrink-0">
                              {formatMessageDate(message.createdAt)}
                            </span>
                            {showModerationStatus && (
                              <div className="flex gap-1">
                                {message.isHidden && (
                                  <Badge variant="destructive" className="text-xs px-1.5 py-0.5 h-5">
                                    <Shield className="h-3 w-3 mr-1" />
                                    Hidden
                                  </Badge>
                                )}
                                {message.moderation?.status === 'blocked' && (
                                  <Badge variant="destructive" className="text-xs px-1.5 py-0.5 h-5">
                                    <Flag className="h-3 w-3 mr-1" />
                                    Blocked
                                  </Badge>
                                )}
                                {message.moderation?.status === 'pending' && (
                                  <Badge variant="outline" className="text-xs px-1.5 py-0.5 h-5 bg-yellow-100 text-yellow-800 border-yellow-200">
                                    <Clock className="h-3 w-3 mr-1" />
                                    Pending
                                  </Badge>
                                )}
                              </div>
                            )}
                          </div>

                          {/* Reply context */}
                          {message.quotedPreview && (
                            <div className="text-xs text-muted-foreground italic border-l-2 border-gray-300 pl-2 mb-2 bg-gray-50 dark:bg-gray-900 rounded p-2">
                              "{message.quotedPreview}"
                            </div>
                          )}

                          {/* Message body */}
                          <p className={`text-sm ${isRTL ? 'text-right' : 'text-left'} whitespace-pre-wrap break-words`}>
                            {message.body}
                          </p>

                          {/* Moderation reason */}
                          {message.moderation?.reason && (
                            <div className="text-xs text-red-700 bg-red-100 dark:bg-red-900/30 p-2 rounded mt-2">
                              <strong>{t('modules.groupsManagement.groupDetail.moderationReason') || 'Reason:'}</strong> {message.moderation.reason}
                            </div>
                          )}
                        </div>

                        {/* Actions */}
                        <div className="opacity-0 group-hover:opacity-100 transition-opacity">
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
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
                                  <CheckCheck className="mr-2 h-4 w-4" />
                                  {t('modules.groupsManagement.groupDetail.unmoderateMessage') || 'Approve'}
                                </DropdownMenuItem>
                              )}
                              <DropdownMenuItem 
                                onClick={() => handleDeleteMessage(message)}
                                className="text-destructive"
                                disabled={isSubmitting}
                              >
                                <Trash2 className="mr-2 h-4 w-4" />
                                {t('modules.groupsManagement.groupDetail.deleteMessage') || 'Delete'}
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      </div>
                    );
                  })}
                  <div ref={messagesEndRef} />
                </div>
              )}
            </ScrollArea>
          </CardContent>
        </Card>
      </div>
    </>
  );
}