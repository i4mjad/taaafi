'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { UserPlus, CheckCircle, Gift, XCircle } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { useTranslation } from '@/contexts/TranslationContext';

interface ActivityItem {
  id: string;
  type: 'signup' | 'verified' | 'reward' | 'blocked';
  message: string;
  timestamp: Date | string;
  userId?: string;
}

interface RecentActivityProps {
  activities: ActivityItem[];
}

function getActivityIcon(type: ActivityItem['type']) {
  switch (type) {
    case 'signup':
      return <UserPlus className="h-4 w-4" />;
    case 'verified':
      return <CheckCircle className="h-4 w-4" />;
    case 'reward':
      return <Gift className="h-4 w-4" />;
    case 'blocked':
      return <XCircle className="h-4 w-4" />;
    default:
      return null;
  }
}

function getActivityColor(type: ActivityItem['type']) {
  switch (type) {
    case 'signup':
      return 'bg-blue-100 text-blue-600 dark:bg-blue-900 dark:text-blue-300';
    case 'verified':
      return 'bg-green-100 text-green-600 dark:bg-green-900 dark:text-green-300';
    case 'reward':
      return 'bg-purple-100 text-purple-600 dark:bg-purple-900 dark:text-purple-300';
    case 'blocked':
      return 'bg-red-100 text-red-600 dark:bg-red-900 dark:text-red-300';
    default:
      return 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300';
  }
}

export function RecentActivity({ activities }: RecentActivityProps) {
  const { t } = useTranslation();

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t('modules.userManagement.referralDashboard.recentActivity.title')}</CardTitle>
        <CardDescription>
          {t('modules.userManagement.referralDashboard.recentActivity.description')}
        </CardDescription>
      </CardHeader>
      <CardContent className="px-3 sm:px-6">
        <div className="space-y-3">
          {activities.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-8">
              {t('modules.userManagement.referralDashboard.recentActivity.noActivity')}
            </p>
          ) : (
            activities.map((activity) => (
              <div key={activity.id} className="flex items-start gap-3 pb-3 border-b last:border-0 last:pb-0">
                <div className={`p-2 rounded-lg flex-shrink-0 ${getActivityColor(activity.type)}`}>
                  {getActivityIcon(activity.type)}
                </div>
                <div className="flex-1 min-w-0 space-y-1">
                  <p className="text-sm font-medium leading-snug">
                    {activity.message}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {formatDistanceToNow(
                      typeof activity.timestamp === 'string' 
                        ? new Date(activity.timestamp) 
                        : activity.timestamp,
                      { addSuffix: true }
                    )}
                  </p>
                </div>
              </div>
            ))
          )}
        </div>
      </CardContent>
    </Card>
  );
}

