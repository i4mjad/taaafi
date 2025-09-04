'use client';

import React, { useMemo } from 'react';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from "@/contexts/TranslationContext";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import {
  ArrowLeft,
  BarChart3,
  TrendingUp,
  TrendingDown,
  Clock,
  CheckCircle,
  AlertCircle,
  FileText,
  Users,
  Timer,
} from 'lucide-react';
import Link from 'next/link';

// Firebase imports - using react-firebase-hooks
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface UserReport {
  id: string;
  uid: string;
  time: Timestamp;
  reportType: string;
  status: 'pending' | 'inProgress' | 'closed' | 'finalized';
  userJustification: string;
  adminResponse: string | null;
}

interface AnalyticsData {
  totalReports: number;
  reportsByStatus: {
    pending: number;
    inProgress: number;
    closed: number;
    finalized: number;
  };
  recentTrends: {
    thisMonth: number;
    lastMonth: number;
    thisWeek: number;
    lastWeek: number;
  };
  responseTimeMetrics: {
    average: number;
    median: number;
    fastest: number;
    slowest: number;
  };
  commonJustifications: Array<{
    text: string;
    count: number;
  }>;
}

export default function ReportsAnalyticsPage() {
  const { t, locale } = useTranslation();

  // Fetch all reports using react-firebase-hooks
  const [reportsSnapshot, reportsLoading, reportsError] = useCollection(
    query(
      collection(db, 'usersReports'),
      orderBy('time', 'desc')
    )
  );

  // Convert Firebase data to UserReport objects
  const allReports: UserReport[] = useMemo(() => {
    if (!reportsSnapshot) return [];
    
    return reportsSnapshot.docs.map(doc => ({
      id: doc.id,
      uid: doc.data().uid || '',
      time: doc.data().time || Timestamp.now(),
      reportType: doc.data().reportType || 'dataError',
      status: doc.data().status || 'pending',
      userJustification: doc.data().userJustification || '',
      adminResponse: doc.data().adminResponse || null,
    }));
  }, [reportsSnapshot]);

  // Calculate analytics data
  const analyticsData: AnalyticsData = useMemo(() => {
    const now = new Date();
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const thisWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const lastWeek = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);

    // Reports by status
    const reportsByStatus = {
      pending: allReports.filter(r => r.status === 'pending').length,
      inProgress: allReports.filter(r => r.status === 'inProgress').length,
      closed: allReports.filter(r => r.status === 'closed').length,
      finalized: allReports.filter(r => r.status === 'finalized').length,
    };

    // Recent trends
    const recentTrends = {
      thisMonth: allReports.filter(r => r.time.toDate() >= thisMonth).length,
      lastMonth: allReports.filter(r => {
        const date = r.time.toDate();
        return date >= lastMonth && date < thisMonth;
      }).length,
      thisWeek: allReports.filter(r => r.time.toDate() >= thisWeek).length,
      lastWeek: allReports.filter(r => {
        const date = r.time.toDate();
        return date >= lastWeek && date < thisWeek;
      }).length,
    };

    // Response time metrics for resolved reports
    const resolvedReports = allReports.filter(r => 
      (r.status === 'closed' || r.status === 'finalized') && r.adminResponse
    );

    let responseTimeMetrics = {
      average: 0,
      median: 0,
      fastest: 0,
      slowest: 0,
    };

    if (resolvedReports.length > 0) {
      const responseTimes = resolvedReports.map(report => {
        const submitTime = report.time.toDate();
        const responseTime = new Date(); // In reality, you'd track actual response time
        return Math.abs(responseTime.getTime() - submitTime.getTime()) / (1000 * 60 * 60); // hours
      });

      responseTimes.sort((a, b) => a - b);
      
      responseTimeMetrics = {
        average: Math.round(responseTimes.reduce((sum, time) => sum + time, 0) / responseTimes.length),
        median: Math.round(responseTimes[Math.floor(responseTimes.length / 2)]),
        fastest: Math.round(responseTimes[0]),
        slowest: Math.round(responseTimes[responseTimes.length - 1]),
      };
    }

    // Common justifications (simplified analysis)
    const justificationWords = allReports
      .map(r => r.userJustification.toLowerCase())
      .join(' ')
      .split(/\s+/)
      .filter(word => word.length > 3);

    const wordCounts: { [key: string]: number } = {};
    justificationWords.forEach(word => {
      wordCounts[word] = (wordCounts[word] || 0) + 1;
    });

    const commonJustifications = Object.entries(wordCounts)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10)
      .map(([text, count]) => ({ text, count }));

    return {
      totalReports: allReports.length,
      reportsByStatus,
      recentTrends,
      responseTimeMetrics,
      commonJustifications,
    };
  }, [allReports]);

  const calculateTrendPercentage = (current: number, previous: number): { percentage: number; trending: 'up' | 'down' | 'neutral' } => {
    if (previous === 0) return { percentage: current > 0 ? 100 : 0, trending: current > 0 ? 'up' : 'neutral' };
    
    const percentage = Math.round(((current - previous) / previous) * 100);
    return {
      percentage: Math.abs(percentage),
      trending: percentage > 0 ? 'up' : percentage < 0 ? 'down' : 'neutral'
    };
  };

  const monthTrend = calculateTrendPercentage(analyticsData.recentTrends.thisMonth, analyticsData.recentTrends.lastMonth);
  const weekTrend = calculateTrendPercentage(analyticsData.recentTrends.thisWeek, analyticsData.recentTrends.lastWeek);

  const headerDictionary = {
    documents: t('appSidebar.reports') || 'Reports',
  };

  if (reportsError) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex flex-1 flex-col">
          <div className="@container/main flex flex-1 flex-col gap-2">
            <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
              <div className="text-center py-8">
                <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
                <h1 className="text-2xl font-bold">Failed to load analytics</h1>
                <p className="text-muted-foreground mt-2">{reportsError.message}</p>
              </div>
            </div>
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
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
            {/* Header */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <Button variant="outline" size="sm" asChild>
                  <Link href={`/${locale}/user-management/reports`}>
                    <ArrowLeft className="h-4 w-4 mr-2" />
                    {t('common.back') || 'Back'}
                  </Link>
                </Button>
                <div>
                  <h1 className="text-3xl font-bold tracking-tight">
                    {t('modules.userManagement.reports.analytics.title') || 'Reports Analytics'}
                  </h1>
                  <p className="text-muted-foreground">
                    {t('modules.userManagement.reports.analytics.description') || 'Overview of user reports and response metrics'}
                  </p>
                </div>
              </div>
            </div>

            {reportsLoading ? (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                {[...Array(8)].map((_, i) => (
                  <Skeleton key={i} className="h-32 w-full" />
                ))}
              </div>
            ) : (
              <>
                {/* Overview Stats */}
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.reports.totalReports') || 'Total Reports'}
                      </CardTitle>
                      <FileText className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{analyticsData.totalReports}</div>
                      <p className="text-xs text-muted-foreground">All time</p>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.reports.analytics.thisMonth') || 'This Month'}
                      </CardTitle>
                      {monthTrend.trending === 'up' ? (
                        <TrendingUp className="h-4 w-4 text-green-600" />
                      ) : monthTrend.trending === 'down' ? (
                        <TrendingDown className="h-4 w-4 text-red-600" />
                      ) : (
                        <BarChart3 className="h-4 w-4 text-muted-foreground" />
                      )}
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{analyticsData.recentTrends.thisMonth}</div>
                      <p className={`text-xs ${monthTrend.trending === 'up' ? 'text-green-600' : monthTrend.trending === 'down' ? 'text-red-600' : 'text-muted-foreground'}`}>
                        {monthTrend.trending !== 'neutral' && `${monthTrend.percentage}% from last month`}
                      </p>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.reports.pendingReports') || 'Pending Reports'}
                      </CardTitle>
                      <Clock className="h-4 w-4 text-yellow-600" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{analyticsData.reportsByStatus.pending}</div>
                      <p className="text-xs text-muted-foreground">Require attention</p>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        {t('modules.userManagement.reports.averageResponseTime') || 'Average Response'}
                      </CardTitle>
                      <Timer className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">
                        {analyticsData.responseTimeMetrics.average}{' '}
                        <span className="text-sm font-normal text-muted-foreground">
                          {t('modules.userManagement.reports.analytics.averageResponseHours') || 'hours'}
                        </span>
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {t('modules.userManagement.reports.analytics.responseTimeTarget') || 'Target: 24 hours'}
                      </p>
                    </CardContent>
                  </Card>
                </div>

                {/* Status Distribution */}
                <div className="grid gap-6 md:grid-cols-2">
                  <Card>
                    <CardHeader>
                      <CardTitle>
                        {t('modules.userManagement.reports.analytics.reportsByStatus') || 'Reports by Status'}
                      </CardTitle>
                      <CardDescription>
                        {t('modules.userManagement.reports.analytics.statusDistribution') || 'Status distribution'}
                      </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="space-y-3">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <Badge variant="secondary" className="text-yellow-600">
                              <Clock className="h-3 w-3 mr-1" />
                              {t('modules.userManagement.reports.statusPending') || 'Pending'}
                            </Badge>
                          </div>
                          <span className="font-medium">{analyticsData.reportsByStatus.pending}</span>
                        </div>

                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <Badge variant="default" className="text-blue-600">
                              <AlertCircle className="h-3 w-3 mr-1" />
                              {t('modules.userManagement.reports.statusInProgress') || 'In Progress'}
                            </Badge>
                          </div>
                          <span className="font-medium">{analyticsData.reportsByStatus.inProgress}</span>
                        </div>

                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <Badge variant="outline" className="text-green-600">
                              <CheckCircle className="h-3 w-3 mr-1" />
                              {t('modules.userManagement.reports.statusClosed') || 'Closed'}
                            </Badge>
                          </div>
                          <span className="font-medium">{analyticsData.reportsByStatus.closed}</span>
                        </div>

                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <Badge variant="default" className="text-gray-600">
                              <CheckCircle className="h-3 w-3 mr-1" />
                              {t('modules.userManagement.reports.statusFinalized') || 'Finalized'}
                            </Badge>
                          </div>
                          <span className="font-medium">{analyticsData.reportsByStatus.finalized}</span>
                        </div>
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader>
                      <CardTitle>
                        {t('modules.userManagement.reports.analytics.responseTimeMetrics') || 'Response Time Metrics'}
                      </CardTitle>
                      <CardDescription>
                        For resolved reports only
                      </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div className="text-center p-4 bg-muted rounded-lg">
                          <p className="text-2xl font-bold">{analyticsData.responseTimeMetrics.average}h</p>
                          <p className="text-sm text-muted-foreground">
                            {t('modules.userManagement.reports.averageResponseTime') || 'Average'}
                          </p>
                        </div>

                        <div className="text-center p-4 bg-muted rounded-lg">
                          <p className="text-2xl font-bold">{analyticsData.responseTimeMetrics.median}h</p>
                          <p className="text-sm text-muted-foreground">
                            {t('modules.userManagement.reports.analytics.medianResponseTime') || 'Median'}
                          </p>
                        </div>

                        <div className="text-center p-4 bg-muted rounded-lg">
                          <p className="text-2xl font-bold">{analyticsData.responseTimeMetrics.fastest}h</p>
                          <p className="text-sm text-muted-foreground">
                            {t('modules.userManagement.reports.analytics.fastestResponse') || 'Fastest'}
                          </p>
                        </div>

                        <div className="text-center p-4 bg-muted rounded-lg">
                          <p className="text-2xl font-bold">{analyticsData.responseTimeMetrics.slowest}h</p>
                          <p className="text-sm text-muted-foreground">
                            {t('modules.userManagement.reports.analytics.slowestResponse') || 'Slowest'}
                          </p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </div>

                {/* Recent Trends */}
                <Card>
                  <CardHeader>
                    <CardTitle>
                      {t('modules.userManagement.reports.analytics.reportsTrends') || 'Reports Trends'}
                    </CardTitle>
                    <CardDescription>
                      {t('modules.userManagement.reports.analytics.trendsChart') || 'Trends over time'}
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                      <div className="text-center p-4 bg-muted rounded-lg">
                        <p className="text-xl font-bold">{analyticsData.recentTrends.thisWeek}</p>
                        <p className="text-sm text-muted-foreground">
                          {t('modules.userManagement.reports.analytics.last7Days') || 'Last 7 days'}
                        </p>
                        {weekTrend.trending !== 'neutral' && (
                          <p className={`text-xs ${weekTrend.trending === 'up' ? 'text-green-600' : 'text-red-600'}`}>
                            {weekTrend.trending === 'up' ? '↗' : '↘'} {weekTrend.percentage}%
                          </p>
                        )}
                      </div>

                      <div className="text-center p-4 bg-muted rounded-lg">
                        <p className="text-xl font-bold">{analyticsData.recentTrends.lastWeek}</p>
                        <p className="text-sm text-muted-foreground">Previous week</p>
                      </div>

                      <div className="text-center p-4 bg-muted rounded-lg">
                        <p className="text-xl font-bold">{analyticsData.recentTrends.thisMonth}</p>
                        <p className="text-sm text-muted-foreground">
                          {t('modules.userManagement.reports.analytics.thisMonth') || 'This month'}
                        </p>
                        {monthTrend.trending !== 'neutral' && (
                          <p className={`text-xs ${monthTrend.trending === 'up' ? 'text-green-600' : 'text-red-600'}`}>
                            {monthTrend.trending === 'up' ? '↗' : '↘'} {monthTrend.percentage}%
                          </p>
                        )}
                      </div>

                      <div className="text-center p-4 bg-muted rounded-lg">
                        <p className="text-xl font-bold">{analyticsData.recentTrends.lastMonth}</p>
                        <p className="text-sm text-muted-foreground">
                          {t('modules.userManagement.reports.analytics.previousMonth') || 'Previous month'}
                        </p>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* Common Justifications */}
                <Card>
                  <CardHeader>
                    <CardTitle>
                      {t('modules.userManagement.reports.analytics.commonJustifications') || 'Common User Justifications'}
                    </CardTitle>
                    <CardDescription>
                      Most frequently mentioned words in user justifications
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    {analyticsData.commonJustifications.length > 0 ? (
                      <div className="space-y-2">
                        {analyticsData.commonJustifications.map((item, index) => (
                          <div key={index} className="flex items-center justify-between p-2 bg-muted rounded">
                            <span className="text-sm font-medium">{item.text}</span>
                            <Badge variant="outline">{item.count} mentions</Badge>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="text-muted-foreground text-center py-4">
                        No data available
                      </p>
                    )}
                  </CardContent>
                </Card>
              </>
            )}
          </div>
        </div>
      </div>
    </>
  );
} 