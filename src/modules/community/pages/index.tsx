'use client';

import React from 'react';
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  MessageSquare,
  Users2,
  Mail,
  TrendingUp,
  Calendar,
  AlertCircle,
  ArrowRight,
} from 'lucide-react';

interface CommunityPageProps {
  t: (key: string) => string;
  locale: string;
}

export default function CommunityPage({ t, locale }: CommunityPageProps) {
  // Mock data for demonstration
  const communityStats = {
    totalPosts: 1247,
    totalGroups: 89,
    activeGroups: 67,
    directMessages: 2341,
    newPostsToday: 23,
    reportedContent: 3,
  };

  const recentActivity = [
    {
      id: 1,
      type: 'forum',
      title: 'New discussion: Mental Health Resources',
      author: 'Ahmad Al-Rashid',
      time: '2 hours ago',
      status: 'active',
    },
    {
      id: 2,
      type: 'group',
      title: 'Recovery Support Group created',
      author: 'Sarah Al-Mahmoud',
      time: '4 hours ago',
      status: 'active',
    },
    {
      id: 3,
      type: 'report',
      title: 'Content reported for review',
      author: 'System',
      time: '6 hours ago',
      status: 'pending',
    },
  ];

  const quickActions = [
    {
      title: t('modules.community.forum'),
      description: t('modules.community.forumDescription'),
      icon: MessageSquare,
      href: `/${locale}/community/forum`,
      stats: `${communityStats.totalPosts} posts`,
      badge: communityStats.newPostsToday > 0 ? `+${communityStats.newPostsToday}` : null,
    },
    {
      title: t('modules.community.groups'),
      description: t('modules.community.groupsDescription'),
      icon: Users2,
      href: `/${locale}/community/groups`,
      stats: `${communityStats.totalGroups} groups`,
      badge: communityStats.reportedContent > 0 ? `${communityStats.reportedContent} reports` : null,
    },
    {
      title: t('modules.community.messages'),
      description: t('modules.community.messagesDescription'),
      icon: Mail,
      href: `/${locale}/community/messages`,
      stats: `${communityStats.directMessages} messages`,
      badge: null,
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{t('modules.community.title')}</h1>
          <p className="text-muted-foreground">
            {t('modules.community.description')}
          </p>
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{t('modules.community.totalPosts')}</CardTitle>
            <MessageSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{communityStats.totalPosts.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-green-600">+{communityStats.newPostsToday}</span> {t('modules.community.today')}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{t('modules.community.activeGroups')}</CardTitle>
            <Users2 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{communityStats.activeGroups}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.ofTotalGroups').replace('{total}', communityStats.totalGroups.toString())}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{t('modules.community.directMessages')}</CardTitle>
            <Mail className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{communityStats.directMessages.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              <TrendingUp className="h-3 w-3 inline mr-1" />
              12% {t('modules.community.fromLastWeek')}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{t('modules.community.reportsPending')}</CardTitle>
            <AlertCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">{communityStats.reportedContent}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.requiresReview')}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {quickActions.map((action) => (
          <Card key={action.title} className="relative overflow-hidden">
            <CardHeader>
              <div className="flex items-center justify-between">
                <action.icon className="h-8 w-8 text-primary" />
                {action.badge && (
                  <Badge variant={action.badge.includes('report') ? 'destructive' : 'secondary'}>
                    {action.badge}
                  </Badge>
                )}
              </div>
              <CardTitle className="text-xl">{action.title}</CardTitle>
              <CardDescription>{action.description}</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center justify-between">
                <p className="text-sm text-muted-foreground">{action.stats}</p>
                <Button asChild size="sm">
                  <Link href={action.href}>
                    {t('modules.content.manage')}
                    <ArrowRight className="h-4 w-4 ml-2" />
                  </Link>
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Recent Activity */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.recentActivity')}</CardTitle>
          <CardDescription>{t('modules.community.recentActivityDescription')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {recentActivity.map((activity) => (
              <div key={activity.id} className="flex items-center space-x-4 border-b pb-4 last:border-b-0">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-muted">
                  {activity.type === 'forum' && <MessageSquare className="h-5 w-5" />}
                  {activity.type === 'group' && <Users2 className="h-5 w-5" />}
                  {activity.type === 'report' && <AlertCircle className="h-5 w-5 text-orange-600" />}
                </div>
                <div className="flex-1 space-y-1">
                  <p className="text-sm font-medium">{activity.title}</p>
                  <div className="flex items-center space-x-2 text-xs text-muted-foreground">
                    <span>by {activity.author}</span>
                    <span>•</span>
                    <span>{activity.time}</span>
                  </div>
                </div>
                <Badge variant={activity.status === 'pending' ? 'destructive' : 'secondary'}>
                  {activity.status}
                </Badge>
              </div>
            ))}
          </div>
          <div className="mt-6 text-center">
            <Button variant="outline">
              {t('modules.community.viewAllActivity')}
              <ArrowRight className="h-4 w-4 ml-2" />
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
} 