'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  ToggleLeft,
  ToggleRight,
  Plus,
  Search,
  MoreHorizontal,
  Edit,
  Trash2,
  Activity,
  Users,
  Shield,
  Zap,
} from 'lucide-react';

interface FeatureFlagsPageProps {
  t: (key: string) => string;
  locale: string;
}

interface FeatureFlag {
  id: string;
  name: string;
  description: string;
  enabled: boolean;
  environment: 'development' | 'staging' | 'production';
  rolloutPercentage: number;
  createdAt: Date;
  updatedAt: Date;
  owner: string;
}

export default function FeatureFlagsPage({ t, locale }: FeatureFlagsPageProps) {
  const [searchQuery, setSearchQuery] = useState('');

  // Mock data for demonstration
  const featureFlags: FeatureFlag[] = [
    {
      id: 'new_onboarding',
      name: 'New User Onboarding',
      description: 'Enhanced onboarding flow for new users with guided tutorials',
      enabled: true,
      environment: 'production',
      rolloutPercentage: 100,
      createdAt: new Date('2024-01-15T10:00:00Z'),
      updatedAt: new Date('2024-01-20T14:30:00Z'),
      owner: 'Product Team',
    },
    {
      id: 'ai_recommendations',
      name: 'AI Content Recommendations',
      description: 'AI-powered content recommendations based on user preferences',
      enabled: false,
      environment: 'staging',
      rolloutPercentage: 25,
      createdAt: new Date('2024-01-18T09:15:00Z'),
      updatedAt: new Date('2024-01-19T16:45:00Z'),
      owner: 'AI Team',
    },
    {
      id: 'group_video_calls',
      name: 'Group Video Calls',
      description: 'Enable video calling functionality for support groups',
      enabled: true,
      environment: 'development',
      rolloutPercentage: 50,
      createdAt: new Date('2024-01-20T11:30:00Z'),
      updatedAt: new Date('2024-01-20T11:30:00Z'),
      owner: 'Community Team',
    },
    {
      id: 'advanced_analytics',
      name: 'Advanced Analytics Dashboard',
      description: 'Comprehensive analytics and reporting for administrators',
      enabled: true,
      environment: 'production',
      rolloutPercentage: 100,
      createdAt: new Date('2024-01-10T08:00:00Z'),
      updatedAt: new Date('2024-01-15T12:00:00Z'),
      owner: 'Analytics Team',
    },
    {
      id: 'dark_mode',
      name: 'Dark Mode',
      description: 'Dark theme option for improved user experience',
      enabled: false,
      environment: 'development',
      rolloutPercentage: 0,
      createdAt: new Date('2024-01-12T14:20:00Z'),
      updatedAt: new Date('2024-01-18T09:45:00Z'),
      owner: 'UI Team',
    },
  ];

  const stats = {
    total: featureFlags.length,
    enabled: featureFlags.filter(f => f.enabled).length,
    production: featureFlags.filter(f => f.environment === 'production').length,
    development: featureFlags.filter(f => f.environment === 'development').length,
  };

  const handleToggleFeature = (featureId: string) => {
    // TODO: Implement feature toggle logic
    
  };

  const getEnvironmentBadge = (environment: string) => {
    const variants = {
      production: 'default',
      staging: 'secondary',
      development: 'outline',
    } as const;

    const colors = {
      production: 'text-green-600',
      staging: 'text-yellow-600',
      development: 'text-blue-600',
    } as const;

    return (
      <Badge variant={variants[environment as keyof typeof variants] || 'outline'}>
        <div className={`h-2 w-2 rounded-full mr-2 ${colors[environment as keyof typeof colors]}`} />
        {environment}
      </Badge>
    );
  };

  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  };

  const filteredFlags = featureFlags.filter(flag =>
    flag.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    flag.description.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{t('modules.features.title')}</h1>
          <p className="text-muted-foreground">
            {t('modules.features.description') || 'Manage feature flags and experimental features'}
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          {t('modules.features.createFeature')}
        </Button>
      </div>

      {/* Stats Overview */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Features</CardTitle>
            <ToggleLeft className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Enabled Features</CardTitle>
            <ToggleRight className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">{stats.enabled}</div>
            <p className="text-xs text-muted-foreground">
              {Math.round((stats.enabled / stats.total) * 100)}% of total
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Production</CardTitle>
            <Shield className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.production}</div>
            <p className="text-xs text-muted-foreground">
              Live features
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Development</CardTitle>
            <Zap className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.development}</div>
            <p className="text-xs text-muted-foreground">
              In development
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Search */}
      <Card>
        <CardHeader>
          <CardTitle>{t('common.search')}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center space-x-2">
            <Search className="h-4 w-4 text-muted-foreground" />
            <Input
              placeholder={t('modules.features.searchPlaceholder') || 'Search feature flags...'}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="flex-1"
            />
          </div>
        </CardContent>
      </Card>

      {/* Feature Flags Table */}
      <Card>
        <CardHeader>
          <CardTitle>Feature Flags</CardTitle>
          <CardDescription>
            Manage feature rollouts and experimental functionality
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Feature</TableHead>
                <TableHead>Environment</TableHead>
                <TableHead>Rollout</TableHead>
                <TableHead>Owner</TableHead>
                <TableHead>Updated</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredFlags.map((flag) => (
                <TableRow key={flag.id}>
                  <TableCell>
                    <div className="space-y-1">
                      <p className="text-sm font-medium">{flag.name}</p>
                      <p className="text-xs text-muted-foreground line-clamp-2">
                        {flag.description}
                      </p>
                    </div>
                  </TableCell>
                  <TableCell>{getEnvironmentBadge(flag.environment)}</TableCell>
                  <TableCell>
                    <div className="flex items-center space-x-2">
                      <div className="flex-1">
                        <div className="h-2 bg-muted rounded-full overflow-hidden">
                          <div
                            className="h-full bg-primary transition-all"
                            style={{ width: `${flag.rolloutPercentage}%` }}
                          />
                        </div>
                      </div>
                      <span className="text-xs text-muted-foreground">
                        {flag.rolloutPercentage}%
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center space-x-2">
                      <Users className="h-3 w-3" />
                      <span className="text-sm">{flag.owner}</span>
                    </div>
                  </TableCell>
                  <TableCell>{formatDate(flag.updatedAt)}</TableCell>
                  <TableCell>
                    <div className="flex items-center space-x-2">
                      <Switch
                        checked={flag.enabled}
                        onCheckedChange={() => handleToggleFeature(flag.id)}
                      />
                      <Badge variant={flag.enabled ? 'default' : 'secondary'}>
                        {flag.enabled ? t('modules.features.enabled') : t('modules.features.disabled')}
                      </Badge>
                    </div>
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" className="h-8 w-8 p-0">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem>
                          <Edit className="h-4 w-4 mr-2" />
                          {t('common.edit')}
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <Activity className="h-4 w-4 mr-2" />
                          View Analytics
                        </DropdownMenuItem>
                        <DropdownMenuSeparator />
                        <DropdownMenuItem className="text-red-600">
                          <Trash2 className="h-4 w-4 mr-2" />
                          {t('common.delete')}
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          {filteredFlags.length === 0 && (
            <div className="text-center py-8">
              <ToggleLeft className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-lg font-medium">{t('common.noData')}</p>
              <p className="text-muted-foreground">
                {searchQuery ? 'No features match your search' : 'No feature flags configured yet'}
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
} 