'use client';

import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { useGroup, useGroupMembers } from '@/hooks/useGroupAdmin';
import { AdminRoute } from '@/components/AdminRoute';
import { AdminLayout } from '@/components/AdminLayout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { 
  Users, 
  MessageSquare, 
  Trophy, 
  Settings, 
  UserPlus,
  AlertTriangle,
  Calendar,
  Clock
} from 'lucide-react';
import { format } from 'date-fns';

export default function GroupAdminPage() {
  const params = useParams();
  const groupId = params.groupId as string;
  const { t } = useTranslation();
  const { group, loading: groupLoading } = useGroup(groupId);
  const { members, loading: membersLoading } = useGroupMembers(groupId);

  const stats = {
    totalMembers: members.length,
    activeMembers: members.filter(m => m.isActive).length,
    admins: members.filter(m => m.role === 'admin').length,
    totalPoints: members.reduce((sum, m) => sum + (m.pointsTotal || 0), 0),
  };

  const recentMembers = members
    .sort((a, b) => new Date(b.joinedAt).getTime() - new Date(a.joinedAt).getTime())
    .slice(0, 5);

  const quickActions = [
    {
      title: t('admin.actions.manageMembers'),
      description: t('admin.actions.manageMembersDesc'),
      icon: Users,
      href: `/community/groups/${groupId}/admin/members`,
      badge: stats.totalMembers,
    },
    {
      title: t('admin.actions.moderateContent'),
      description: t('admin.actions.moderateContentDesc'),
      icon: MessageSquare,
      href: `/community/groups/${groupId}/admin/content`,
      // badge: reportedCount, // TODO: Add reported content count
    },
    {
      title: t('admin.actions.manageChallenges'),
      description: t('admin.actions.manageChallengesDesc'),
      icon: Trophy,
      href: `/community/groups/${groupId}/admin/challenges`,
    },
    {
      title: t('admin.actions.groupSettings'),
      description: t('admin.actions.groupSettingsDesc'),
      icon: Settings,
      href: `/community/groups/${groupId}/admin/settings`,
    },
  ];

  return (
    <AdminRoute groupId={groupId}>
      <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin`}>
        <div className="space-y-6">
          {/* Header */}
          <div>
            <h1 className="text-2xl lg:text-3xl font-bold tracking-tight">
              {t('admin.dashboard.title')}
            </h1>
            <p className="text-muted-foreground mt-1">
              {t('admin.dashboard.description')}
            </p>
          </div>

          {/* Group Info Card */}
          {group && (
            <Card>
              <CardHeader>
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  <div>
                    <CardTitle className="text-xl">{group.name}</CardTitle>
                    <CardDescription className="mt-1">
                      {group.description}
                    </CardDescription>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Badge variant={group.isActive ? 'default' : 'secondary'}>
                      {group.isActive ? t('common.active') : t('common.inactive')}
                    </Badge>
                    <Badge variant="outline">
                      {t('admin.dashboard.capacity', { 
                        current: stats.totalMembers, 
                        max: group.capacity 
                      })}
                    </Badge>
                    <Badge variant="outline">
                      {group.gender}
                    </Badge>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4 text-muted-foreground" />
                    <span className="text-muted-foreground">
                      {t('admin.dashboard.created')}
                    </span>
                    <span>{format(group.createdAt, 'MMM dd, yyyy')}</span>
                  </div>
                  {group.updatedAt && (
                    <div className="flex items-center gap-2">
                      <Clock className="h-4 w-4 text-muted-foreground" />
                      <span className="text-muted-foreground">
                        {t('admin.dashboard.updated')}
                      </span>
                      <span>{format(group.updatedAt, 'MMM dd, yyyy')}</span>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Stats Cards */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.stats.totalMembers')}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.totalMembers}</div>
                <p className="text-xs text-muted-foreground">
                  {stats.admins} {t('admin.stats.admins')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.stats.totalPoints')}
                </CardTitle>
                <Trophy className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.totalPoints}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.stats.fromChallenges')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.stats.capacity')}
                </CardTitle>
                <UserPlus className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {group && group.capacity > 0 ? Math.round((stats.totalMembers / group.capacity) * 100) : 0}%
                </div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.stats.capacityUsed')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.stats.pendingActions')}
                </CardTitle>
                <AlertTriangle className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">0</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.stats.requiresAttention')}
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Quick Actions */}
          <Card>
            <CardHeader>
              <CardTitle>{t('admin.dashboard.quickActions')}</CardTitle>
              <CardDescription>
                {t('admin.dashboard.quickActionsDesc')}
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
                          <div className="flex items-center gap-2">
                            <span className="font-medium">{action.title}</span>
                            {action.badge && (
                              <Badge variant="secondary" className="text-xs">
                                {action.badge}
                              </Badge>
                            )}
                          </div>
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

          {/* Recent Members */}
          {recentMembers.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>{t('admin.dashboard.recentMembers')}</CardTitle>
                <CardDescription>
                  {t('admin.dashboard.recentMembersDesc')}
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {recentMembers.map((member) => (
                    <div key={member.id} className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center">
                          <Users className="h-4 w-4" />
                        </div>
                        <div>
                          <p className="font-medium text-sm">{member.cpId}</p>
                          <p className="text-xs text-muted-foreground">
                            {t('admin.dashboard.joined')} {format(member.joinedAt, 'MMM dd')}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant={member.role === 'admin' ? 'default' : 'secondary'} className="text-xs">
                          {member.role}
                        </Badge>
                        <span className="text-sm text-muted-foreground">
                          {member.pointsTotal || 0} pts
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </AdminLayout>
    </AdminRoute>
  );
}
