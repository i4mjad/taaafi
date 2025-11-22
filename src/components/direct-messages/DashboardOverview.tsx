'use client';

import { useState, useMemo, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useTranslation } from '@/contexts/TranslationContext';
import { collection, query, where, getDocs, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { MessageCircle, AlertCircle, CheckCircle, Clock, Flag, TrendingUp } from 'lucide-react';
import { Skeleton } from '@/components/ui/skeleton';

interface MetricCardProps {
  title: string;
  value: string | number;
  subtitle: string;
  icon: React.ReactNode;
  loading?: boolean;
}

function MetricCard({ title, value, subtitle, icon, loading }: MetricCardProps) {
  if (loading) {
    return (
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">{title}</CardTitle>
          {icon}
        </CardHeader>
        <CardContent>
          <Skeleton className="h-8 w-24" />
          <Skeleton className="h-4 w-32 mt-2" />
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
        <p className="text-xs text-muted-foreground mt-2">{subtitle}</p>
      </CardContent>
    </Card>
  );
}

export function DashboardOverview() {
  const { t } = useTranslation();
  const [isLoading, setIsLoading] = useState(true);
  const [globalStats, setGlobalStats] = useState({
    totalConversations: 0,
    totalMessages: 0,
    todayMessages: 0,
    pendingReview: 0,
    approved: 0,
    blocked: 0,
    activeReports: 0,
  });
  
  // Fetch global stats (independent of filters)
  useEffect(() => {
    const fetchGlobalStats = async () => {
      try {
        setIsLoading(true);
        
        // Calculate today's date range
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayTimestamp = Timestamp.fromDate(today);
        
        // Fetch all conversations
        const conversationsQuery = query(collection(db, 'direct_conversations'));
        const conversationsSnapshot = await getDocs(conversationsQuery);
        
        // Fetch all moderation queue items for direct messages
        const queueQuery = query(
          collection(db, 'moderation_queue'),
          where('messageType', '==', 'direct_message')
        );
        const queueSnapshot = await getDocs(queueQuery);
        
        // Fetch today's messages
        const todayQuery = query(
          collection(db, 'moderation_queue'),
          where('messageType', '==', 'direct_message'),
          where('createdAt', '>=', todayTimestamp)
        );
        const todaySnapshot = await getDocs(todayQuery);
        
        // Fetch user reports
        const reportsQuery = query(
          collection(db, 'usersReports'),
          where('reportType', '==', 'message'),
          where('conversationId', '!=', null)
        );
        const reportsSnapshot = await getDocs(reportsQuery);
        
        // Calculate stats
        let pendingReview = 0;
        let approved = 0;
        let blocked = 0;
        
        queueSnapshot.forEach((doc) => {
          const data = doc.data();
          if (data.status === 'pending') {
            pendingReview++;
          } else if (data.status === 'reviewed') {
            if (data.reviewAction === 'approve') {
              approved++;
            } else if (data.reviewAction === 'reject') {
              blocked++;
            }
          }
        });
        
        const activeReports = reportsSnapshot.docs.filter((doc) => doc.data().status === 'active').length;
        
        setGlobalStats({
          totalConversations: conversationsSnapshot.size,
          totalMessages: queueSnapshot.size,
          todayMessages: todaySnapshot.size,
          pendingReview,
          approved,
          blocked,
          activeReports,
        });
      } catch (error) {
        console.error('Error fetching global stats:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchGlobalStats();
  }, []);
  
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-5">
      <MetricCard
        title={t('modules.community.directMessages.dashboard.metrics.totalConversations')}
        value={globalStats.totalConversations}
        subtitle={t('modules.community.directMessages.dashboard.subtitles.allTime')}
        icon={<MessageCircle className="h-4 w-4 text-muted-foreground" />}
        loading={isLoading}
      />
      
      <MetricCard
        title={t('modules.community.directMessages.dashboard.metrics.todaysMessages')}
        value={globalStats.todayMessages}
        subtitle={t('modules.community.directMessages.dashboard.subtitles.last24Hours')}
        icon={<TrendingUp className="h-4 w-4 text-muted-foreground" />}
        loading={isLoading}
      />
      
      <MetricCard
        title={t('modules.community.directMessages.statuses.pending')}
        value={globalStats.pendingReview}
        subtitle={t('modules.community.directMessages.dashboard.subtitles.requiresAction')}
        icon={<Clock className="h-4 w-4 text-muted-foreground" />}
        loading={isLoading}
      />
      
      <MetricCard
        title={t('modules.community.directMessages.statuses.approved')}
        value={globalStats.approved}
        subtitle={t('modules.community.directMessages.dashboard.subtitles.allTime')}
        icon={<CheckCircle className="h-4 w-4 text-muted-foreground" />}
        loading={isLoading}
      />
      
      <MetricCard
        title={t('modules.community.directMessages.statuses.blocked')}
        value={globalStats.blocked}
        subtitle={t('modules.community.directMessages.dashboard.subtitles.actionsTaken')}
        icon={<AlertCircle className="h-4 w-4 text-muted-foreground" />}
        loading={isLoading}
      />
    </div>
  );
}

