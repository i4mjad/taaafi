'use client';

import { useState, useEffect } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { 
  TrendingUp, 
  TrendingDown,
  Users,
  UserCheck,
  UserX,
  Award,
  BarChart3,
  PieChart,
  Calendar,
  Download,
  RefreshCw,
  Loader2,
} from 'lucide-react';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart as RePieChart,
  Pie,
  Cell,
} from 'recharts';

interface OverviewData {
  totalReferrals: number;
  totalVerified: number;
  totalPending: number;
  totalBlocked: number;
  conversionRate: number;
  avgFraudScore: number;
  totalRewardsDistributed: number;
}

interface CohortData {
  cohortKey: string;
  totalSignups: number;
  totalVerified: number;
  conversionRate: number;
  avgTimeToVerify: number;
}

interface FunnelStage {
  stage: string;
  count: number;
  percentage: number;
  dropOff: number;
}

interface RetentionData {
  totalUsers: number;
  verifiedUsers: number;
  retentionRate: number;
  breakdown: {
    within7Days: number;
    within14Days: number;
    within30Days: number;
    over30Days: number;
    neverCompleted: number;
  };
}

export function AnalyticsDashboardTab() {
  const { t } = useTranslation();
  
  const [dateRange, setDateRange] = useState('30');
  const [cohortGroupBy, setCohortGroupBy] = useState('week');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Data states
  const [overviewData, setOverviewData] = useState<OverviewData | null>(null);
  const [cohortData, setCohortData] = useState<CohortData[]>([]);
  const [funnelData, setFunnelData] = useState<FunnelStage[]>([]);
  const [retentionData, setRetentionData] = useState<RetentionData | null>(null);

  useEffect(() => {
    fetchAllAnalytics();
  }, [dateRange, cohortGroupBy]);

  const fetchAllAnalytics = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - parseInt(dateRange));

      const [overviewRes, cohortsRes, funnelRes, retentionRes] = await Promise.all([
        fetch(`/api/admin/referrals/analytics/overview?startDate=${startDate.toISOString()}&endDate=${endDate.toISOString()}`),
        fetch(`/api/admin/referrals/analytics/cohorts?groupBy=${cohortGroupBy}&limit=12`),
        fetch(`/api/admin/referrals/analytics/funnels?startDate=${startDate.toISOString()}&endDate=${endDate.toISOString()}`),
        fetch(`/api/admin/referrals/analytics/retention`),
      ]);

      if (!overviewRes.ok || !cohortsRes.ok || !funnelRes.ok || !retentionRes.ok) {
        throw new Error('Failed to fetch analytics data');
      }

      const [overview, cohorts, funnel, retention] = await Promise.all([
        overviewRes.json(),
        cohortsRes.json(),
        funnelRes.json(),
        retentionRes.json(),
      ]);

      setOverviewData(overview);
      setCohortData(cohorts.cohorts || []);
      setFunnelData(funnel.funnel || []);
      setRetentionData(retention);
    } catch (err) {
      console.error('Error fetching analytics:', err);
      setError(err instanceof Error ? err.message : 'Failed to load analytics');
    } finally {
      setIsLoading(false);
    }
  };

  const handleExportData = () => {
    const dataToExport = {
      overview: overviewData,
      cohorts: cohortData,
      funnel: funnelData,
      retention: retentionData,
      exportedAt: new Date().toISOString(),
    };

    const blob = new Blob([JSON.stringify(dataToExport, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `referral-analytics-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <p className="text-destructive mb-4">{error}</p>
        <Button onClick={fetchAllAnalytics}>
          <RefreshCw className="h-4 w-4 mr-2" />
          {t('modules.userManagement.referralDashboard.analytics.retry')}
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header with Controls */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h3 className="text-lg font-semibold">
            {t('modules.userManagement.referralDashboard.analytics.title')}
          </h3>
          <p className="text-sm text-muted-foreground mt-1">
            {t('modules.userManagement.referralDashboard.analytics.description')}
          </p>
        </div>
        <div className="flex gap-2 flex-wrap">
          <Select value={dateRange} onValueChange={setDateRange}>
            <SelectTrigger className="w-[150px]">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7">
                {t('modules.userManagement.referralDashboard.analytics.last7Days')}
              </SelectItem>
              <SelectItem value="30">
                {t('modules.userManagement.referralDashboard.analytics.last30Days')}
              </SelectItem>
              <SelectItem value="90">
                {t('modules.userManagement.referralDashboard.analytics.last90Days')}
              </SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" size="sm" onClick={handleExportData}>
            <Download className="h-4 w-4 mr-2" />
            {t('modules.userManagement.referralDashboard.analytics.export')}
          </Button>
          <Button variant="outline" size="sm" onClick={fetchAllAnalytics}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Key Metrics */}
      {overviewData && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.userManagement.referralDashboard.analytics.totalReferrals')}
              </CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{overviewData.totalReferrals}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {t('modules.userManagement.referralDashboard.analytics.inSelectedPeriod')}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.userManagement.referralDashboard.analytics.conversionRate')}
              </CardTitle>
              <TrendingUp className="h-4 w-4 text-green-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{overviewData.conversionRate.toFixed(1)}%</div>
              <p className="text-xs text-muted-foreground mt-1">
                {overviewData.totalVerified} {t('modules.userManagement.referralDashboard.analytics.verified')}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.userManagement.referralDashboard.analytics.rewardsDistributed')}
              </CardTitle>
              <Award className="h-4 w-4 text-yellow-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{overviewData.totalRewardsDistributed}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {t('modules.userManagement.referralDashboard.analytics.premiumDays')}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {t('modules.userManagement.referralDashboard.analytics.avgFraudScore')}
              </CardTitle>
              <UserX className="h-4 w-4 text-red-500" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{overviewData.avgFraudScore.toFixed(1)}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {overviewData.totalBlocked} {t('modules.userManagement.referralDashboard.analytics.blocked')}
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Conversion Funnel */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.userManagement.referralDashboard.analytics.conversionFunnel')}</CardTitle>
          <CardDescription>
            {t('modules.userManagement.referralDashboard.analytics.conversionFunnelDesc')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={funnelData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="stage" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="count" fill="#3b82f6" name={t('modules.userManagement.referralDashboard.analytics.users')} />
              <Bar dataKey="percentage" fill="#10b981" name={t('modules.userManagement.referralDashboard.analytics.percentage')} />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Cohort Analysis */}
      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <div>
              <CardTitle>{t('modules.userManagement.referralDashboard.analytics.cohortAnalysis')}</CardTitle>
              <CardDescription>
                {t('modules.userManagement.referralDashboard.analytics.cohortAnalysisDesc')}
              </CardDescription>
            </div>
            <Select value={cohortGroupBy} onValueChange={setCohortGroupBy}>
              <SelectTrigger className="w-[120px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="week">
                  {t('modules.userManagement.referralDashboard.analytics.weekly')}
                </SelectItem>
                <SelectItem value="month">
                  {t('modules.userManagement.referralDashboard.analytics.monthly')}
                </SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={cohortData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="cohortKey" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line 
                type="monotone" 
                dataKey="totalSignups" 
                stroke="#3b82f6" 
                name={t('modules.userManagement.referralDashboard.analytics.signups')} 
              />
              <Line 
                type="monotone" 
                dataKey="totalVerified" 
                stroke="#10b981" 
                name={t('modules.userManagement.referralDashboard.analytics.verified')} 
              />
              <Line 
                type="monotone" 
                dataKey="conversionRate" 
                stroke="#f59e0b" 
                name={t('modules.userManagement.referralDashboard.analytics.conversionRate')} 
              />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Retention Analysis */}
      {retentionData && (
        <div className="grid gap-4 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>{t('modules.userManagement.referralDashboard.analytics.retentionRate')}</CardTitle>
              <CardDescription>
                {t('modules.userManagement.referralDashboard.analytics.retentionRateDesc')}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="text-4xl font-bold text-center py-8">
                {retentionData.retentionRate.toFixed(1)}%
              </div>
              <div className="text-center text-sm text-muted-foreground">
                {retentionData.verifiedUsers} / {retentionData.totalUsers}{' '}
                {t('modules.userManagement.referralDashboard.analytics.usersVerified')}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>{t('modules.userManagement.referralDashboard.analytics.timeToVerify')}</CardTitle>
              <CardDescription>
                {t('modules.userManagement.referralDashboard.analytics.timeToVerifyDesc')}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={200}>
                <RePieChart>
                  <Pie
                    data={[
                      { name: '≤ 7 days', value: retentionData.breakdown.within7Days },
                      { name: '8-14 days', value: retentionData.breakdown.within14Days },
                      { name: '15-30 days', value: retentionData.breakdown.within30Days },
                      { name: '> 30 days', value: retentionData.breakdown.over30Days },
                      { name: 'Never', value: retentionData.breakdown.neverCompleted },
                    ]}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={(entry) => `${entry.name}: ${entry.value}`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {COLORS.map((color, index) => (
                      <Cell key={`cell-${index}`} fill={color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </RePieChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Cohort Performance Table */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.userManagement.referralDashboard.analytics.cohortPerformance')}</CardTitle>
          <CardDescription>
            {t('modules.userManagement.referralDashboard.analytics.cohortPerformanceDesc')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b">
                  <th className="text-left p-2 font-medium">
                    {t('modules.userManagement.referralDashboard.analytics.cohort')}
                  </th>
                  <th className="text-left p-2 font-medium">
                    {t('modules.userManagement.referralDashboard.analytics.signups')}
                  </th>
                  <th className="text-left p-2 font-medium">
                    {t('modules.userManagement.referralDashboard.analytics.verified')}
                  </th>
                  <th className="text-left p-2 font-medium">
                    {t('modules.userManagement.referralDashboard.analytics.conversionRate')}
                  </th>
                  <th className="text-left p-2 font-medium">
                    {t('modules.userManagement.referralDashboard.analytics.avgTimeToVerify')}
                  </th>
                </tr>
              </thead>
              <tbody>
                {cohortData.map((cohort) => (
                  <tr key={cohort.cohortKey} className="border-b">
                    <td className="p-2">{cohort.cohortKey}</td>
                    <td className="p-2">{cohort.totalSignups}</td>
                    <td className="p-2">{cohort.totalVerified}</td>
                    <td className="p-2">
                      <Badge variant={cohort.conversionRate > 50 ? 'default' : 'secondary'}>
                        {cohort.conversionRate.toFixed(1)}%
                      </Badge>
                    </td>
                    <td className="p-2">{cohort.avgTimeToVerify.toFixed(1)} days</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

