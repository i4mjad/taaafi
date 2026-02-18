'use client';

import React from 'react';
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  FileText,
  FolderOpen,
  Tag,
  List,
  TrendingUp,
  Clock,
  Users,
  ArrowRight,
  Plus,
} from 'lucide-react';

interface ContentPageProps {
  t: (key: string) => string;
  locale: string;
}

export default function ContentPage({ t, locale }: ContentPageProps) {
  // Mock data for demonstration
  const contentStats = {
    totalContent: 2456,
    contentTypes: 12,
    categories: 45,
    contentOwners: 67,
    contentLists: 23,
    publishedToday: 18,
    draftContent: 156,
    pendingReview: 12,
  };

  const recentContent = [
    {
      id: 1,
      title: 'Understanding Addiction Recovery',
      type: 'Article',
      category: 'Education',
      owner: 'Dr. Ahmad Khalil',
      status: 'published',
      publishedAt: '2 hours ago',
    },
    {
      id: 2,
      title: 'Meditation Guide for Recovery',
      type: 'Video',
      category: 'Wellness',
      owner: 'Sarah Al-Mahmoud',
      status: 'draft',
      publishedAt: 'Draft',
    },
    {
      id: 3,
      title: 'Support Group Directory',
      type: 'Resource',
      category: 'Community',
      owner: 'Ta\'aafi Team',
      status: 'pending',
      publishedAt: 'Pending Review',
    },
  ];

  const contentModules = [
    {
      title: t('sidebar.contentTypes'),
      description: t('modules.content.typesDescription'),
      icon: FileText,
      href: `/${locale}/content/types`,
      stats: `${contentStats.contentTypes} types`,
      color: 'text-blue-600',
    },
    {
      title: t('sidebar.contentOwners'),
      description: t('modules.content.ownersDescription'),
      icon: Users,
      href: `/${locale}/content/owners`,
      stats: `${contentStats.contentOwners} owners`,
      color: 'text-green-600',
    },
    {
      title: t('sidebar.categories'),
      description: t('modules.content.categoriesDescription'),
      icon: Tag,
      href: `/${locale}/content/categories`,
      stats: `${contentStats.categories} categories`,
      color: 'text-purple-600',
    },
    {
      title: t('sidebar.contentItems'),
      description: t('modules.content.itemsDescription'),
      icon: FileText,
      href: `/${locale}/content`,
      stats: `${contentStats.totalContent} items`,
      color: 'text-orange-600',
    },
    {
      title: t('sidebar.contentLists'),
      description: t('modules.content.listsDescription'),
      icon: List,
      href: `/${locale}/content/lists`,
      stats: `${contentStats.contentLists} lists`,
      color: 'text-red-600',
    },
  ];

  const getStatusBadge = (status: string) => {
    const variants = {
      published: 'default',
      draft: 'secondary',
      pending: 'destructive',
    } as const;

    return (
      <Badge variant={variants[status as keyof typeof variants] || 'secondary'}>
        {status}
      </Badge>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{t('modules.content.title')}</h1>
          <p className="text-muted-foreground">
            {t('modules.content.description')}
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          {t('modules.content.createContent')}
        </Button>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{t('modules.content.totalContent')}</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{contentStats.totalContent.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              <span className="text-green-600">+{contentStats.publishedToday}</span> {t('modules.content.publishedToday')}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{t('modules.content.draftContent')}</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{contentStats.draftContent}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.content.readyForReview')}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{t('modules.content.contentTypes')}</CardTitle>
            <FolderOpen className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{contentStats.contentTypes}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.content.activeContentTypes')}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{t('modules.content.pendingReview')}</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">{contentStats.pendingReview}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.content.awaitingApproval')}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Content Modules */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {contentModules.map((module) => (
          <Card key={module.title} className="relative overflow-hidden hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="flex items-center justify-between">
                <module.icon className={`h-8 w-8 ${module.color}`} />
              </div>
              <CardTitle className="text-xl">{module.title}</CardTitle>
              <CardDescription>{module.description}</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-center justify-between">
                <p className="text-sm text-muted-foreground">{module.stats}</p>
                <Button asChild size="sm">
                  <Link href={module.href}>
                    {t('modules.content.manage')}
                    <ArrowRight className="h-4 w-4 ml-2" />
                  </Link>
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Recent Content */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.content.recentContent')}</CardTitle>
          <CardDescription>{t('modules.content.recentContentDescription')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {recentContent.map((content) => (
              <div key={content.id} className="flex items-center space-x-4 border-b pb-4 last:border-b-0">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-muted">
                  <FileText className="h-5 w-5" />
                </div>
                <div className="flex-1 space-y-1">
                  <p className="text-sm font-medium">{content.title}</p>
                  <div className="flex items-center space-x-2 text-xs text-muted-foreground">
                    <span>{content.type}</span>
                    <span>•</span>
                    <span>{content.category}</span>
                    <span>•</span>
                    <span>by {content.owner}</span>
                  </div>
                </div>
                <div className="text-xs text-muted-foreground">
                  {content.publishedAt}
                </div>
                {getStatusBadge(content.status)}
              </div>
            ))}
          </div>
          <div className="mt-6 text-center">
            <Button variant="outline" asChild>
              <Link href={`/${locale}/content`}>
                {t('modules.content.viewAllContent')}
                <ArrowRight className="h-4 w-4 ml-2" />
              </Link>
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
} 