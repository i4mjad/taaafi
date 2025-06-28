"use client";

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Users, Plus, Minus, AlertCircle, CheckCircle } from 'lucide-react';
import { useTranslation } from "@/contexts/TranslationContext";

interface Group {
  id: string;
  name: string;
  nameAr: string;
  description?: string;
  descriptionAr?: string;
  topicId: string;
  memberCount: number;
  isActive: boolean;
  createdAt: Date;
}

interface UserGroup {
  groupId: string;
  groupName: string;
  groupNameAr: string;
  topicId: string;
  subscribedAt: Date;
}

interface UserGroupsCardProps {
  userId: string;
}

export default function UserGroupsCard({ userId }: UserGroupsCardProps) {
  const { t, locale } = useTranslation();
  const [userGroups, setUserGroups] = useState<UserGroup[]>([]);
  const [allGroups, setAllGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  useEffect(() => {
    loadGroupData();
  }, [userId]);

  const loadGroupData = async () => {
    try {
      setLoading(true);
      
      // Load user's group memberships and all available groups
      const response = await fetch(`/api/admin/users/${userId}/subscribe-group`);
      
      if (response.ok) {
        const data = await response.json();
        setUserGroups(data.userGroups || []);
        setAllGroups(data.allGroups || []);
      } else {
        console.error('Failed to load group data');
      }
    } catch (error) {
      console.error('Error loading group data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleGroupAction = async (groupId: string, action: 'subscribe' | 'unsubscribe') => {
    try {
      setActionLoading(groupId);
      setAlert(null);

      const response = await fetch(`/api/admin/users/${userId}/subscribe-group`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          groupId,
          action,
        }),
      });

      const result = await response.json();

      if (response.ok) {
        setAlert({
          type: 'success',
          message: result.message,
        });
        
        // Reload group data to get updated membership info
        await loadGroupData();
      } else {
        setAlert({
          type: 'error',
          message: result.error || `Failed to ${action} user`,
        });
      }
    } catch (error) {
      setAlert({
        type: 'error',
        message: `Failed to ${action} user to/from group`,
      });
    } finally {
      setActionLoading(null);
    }
  };

  const isUserInGroup = (groupId: string): boolean => {
    return userGroups.some(ug => ug.groupId === groupId);
  };

  const getGroupName = (group: Group): string => {
    return locale === 'ar' && group.nameAr ? group.nameAr : group.name;
  };

  const getGroupDescription = (group: Group): string => {
    const desc = locale === 'ar' && group.descriptionAr ? group.descriptionAr : group.description;
    return desc || '';
  };

  const formatDate = (date: Date | string) => {
    const dateObj = date instanceof Date ? date : new Date(date);
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(dateObj);
  };

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            <Skeleton className="h-5 w-32" />
          </CardTitle>
          <Skeleton className="h-4 w-48" />
        </CardHeader>
        <CardContent className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="flex items-center justify-between p-3 border rounded-lg">
              <div className="space-y-2">
                <Skeleton className="h-4 w-24" />
                <Skeleton className="h-3 w-48" />
              </div>
              <Skeleton className="h-8 w-20" />
            </div>
          ))}
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Users className="h-5 w-5" />
          {t('modules.userManagement.groups.title') || 'Messaging Groups'}
        </CardTitle>
        <CardDescription>
          {t('modules.userManagement.groups.userSubscription') || 'Manage user group subscriptions for targeted messaging'}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {alert && (
          <div className={`flex items-center gap-2 p-3 rounded-lg border ${
            alert.type === 'error' 
              ? 'bg-destructive/10 border-destructive text-destructive' 
              : 'bg-green-50 border-green-200 text-green-800'
          }`}>
            {alert.type === 'error' ? (
              <AlertCircle className="h-4 w-4" />
            ) : (
              <CheckCircle className="h-4 w-4" />
            )}
            <span className="text-sm">{alert.message}</span>
          </div>
        )}

        {allGroups.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">
            <Users className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>{t('modules.userManagement.groups.noGroupsAvailable') || 'No groups available'}</p>
          </div>
        ) : (
          <div className="space-y-3">
            {allGroups.map((group) => {
              const isSubscribed = isUserInGroup(group.id);
              const userGroup = userGroups.find(ug => ug.groupId === group.id);
              
              return (
                <div key={group.id} className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex-1">
                    <div className="flex items-center gap-3">
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="font-medium">{getGroupName(group)}</h3>
                          <Badge variant="outline" className="text-xs">
                            {group.memberCount} {t('modules.userManagement.groups.members') || 'members'}
                          </Badge>
                          {isSubscribed && (
                            <Badge variant="default" className="text-xs">
                              <CheckCircle className="h-3 w-3 mr-1" />
                              {t('modules.userManagement.groups.subscribed') || 'Subscribed'}
                            </Badge>
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground">
                          {getGroupDescription(group) || `Topic: ${group.topicId}`}
                        </p>
                        {isSubscribed && userGroup && (
                          <p className="text-xs text-muted-foreground mt-1">
                            {t('modules.userManagement.groups.subscribedOn') || 'Subscribed on'}: {formatDate(userGroup.subscribedAt)}
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                  
                  <Button
                    variant={isSubscribed ? "destructive" : "default"}
                    size="sm"
                    onClick={() => handleGroupAction(group.id, isSubscribed ? 'unsubscribe' : 'subscribe')}
                    disabled={actionLoading === group.id || !group.isActive}
                  >
                    {actionLoading === group.id ? (
                      <div className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
                    ) : isSubscribed ? (
                      <>
                        <Minus className="h-4 w-4 mr-2" />
                        {t('modules.userManagement.groups.unsubscribe') || 'Unsubscribe'}
                      </>
                    ) : (
                      <>
                        <Plus className="h-4 w-4 mr-2" />
                        {t('modules.userManagement.groups.subscribe') || 'Subscribe'}
                      </>
                    )}
                  </Button>
                </div>
              );
            })}
          </div>
        )}
        
        {userGroups.length > 0 && (
          <div className="mt-6 pt-4 border-t">
            <p className="text-sm text-muted-foreground">
              {t('modules.userManagement.groups.currentSubscriptions') || 'Current subscriptions'}: {userGroups.length}
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
} 