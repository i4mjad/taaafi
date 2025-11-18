'use client';

import { useState, useMemo } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollectionData } from 'react-firebase-hooks/firestore';
import { collection, query, where, orderBy, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { MessageCircle, AlertCircle, CheckCircle, Clock, Flag, TrendingUp } from 'lucide-react';
import { Skeleton } from '@/components/ui/skeleton';

type TimeFilter = 'allTime' | 'last30Days' | 'last7Days' | 'today';

interface MetricCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  trend?: string;
  loading?: boolean;
}

function MetricCard({ title, value, icon, trend, loading }: MetricCardProps) {
  if (loading) {
    return (
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">{title}</CardTitle>
          {icon}
        </CardHeader>
        <CardContent>
          <Skeleton className="h-8 w-24" />
          {trend && <Skeleton className="h-4 w-32 mt-2" />}
        </CardContent>
      </Card>
    );
  }
  
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        {icon}
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        {trend && (
          <p className="text-xs text-muted-foreground mt-2 flex items-center gap-1">
            <TrendingUp className="h-3 w-3" />
            {trend}
          </p>
        )}
      </CardContent>
    </Card>
  );
}

export function DashboardOverview() {
  const { t } = useTranslation();
  const [timeFilter, setTimeFilter] = useState<TimeFilter>('last30Days');
  
  // Calculate date range based on filter
  const getDateFilter = useMemo(() => {
    const now = new Date();
    switch (timeFilter) {
      case 'today':
        const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        return Timestamp.fromDate(startOfDay);
      case 'last7Days':
        const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        return Timestamp.fromDate(sevenDaysAgo);
      case 'last30Days':
        const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        return Timestamp.fromDate(thirtyDaysAgo);
      default:
        return null;
    }
  }, [timeFilter]);
  
  // Fetch conversations
  const conversationsQuery = useMemo(() => {
    if (getDateFilter) {
      return query(
        collection(db, 'direct_conversations'),
        where('createdAt', '>=', getDateFilter)
      );
    }
    return query(collection(db, 'direct_conversations'));
  }, [getDateFilter]);
  
  const [conversations, conversationsLoading] = useCollectionData(conversationsQuery, { idField: 'id' });
  
  // Fetch moderation queue
  const queueQuery = useMemo(() => {
    if (getDateFilter) {
      return query(
        collection(db, 'moderation_queue'),
        where('messageType', '==', 'direct_message'),
        where('createdAt', '>=', getDateFilter)
      );
    }
    return query(
      collection(db, 'moderation_queue'),
      where('messageType', '==', 'direct_message')
    );
  }, [getDateFilter]);
  
  const [queueItems, queueLoading] = useCollectionData(queueQuery, { idField: 'id' });
  
  // Fetch user reports for DMs
  const reportsQuery = useMemo(() => {
    if (getDateFilter) {
      return query(
        collection(db, 'usersReports'),
        where('reportType', '==', 'message'),
        where('conversationId', '!=', null),
        where('createdAt', '>=', getDateFilter)
      );
    }
    return query(
      collection(db, 'usersReports'),
      where('reportType', '==', 'message'),
      where('conversationId', '!=', null)
    );
  }, [getDateFilter]);
  
  const [reports, reportsLoading] = useCollectionData(reportsQuery, { idField: 'id' });
  
  // Calculate statistics
  const stats = useMemo(() => {
    if (!queueItems) {
      return {
        totalMessages: 0,
        pendingReview: 0,
        approved: 0,
        blocked: 0,
        activeReports: 0,
        avgResponseTime: 0,
      };
    }
    
    const pendingReview = queueItems.filter((item: any) => item.status === 'pending').length;
    const reviewed = queueItems.filter((item: any) => item.status === 'reviewed');
    const approved = reviewed.filter((item: any) => item.reviewAction === 'approve').length;
    const blocked = reviewed.filter((item: any) => item.reviewAction === 'reject').length;
    
    // Calculate average response time for reviewed items
    let totalResponseTime = 0;
    let count = 0;
    reviewed.forEach((item: any) => {
      if (item.createdAt && item.reviewedAt) {
        const responseTime = item.reviewedAt.toMillis() - item.createdAt.toMillis();
        totalResponseTime += responseTime;
        count++;
      }
    });
    const avgResponseTime = count > 0 ? Math.round(totalResponseTime / count / 1000 / 60) : 0; // in minutes
    
    const activeReports = reports?.filter((report: any) => report.status === 'active').length || 0;
    
    return {
      totalMessages: queueItems.length,
      pendingReview,
      approved,
      blocked,
      activeReports,
      avgResponseTime,
    };
  }, [queueItems, reports]);
  
  // Calculate top violations
  const topViolations = useMemo(() => {
    if (!queueItems) return [];
    
    const violationCounts: { [key: string]: number } = {};
    
    queueItems.forEach((item: any) => {
      const violationType = item.finalDecision?.violationType || item.openaiAnalysis?.violationType;
      if (violationType && violationType !== 'none') {
        violationCounts[violationType] = (violationCounts[violationType] || 0) + 1;
      }
    });
    
    return Object.entries(violationCounts)
      .map(([type, count]) => ({ type, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);
  }, [queueItems]);
  
  const isLoading = conversationsLoading || queueLoading || reportsLoading;
  
  return (
    <div className="space-y-6">
      {/* Time Filter */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">
            {t('modules.community.directMessages.dashboard.title')}
          </h2>
          <p className="text-muted-foreground">
            {t('modules.community.directMessages.dashboard.description')}
          </p>
        </div>
        <Tabs value={timeFilter} onValueChange={(v) => setTimeFilter(v as TimeFilter)}>
          <TabsList>
            <TabsTrigger value="today">
              {t('modules.community.directMessages.dashboard.timeFilters.today')}
            </TabsTrigger>
            <TabsTrigger value="last7Days">
              {t('modules.community.directMessages.dashboard.timeFilters.last7Days')}
            </TabsTrigger>
            <TabsTrigger value="last30Days">
              {t('modules.community.directMessages.dashboard.timeFilters.last30Days')}
            </TabsTrigger>
            <TabsTrigger value="allTime">
              {t('modules.community.directMessages.dashboard.timeFilters.allTime')}
            </TabsTrigger>
          </TabsList>
        </Tabs>
      </div>
      
      {/* Main Metrics */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <MetricCard
          title={t('modules.community.directMessages.dashboard.metrics.totalConversations')}
          value={conversations?.length || 0}
          icon={<MessageCircle className="h-4 w-4 text-muted-foreground" />}
          loading={isLoading}
        />
        
        <MetricCard
          title={t('modules.community.directMessages.dashboard.metrics.totalMessages')}
          value={stats.totalMessages}
          icon={<MessageCircle className="h-4 w-4 text-muted-foreground" />}
          loading={isLoading}
        />
        
        <MetricCard
          title={t('modules.community.directMessages.statuses.pending')}
          value={stats.pendingReview}
          icon={<Clock className="h-4 w-4 text-yellow-500" />}
          loading={isLoading}
        />
        
        <MetricCard
          title={t('modules.community.directMessages.statuses.approved')}
          value={stats.approved}
          icon={<CheckCircle className="h-4 w-4 text-green-500" />}
          loading={isLoading}
        />
        
        <MetricCard
          title={t('modules.community.directMessages.statuses.blocked')}
          value={stats.blocked}
          icon={<AlertCircle className="h-4 w-4 text-red-500" />}
          loading={isLoading}
        />
        
        <MetricCard
          title={t('modules.community.directMessages.dashboard.metrics.activeReports')}
          value={stats.activeReports}
          icon={<Flag className="h-4 w-4 text-orange-500" />}
          loading={isLoading}
        />
      </div>
      
      {/* Additional Metrics */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>
              {t('modules.community.directMessages.dashboard.metrics.avgResponseTime')}
            </CardTitle>
            <CardDescription>Time to review flagged messages</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-12 w-32" />
            ) : (
              <div className="text-3xl font-bold">
                {stats.avgResponseTime} <span className="text-lg text-muted-foreground">mins</span>
              </div>
            )}
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader>
            <CardTitle>
              {t('modules.community.directMessages.dashboard.metrics.topViolations')}
            </CardTitle>
            <CardDescription>Most common violation types detected</CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="space-y-2">
                {[1, 2, 3].map((i) => (
                  <Skeleton key={i} className="h-6 w-full" />
                ))}
              </div>
            ) : topViolations.length > 0 ? (
              <div className="space-y-2">
                {topViolations.map((violation, index) => (
                  <div key={violation.type} className="flex items-center justify-between">
                    <span className="text-sm">
                      {index + 1}. {t(`modules.community.directMessages.violationTypes.${violation.type}`)}
                    </span>
                    <span className="text-sm font-semibold">{violation.count}</span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">
                {t('modules.community.directMessages.common.noData')}
              </p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

