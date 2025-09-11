'use client';

import { useState, useEffect, useMemo } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { 
  collection, 
  query, 
  orderBy, 
  limit, 
  startAfter, 
  endBefore,
  limitToLast,
  getDocs,
  doc,
  getDoc,
  DocumentSnapshot,
  QueryConstraint,
  where
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { 
  MessageSquare, 
  Search, 
  Eye, 
  EyeOff, 
  Trash2, 
  CheckCircle,
  MoreHorizontal,
  Flag,
  Users,
  ChevronLeft,
  ChevronRight,
  Loader2
} from 'lucide-react';
import { format } from 'date-fns';
import { toast } from 'sonner';

interface GroupMessage {
  id: string;
  groupId: string;
  senderCpId: string;
  body: string;
  replyToMessageId?: string;
  isDeleted: boolean;
  isHidden: boolean;
  moderation: {
    status: 'pending' | 'approved' | 'blocked';
    reason?: string;
  };
  createdAt: any;
}

interface MessagesTableProps {
  groupFilter?: string;
  statusFilter?: string;
  searchQuery?: string;
  groups: Array<{ id: string; name: string; }>;
  reports: Array<{ relatedContent?: { contentId: string; }; }>;
  onBulkAction?: (selectedIds: string[], action: 'approve' | 'hide' | 'delete', reason?: string) => Promise<void>;
  onMessageModeration?: (messageId: string, action: 'approve' | 'block' | 'hide' | 'delete' | 'unhide', reason?: string, violationType?: string) => Promise<boolean>;
  onStatsUpdate?: (stats: MessageStats) => void;
  locale?: string;
}

export interface MessageStats {
  total: number;
  pending: number;
  approved: number;
  blocked: number;
  reported: number;
  hidden: number;
  deleted: number;
  currentPage: number;
  totalPages: number;
  itemsShown: number;
}


export function MessagesTable({ 
  groupFilter = 'all',
  statusFilter = 'all', 
  searchQuery = '',
  groups = [],
  reports = [],
  onBulkAction,
  onMessageModeration,
  onStatsUpdate,
  locale = 'en'
}: MessagesTableProps) {
  const { t } = useTranslation();
  const [messages, setMessages] = useState<GroupMessage[]>([]);
  const [allMessages, setAllMessages] = useState<GroupMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [currentPage, setCurrentPage] = useState(1);
  const [firstDoc, setFirstDoc] = useState<DocumentSnapshot | null>(null);
  const [lastDoc, setLastDoc] = useState<DocumentSnapshot | null>(null);
  const [hasNext, setHasNext] = useState(false);
  const [hasPrev, setHasPrev] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [pageSize, setPageSize] = useState(20);
  
  // Bulk action dialog state
  const [showBulkDialog, setShowBulkDialog] = useState(false);
  const [bulkAction, setBulkAction] = useState<'approve' | 'hide' | 'delete'>('approve');
  const [bulkReason, setBulkReason] = useState('');
  const [isProcessingBulk, setIsProcessingBulk] = useState(false);

  // Message detail dialog state
  const [selectedMessage, setSelectedMessage] = useState<GroupMessage | null>(null);
  const [showMessageDialog, setShowMessageDialog] = useState(false);
  
  // Individual moderation dialog state
  const [showModerationDialog, setShowModerationDialog] = useState(false);
  const [moderationAction, setModerationAction] = useState<'approve' | 'block' | 'hide' | 'delete' | 'unhide'>('block');
  const [moderationReason, setModerationReason] = useState('');
  const [violationType, setViolationType] = useState('');
  const [isProcessingModeration, setIsProcessingModeration] = useState(false);

  const groupsLookup = useMemo(() => {
    return groups.reduce((acc, group) => {
      acc[group.id] = group;
      return acc;
    }, {} as Record<string, any>);
  }, [groups]);

  const reportedMessageIds = useMemo(() => {
    return new Set(
      reports
        .filter(report => report.relatedContent?.contentId)
        .map(report => report.relatedContent!.contentId)
    );
  }, [reports]);

  // Build query constraints
  const buildQueryConstraints = (includePagination: boolean = true): QueryConstraint[] => {
    const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];
    
    if (groupFilter && groupFilter !== 'all') {
      constraints.push(where('groupId', '==', groupFilter));
    }
    
    if (statusFilter && statusFilter !== 'all') {
      if (statusFilter === 'reported') {
        // For reported messages, we'll filter on the client side after fetching
      } else {
        constraints.push(where('moderation.status', '==', statusFilter));
      }
    }
    
    if (includePagination) {
      constraints.push(limit(pageSize + 1)); // +1 to check if there's a next page
    }
    
    return constraints;
  };

  // Fetch all messages for statistics calculation
  const fetchAllMessagesForStats = async () => {
    try {
      const constraints = buildQueryConstraints(false); // No pagination for stats
      const messagesQuery = query(collection(db, 'group_messages'), ...constraints);
      const snapshot = await getDocs(messagesQuery);
      
      let fetchedMessages = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
      })) as GroupMessage[];

      // Apply client-side filtering
      if (searchQuery) {
        fetchedMessages = fetchedMessages.filter(message => 
          message.body?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          message.senderCpId?.toLowerCase().includes(searchQuery.toLowerCase())
        );
      }

      if (statusFilter === 'reported') {
        fetchedMessages = fetchedMessages.filter(message => 
          reportedMessageIds.has(message.id)
        );
      }

      setAllMessages(fetchedMessages);
      calculateAndReportStats(fetchedMessages);
      
      return fetchedMessages;
    } catch (error) {
      console.error('Error fetching all messages for stats:', error);
      return [];
    }
  };

  // Calculate and report statistics to parent
  const calculateAndReportStats = (allMsgs: GroupMessage[]) => {
    if (!onStatsUpdate) return;

    const stats: MessageStats = {
      total: allMsgs.length,
      pending: allMsgs.filter(m => m.moderation?.status === 'pending' || !m.moderation?.status).length,
      approved: allMsgs.filter(m => m.moderation?.status === 'approved').length,
      blocked: allMsgs.filter(m => m.moderation?.status === 'blocked').length,
      reported: allMsgs.filter(m => reportedMessageIds.has(m.id)).length,
      hidden: allMsgs.filter(m => m.isHidden && !m.isDeleted).length,
      deleted: allMsgs.filter(m => m.isDeleted).length,
      currentPage,
      totalPages: Math.max(1, Math.ceil(allMsgs.length / pageSize)),
      itemsShown: messages.length
    };

    setTotalPages(stats.totalPages);
    onStatsUpdate(stats);
  };

  // Fetch messages
  const fetchMessages = async (direction: 'first' | 'next' | 'prev' = 'first', cursor?: DocumentSnapshot) => {
    console.log('fetchMessages called with direction:', direction, 'cursor:', cursor?.id, 'currentPage:', currentPage);
    setLoading(true);
    try {
      // Fetch all messages for statistics on first load or filter changes
      if (direction === 'first') {
        await fetchAllMessagesForStats();
      }

      let constraints = buildQueryConstraints(true);
      
      if (direction === 'next' && cursor) {
        constraints = constraints.map(c => c.type === 'limit' ? limit(pageSize + 1) : c);
        constraints.push(startAfter(cursor));
      } else if (direction === 'prev' && cursor) {
        constraints = constraints.map(c => c.type === 'limit' ? limit(pageSize + 1) : c);
        constraints.push(endBefore(cursor));
      }

      const messagesQuery = query(collection(db, 'group_messages'), ...constraints);
      const snapshot = await getDocs(messagesQuery);
      console.log('Query returned', snapshot.docs.length, 'documents for direction:', direction);
      
      let fetchedMessages = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
      })) as GroupMessage[];

      // Handle pagination logic  
      const hasMoreDocs = fetchedMessages.length > pageSize;
      
      if (hasMoreDocs) {
        fetchedMessages = fetchedMessages.slice(0, pageSize);
      }

      // Client-side filtering for search and reported status
      let filteredMessages = fetchedMessages;
      
      if (searchQuery) {
        filteredMessages = filteredMessages.filter(message => 
          message.body?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          message.senderCpId?.toLowerCase().includes(searchQuery.toLowerCase())
        );
      }

      if (statusFilter === 'reported') {
        filteredMessages = filteredMessages.filter(message => 
          reportedMessageIds.has(message.id)
        );
      }

      setMessages(filteredMessages);
      
      if (snapshot.docs.length > 0) {
        // Set document cursors for pagination
        const docsToUse = hasMoreDocs ? snapshot.docs.slice(0, pageSize) : snapshot.docs;
        setFirstDoc(docsToUse[0]);
        setLastDoc(docsToUse[docsToUse.length - 1]);
      }
      
      // Update pagination state
      setHasNext(hasMoreDocs);
      setHasPrev(currentPage > 1);

      // Update stats with current messages shown
      if (direction !== 'first' && allMessages.length > 0) {
        calculateAndReportStats(allMessages);
      }
      
    } catch (error) {
      console.error('Error fetching messages:', error);
      toast.error(t('modules.admin.content.loadError'));
    } finally {
      setLoading(false);
    }
  };

  // Load initial data
  useEffect(() => {
    setCurrentPage(1);
    setSelectedIds([]);
    fetchMessages('first');
  }, [groupFilter, statusFilter, searchQuery]);

  // Handle pagination
  const handleNextPage = () => {
    if (hasNext && lastDoc) {
      setCurrentPage(prev => prev + 1);
      fetchMessages('next', lastDoc);
      setSelectedIds([]);
    }
  };

  const handlePrevPage = () => {
    if (hasPrev && firstDoc) {
      console.log('Going to prev page, currentPage:', currentPage, 'firstDoc:', firstDoc.id);
      setCurrentPage(prev => prev - 1);
      fetchMessages('prev', firstDoc);
      setSelectedIds([]);
    } else {
      console.log('Cannot go to prev page, hasPrev:', hasPrev, 'firstDoc:', !!firstDoc);
    }
  };

  // Handle selection
  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      const moderatableIds = messages
        .filter(m => !m.isDeleted) // Allow hidden messages to be selected
        .map(m => m.id);
      setSelectedIds(moderatableIds);
    } else {
      setSelectedIds([]);
    }
  };

  const handleSelectMessage = (messageId: string, checked: boolean) => {
    if (checked) {
      setSelectedIds(prev => [...prev, messageId]);
    } else {
      setSelectedIds(prev => prev.filter(id => id !== messageId));
    }
  };

  // Get moderation badge
  const getModerationBadge = (message: GroupMessage) => {
    const status = message.moderation?.status || 'pending';
    const variants = {
      pending: 'secondary' as const,
      approved: 'default' as const,
      blocked: 'destructive' as const,
    };
    
    return (
      <Badge variant={variants[status]} className="text-xs">
        {t(`modules.admin.content.status.${status}`)}
      </Badge>
    );
  };

  // Handle individual message moderation
  const handleIndividualModeration = (message: GroupMessage, action: 'approve' | 'block' | 'hide' | 'delete' | 'unhide') => {
    setSelectedMessage(message);
    setModerationAction(action);
    setModerationReason('');
    setViolationType('');
    setShowModerationDialog(true);
  };

  const confirmIndividualModeration = async () => {
    if (!selectedMessage || !onMessageModeration) return;

    setIsProcessingModeration(true);
    try {
      const success = await onMessageModeration(
        selectedMessage.id,
        moderationAction,
        moderationReason || undefined,
        violationType || undefined
      );

      if (success) {
        const actionKey = `message${moderationAction.charAt(0).toUpperCase() + moderationAction.slice(1)}ed`;
        toast.success(t(`modules.admin.content.${actionKey}`));
        setShowModerationDialog(false);
        setModerationReason('');
        setViolationType('');
        // Refresh messages
        fetchMessages('first');
      } else {
        toast.error(t('modules.admin.content.moderationError'));
      }
    } catch (error) {
      console.error('Error moderating message:', error);
      toast.error(t('modules.admin.content.moderationError'));
    } finally {
      setIsProcessingModeration(false);
    }
  };

  // Handle bulk actions
  const handleBulkAction = async (action: 'approve' | 'hide' | 'delete') => {
    if (selectedIds.length === 0) {
      toast.error(t('modules.admin.content.bulk.error'));
      return;
    }

    setBulkAction(action);
    setShowBulkDialog(true);
  };

  const confirmBulkAction = async () => {
    if (!onBulkAction) return;
    
    setIsProcessingBulk(true);
    try {
      await onBulkAction(selectedIds, bulkAction, bulkReason);
      setSelectedIds([]);
      setShowBulkDialog(false);
      setBulkReason('');
      // Refresh current page
      fetchMessages('first');
      toast.success(t('modules.admin.content.bulk.success', { count: selectedIds.length }));
    } catch (error) {
      toast.error(t('modules.admin.content.bulk.error'));
    } finally {
      setIsProcessingBulk(false);
    }
  };

  const moderatableCount = messages.filter(m => !m.isDeleted).length; // Allow hidden messages to be moderated
  const allModeratable = selectedIds.length > 0 && selectedIds.length === moderatableCount;
  const someSelected = selectedIds.length > 0 && selectedIds.length < moderatableCount;

  return (
    <div className="space-y-4">
      {/* Bulk Actions Toolbar */}
      {selectedIds.length > 0 && (
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <span className="text-sm font-medium">
                  {t('modules.admin.content.bulk.selected', { count: selectedIds.length })}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setSelectedIds([])}
                >
                  {t('modules.admin.content.bulk.clearSelection')}
                </Button>
              </div>
              <div className="flex items-center gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkAction('approve')}
                >
                  <CheckCircle className="h-4 w-4 mr-2" />
                  {t('modules.admin.content.actions.approve')}
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkAction('hide')}
                >
                  <EyeOff className="h-4 w-4 mr-2" />
                  {t('modules.admin.content.actions.hide')}
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={() => handleBulkAction('delete')}
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  {t('modules.admin.content.actions.delete')}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Messages Table */}
      <Card>
        <CardHeader>
          <CardTitle>
            {t('modules.admin.content.messages.title')} 
            {!loading && ` (${messages.length} ${t('common.shown')})`}
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="h-8 w-8 animate-spin" />
            </div>
          ) : messages.length === 0 ? (
            <div className="text-center py-8">
              <MessageSquare className="mx-auto h-12 w-12 text-muted-foreground/50" />
              <h3 className="mt-4 text-lg font-semibold">
                {t('modules.admin.content.noMessages')}
              </h3>
              <p className="text-muted-foreground">
                {t('modules.admin.content.tryDifferentFilters')}
              </p>
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[50px]">
                      <Checkbox
                        checked={allModeratable}
                        ref={(el) => {
                          const inputEl = el?.querySelector('input');
                          if (inputEl) inputEl.indeterminate = someSelected;
                        }}
                        onCheckedChange={handleSelectAll}
                      />
                    </TableHead>
                    <TableHead>{t('modules.admin.content.messageDetails.sender')}</TableHead>
                    <TableHead>{t('modules.admin.content.messageDetails.content')}</TableHead>
                    <TableHead>{t('common.group')}</TableHead>
                    <TableHead>{t('modules.admin.content.messageDetails.status')}</TableHead>
                    <TableHead>{t('modules.admin.content.messageDetails.created')}</TableHead>
                    <TableHead className="w-[100px]">{t('common.actions')}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {messages.map((message) => {
                    const group = groupsLookup[message.groupId];
                    const isReported = reportedMessageIds.has(message.id);
                    const canModerate = !message.isDeleted; // Allow hidden messages to be moderated
                    
                    return (
                      <TableRow key={message.id}>
                        <TableCell>
                          {canModerate && (
                            <Checkbox
                              checked={selectedIds.includes(message.id)}
                              onCheckedChange={(checked) => 
                                handleSelectMessage(message.id, checked as boolean)
                              }
                            />
                          )}
                        </TableCell>
                        <TableCell className="font-medium">
                          {message.senderCpId}
                        </TableCell>
                        <TableCell className="max-w-[300px]">
                          {message.isDeleted ? (
                            <span className="text-muted-foreground italic">
                              {t('modules.admin.content.messageDeleted')}
                            </span>
                          ) : (
                            <div className="space-y-1">
                              {message.isHidden && (
                                <Badge variant="outline" className="text-xs text-orange-600 border-orange-600">
                                  {t('modules.admin.content.messageHidden')}
                                </Badge>
                              )}
                              <div className={`truncate ${message.isHidden ? 'text-muted-foreground' : ''}`} title={message.body}>
                                {message.body}
                              </div>
                            </div>
                          )}
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline" className="text-xs">
                            <Users className="h-3 w-3 mr-1" />
                            {group?.name || message.groupId}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            {getModerationBadge(message)}
                            {isReported && (
                              <Badge variant="outline" className="text-xs text-orange-600 border-orange-600">
                                <Flag className="h-3 w-3 mr-1" />
                                {t('modules.admin.content.status.reported')}
                              </Badge>
                            )}
                          </div>
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {format(message.createdAt, 'MMM dd, yyyy HH:mm')}
                        </TableCell>
                        <TableCell>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" className="h-8 w-8 p-0">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onClick={() => {
                                setSelectedMessage(message);
                                setShowMessageDialog(true);
                              }}>
                                <Eye className="mr-2 h-4 w-4" />
                                {t('modules.admin.content.actions.viewDetails')}
                              </DropdownMenuItem>
                              
                              {/* Individual Moderation Actions */}
                              {onMessageModeration && (
                                <>
                                  <DropdownMenuItem onClick={() => handleIndividualModeration(message, 'approve')}>
                                    <CheckCircle className="mr-2 h-4 w-4" />
                                    {t('modules.admin.content.approveMessage')}
                                  </DropdownMenuItem>
                                  <DropdownMenuItem onClick={() => handleIndividualModeration(message, 'block')}>
                                    <Flag className="mr-2 h-4 w-4" />
                                    {t('modules.admin.content.blockMessage')}
                                  </DropdownMenuItem>
                                  {message.isHidden ? (
                                    <DropdownMenuItem onClick={() => handleIndividualModeration(message, 'unhide')}>
                                      <Eye className="mr-2 h-4 w-4" />
                                      {t('modules.admin.content.unhideMessage')}
                                    </DropdownMenuItem>
                                  ) : (
                                    <DropdownMenuItem onClick={() => handleIndividualModeration(message, 'hide')}>
                                      <EyeOff className="mr-2 h-4 w-4" />
                                      {t('modules.admin.content.hideMessage')}
                                    </DropdownMenuItem>
                                  )}
                                  <DropdownMenuItem 
                                    onClick={() => handleIndividualModeration(message, 'delete')}
                                    className="text-destructive"
                                  >
                                    <Trash2 className="mr-2 h-4 w-4" />
                                    {t('modules.admin.content.deleteMessage')}
                                  </DropdownMenuItem>
                                </>
                              )}
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>

              {/* Pagination */}
              <div className="flex items-center justify-between pt-4">
                <div className="text-sm text-muted-foreground">
                  {allMessages.length > 0 ? (
                    <>
                      {t('common.showing')} {((currentPage - 1) * pageSize) + 1} - {Math.min(currentPage * pageSize, allMessages.length)} {t('common.of')} {allMessages.length} {t('common.items')}
                    </>
                  ) : (
                    t('common.noItemsFound')
                  )}
                </div>
                <div className="flex items-center gap-4">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">{t('common.rowsPerPage') || 'Rows per page'}</span>
                    <Select
                      value={`${pageSize}`}
                      onValueChange={(value) => {
                        const newPageSize = Number(value);
                        setPageSize(newPageSize);
                        setCurrentPage(1);
                        setFirstDoc(null);
                        setLastDoc(null);
                        fetchMessages('first');
                      }}
                    >
                      <SelectTrigger className="h-8 w-[70px]">
                        <SelectValue placeholder={pageSize} />
                      </SelectTrigger>
                      <SelectContent side="top">
                        {[10, 20, 30, 50, 100].map((size) => (
                          <SelectItem key={size} value={`${size}`}>
                            {size}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {t('common.page')} {currentPage} {t('common.of')} {totalPages}
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handlePrevPage}
                      disabled={!hasPrev || loading}
                    >
                      <ChevronLeft className="h-4 w-4 mr-2" />
                      {t('common.previous')}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handleNextPage}
                      disabled={!hasNext || loading}
                    >
                      {t('common.next')}
                      <ChevronRight className="h-4 w-4 ml-2" />
                    </Button>
                  </div>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Bulk Action Dialog */}
      <Dialog open={showBulkDialog} onOpenChange={setShowBulkDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {bulkAction === 'approve' && t('modules.admin.content.bulk.approveTitle')}
              {bulkAction === 'hide' && t('modules.admin.content.bulk.hideTitle')}
              {bulkAction === 'delete' && t('modules.admin.content.bulk.deleteTitle')}
            </DialogTitle>
            <DialogDescription>
              {t('modules.admin.content.bulk.confirmAction', { 
                count: selectedIds.length,
                action: t(`modules.admin.content.actions.${bulkAction}`).toLowerCase()
              })}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="bulk-reason">{t('modules.admin.content.moderation.reason')}</Label>
              <Textarea
                id="bulk-reason"
                placeholder={t('modules.admin.content.moderation.reasonPlaceholder')}
                value={bulkReason}
                onChange={(e) => setBulkReason(e.target.value)}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowBulkDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button 
              onClick={confirmBulkAction}
              disabled={isProcessingBulk}
              variant={bulkAction === 'delete' ? 'destructive' : 'default'}
            >
              {isProcessingBulk 
                ? t('modules.admin.content.bulk.processing') 
                : t('modules.admin.content.bulk.confirm', { action: t(`modules.admin.content.actions.${bulkAction}`) })
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Message Detail Dialog */}
      {selectedMessage && (
        <Dialog open={showMessageDialog} onOpenChange={setShowMessageDialog}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>{t('modules.admin.content.messageDetails.title')}</DialogTitle>
              <DialogDescription>
                {t('modules.admin.content.messageDetails.description')}
              </DialogDescription>
            </DialogHeader>
            
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label className="text-sm font-medium">
                    {t('modules.admin.content.messageDetails.sender')}
                  </Label>
                  <p className="text-sm text-muted-foreground">
                    {selectedMessage.senderCpId}
                  </p>
                </div>
                <div>
                  <Label className="text-sm font-medium">
                    {t('modules.admin.content.messageDetails.created')}
                  </Label>
                  <p className="text-sm text-muted-foreground">
                    {format(selectedMessage.createdAt, 'MMM dd, yyyy HH:mm')}
                  </p>
                </div>
              </div>
              
              <div>
                <Label className="text-sm font-medium">
                  {t('modules.admin.content.messageDetails.content')}
                </Label>
                <div className="mt-1 p-3 bg-muted rounded-md">
                  <p className="text-sm whitespace-pre-wrap">{selectedMessage.body}</p>
                </div>
              </div>

              <div>
                <Label className="text-sm font-medium">
                  {t('modules.admin.content.messageDetails.status')}
                </Label>
                <div className="mt-1">
                  {getModerationBadge(selectedMessage)}
                </div>
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setShowMessageDialog(false)}>
                {t('common.close')}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Individual Message Moderation Dialog */}
      {selectedMessage && (
        <Dialog open={showModerationDialog} onOpenChange={setShowModerationDialog}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>
                {t('modules.admin.content.moderateMessage')}
              </DialogTitle>
              <DialogDescription>
                {t(`modules.admin.content.${moderationAction}Confirm`)}
              </DialogDescription>
            </DialogHeader>
            
            <div className="space-y-4">
              {/* Message Content */}
              <div>
                <Label className="text-sm font-medium">
                  {t('modules.admin.content.messageDetails.content')}
                </Label>
                <div className="mt-1 p-3 bg-muted rounded-md">
                  <p className="text-sm whitespace-pre-wrap">{selectedMessage.body}</p>
                </div>
              </div>

              {/* Violation Type Selection (for block action) */}
              {moderationAction === 'block' && (
                <div className="space-y-2">
                  <Label htmlFor="violation-type">
                    {t('modules.admin.content.violationType')}
                  </Label>
                  <Select value={violationType} onValueChange={setViolationType}>
                    <SelectTrigger>
                      <SelectValue placeholder={t('modules.admin.content.selectViolationType')} />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="social_media_sharing">
                        {t('modules.admin.content.violationTypes.social_media_sharing')}
                      </SelectItem>
                      <SelectItem value="sexual_content">
                        {t('modules.admin.content.violationTypes.sexual_content')}
                      </SelectItem>
                      <SelectItem value="cuckoldry_content">
                        {t('modules.admin.content.violationTypes.cuckoldry_content')}
                      </SelectItem>
                      <SelectItem value="homosexuality_content">
                        {t('modules.admin.content.violationTypes.homosexuality_content')}
                      </SelectItem>
                      <SelectItem value="inappropriate_content">
                        {t('modules.admin.content.violationTypes.inappropriate_content')}
                      </SelectItem>
                      <SelectItem value="spam">
                        {t('modules.admin.content.violationTypes.spam')}
                      </SelectItem>
                      <SelectItem value="harassment">
                        {t('modules.admin.content.violationTypes.harassment')}
                      </SelectItem>
                      <SelectItem value="other">
                        {t('modules.admin.content.violationTypes.other')}
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              )}

              {/* Moderation Reason */}
              <div className="space-y-2">
                <Label htmlFor="moderation-reason">
                  {t('modules.admin.content.moderationReason')}
                </Label>
                <Textarea
                  id="moderation-reason"
                  placeholder={t('modules.admin.content.moderationReasonPlaceholder')}
                  value={moderationReason}
                  onChange={(e) => setModerationReason(e.target.value)}
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setShowModerationDialog(false)}>
                {t('common.cancel')}
              </Button>
              <Button 
                onClick={confirmIndividualModeration}
                disabled={isProcessingModeration}
                variant={moderationAction === 'delete' ? 'destructive' : 'default'}
              >
                {isProcessingModeration ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    {t('modules.admin.content.processing')}
                  </>
                ) : (
                  t(`modules.admin.content.${moderationAction}Message`)
                )}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
}
