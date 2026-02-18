'use client';

import { useEffect, useState } from 'react';
import { StatsCards } from './components/StatsCards';
import { ReferralsChart } from './components/ReferralsChart';
import { TopReferrersTable } from './components/TopReferrersTable';
import { RecentActivity } from './components/RecentActivity';
import { Button } from '@/components/ui/button';
import { RefreshCw } from 'lucide-react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';

interface AggregateStats {
  totalReferrals: number;
  totalVerified: number;
  totalPending: number;
  totalBlocked: number;
  flaggedForReview: number;
  autoBlocked: number;
  totalRewardsDistributed: number;
  conversionRate: number;
}

interface ChartDataPoint {
  date: string;
  referrals: number;
  verified: number;
}

interface TopReferrer {
  userId: string;
  displayName: string;
  email: string;
  photoURL?: string | null;
  totalReferred: number;
  totalVerified: number;
  totalRewards: string;
}

interface ActivityItem {
  id: string;
  type: 'signup' | 'verified' | 'reward' | 'blocked';
  message: string;
  timestamp: Date | string;
  userId?: string;
}

export default function ReferralDashboardPage() {
  const params = useParams();
  const lang = params.lang as string;
  const { t } = useTranslation();

  const [stats, setStats] = useState<AggregateStats | null>(null);
  const [chartData, setChartData] = useState<ChartDataPoint[]>([]);
  const [topReferrers, setTopReferrers] = useState<TopReferrer[]>([]);
  const [recentActivity, setRecentActivity] = useState<ActivityItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDashboardData = async () => {
    setIsLoading(true);
    setError(null);

    try {
      // Fetch all data in parallel
      const [statsRes, chartRes, referrersRes, activityRes] = await Promise.all([
        fetch('/api/admin/referrals/stats'),
        fetch('/api/admin/referrals/chart-data?days=30'),
        fetch('/api/admin/referrals/top-referrers?limit=10'),
        fetch('/api/admin/referrals/recent-activity?limit=15'),
      ]);

      // Check for errors
      if (!statsRes.ok || !chartRes.ok || !referrersRes.ok || !activityRes.ok) {
        throw new Error('Failed to fetch dashboard data');
      }

      // Parse responses
      const [statsData, chartDataRes, referrersData, activityData] = await Promise.all([
        statsRes.json(),
        chartRes.json(),
        referrersRes.json(),
        activityRes.json(),
      ]);

      setStats(statsData);
      setChartData(chartDataRes);
      setTopReferrers(referrersData);
      setRecentActivity(activityData);
    } catch (err) {
      console.error('Error fetching dashboard data:', err);
      setError(err instanceof Error ? err.message : 'Failed to load dashboard');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  if (error) {
    return (
      <div className="flex h-[50vh] items-center justify-center">
        <div className="text-center">
          <h3 className="text-lg font-semibold">{t('modules.userManagement.referralDashboard.errorLoading')}</h3>
          <p className="text-sm text-muted-foreground mt-2">{error}</p>
          <Button onClick={fetchDashboardData} className="mt-4">
            {t('modules.userManagement.referralDashboard.tryAgain')}
          </Button>
        </div>
      </div>
    );
  }

  if (isLoading || !stats) {
    return (
      <div className="flex h-[50vh] items-center justify-center">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto text-muted-foreground" />
          <p className="text-sm text-muted-foreground mt-4">{t('modules.userManagement.referralDashboard.loading')}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 w-full">
      <div className="container mx-auto p-4 md:p-6 lg:p-8 space-y-6">
        {/* Header Section - Mobile Optimized */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-2xl md:text-3xl font-bold tracking-tight">
              {t('modules.userManagement.referralDashboard.title')}
            </h2>
            <p className="text-sm text-muted-foreground mt-1">
              {t('modules.userManagement.referralDashboard.description')}
            </p>
          </div>
          <Button 
            variant="outline" 
            size="sm" 
            onClick={fetchDashboardData}
            className="w-full sm:w-auto"
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            {t('modules.userManagement.referralDashboard.refresh')}
          </Button>
        </div>

        {/* Stats Cards - Mobile First Grid */}
        <StatsCards stats={stats} />

        {/* Chart Section - Full Width on Mobile */}
        <ReferralsChart data={chartData} />

        {/* Bottom Section - Responsive Layout */}
        {topReferrers.length > 0 ? (
          <div className="grid gap-6 grid-cols-1 lg:grid-cols-2">
            <TopReferrersTable referrers={topReferrers} lang={lang} />
            <RecentActivity activities={recentActivity} />
          </div>
        ) : (
          <RecentActivity activities={recentActivity} />
        )}
      </div>
    </div>
  );
}

