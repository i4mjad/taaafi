'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { RefreshCw, ShieldAlert, LayoutDashboard } from 'lucide-react';
import { SiteHeader } from '@/components/site-header';

// Dashboard tab components
import { StatsCards } from './dashboard/components/StatsCards';
import { ReferralsChart } from './dashboard/components/ReferralsChart';
import { TopReferrersTable } from './dashboard/components/TopReferrersTable';
import { RecentActivity } from './dashboard/components/RecentActivity';

// Fraud queue tab components
import { FraudQueueTable } from './components/FraudQueueTable';

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

export default function ReferralManagementPage() {
  const params = useParams();
  const lang = params.lang as string;
  const { t } = useTranslation();

  const [activeTab, setActiveTab] = useState('dashboard');
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

  const headerDictionary = {
    documents: t('modules.userManagement.referralDashboard.title'),
  };

  if (error) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex h-[50vh] items-center justify-center">
          <div className="text-center">
            <h3 className="text-lg font-semibold">{t('modules.userManagement.referralDashboard.errorLoading')}</h3>
            <p className="text-sm text-muted-foreground mt-2">{error}</p>
            <Button onClick={fetchDashboardData} className="mt-4">
              {t('modules.userManagement.referralDashboard.tryAgain')}
            </Button>
          </div>
        </div>
      </>
    );
  }

  if (isLoading || !stats) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex h-[50vh] items-center justify-center">
          <div className="text-center">
            <RefreshCw className="h-8 w-8 animate-spin mx-auto text-muted-foreground" />
            <p className="text-sm text-muted-foreground mt-4">{t('modules.userManagement.referralDashboard.loading')}</p>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex flex-1 flex-col">
        <div className="@container/main flex flex-1 flex-col gap-2">
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6 space-y-6">
            {/* Header Section */}
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

                {/* Tabs */}
            <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
              <TabsList className="grid w-full grid-cols-2 max-w-md">
                <TabsTrigger value="dashboard" className="gap-2">
                  <LayoutDashboard className="h-4 w-4" />
                  {t('modules.userManagement.referralDashboard.tabs.dashboard')}
                </TabsTrigger>
                <TabsTrigger value="fraud-queue" className="gap-2">
                  <ShieldAlert className="h-4 w-4" />
                  {t('modules.userManagement.referralDashboard.tabs.fraudQueue')}
                  {stats.flaggedForReview > 0 && (
                    <span className="ml-1 flex h-5 w-5 items-center justify-center rounded-full bg-orange-600 text-xs text-white">
                      {stats.flaggedForReview}
                    </span>
                  )}
                </TabsTrigger>
              </TabsList>

              {/* Dashboard Tab */}
              <TabsContent value="dashboard" className="space-y-6">
                {/* Stats Cards */}
                <StatsCards stats={stats} />

                {/* Chart Section */}
                <ReferralsChart data={chartData} />

                {/* Bottom Section */}
                {topReferrers.length > 0 ? (
                  <div className="grid gap-6 grid-cols-1 lg:grid-cols-2">
                    <TopReferrersTable referrers={topReferrers} lang={lang} />
                    <RecentActivity activities={recentActivity} />
                  </div>
                ) : (
                  <RecentActivity activities={recentActivity} />
                )}
              </TabsContent>

              {/* Fraud Queue Tab */}
              <TabsContent value="fraud-queue" className="space-y-6">
                <FraudQueueTable />
              </TabsContent>
            </Tabs>
          </div>
        </div>
      </div>
    </>
  );
}

