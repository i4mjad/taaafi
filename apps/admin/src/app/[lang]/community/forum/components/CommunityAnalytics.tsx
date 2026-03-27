'use client';

import { useState, useMemo, useEffect, useCallback } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { collection, query, orderBy, where, getDocs, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { BarChart, Users, MessageSquare, ThumbsUp, TrendingUp, Download, RefreshCw } from 'lucide-react';
import { format, subDays, startOfDay } from 'date-fns';
import { ForumPost, Comment, Interaction, CommunityProfile } from '@/types/community';
import { toast } from 'sonner';

interface AnalyticsData {
  posts: ForumPost[];
  comments: Comment[];
  interactions: Interaction[];
  profiles: CommunityProfile[];
  allProfiles: CommunityProfile[];
  categories: { id: string; name: string; nameAr: string }[];
}

export default function CommunityAnalytics() {
  const { t } = useTranslation();
  const [dateRange, setDateRange] = useState<string>('7');
  const [isLoading, setIsLoading] = useState(true);
  const [data, setData] = useState<AnalyticsData>({
    posts: [],
    comments: [],
    interactions: [],
    profiles: [],
    allProfiles: [],
    categories: [],
  });

  const fetchData = useCallback(async () => {
    setIsLoading(true);
    try {
      const days = parseInt(dateRange);
      const startDate = startOfDay(subDays(new Date(), days));
      const startTimestamp = Timestamp.fromDate(startDate);

      const [postsSnap, commentsSnap, interactionsSnap, profilesSnap, allProfilesSnap, categoriesSnap] =
        await Promise.all([
          getDocs(query(collection(db, 'forumPosts'), where('createdAt', '>=', startTimestamp), orderBy('createdAt', 'desc'))),
          getDocs(query(collection(db, 'comments'), where('createdAt', '>=', startTimestamp), orderBy('createdAt', 'desc'))),
          getDocs(query(collection(db, 'interactions'), where('createdAt', '>=', startTimestamp), orderBy('createdAt', 'desc'))),
          getDocs(query(collection(db, 'communityProfiles'), where('createdAt', '>=', startTimestamp), orderBy('createdAt', 'desc'))),
          getDocs(query(collection(db, 'communityProfiles'), orderBy('createdAt', 'desc'))),
          getDocs(query(collection(db, 'postCategories'), orderBy('sortOrder'))),
        ]);

      setData({
        posts: postsSnap.docs.map(doc => ({ id: doc.id, ...doc.data(), createdAt: doc.data().createdAt?.toDate() || new Date() })) as ForumPost[],
        comments: commentsSnap.docs.map(doc => ({ id: doc.id, ...doc.data(), createdAt: doc.data().createdAt?.toDate() || new Date() })) as Comment[],
        interactions: interactionsSnap.docs.map(doc => ({ id: doc.id, ...doc.data(), createdAt: doc.data().createdAt?.toDate() || new Date() })) as Interaction[],
        profiles: profilesSnap.docs.map(doc => ({ id: doc.id, ...doc.data(), createdAt: doc.data().createdAt?.toDate() || new Date() })) as CommunityProfile[],
        allProfiles: allProfilesSnap.docs.map(doc => ({ id: doc.id, ...doc.data(), createdAt: doc.data().createdAt?.toDate() || new Date() })) as CommunityProfile[],
        categories: categoriesSnap.docs.map(doc => ({ id: doc.id, name: doc.data().name || 'Unknown', nameAr: doc.data().nameAr || 'غير معروف', ...doc.data() })),
      });
    } catch (error) {
      console.error('Error fetching analytics:', error);
      toast.error('Failed to load analytics data');
    } finally {
      setIsLoading(false);
    }
  }, [dateRange]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const { posts, comments, interactions, profiles, allProfiles, categories } = data;

  // filteredData alias kept for useMemo below
  const filteredData = useMemo(() => ({
    filteredPosts: posts,
    filteredComments: comments,
    filteredInteractions: interactions,
    filteredProfiles: profiles,
  }), [posts, comments, interactions, profiles]);

  // Calculate analytics
  const analytics = useMemo(() => {
    const { filteredPosts, filteredComments, filteredInteractions, filteredProfiles } = filteredData;

    // Overall metrics
    const totalPosts = filteredPosts.length;
    const totalComments = filteredComments.length;
    const totalInteractions = filteredInteractions.length;
    const newProfiles = filteredProfiles.length;

    // Engagement metrics
    const likes = filteredInteractions.filter(i => i.value === 1).length;
    const dislikes = filteredInteractions.filter(i => i.value === -1).length;
    const averageCommentsPerPost = totalPosts > 0 ? totalComments / totalPosts : 0;
    const averageLikesPerPost = totalPosts > 0 ? likes / totalPosts : 0;

    // Category breakdown
    const categoryStats = categories.map(category => {
      const categoryPosts = filteredPosts.filter(post => post.category === category.id);
      return {
        id: category.id,
        name: category.name,
        nameAr: category.nameAr,
        postCount: categoryPosts.length,
        percentage: totalPosts > 0 ? (categoryPosts.length / totalPosts) * 100 : 0,
      };
    }).sort((a, b) => b.postCount - a.postCount);

    // Gender distribution (all-time, not date-filtered)
    const genderStats = {
      male: allProfiles.filter(p => p.gender === 'male').length,
      female: allProfiles.filter(p => p.gender === 'female').length,
      other: allProfiles.filter(p => p.gender === 'other').length,
    };

    // Anonymous vs identified posts
    const anonymousPosts = filteredPosts.filter(p => p.isAnonymous).length;
    const identifiedPosts = filteredPosts.filter(p => !p.isAnonymous).length;

    // Top posts by engagement
    const topPosts = filteredPosts
      .map(post => ({
        ...post,
        totalEngagement: post.likeCount + post.dislikeCount + 
          filteredComments.filter(c => c.postId === post.id).length,
      }))
      .sort((a, b) => b.totalEngagement - a.totalEngagement)
      .slice(0, 5);

    return {
      totalPosts,
      totalComments,
      totalInteractions,
      newProfiles,
      likes,
      dislikes,
      averageCommentsPerPost,
      averageLikesPerPost,
      categoryStats,
      genderStats,
      anonymousPosts,
      identifiedPosts,
      topPosts,
    };
  }, [filteredData, categories, allProfiles]);

  const handleExportData = () => {
    toast.info(t('modules.community.analytics.exportComingSoon'));
  };

  const handleRefreshData = () => {
    fetchData();
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <Card key={i}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  <div className="h-4 bg-muted rounded animate-pulse" />
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-8 bg-muted rounded animate-pulse mb-2" />
                <div className="h-3 bg-muted rounded animate-pulse" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-start">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">{t('modules.community.analytics.title')}</h2>
          <p className="text-muted-foreground">
            {t('modules.community.analytics.description')}
          </p>
        </div>
        <div className="flex items-center space-x-2">
          <Select value={dateRange} onValueChange={setDateRange}>
            <SelectTrigger className="w-[180px]">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7">{t('modules.community.analytics.last7Days')}</SelectItem>
              <SelectItem value="30">{t('modules.community.analytics.last30Days')}</SelectItem>
              <SelectItem value="90">{t('modules.community.analytics.last90Days')}</SelectItem>
              <SelectItem value="365">{t('modules.community.analytics.lastYear')}</SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" size="sm" onClick={handleRefreshData}>
            <RefreshCw className="h-4 w-4 mr-2" />
            {t('modules.community.analytics.refreshData')}
          </Button>
          <Button variant="outline" size="sm" onClick={handleExportData}>
            <Download className="h-4 w-4 mr-2" />
            {t('modules.community.analytics.exportData')}
          </Button>
        </div>
      </div>

      {/* Overview Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.analytics.totalInteractions')}
            </CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analytics.totalInteractions}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.analytics.likesDislikes', { likes: analytics.likes, dislikes: analytics.dislikes })}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.analytics.averageCommentsPerPost')}
            </CardTitle>
            <MessageSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analytics.averageCommentsPerPost.toFixed(1)}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.analytics.totalComments', { count: analytics.totalComments })}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.analytics.averageLikesPerPost')}
            </CardTitle>
            <ThumbsUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analytics.averageLikesPerPost.toFixed(1)}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.analytics.totalPosts', { count: analytics.totalPosts })}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.analytics.newUsers')}
            </CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analytics.newProfiles}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.analytics.inSelectedPeriod')}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Category Breakdown */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.analytics.mostActiveCategories')}</CardTitle>
          <CardDescription>
            {t('modules.community.analytics.postDistribution')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {analytics.categoryStats.length === 0 ? (
            <div className="text-center py-8">
              <BarChart className="mx-auto h-12 w-12 text-muted-foreground/50" />
              <h3 className="mt-4 text-lg font-semibold">{t('modules.community.analytics.noDataAvailable')}</h3>
              <p className="text-muted-foreground">{t('modules.community.analytics.noPostsFound')}</p>
            </div>
          ) : (
            <div className="space-y-4">
              {analytics.categoryStats.slice(0, 10).map((category) => (
                <div key={category.id} className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <div className="font-medium">{category.name}</div>
                    <Badge variant="outline">{t('modules.community.analytics.postsCount', { count: category.postCount })}</Badge>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="text-sm text-muted-foreground">
                      {category.percentage.toFixed(1)}%
                    </div>
                    <div className="w-20 h-2 bg-muted rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-primary rounded-full"
                        style={{ width: `${Math.min(category.percentage, 100)}%` }}
                      />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Gender Distribution */}
        <Card>
          <CardHeader>
            <CardTitle>{t('modules.community.analytics.genderDistribution')}</CardTitle>
            <CardDescription>
              {t('modules.community.analytics.genderBreakdown')}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div className="text-sm font-medium">{t('modules.community.analytics.male')}</div>
                  <Badge variant="outline">{analytics.genderStats.male}</Badge>
                </div>
                <div className="text-sm text-muted-foreground">
                  {allProfiles.length > 0
                    ? `${Math.round((analytics.genderStats.male / allProfiles.length) * 100)}%`
                    : '0%'
                  }
                </div>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div className="text-sm font-medium">{t('modules.community.analytics.female')}</div>
                  <Badge variant="outline">{analytics.genderStats.female}</Badge>
                </div>
                <div className="text-sm text-muted-foreground">
                  {allProfiles.length > 0
                    ? `${Math.round((analytics.genderStats.female / allProfiles.length) * 100)}%`
                    : '0%'
                  }
                </div>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div className="text-sm font-medium">{t('modules.community.analytics.other')}</div>
                  <Badge variant="outline">{analytics.genderStats.other}</Badge>
                </div>
                <div className="text-sm text-muted-foreground">
                  {allProfiles.length > 0
                    ? `${Math.round((analytics.genderStats.other / allProfiles.length) * 100)}%`
                    : '0%'
                  }
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Anonymous vs Identified */}
        <Card>
          <CardHeader>
            <CardTitle>{t('modules.community.analytics.anonymousVsIdentified')}</CardTitle>
            <CardDescription>
              {t('modules.community.analytics.anonymityBreakdown')}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div className="text-sm font-medium">{t('modules.community.analytics.anonymousPosts')}</div>
                  <Badge variant="secondary">{analytics.anonymousPosts}</Badge>
                </div>
                <div className="text-sm text-muted-foreground">
                  {analytics.totalPosts > 0 
                    ? `${Math.round((analytics.anonymousPosts / analytics.totalPosts) * 100)}%`
                    : '0%'
                  }
                </div>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div className="text-sm font-medium">{t('modules.community.analytics.identifiedPosts')}</div>
                  <Badge variant="default">{analytics.identifiedPosts}</Badge>
                </div>
                <div className="text-sm text-muted-foreground">
                  {analytics.totalPosts > 0 
                    ? `${Math.round((analytics.identifiedPosts / analytics.totalPosts) * 100)}%`
                    : '0%'
                  }
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Top Engaging Posts */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.analytics.topPosts')}</CardTitle>
          <CardDescription>
            {t('modules.community.analytics.mostEngagingPosts')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {analytics.topPosts.length === 0 ? (
            <div className="text-center py-8">
              <MessageSquare className="mx-auto h-12 w-12 text-muted-foreground/50" />
              <h3 className="mt-4 text-lg font-semibold">{t('modules.community.analytics.noDataAvailable')}</h3>
            </div>
          ) : (
            <div className="space-y-4">
              {analytics.topPosts.map((post, index) => (
                <div key={post.id} className="flex items-start space-x-4 p-4 border rounded-lg">
                  <div className="flex-shrink-0 w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center">
                    <span className="text-sm font-semibold text-primary">#{index + 1}</span>
                  </div>
                  <div className="flex-1">
                    <h4 className="font-medium line-clamp-1">{post.title}</h4>
                    <p className="text-sm text-muted-foreground line-clamp-2 mt-1">
                      {post.body}
                    </p>
                    <div className="flex items-center space-x-4 mt-2 text-xs text-muted-foreground">
                      <span>{format(post.createdAt, t('modules.community.analytics.dateFormat'))}</span>
                      <span>{t('modules.community.analytics.likes', { count: post.likeCount })}</span>
                      <span>{t('modules.community.analytics.dislikes', { count: post.dislikeCount })}</span>
                      <span>{t('modules.community.analytics.totalEngagement', { count: post.totalEngagement })}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Last Updated */}
      <div className="text-center text-sm text-muted-foreground">
        {t('modules.community.analytics.lastUpdated')}: {format(new Date(), t('modules.community.analytics.dateTimeFormat'))}
      </div>
    </div>
  );
} 