'use client';

import { useState, useMemo, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { collection, query, where, orderBy, doc, updateDoc, getDocs, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useGroup } from '@/hooks/useGroupAdmin';
import { GroupMessage } from '@/types/community';
import { AdminRoute } from '@/components/AdminRoute';
import { AdminLayout } from '@/components/AdminLayout';
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
  Flag, 
  Search, 
  Eye, 
  CheckCircle, 
  XCircle,
  MoreHorizontal,
  AlertTriangle,
  Clock,
  User,
  MessageSquare,
  RefreshCw
} from 'lucide-react';
import { format } from 'date-fns';
import { toast } from 'sonner';

interface UserReport {
  id: string;
  uid: string; // Reporter UID
  status: 'open' | 'closed' | 'in_review';
  relatedContent: {
    type: string;
    contentId: string;
    groupId?: string;
    title?: string;
  };
  initialMessage: string;
  messagesCount: number;
  time: Date;
  lastUpdated: Date;
  reportTypeId?: string;
}

// GroupMessage interface now imported from @/types/community

export default function GroupReportsPage() {
  const params = useParams();
  const groupId = params.groupId as string;
  const { t } = useTranslation();
  const { group } = useGroup(groupId);
  
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('open');
  const [selectedReport, setSelectedReport] = useState<UserReport | null>(null);
  const [showReportDialog, setShowReportDialog] = useState(false);
  const [showActionDialog, setShowActionDialog] = useState(false);
  const [actionType, setActionType] = useState<'resolve' | 'dismiss'>('resolve');
  const [actionReason, setActionReason] = useState('');
  const [isUpdating, setIsUpdating] = useState(false);

  // State for reports and messages
  const [reports, setReports] = useState<UserReport[]>([]);
  const [reportsLoading, setReportsLoading] = useState(true);
  const [reportsError, setReportsError] = useState<Error | null>(null);
  const [messages, setMessages] = useState<Record<string, GroupMessage>>({});
  const [usersData, setUsersData] = useState<Map<string, { displayName: string; email: string }>>(new Map());
  const [usersLoading, setUsersLoading] = useState(false);

  // Fetch reports and related data
  const fetchReportsData = async () => {
    setReportsLoading(true);
    setReportsError(null);
    try {
      // Fetch reports for this group
      const reportsQuery = query(
        collection(db, 'usersReports'),
        where('relatedContent.type', 'in', ['group_message', 'group_member', 'group_challenge', 'group_task']),
        where('relatedContent.groupId', '==', groupId),
        orderBy('time', 'desc')
      );
      const reportsSnapshot = await getDocs(reportsQuery);
      
      const reportsData = reportsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        time: doc.data().time?.toDate() || new Date(),
        lastUpdated: doc.data().lastUpdated?.toDate() || new Date(),
      })) as UserReport[];
      
      setReports(reportsData);

      // Extract unique message IDs from reports
      const messageIds = new Set<string>();
      const userIds = new Set<string>();
      
      reportsData.forEach(report => {
        // Add reporter UID
        userIds.add(report.uid);
        
        // Add message ID if it's a message report
        if (report.relatedContent.type === 'group_message') {
          messageIds.add(report.relatedContent.contentId);
        }
      });

      // Fetch only the messages that are reported
      if (messageIds.size > 0) {
        const messagesMap: Record<string, GroupMessage> = {};
        const messagePromises = Array.from(messageIds).map(async (messageId) => {
          const messageDoc = await getDoc(doc(db, 'group_messages', messageId));
          if (messageDoc.exists()) {
            const data = messageDoc.data();
            messagesMap[messageId] = {
              id: messageDoc.id,
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
            // Add message sender to userIds
            if (data.senderCpId) {
              userIds.add(data.senderCpId);
            }
          }
        });
        await Promise.all(messagePromises);
        setMessages(messagesMap);
      }

      // Fetch user details for all unique users (reporters and message senders)
      if (userIds.size > 0) {
        setUsersLoading(true);
        const userPromises = Array.from(userIds).map(async (userId) => {
          const userDoc = await getDoc(doc(db, 'users', userId));
          return { userId, data: userDoc.exists() ? userDoc.data() : null };
        });
        
        const userResults = await Promise.all(userPromises);
        const newUsersMap = new Map<string, { displayName: string; email: string }>();
        
        userResults.forEach(({ userId, data }) => {
          if (data) {
            newUsersMap.set(userId, {
              displayName: data.displayName || 'Unknown User',
              email: data.email || '',
            });
          } else {
            newUsersMap.set(userId, { displayName: 'Unknown User', email: '' });
          }
        });
        
        setUsersData(newUsersMap);
        setUsersLoading(false);
      }

    } catch (error) {
      console.error('Error fetching reports data:', error);
      setReportsError(error as Error);
      toast.error(t('admin.reports.loadError'));
    } finally {
      setReportsLoading(false);
    }
  };

  useEffect(() => {
    fetchReportsData();
  }, [groupId]);

  // Filter reports
  const filteredReports = useMemo(() => {
    let filtered = reports;

    // Apply search filter
    if (search) {
      filtered = filtered.filter(report => 
        report.initialMessage.toLowerCase().includes(search.toLowerCase()) ||
        report.uid.toLowerCase().includes(search.toLowerCase()) ||
        report.relatedContent.contentId.toLowerCase().includes(search.toLowerCase())
      );
    }

    // Apply status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter(report => report.status === statusFilter);
    }

    return filtered;
  }, [reports, search, statusFilter]);

  // Calculate stats
  const stats = useMemo(() => {
    const total = reports.length;
    const open = reports.filter(r => r.status === 'open').length;
    const inReview = reports.filter(r => r.status === 'in_review').length;
    const closed = reports.filter(r => r.status === 'closed').length;
    const messageReports = reports.filter(r => r.relatedContent.type === 'group_message').length;
    const memberReports = reports.filter(r => r.relatedContent.type === 'group_member').length;

    return { total, open, inReview, closed, messageReports, memberReports };
  }, [reports]);

  const handleReportAction = async () => {
    if (!selectedReport) return;

    setIsUpdating(true);
    try {
      const newStatus = actionType === 'resolve' ? 'closed' : 'closed';
      
      await updateDoc(doc(db, 'usersReports', selectedReport.id), {
        status: newStatus,
        lastUpdated: new Date(),
        resolution: {
          action: actionType,
          reason: actionReason,
          resolvedBy: 'admin', // TODO: Get actual admin CP ID
          resolvedAt: new Date(),
        }
      });

      toast.success(t('admin.reports.actionSuccess'));
      setShowActionDialog(false);
      setSelectedReport(null);
      setActionReason('');
    } catch (error) {
      console.error('Error updating report:', error);
      toast.error(t('admin.reports.actionError'));
    } finally {
      setIsUpdating(false);
    }
  };

  const openActionDialog = (report: UserReport, action: 'resolve' | 'dismiss') => {
    setSelectedReport(report);
    setActionType(action);
    setShowActionDialog(true);
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'open':
        return <Badge variant="destructive" className="text-xs">Open</Badge>;
      case 'in_review':
        return <Badge variant="outline" className="text-xs">In Review</Badge>;
      case 'closed':
        return <Badge variant="secondary" className="text-xs">Closed</Badge>;
      default:
        return <Badge variant="secondary" className="text-xs">{status}</Badge>;
    }
  };

  const getContentTypeIcon = (type: string) => {
    switch (type) {
      case 'group_message':
        return <MessageSquare className="h-4 w-4" />;
      case 'group_member':
        return <User className="h-4 w-4" />;
      default:
        return <Flag className="h-4 w-4" />;
    }
  };

  const getReportedContent = (report: UserReport) => {
    if (report.relatedContent.type === 'group_message') {
      const message = messages[report.relatedContent.contentId];
      if (message) {
        return {
          preview: message.isDeleted ? '[Deleted]' : message.isHidden ? '[Hidden]' : message.body.substring(0, 100) + '...',
          sender: message.senderCpId,
        };
      }
    }
    return {
      preview: report.relatedContent.title || 'Content not found',
      sender: 'Unknown',
    };
  };

  if (reportsLoading) {
    return (
      <AdminRoute groupId={groupId}>
        <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin/reports`}>
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <Flag className="h-12 w-12 text-muted-foreground mx-auto mb-4 animate-pulse" />
              <p className="text-muted-foreground">{t('admin.reports.loading')}</p>
            </div>
          </div>
        </AdminLayout>
      </AdminRoute>
    );
  }

  if (reportsError) {
    return (
      <AdminRoute groupId={groupId}>
        <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin/reports`}>
          <div className="flex items-center justify-center py-12">
            <Card className="w-full max-w-md">
              <CardContent className="flex flex-col items-center justify-center p-8">
                <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
                <p className="text-center text-destructive font-medium">
                  {t('admin.reports.loadError')}
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
      <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin/reports`}>
        <div className="space-y-6">
          {/* Header */}
          <div>
            <h1 className="text-2xl lg:text-3xl font-bold tracking-tight">
              {t('admin.reports.title')}
            </h1>
            <p className="text-muted-foreground mt-1">
              {t('admin.reports.description')}
            </p>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.reports.stats.totalReports')}
                </CardTitle>
                <Flag className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.total}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.reports.stats.allTime')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.reports.stats.openReports')}
                </CardTitle>
                <AlertTriangle className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.open}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.reports.stats.needsReview')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.reports.stats.messageReports')}
                </CardTitle>
                <MessageSquare className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.messageReports}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.reports.stats.contentReports')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.reports.stats.memberReports')}
                </CardTitle>
                <User className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.memberReports}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.reports.stats.userReports')}
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Filters */}
          <Card>
            <CardHeader>
              <CardTitle>{t('admin.reports.filters.title')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('admin.reports.filters.search')}</label>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      placeholder={t('admin.reports.filters.searchPlaceholder')}
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      className="pl-10"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('admin.reports.filters.status')}</label>
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger>
                      <SelectValue placeholder={t('admin.reports.filters.selectStatus')} />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">{t('common.all')}</SelectItem>
                      <SelectItem value="open">{t('admin.reports.status.open')}</SelectItem>
                      <SelectItem value="in_review">{t('admin.reports.status.inReview')}</SelectItem>
                      <SelectItem value="closed">{t('admin.reports.status.closed')}</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Reports List */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <CardTitle>
                  {t('admin.reports.list.title')} ({filteredReports.length})
                </CardTitle>
                <CardDescription>
                  {t('admin.reports.list.description')}
                </CardDescription>
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={fetchReportsData}
                disabled={reportsLoading}
              >
                {reportsLoading ? (
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <RefreshCw className="h-4 w-4 mr-2" />
                )}
                {t('common.refresh')}
              </Button>
            </CardHeader>
            <CardContent>
              {filteredReports.length === 0 ? (
                <div className="text-center py-8">
                  <Flag className="mx-auto h-12 w-12 text-muted-foreground/50" />
                  <h3 className="mt-4 text-lg font-semibold">
                    {search || statusFilter !== 'all' ? t('admin.reports.noResults') : t('admin.reports.noReports')}
                  </h3>
                  <p className="text-muted-foreground">
                    {search || statusFilter !== 'all' 
                      ? t('admin.reports.tryDifferentFilters') 
                      : t('admin.reports.noReportsDesc')
                    }
                  </p>
                </div>
              ) : (
                <div className="space-y-4">
                  {filteredReports.map((report) => {
                    const content = getReportedContent(report);
                    return (
                      <div key={report.id} className="border rounded-lg p-4 hover:bg-muted/50 transition-colors">
                        <div className="flex items-start justify-between gap-4">
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 mb-2">
                              {getContentTypeIcon(report.relatedContent.type)}
                              <span className="font-medium text-sm capitalize">
                                {report.relatedContent.type.replace('_', ' ')} Report
                              </span>
                              {getStatusBadge(report.status)}
                            </div>
                            
                            <div className="mb-2">
                              <p className="text-sm font-medium mb-1">
                                Reported by: {usersLoading ? (
                                  <span className="text-muted-foreground">{t('common.loading')}...</span>
                                ) : (
                                  <>
                                    {usersData.get(report.uid)?.displayName || report.uid}
                                    {usersData.get(report.uid)?.email && (
                                      <span className="text-xs text-muted-foreground ml-1">
                                        ({usersData.get(report.uid)?.email})
                                      </span>
                                    )}
                                  </>
                                )}
                              </p>
                              <p className="text-sm text-muted-foreground mb-2">{report.initialMessage}</p>
                              
                              {report.relatedContent.type === 'group_message' && (
                                <div className="p-2 bg-muted/50 rounded border-l-2 border-orange-500">
                                  <p className="text-xs text-muted-foreground">Reported content:</p>
                                  <p className="text-sm">{content.preview}</p>
                                  <p className="text-xs text-muted-foreground mt-1">
                                    by {usersLoading ? (
                                      <span>{t('common.loading')}...</span>
                                    ) : (
                                      usersData.get(content.sender)?.displayName || content.sender
                                    )}
                                  </p>
                                </div>
                              )}
                            </div>

                            <div className="flex items-center gap-4 text-xs text-muted-foreground">
                              <span>{format(report.time, 'MMM dd, yyyy HH:mm')}</span>
                              <span>{report.messagesCount || 1} message(s)</span>
                              {report.lastUpdated && report.lastUpdated.getTime() !== report.time.getTime() && (
                                <span>Updated {format(report.lastUpdated, 'MMM dd, HH:mm')}</span>
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
                                setSelectedReport(report);
                                setShowReportDialog(true);
                              }}>
                                <Eye className="mr-2 h-4 w-4" />
                                {t('admin.reports.actions.viewDetails')}
                              </DropdownMenuItem>
                              {report.status === 'open' && (
                                <>
                                  <DropdownMenuItem 
                                    onClick={() => openActionDialog(report, 'resolve')}
                                    disabled={isUpdating}
                                  >
                                    <CheckCircle className="mr-2 h-4 w-4" />
                                    {t('admin.reports.actions.resolve')}
                                  </DropdownMenuItem>
                                  <DropdownMenuItem 
                                    onClick={() => openActionDialog(report, 'dismiss')}
                                    disabled={isUpdating}
                                  >
                                    <XCircle className="mr-2 h-4 w-4" />
                                    {t('admin.reports.actions.dismiss')}
                                  </DropdownMenuItem>
                                </>
                              )}
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Report Details Dialog */}
          <Dialog open={showReportDialog} onOpenChange={setShowReportDialog}>
            <DialogContent className="max-w-2xl">
              <DialogHeader>
                <DialogTitle>{t('admin.reports.details.title')}</DialogTitle>
                <DialogDescription>
                  {t('admin.reports.details.description')}
                </DialogDescription>
              </DialogHeader>
              
              {selectedReport && (
                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <label className="font-medium">{t('admin.reports.details.reporter')}</label>
                      <p>
                        {usersLoading ? (
                          <span className="text-muted-foreground">{t('common.loading')}...</span>
                        ) : (
                          <>
                            {usersData.get(selectedReport.uid)?.displayName || selectedReport.uid}
                            {usersData.get(selectedReport.uid)?.email && (
                              <span className="text-xs text-muted-foreground block">
                                {usersData.get(selectedReport.uid)?.email}
                              </span>
                            )}
                          </>
                        )}
                      </p>
                    </div>
                    <div>
                      <label className="font-medium">{t('admin.reports.details.status')}</label>
                      <div className="mt-1">{getStatusBadge(selectedReport.status)}</div>
                    </div>
                    <div>
                      <label className="font-medium">{t('admin.reports.details.reported')}</label>
                      <p>{format(selectedReport.time, 'MMMM dd, yyyy HH:mm:ss')}</p>
                    </div>
                    <div>
                      <label className="font-medium">{t('admin.reports.details.contentType')}</label>
                      <p className="capitalize">{selectedReport.relatedContent.type.replace('_', ' ')}</p>
                    </div>
                  </div>

                  <div>
                    <label className="font-medium text-sm">{t('admin.reports.details.reportMessage')}</label>
                    <div className="mt-1 p-3 bg-muted rounded-lg">
                      <p className="whitespace-pre-wrap">{selectedReport.initialMessage}</p>
                    </div>
                  </div>

                  {selectedReport.relatedContent.type === 'group_message' && (
                    <div>
                      <label className="font-medium text-sm">{t('admin.reports.details.reportedContent')}</label>
                      <div className="mt-1 p-3 bg-muted rounded-lg border-l-4 border-orange-500">
                        {(() => {
                          const content = getReportedContent(selectedReport);
                          return (
                            <div>
                              <p className="text-xs text-muted-foreground mb-1">
                                Sent by {usersLoading ? (
                                  <span>{t('common.loading')}...</span>
                                ) : (
                                  usersData.get(content.sender)?.displayName || content.sender
                                )}
                              </p>
                              <p>{content.preview}</p>
                            </div>
                          );
                        })()}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </DialogContent>
          </Dialog>

          {/* Action Dialog */}
          <Dialog open={showActionDialog} onOpenChange={setShowActionDialog}>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>
                  {actionType === 'resolve' ? t('admin.reports.actions.resolveTitle') : t('admin.reports.actions.dismissTitle')}
                </DialogTitle>
                <DialogDescription>
                  {actionType === 'resolve' 
                    ? t('admin.reports.actions.resolveDesc') 
                    : t('admin.reports.actions.dismissDesc')
                  }
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="action-reason">{t('admin.reports.actions.reason')}</Label>
                  <Textarea
                    id="action-reason"
                    placeholder={t('admin.reports.actions.reasonPlaceholder')}
                    value={actionReason}
                    onChange={(e) => setActionReason(e.target.value)}
                    rows={3}
                  />
                </div>
              </div>

              <DialogFooter>
                <Button variant="outline" onClick={() => setShowActionDialog(false)}>
                  {t('common.cancel')}
                </Button>
                <Button 
                  onClick={handleReportAction}
                  disabled={isUpdating}
                >
                  {isUpdating ? t('admin.reports.processing') : t(`admin.reports.actions.${actionType}`)}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </AdminLayout>
    </AdminRoute>
  );
}
