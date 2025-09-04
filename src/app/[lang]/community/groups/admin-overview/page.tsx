'use client';

import { useState, useMemo } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { SiteHeader } from '@/components/site-header';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ContentActivityChart } from '@/components/admin-content-activity-chart';
import { SystemHealthChart } from '@/components/admin-system-health-chart';


import { 
  Users, 
  MessageSquare, 
  Settings, 
  Shield,
  AlertTriangle
} from 'lucide-react';


export default function SystemAdminOverviewPage() {
  const params = useParams();
  const lang = params.lang as string;
  const { t } = useTranslation();
  // Fetch all groups for system admin overview
  const [groupsSnapshot, groupsLoading] = useCollection(
    query(collection(db, 'groups'), orderBy('createdAt', 'desc'))
  );

  // Fetch all memberships for stats
  const [membershipsSnapshot] = useCollection(
    collection(db, 'group_memberships')
  );

  // Fetch all messages for stats
  const [messagesSnapshot] = useCollection(
    collection(db, 'group_messages')
  );

  // Fetch all reports for stats
  const [reportsSnapshot] = useCollection(
    collection(db, 'usersReports')
  );

  const groups = useMemo(() => {
    if (!groupsSnapshot) return [];
    return groupsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    }));
  }, [groupsSnapshot]);

  const memberships = useMemo(() => {
    if (!membershipsSnapshot) return [];
    return membershipsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  }, [membershipsSnapshot]);

  const messages = useMemo(() => {
    if (!messagesSnapshot) return [];
    return messagesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    }));
  }, [messagesSnapshot]);

  const reports = useMemo(() => {
    if (!reportsSnapshot) return [];
    return reportsSnapshot.docs.filter(doc => 
      doc.data().relatedContent?.type?.startsWith('group_')
    ).map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  }, [reportsSnapshot]);

  // Calculate comprehensive stats
  const stats = useMemo(() => {
    const totalGroups = groups.length;
    const activeGroups = groups.filter(g => g.isActive).length;
    const totalMembers = memberships.filter(m => m.isActive).length;
    const admins = memberships.filter(m => m.role === 'admin' && m.isActive).length;
    const totalMessages = messages.length;
    const pendingMessages = messages.filter(m => m.moderation?.status === 'pending').length;
    const openReports = reports.filter(r => r.status === 'open').length;
    const totalReports = reports.length;

    return {
      totalGroups,
      activeGroups,
      totalMembers,
      admins,
      totalMessages,
      pendingMessages,
      openReports,
      totalReports,
    };
  }, [groups, memberships, messages, reports]);

  const quickActions = [
    {
      title: t('modules.admin.actions.manageMembers'),
      description: t('modules.admin.actions.manageMembersDesc'),
      icon: Users,
      href: `/${lang}/community/groups/admin-members`,
    },
    {
      title: t('modules.admin.actions.moderateContent'),
      description: t('modules.admin.actions.moderateContentDesc'),
      icon: MessageSquare,
      href: `/${lang}/community/groups/admin-content`,
    },
    {
      title: t('modules.admin.actions.manageReports'),
      description: t('modules.admin.actions.manageReportsDesc'),
      icon: Shield,
      href: `/${lang}/community/groups/admin-reports`,
    },
    {
      title: t('modules.admin.actions.groupSettings'),
      description: t('modules.admin.actions.groupSettingsDesc'),
      icon: Settings,
      href: `/${lang}/community/groups/admin-settings`,
    },
  ];

  if (groupsLoading) {
    return (
      <div className="h-full flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <div className="h-8 w-48 bg-muted rounded animate-pulse mb-2" />
            <div className="h-4 w-64 bg-muted rounded animate-pulse" />
          </div>
        </div>
        <div className="flex-1 overflow-auto">
          <div className="p-6 space-y-6">
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              {[...Array(4)].map((_, i) => (
                <Card key={i}>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <div className="h-4 w-24 bg-muted rounded animate-pulse" />
                    <div className="h-4 w-4 bg-muted rounded animate-pulse" />
                  </CardHeader>
                  <CardContent>
                    <div className="h-8 w-16 bg-muted rounded animate-pulse mb-2" />
                    <div className="h-3 w-20 bg-muted rounded animate-pulse" />
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  const headerDictionary = {
    documents: t('modules.admin.systemAdmin.title') || 'System Administration',
  };

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">
              {t('modules.admin.systemAdmin.title')}
            </h1>
            <p className="text-muted-foreground">
              {t('modules.admin.systemAdmin.description')}
            </p>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto">
        <div className="p-6 space-y-6 max-w-none">
          {/* Stats Cards */}
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('modules.admin.stats.totalGroups')}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.totalGroups}</div>
                <p className="text-xs text-muted-foreground">
                  {stats.activeGroups} active
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('modules.admin.stats.totalMembers')}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.totalMembers}</div>
                <p className="text-xs text-muted-foreground">
                  {stats.admins} admins
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('modules.admin.stats.totalMessages')}
                </CardTitle>
                <MessageSquare className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.totalMessages}</div>
                <p className="text-xs text-muted-foreground">
                  {stats.pendingMessages} pending review
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('modules.admin.stats.openReports')}
                </CardTitle>
                <AlertTriangle className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.openReports}</div>
                <p className="text-xs text-muted-foreground">
                  {stats.totalReports} total reports
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle>{t('modules.admin.dashboard.quickActions')}</CardTitle>
              <CardDescription>
                {t('modules.admin.systemAdmin.quickActionsDesc')}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {quickActions.map((action) => {
                  const Icon = action.icon;
                  return (
                    <Button
                      key={action.href}
                      variant="outline"
                      className="h-auto p-4 justify-start"
                      onClick={() => window.location.href = action.href}
                    >
                      <div className="flex items-start gap-3 w-full">
                        <Icon className="h-5 w-5 mt-0.5 flex-shrink-0" />
                        <div className="flex-1 text-left">
                            <span className="font-medium">{action.title}</span>
                          <p className="text-sm text-muted-foreground mt-1">
                            {action.description}
                          </p>
                        </div>
                      </div>
                    </Button>
                  );
                })}
              </div>
            </CardContent>
          </Card>

          {/* Admin Analytics Charts */}
          <div className="grid gap-6 lg:grid-cols-2">
            <ContentActivityChart 
              messages={messages} 
              reports={reports} 
              t={t} 
            />
            <SystemHealthChart 
              groups={groups} 
              messages={messages} 
              t={t} 
            />
          </div>
        </div>
        </div>
      </div>
    </div>
  );
}
