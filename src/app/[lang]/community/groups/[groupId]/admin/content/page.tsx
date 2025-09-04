'use client';

import { useState, useMemo } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, where, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useGroup } from '@/hooks/useGroupAdmin';
import { AdminRoute } from '@/components/AdminRoute';
import { AdminLayout } from '@/components/AdminLayout';
import { BulkModerationTools } from '@/components/BulkModerationTools';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { 
  MessageSquare, 
  Search, 
  Eye, 
  EyeOff, 
  Trash2, 
  CheckCircle, 
  XCircle,
  MoreHorizontal,
  AlertTriangle,
  Clock,
  Shield,
  Flag
} from 'lucide-react';
import { format } from 'date-fns';
import { toast } from 'sonner';

interface GroupMessage {
  id: string;
  groupId: string;
  senderCpId: string;
  body: string;
  replyToMessageId?: string;
  quotedPreview?: string;
  mentions?: string[];
  mentionHandles?: string[];
  isDeleted: boolean;
  isHidden: boolean;
  moderation: {
    status: 'pending' | 'approved' | 'blocked';
    reason?: string;
    moderatedBy?: string;
    moderatedAt?: Date;
  };
  createdAt: Date;
  reportCount?: number;
}

interface UserReport {
  id: string;
  uid: string;
  status: 'open' | 'closed' | 'in_review';
  relatedContent: {
    type: string;
    contentId: string;
    groupId?: string;
    title?: string;
  };
  initialMessage: string;
  time: Date;
  lastUpdated: Date;
}

