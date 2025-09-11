'use client';

import { useState, useMemo } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { SiteHeader } from '@/components/site-header';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, doc, writeBatch, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { MessagesTable, MessageStats } from '@/components/MessagesTable';
import { 
  MessageSquare, 
  Search, 
  CheckCircle,
  AlertTriangle,
  Flag
} from 'lucide-react';

export default function SystemAdminContentPage() {
  const params = useParams();
  const lang = params.lang as string;
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [groupFilter, setGroupFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [messageStats, setMessageStats] = useState<MessageStats>({
    total: 0,
    pending: 0,
    approved: 0,
    blocked: 0,
    reported: 0,
    hidden: 0,
    deleted: 0,
    currentPage: 1,
    totalPages: 1,
    itemsShown: 0,
  });

  const headerDictionary = {
    documents: t('modules.admin.content.title') || 'Content Moderation',
  };

  // Fetch all groups
  const [groupsSnapshot] = useCollection(
    query(collection(db, 'groups'), orderBy('createdAt', 'desc'))
  );

  // Fetch all reports
  const [reportsSnapshot] = useCollection(
    collection(db, 'usersReports')
  );

  const groups = useMemo(() => {
    if (!groupsSnapshot) return [];
    return groupsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    })) as Array<{id: string; name: string}>;
  }, [groupsSnapshot]);

  const reports = useMemo(() => {
    if (!reportsSnapshot) return [];
    return reportsSnapshot.docs.filter(doc => 
      doc.data().relatedContent?.type === 'group_message'
    ).map(doc => doc.data());
  }, [reportsSnapshot]);

  // Handle individual message moderation
  const handleMessageModeration = async (
    messageId: string, 
    action: 'approve' | 'block' | 'hide' | 'delete' | 'unhide', 
    reason?: string,
    violationType?: string
  ) => {
    try {
      const messageRef = doc(db, 'group_messages', messageId);
      const updates: any = {
        moderation: {
          status: action === 'approve' || action === 'unhide' ? 'approved' : 'blocked',
          reason: reason || getLocalizedViolationMessage(violationType),
          moderatedBy: 'admin', // TODO: Get actual admin ID
          moderatedAt: new Date(),
        }
      };

      // Apply the same logic as cloud function
      if (action === 'block') {
        updates.isHidden = true; // Hide from other users like cloud function does
      } else if (action === 'hide') {
        updates.isHidden = true;
      } else if (action === 'delete') {
        updates.isDeleted = true;
      } else if (action === 'unhide' || action === 'approve') {
        updates.isHidden = false; // Unhide the message when approving or explicitly unhiding
      }

      await updateDoc(messageRef, updates);
      return true;
    } catch (error) {
      console.error('Error moderating message:', error);
      return false;
    }
  };

  // Get localized violation message using translation system
  const getLocalizedViolationMessage = (violationType?: string): string => {
    if (!violationType) {
      return t('modules.admin.content.violationTypes.other');
    }
    
    return t(`modules.admin.content.violationTypes.${violationType}`) || t('modules.admin.content.violationTypes.other');
  };

  // Handle bulk moderation actions
  const handleBulkModeration = async (selectedIds: string[], action: 'approve' | 'hide' | 'delete', reason?: string) => {
    const batch = writeBatch(db);

    selectedIds.forEach(messageId => {
      const messageRef = doc(db, 'group_messages', messageId);
      const updates: any = {
        moderation: {
          status: action === 'approve' ? 'approved' : 'blocked',
          reason: reason || undefined,
          moderatedBy: 'admin', // TODO: Get actual admin ID
          moderatedAt: new Date(),
        }
      };

      if (action === 'hide') {
        updates.isHidden = true;
      } else if (action === 'delete') {
        updates.isDeleted = true;
      } else if (action === 'approve') {
        updates.isHidden = false; // Unhide the message when approving
      }

      batch.update(messageRef, updates);
    });

    await batch.commit();
  };

  // Handle statistics updates from MessagesTable
  const handleStatsUpdate = (stats: MessageStats) => {
    setMessageStats(stats);
  };

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">{t('modules.admin.content.title')}</h1>
            <p className="text-muted-foreground">{t('modules.admin.systemAdmin.contentDescription')}</p>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto">
          <div className="p-6 space-y-6 max-w-none">
            {/* Statistics */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">{t('modules.admin.systemAdmin.totalMessages')}</CardTitle>
                  <MessageSquare className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{messageStats.total}</div>
                  <p className="text-xs text-muted-foreground">{t('modules.admin.systemAdmin.allTime')}</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">{t('modules.admin.systemAdmin.pendingReview')}</CardTitle>
                  <AlertTriangle className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{messageStats.pending}</div>
                  <p className="text-xs text-muted-foreground">{t('modules.admin.systemAdmin.needAttention')}</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">{t('modules.admin.systemAdmin.reportedContent')}</CardTitle>
                  <Flag className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{messageStats.reported}</div>
                  <p className="text-xs text-muted-foreground">{t('modules.admin.systemAdmin.openReports')}</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">{t('modules.admin.systemAdmin.moderatedContent')}</CardTitle>
                  <CheckCircle className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{messageStats.blocked + messageStats.hidden + messageStats.deleted}</div>
                  <p className="text-xs text-muted-foreground">{t('modules.admin.systemAdmin.actionsTaken')}</p>
                </CardContent>
              </Card>
            </div>

            {/* Filters */}
            <Card>
              <CardHeader>
                <CardTitle>{t('modules.admin.content.filters.title')}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium">{t('common.search')}</label>
                    <div className="relative">
                      <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                      <Input
                        placeholder={t('modules.admin.systemAdmin.searchPlaceholder')}
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        className="pl-10"
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">{t('modules.admin.systemAdmin.filterByGroup')}</label>
                    <Select value={groupFilter} onValueChange={setGroupFilter}>
                      <SelectTrigger>
                        <SelectValue placeholder={t('modules.admin.systemAdmin.selectGroupPlaceholder')} />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">{t('modules.admin.systemAdmin.allGroups')}</SelectItem>
                        {groups.map((group) => (
                          <SelectItem key={group.id} value={group.id}>
                            {group.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">{t('modules.admin.systemAdmin.moderationStatus')}</label>
                    <Select value={statusFilter} onValueChange={setStatusFilter}>
                      <SelectTrigger>
                        <SelectValue placeholder={t('modules.admin.systemAdmin.selectStatusPlaceholder')} />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">{t('modules.admin.systemAdmin.allStatus')}</SelectItem>
                        <SelectItem value="pending">{t('modules.admin.content.status.pending')}</SelectItem>
                        <SelectItem value="approved">{t('modules.admin.content.status.approved')}</SelectItem>
                        <SelectItem value="blocked">{t('modules.admin.content.status.blocked')}</SelectItem>
                        <SelectItem value="reported">{t('modules.admin.content.status.reported')}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Messages Table with Pagination and Bulk Actions */}
            <MessagesTable 
              groupFilter={groupFilter}
              statusFilter={statusFilter}
              searchQuery={search}
              groups={groups}
              reports={reports}
              onBulkAction={handleBulkModeration}
              onMessageModeration={handleMessageModeration}
              onStatsUpdate={handleStatsUpdate}
              locale={lang}
            />
          </div>
        </div>
      </div>
    </div>
  );
}