'use client';

import { useState, useMemo } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { SiteHeader } from '@/components/site-header';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { UserReport } from '@/types/reports';
import { Group } from '@/types/community';
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
  User,
  MessageSquare,
  Users
} from 'lucide-react';
import { format } from 'date-fns';
import { toast } from 'sonner';

export default function SystemAdminReportsPage() {
  const params = useParams();
  const lang = params.lang as string;
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [groupFilter, setGroupFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('open');
  const [selectedReport, setSelectedReport] = useState<any>(null);
  const [showReportDialog, setShowReportDialog] = useState(false);
  const [showActionDialog, setShowActionDialog] = useState(false);
  const [actionType, setActionType] = useState<'resolve' | 'dismiss'>('resolve');
  const [actionReason, setActionReason] = useState('');
  const [isUpdating, setIsUpdating] = useState(false);

  // Fetch all groups
  const [groupsSnapshot] = useCollection(
    query(collection(db, 'groups'), orderBy('createdAt', 'desc'))
  );

  // Fetch all reports
  const [reportsSnapshot, reportsLoading] = useCollection(
    query(collection(db, 'usersReports'), orderBy('time', 'desc'))
  );

  // Fetch all messages for context
  const [messagesSnapshot] = useCollection(
    collection(db, 'group_messages')
  );

  const groups = useMemo(() => {
    if (!groupsSnapshot) return [];
    return groupsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as Group[];
  }, [groupsSnapshot]);

  const reports = useMemo(() => {
    if (!reportsSnapshot) return [];
    return reportsSnapshot.docs.filter(doc => 
      doc.data().relatedContent?.type?.startsWith('group_')
    ).map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        uid: data.uid,
        time: data.time,
        reportTypeId: data.reportTypeId,
        status: data.status,
        initialMessage: data.initialMessage,
        lastUpdated: data.lastUpdated,
        messagesCount: data.messagesCount,
        relatedContent: data.relatedContent,
        targetId: data.targetId,
        targetType: data.targetType,
      } as UserReport;
    });
  }, [reportsSnapshot]);

  const messages = useMemo(() => {
    if (!messagesSnapshot) return {};
    return messagesSnapshot.docs.reduce((acc, doc) => {
      acc[doc.id] = {
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
      };
      return acc;
    }, {} as Record<string, any>);
  }, [messagesSnapshot]);

  const groupsLookup = useMemo(() => {
    return groups.reduce((acc, group) => {
      acc[group.id] = group;
      return acc;
    }, {} as Record<string, any>);
  }, [groups]);

  // Filter reports
  const filteredReports = useMemo(() => {
    let filtered = reports;

    if (search) {
      filtered = filtered.filter(report => 
        report.initialMessage?.toLowerCase().includes(search.toLowerCase()) ||
        report.uid?.toLowerCase().includes(search.toLowerCase()) ||
        (report.relatedContent?.contentId && groupsLookup[report.relatedContent.contentId]?.name?.toLowerCase().includes(search.toLowerCase()))
      );
    }

    if (groupFilter !== 'all') {
      filtered = filtered.filter(report => report.relatedContent?.contentId === groupFilter);
    }

    if (statusFilter !== 'all') {
      filtered = filtered.filter(report => report.status === statusFilter);
    }

    return filtered;
  }, [reports, search, groupFilter, statusFilter, groupsLookup]);

  const stats = useMemo(() => {
    const total = reports.length;
    const open = reports.filter(r => r.status === 'pending').length;
    const inReview = reports.filter(r => r.status === 'inProgress' || r.status === 'waitingForAdminResponse').length;
    const closed = reports.filter(r => r.status === 'closed' || r.status === 'finalized').length;
    const messageReports = reports.filter(r => r.relatedContent?.type === 'comment').length;
    const memberReports = reports.filter(r => r.relatedContent?.type === 'user').length;

    return { total, open, inReview, closed, messageReports, memberReports };
  }, [reports]);

  const handleReportAction = async () => {
    if (!selectedReport) return;

    setIsUpdating(true);
    try {
      await updateDoc(doc(db, 'usersReports', selectedReport.id), {
        status: 'closed',
        lastUpdated: new Date(),
        resolution: {
          action: actionType,
          reason: actionReason,
          resolvedBy: 'system-admin',
          resolvedAt: new Date(),
        }
      });

      toast.success(t('modules.admin.systemAdmin.reportActionSuccess'));
      setShowActionDialog(false);
      setSelectedReport(null);
      setActionReason('');
    } catch (error) {
      console.error('Error updating report:', error);
      toast.error(t('modules.admin.systemAdmin.reportActionError'));
    } finally {
      setIsUpdating(false);
    }
  };

  const openActionDialog = (report: any, action: 'resolve' | 'dismiss') => {
    setSelectedReport(report);
    setActionType(action);
    setShowActionDialog(true);
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'open': return <Badge variant="destructive" className="text-xs">Open</Badge>;
      case 'in_review': return <Badge variant="outline" className="text-xs">In Review</Badge>;
      case 'closed': return <Badge variant="secondary" className="text-xs">Closed</Badge>;
      default: return <Badge variant="secondary" className="text-xs">{status}</Badge>;
    }
  };

  const getReportedContent = (report: any) => {
    if (report.relatedContent?.type === 'group_message') {
      const message = messages[report.relatedContent.contentId];
      if (message) {
        return {
          preview: message.isDeleted ? '[Deleted]' : message.isHidden ? '[Hidden]' : message.body?.substring(0, 100) + '...',
          sender: message.senderCpId,
        };
      }
    }
    return {
      preview: report.relatedContent?.title || t('modules.admin.systemAdmin.contentNotFound'),
      sender: t('modules.admin.systemAdmin.unknown'),
    };
  };

  if (reportsLoading) {
    return (
      <div className="h-full flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Reports Management</h1>
            <p className="text-muted-foreground">System-wide reports management</p>
          </div>
        </div>
        <div className="flex-1 overflow-auto">
          <div className="p-6">
            <div className="flex items-center justify-center py-12">
              <Flag className="h-12 w-12 text-muted-foreground animate-pulse" />
            </div>
          </div>
        </div>
      </div>
    );
  }

  const headerDictionary = {
    documents: t('modules.admin.reports.title') || 'Reports Management',
  };

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t('modules.admin.reports.title')}</h1>
            <p className="text-muted-foreground">{t('modules.admin.systemAdmin.reportsDescription')}</p>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto">
        <div className="p-6 space-y-6 max-w-none">
          {/* Stats */}
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{t('modules.admin.systemAdmin.totalReports')}</CardTitle>
                <Flag className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.total}</div>
                <p className="text-xs text-muted-foreground">{t('modules.admin.systemAdmin.allTime')}</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{t('modules.admin.systemAdmin.openReports')}</CardTitle>
                <AlertTriangle className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.open}</div>
                <p className="text-xs text-muted-foreground">{t('modules.admin.systemAdmin.needReview')}</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{t('modules.admin.systemAdmin.messageReports')}</CardTitle>
                <MessageSquare className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.messageReports}</div>
                <p className="text-xs text-muted-foreground">{t('modules.admin.systemAdmin.contentReports')}</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{t('modules.admin.systemAdmin.memberReports')}</CardTitle>
                <User className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.memberReports}</div>
                <p className="text-xs text-muted-foreground">{t('modules.admin.systemAdmin.userReports')}</p>
              </CardContent>
            </Card>
          </div>

          {/* Filters */}
          <Card>
            <CardHeader>
              <CardTitle>Filter Reports</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Search</label>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      placeholder="Search reports, users, or groups..."
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      className="pl-10"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">Filter by Group</label>
                  <Select value={groupFilter} onValueChange={setGroupFilter}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select group" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Groups</SelectItem>
                      {groups.map((group) => (
                        <SelectItem key={group.id} value={group.id}>
                          {group.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">Status</label>
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select status" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Status</SelectItem>
                      <SelectItem value="pending">Open</SelectItem>
                      <SelectItem value="inProgress">In Review</SelectItem>
                      <SelectItem value="closed">Closed</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Reports List */}
          <Card>
            <CardHeader>
              <CardTitle>All Group Reports ({filteredReports.length})</CardTitle>
              <CardDescription>System-wide view of all group-related reports</CardDescription>
            </CardHeader>
            <CardContent>
              {filteredReports.length === 0 ? (
                <div className="text-center py-8">
                  <Flag className="mx-auto h-12 w-12 text-muted-foreground/50" />
                  <h3 className="mt-4 text-lg font-semibold">No reports found</h3>
                  <p className="text-muted-foreground">Try adjusting your filters</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {filteredReports.map((report) => {
                    const group = report.relatedContent?.contentId ? groupsLookup[report.relatedContent.contentId] : null;
                    const content = getReportedContent(report);
                    
                    return (
                      <div key={report.id} className="border rounded-lg p-4 hover:bg-muted/50 transition-colors">
                        <div className="flex items-start justify-between gap-4">
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 mb-2">
                              <Flag className="h-4 w-4" />
                              <span className="font-medium text-sm capitalize">
                                {report.relatedContent?.type?.replace('_', ' ')} Report
                              </span>
                              <Badge variant="outline" className="text-xs">
                                <Users className="h-3 w-3 mr-1" />
                                {group?.name || report.relatedContent?.contentId}
                              </Badge>
                              {getStatusBadge(report.status)}
                            </div>
                            
                            <div className="mb-2">
                              <p className="text-sm font-medium mb-1">Reported by: {report.uid}</p>
                              <p className="text-sm text-muted-foreground mb-2">{report.initialMessage}</p>
                              
                              {report.relatedContent?.type === 'comment' && (
                                <div className="p-2 bg-muted/50 rounded border-l-2 border-orange-500">
                                  <p className="text-xs text-muted-foreground">Reported content:</p>
                                  <p className="text-sm">{content.preview}</p>
                                  <p className="text-xs text-muted-foreground mt-1">by {content.sender}</p>
                                </div>
                              )}
                            </div>

                            <div className="flex items-center gap-4 text-xs text-muted-foreground">
                              <span>{format(report.time?.toDate ? report.time.toDate() : new Date(), 'MMM dd, yyyy HH:mm')}</span>
                              <span>{report.messagesCount || 1} message(s)</span>
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
                                View Details
                              </DropdownMenuItem>
                              {report.status === 'pending' && (
                                <>
                                  <DropdownMenuItem 
                                    onClick={() => openActionDialog(report, 'resolve')}
                                    disabled={isUpdating}
                                  >
                                    <CheckCircle className="mr-2 h-4 w-4" />
                                    Resolve
                                  </DropdownMenuItem>
                                  <DropdownMenuItem 
                                    onClick={() => openActionDialog(report, 'dismiss')}
                                    disabled={isUpdating}
                                  >
                                    <XCircle className="mr-2 h-4 w-4" />
                                    Dismiss
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

          {/* Action Dialog */}
          <Dialog open={showActionDialog} onOpenChange={setShowActionDialog}>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>
                  {actionType === 'resolve' ? t('modules.admin.systemAdmin.resolveReport') : t('modules.admin.systemAdmin.dismissReport')}
                </DialogTitle>
                <DialogDescription>
                  {actionType === 'resolve' 
                    ? t('modules.admin.systemAdmin.resolveDesc')
                    : t('modules.admin.systemAdmin.dismissDesc')
                  }
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="action-reason">{t('modules.admin.systemAdmin.resolutionReason')}</Label>
                  <Textarea
                    id="action-reason"
                    placeholder={t('modules.admin.systemAdmin.resolutionPlaceholder')}
                    value={actionReason}
                    onChange={(e) => setActionReason(e.target.value)}
                    rows={3}
                  />
                </div>
              </div>

              <DialogFooter>
                <Button variant="outline" onClick={() => setShowActionDialog(false)}>
                  {t('modules.admin.systemAdmin.cancel')}
                </Button>
                <Button 
                  onClick={handleReportAction}
                  disabled={isUpdating}
                >
                  {isUpdating ? t('modules.admin.systemAdmin.processing') : t(`admin.systemAdmin.${actionType}`)}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
        </div>
      </div>
    </div>
  );
}