export default function GroupContentPage() {
  const params = useParams();
  const groupId = params.groupId as string;
  const { t } = useTranslation();
  const { group } = useGroup(groupId);
  
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedMessage, setSelectedMessage] = useState<GroupMessage | null>(null);
  const [showMessageDialog, setShowMessageDialog] = useState(false);
  const [showModerationDialog, setShowModerationDialog] = useState(false);
  const [moderationAction, setModerationAction] = useState<'approve' | 'hide' | 'delete'>('approve');
  const [moderationReason, setModerationReason] = useState('');
  const [isUpdating, setIsUpdating] = useState(false);
  const [selectedMessageIds, setSelectedMessageIds] = useState<string[]>([]);

  // Fetch group messages
  const [messagesSnapshot, messagesLoading, messagesError] = useCollection(
    query(
      collection(db, 'group_messages'),
      where('groupId', '==', groupId),
      orderBy('createdAt', 'desc')
    )
  );

  // Fetch reports for this group
  const [reportsSnapshot, reportsLoading, reportsError] = useCollection(
    query(
      collection(db, 'usersReports'),
      where('relatedContent.type', '==', 'group_message'),
      where('relatedContent.groupId', '==', groupId),
      where('status', '==', 'open')
    )
  );

  const messages = useMemo(() => {
    if (!messagesSnapshot) return [];
    
    return messagesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      moderation: {
        ...doc.data().moderation,
        moderatedAt: doc.data().moderation?.moderatedAt?.toDate(),
      }
    })) as GroupMessage[];
  }, [messagesSnapshot]);

  const reports = useMemo(() => {
    if (!reportsSnapshot) return [];
    
    return reportsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      time: doc.data().time?.toDate() || new Date(),
      lastUpdated: doc.data().lastUpdated?.toDate() || new Date(),
    })) as UserReport[];
  }, [reportsSnapshot]);

  // Filter messages
  const filteredMessages = useMemo(() => {
    let filtered = messages;

    // Apply search filter
    if (search) {
      filtered = filtered.filter(message => 
        message.body.toLowerCase().includes(search.toLowerCase()) ||
        message.senderCpId.toLowerCase().includes(search.toLowerCase())
      );
    }

    // Apply status filter
    if (statusFilter !== 'all') {
      if (statusFilter === 'reported') {
        const reportedMessageIds = reports.map(r => r.relatedContent.contentId);
        filtered = filtered.filter(message => reportedMessageIds.includes(message.id));
      } else {
        filtered = filtered.filter(message => message.moderation?.status === statusFilter);
      }
    }

    return filtered;
  }, [messages, search, statusFilter, reports]);

  // Calculate stats
  const stats = useMemo(() => {
    const total = messages.length;
    const pending = messages.filter(m => m.moderation?.status === 'pending').length;
    const approved = messages.filter(m => m.moderation?.status === 'approved').length;
    const blocked = messages.filter(m => m.moderation?.status === 'blocked').length;
    const reported = reports.length;
    const hidden = messages.filter(m => m.isHidden).length;
    const deleted = messages.filter(m => m.isDeleted).length;

    return { total, pending, approved, blocked, reported, hidden, deleted };
  }, [messages, reports]);

  const handleModerateMessage = async () => {
    if (!selectedMessage) return;

    setIsUpdating(true);
    try {
      const updates: any = {
        moderation: {
          status: moderationAction === 'approve' ? 'approved' : 'blocked',
          reason: moderationReason || undefined,
          moderatedBy: 'admin', // TODO: Get actual admin CP ID
          moderatedAt: new Date(),
        }
      };

      if (moderationAction === 'hide') {
        updates.isHidden = true;
        updates.moderation.status = 'blocked';
      } else if (moderationAction === 'delete') {
        updates.isDeleted = true;
        updates.moderation.status = 'blocked';
      }

      await updateDoc(doc(db, 'group_messages', selectedMessage.id), updates);

      toast.success(t('admin.content.messageModerated'));
      setShowModerationDialog(false);
      setSelectedMessage(null);
      setModerationReason('');
    } catch (error) {
      console.error('Error moderating message:', error);
      toast.error(t('admin.content.moderationError'));
    } finally {
      setIsUpdating(false);
    }
  };

  const openModerationDialog = (message: GroupMessage, action: 'approve' | 'hide' | 'delete') => {
    setSelectedMessage(message);
    setModerationAction(action);
    setShowModerationDialog(true);
  };

  const getModerationBadge = (message: GroupMessage) => {
    if (message.isDeleted) {
      return <Badge variant="destructive" className="text-xs">Deleted</Badge>;
    }
    if (message.isHidden) {
      return <Badge variant="secondary" className="text-xs">Hidden</Badge>;
    }
    
    const status = message.moderation?.status;
    if (status === 'pending') {
      return <Badge variant="outline" className="text-xs">Pending</Badge>;
    } else if (status === 'approved') {
      return <Badge variant="default" className="text-xs">Approved</Badge>;
    } else if (status === 'blocked') {
      return <Badge variant="destructive" className="text-xs">Blocked</Badge>;
    }
    
    return <Badge variant="secondary" className="text-xs">Unmoderated</Badge>;
  };

  const isReported = (messageId: string) => {
    return reports.some(r => r.relatedContent.contentId === messageId);
  };

  if (messagesLoading || reportsLoading) {
    return (
      <AdminRoute groupId={groupId}>
        <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin/content`}>
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <MessageSquare className="h-12 w-12 text-muted-foreground mx-auto mb-4 animate-pulse" />
              <p className="text-muted-foreground">{t('admin.content.loading')}</p>
            </div>
          </div>
        </AdminLayout>
      </AdminRoute>
    );
  }

  if (messagesError || reportsError) {
    return (
      <AdminRoute groupId={groupId}>
        <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin/content`}>
          <div className="flex items-center justify-center py-12">
            <Card className="w-full max-w-md">
              <CardContent className="flex flex-col items-center justify-center p-8">
                <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
                <p className="text-center text-destructive font-medium">
                  {t('admin.content.loadError')}
                </p>
              </CardContent>
            </Card>
          </div>
        </AdminLayout>
      </AdminRoute>
    );
  }

  return (
    <AdminRoute groupId={groupId}>
      <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin/content`}>
        <div className="space-y-6">
          {/* Header */}
          <div>
            <h1 className="text-2xl lg:text-3xl font-bold tracking-tight">
              {t('admin.content.title')}
            </h1>
            <p className="text-muted-foreground mt-1">
              {t('admin.content.description')}
            </p>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.content.stats.totalMessages')}
                </CardTitle>
                <MessageSquare className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.total}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.content.stats.allTime')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.content.stats.pendingReview')}
                </CardTitle>
                <Clock className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.pending}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.content.stats.needsAttention')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.content.stats.reported')}
                </CardTitle>
                <Flag className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.reported}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.content.stats.openReports')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.content.stats.moderated')}
                </CardTitle>
                <Shield className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.blocked + stats.hidden + stats.deleted}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.content.stats.actionsTaken')}
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Filters */}
          <Card>
            <CardHeader>
              <CardTitle>{t('admin.content.filters.title')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('admin.content.filters.search')}</label>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      placeholder={t('admin.content.filters.searchPlaceholder')}
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      className="pl-10"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('admin.content.filters.status')}</label>
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger>
                      <SelectValue placeholder={t('admin.content.filters.selectStatus')} />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">{t('common.all')}</SelectItem>
                      <SelectItem value="pending">{t('admin.content.status.pending')}</SelectItem>
                      <SelectItem value="approved">{t('admin.content.status.approved')}</SelectItem>
                      <SelectItem value="blocked">{t('admin.content.status.blocked')}</SelectItem>
                      <SelectItem value="reported">{t('admin.content.status.reported')}</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Bulk Moderation Tools */}
          {filteredMessages.length > 0 && (
            <BulkModerationTools
              messages={filteredMessages}
              onSelectionChange={setSelectedMessageIds}
            />
          )}

          {/* Messages List */}
          <Card>
            <CardHeader>
              <CardTitle>
                {t('admin.content.messages.title')} ({filteredMessages.length})
              </CardTitle>
              <CardDescription>
                {t('admin.content.messages.description')}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {filteredMessages.length === 0 ? (
                <div className="text-center py-8">
                  <MessageSquare className="mx-auto h-12 w-12 text-muted-foreground/50" />
                  <h3 className="mt-4 text-lg font-semibold">
                    {search || statusFilter !== 'all' ? t('admin.content.noResults') : t('admin.content.noMessages')}
                  </h3>
                  <p className="text-muted-foreground">
                    {search || statusFilter !== 'all' 
                      ? t('admin.content.tryDifferentFilters') 
                      : t('admin.content.noMessagesDesc')
                    }
                  </p>
                </div>
              ) : (
                <div className="space-y-4">
                  {filteredMessages.map((message) => (
                    <div key={message.id} className="border rounded-lg p-4 hover:bg-muted/50 transition-colors">
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-2">
                            <span className="font-medium text-sm">{message.senderCpId}</span>
                            {getModerationBadge(message)}
                            {isReported(message.id) && (
                              <Badge variant="outline" className="text-xs text-orange-600 border-orange-600">
                                <Flag className="h-3 w-3 mr-1" />
                                Reported
                              </Badge>
                            )}
                          </div>
                          
                          <div className="mb-2">
                            {message.isDeleted ? (
                              <p className="text-muted-foreground italic text-sm">
                                {t('admin.content.messageDeleted')}
                              </p>
                            ) : message.isHidden ? (
                              <p className="text-muted-foreground italic text-sm">
                                {t('admin.content.messageHidden')}
                              </p>
                            ) : (
                              <p className="text-sm line-clamp-3">{message.body}</p>
                            )}
                          </div>

                          <div className="flex items-center gap-4 text-xs text-muted-foreground">
                            <span>{format(message.createdAt, 'MMM dd, yyyy HH:mm')}</span>
                            {message.replyToMessageId && (
                              <span className="flex items-center gap-1">
                                <MessageSquare className="h-3 w-3" />
                                Reply
                              </span>
                            )}
                            {message.moderation?.moderatedAt && (
                              <span>
                                Moderated {format(message.moderation.moderatedAt, 'MMM dd, HH:mm')}
                              </span>
                            )}
                          </div>
                        </div>

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
                              {t('admin.content.actions.viewDetails')}
                            </DropdownMenuItem>
                            {!message.isDeleted && !message.isHidden && (
                              <>
                                <DropdownMenuItem 
                                  onClick={() => openModerationDialog(message, 'approve')}
                                  disabled={isUpdating}
                                >
                                  <CheckCircle className="mr-2 h-4 w-4" />
                                  {t('admin.content.actions.approve')}
                                </DropdownMenuItem>
                                <DropdownMenuItem 
                                  onClick={() => openModerationDialog(message, 'hide')}
                                  disabled={isUpdating}
                                >
                                  <EyeOff className="mr-2 h-4 w-4" />
                                  {t('admin.content.actions.hide')}
                                </DropdownMenuItem>
                                <DropdownMenuItem 
                                  onClick={() => openModerationDialog(message, 'delete')}
                                  className="text-destructive"
                                  disabled={isUpdating}
                                >
                                  <Trash2 className="mr-2 h-4 w-4" />
                                  {t('admin.content.actions.delete')}
                                </DropdownMenuItem>
                              </>
                            )}
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Message Details Dialog */}
          <Dialog open={showMessageDialog} onOpenChange={setShowMessageDialog}>
            <DialogContent className="max-w-2xl">
              <DialogHeader>
                <DialogTitle>{t('admin.content.messageDetails.title')}</DialogTitle>
                <DialogDescription>
                  {t('admin.content.messageDetails.description')}
                </DialogDescription>
              </DialogHeader>
              
              {selectedMessage && (
                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <label className="font-medium">{t('admin.content.messageDetails.sender')}</label>
                      <p>{selectedMessage.senderCpId}</p>
                    </div>
                    <div>
                      <label className="font-medium">{t('admin.content.messageDetails.status')}</label>
                      <div className="mt-1">{getModerationBadge(selectedMessage)}</div>
                    </div>
                    <div>
                      <label className="font-medium">{t('admin.content.messageDetails.created')}</label>
                      <p>{format(selectedMessage.createdAt, 'MMMM dd, yyyy HH:mm:ss')}</p>
                    </div>
                    {selectedMessage.moderation?.moderatedAt && (
                      <div>
                        <label className="font-medium">{t('admin.content.messageDetails.moderated')}</label>
                        <p>{format(selectedMessage.moderation.moderatedAt, 'MMMM dd, yyyy HH:mm:ss')}</p>
                      </div>
                    )}
                  </div>

                  <div>
                    <label className="font-medium text-sm">{t('admin.content.messageDetails.content')}</label>
                    <div className="mt-1 p-3 bg-muted rounded-lg">
                      {selectedMessage.isDeleted ? (
                        <p className="text-muted-foreground italic">
                          {t('admin.content.messageDeleted')}
                        </p>
                      ) : selectedMessage.isHidden ? (
                        <p className="text-muted-foreground italic">
                          {t('admin.content.messageHidden')}
                        </p>
                      ) : (
                        <p className="whitespace-pre-wrap">{selectedMessage.body}</p>
                      )}
                    </div>
                  </div>

                  {selectedMessage.moderation?.reason && (
                    <div>
                      <label className="font-medium text-sm">{t('admin.content.messageDetails.moderationReason')}</label>
                      <p className="mt-1 text-sm text-muted-foreground">{selectedMessage.moderation.reason}</p>
                    </div>
                  )}

                  {selectedMessage.replyToMessageId && (
                    <div>
                      <label className="font-medium text-sm">{t('admin.content.messageDetails.replyTo')}</label>
                      <div className="mt-1 p-2 bg-muted/50 rounded border-l-2 border-primary">
                        <p className="text-sm">{selectedMessage.quotedPreview || 'Original message'}</p>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </DialogContent>
          </Dialog>

          {/* Moderation Action Dialog */}
          <Dialog open={showModerationDialog} onOpenChange={setShowModerationDialog}>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>
                  {moderationAction === 'approve' && t('admin.content.moderation.approveTitle')}
                  {moderationAction === 'hide' && t('admin.content.moderation.hideTitle')}
                  {moderationAction === 'delete' && t('admin.content.moderation.deleteTitle')}
                </DialogTitle>
                <DialogDescription>
                  {moderationAction === 'approve' && t('admin.content.moderation.approveDesc')}
                  {moderationAction === 'hide' && t('admin.content.moderation.hideDesc')}
                  {moderationAction === 'delete' && t('admin.content.moderation.deleteDesc')}
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="reason">{t('admin.content.moderation.reason')}</Label>
                  <Textarea
                    id="reason"
                    placeholder={t('admin.content.moderation.reasonPlaceholder')}
                    value={moderationReason}
                    onChange={(e) => setModerationReason(e.target.value)}
                    rows={3}
                  />
                </div>
              </div>

              <DialogFooter>
                <Button variant="outline" onClick={() => setShowModerationDialog(false)}>
                  {t('common.cancel')}
                </Button>
                <Button 
                  onClick={handleModerateMessage}
                  disabled={isUpdating}
                  variant={moderationAction === 'delete' ? 'destructive' : 'default'}
                >
                  {isUpdating ? t('admin.content.moderating') : t(`admin.content.actions.${moderationAction}`)}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </AdminLayout>
    </AdminRoute>
  );
}
