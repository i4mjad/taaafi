'use client';

import { Users, CheckCircle, AlertCircle, XCircle } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
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

interface StatsCardsProps {
  stats: AggregateStats;
}

export function StatsCards({ stats }: StatsCardsProps) {
  const { t } = useTranslation();

  return (
    <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">
            {t('modules.userManagement.referralDashboard.stats.totalReferrals')}
          </CardTitle>
          <Users className="h-5 w-5 text-muted-foreground flex-shrink-0" />
        </CardHeader>
        <CardContent>
          <div className="text-3xl font-bold">{stats.totalReferrals.toLocaleString()}</div>
          <p className="text-xs text-muted-foreground mt-1">
            {t('modules.userManagement.referralDashboard.stats.totalReferralsDesc')}
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">
            {t('modules.userManagement.referralDashboard.stats.verifiedUsers')}
          </CardTitle>
          <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0" />
        </CardHeader>
        <CardContent>
          <div className="text-3xl font-bold text-green-600">{stats.totalVerified.toLocaleString()}</div>
          <p className="text-xs text-muted-foreground mt-1">
            {stats.conversionRate}% {t('modules.userManagement.referralDashboard.stats.conversionRate')}
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">
            {t('modules.userManagement.referralDashboard.stats.pendingReview')}
          </CardTitle>
          <AlertCircle className="h-5 w-5 text-orange-600 flex-shrink-0" />
        </CardHeader>
        <CardContent>
          <div className="text-3xl font-bold text-orange-600">{stats.flaggedForReview.toLocaleString()}</div>
          <p className="text-xs text-muted-foreground mt-1">
            {t('modules.userManagement.referralDashboard.stats.pendingReviewDesc')}
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium">
            {t('modules.userManagement.referralDashboard.stats.blocked')}
          </CardTitle>
          <XCircle className="h-5 w-5 text-red-600 flex-shrink-0" />
        </CardHeader>
        <CardContent>
          <div className="text-3xl font-bold text-red-600">{stats.totalBlocked.toLocaleString()}</div>
          <p className="text-xs text-muted-foreground mt-1">
            {t('modules.userManagement.referralDashboard.stats.blockedDesc')}
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

