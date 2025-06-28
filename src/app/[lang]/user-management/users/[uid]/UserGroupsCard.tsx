"use client";

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Users, Plus, Minus, AlertCircle, CheckCircle, Wifi, WifiOff } from 'lucide-react';
import { useTranslation } from "@/contexts/TranslationContext";
// Firebase imports
import { useCollection, useDocument } from 'react-firebase-hooks/firestore';
import { collection, doc, setDoc, updateDoc, increment, serverTimestamp, runTransaction, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';

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

// FCM Topic Management API
const manageFCMTopicSubscription = async (
  userId: string, 
  topicId: string, 
  action: 'subscribe' | 'unsubscribe'
) => {
  const response = await fetch('/api/fcm/manage-topic', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, topicId, action }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || `Failed to ${action} to FCM topic`);
  }

  return response.json();
};

export default function UserGroupsCard({ userId }: UserGroupsCardProps) {
  const { t, locale } = useTranslation();
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [alert, setAlert] = useState<{ type: 'success' | 'error' | 'warning'; message: string } | null>(null);

  // Use Firebase hooks to fetch data
  const [groupsSnapshot, groupsLoading, groupsError] = useCollection(
    collection(db, 'usersMessagingGroups')
  );

  const [userMembershipsSnapshot, userMembershipsLoading, userMembershipsError] = useDocument(
    doc(db, 'userGroupMemberships', userId)
  );

  // Check user document for messagingToken
  const [userSnapshot, userLoading, userError] = useDocument(
    doc(db, 'users', userId)
  );

  // Convert Firestore documents to typed objects
  const allGroups: Group[] = groupsSnapshot?.docs.map(doc => {
    const data = doc.data();
    return {
      id: doc.id,
      name: data.name,
      nameAr: data.nameAr,
      description: data.description,
      descriptionAr: data.descriptionAr,
      topicId: data.topicId,
      memberCount: data.memberCount || 0,
      isActive: data.isActive !== false,
      createdAt: data.createdAt?.toDate() || new Date(),
    };
  }) || [];

  const userGroups: UserGroup[] = userMembershipsSnapshot?.exists() 
    ? (userMembershipsSnapshot.data()?.groups || []).map((group: any) => ({
        ...group,
        subscribedAt: group.subscribedAt?.toDate() || new Date(),
      }))
    : [];

  // Check if user has a valid messaging token
  const userData = userSnapshot?.exists() ? userSnapshot.data() : null;
  const hasValidFCMToken = !!(userData?.messagingToken && userData.messagingToken.trim());

  const loading = groupsLoading || userMembershipsLoading || userLoading;
  const error = groupsError || userMembershipsError || userError;

  const handleGroupAction = async (groupId: string, action: 'subscribe' | 'unsubscribe') => {
    try {
      setActionLoading(groupId);
      setAlert(null);

      const group = allGroups.find(g => g.id === groupId);
      if (!group) {
        throw new Error(t('modules.userManagement.groups.errors.groupNotFound') || 'Group not found');
      }

      // Validation checks
      if (!group.isActive) {
        throw new Error(t('modules.userManagement.groups.errors.cannotSubscribeInactive') || 'Cannot subscribe to inactive group');
      }

      if (action === 'subscribe') {
        // Check if already subscribed
        if (isUserInGroup(groupId)) {
          throw new Error(t('modules.userManagement.groups.errors.alreadySubscribed') || 'User is already subscribed to this group');
        }

        // Check if user has FCM token for notifications
        if (!hasValidFCMToken) {
          setAlert({
            type: 'warning',
            message: t('modules.userManagement.groups.warnings.noMessagingToken') || 'User has no messaging token. Subscription will be saved but notifications may not work.',
          });
        }
      } else {
        // Check if actually subscribed
        if (!isUserInGroup(groupId)) {
          throw new Error(t('modules.userManagement.groups.errors.notSubscribed') || 'User is not subscribed to this group');
        }
      }

      // Use Firestore transaction for atomic database operations
      await runTransaction(db, async (transaction) => {
        const userGroupsRef = doc(db, 'userGroupMemberships', userId);
        const groupRef = doc(db, 'usersMessagingGroups', groupId);

        // Read current state within transaction
        const userGroupsDoc = await transaction.get(userGroupsRef);
        const groupDoc = await transaction.get(groupRef);

        let currentUserGroups = userGroupsDoc.exists() ? (userGroupsDoc.data()?.groups || []) : [];
        const currentGroupData = groupDoc.data();

        if (!currentGroupData) {
          throw new Error(t('modules.userManagement.groups.errors.groupDataNotFound') || 'Group data not found');
        }

        // Prepare updated user groups
        let updatedGroups = [...currentUserGroups];

        if (action === 'subscribe') {
          // Double-check within transaction
          if (!currentUserGroups.some((ug: any) => ug.groupId === groupId)) {
            updatedGroups.push({
              groupId,
              groupName: group.name,
              groupNameAr: group.nameAr,
              topicId: group.topicId,
              subscribedAt: new Date(),
            });
          }
        } else {
          // Remove group
          updatedGroups = updatedGroups.filter((ug: any) => ug.groupId !== groupId);
        }

        // Update user's group memberships
        transaction.set(userGroupsRef, {
          userId,
          groups: updatedGroups,
          updatedAt: serverTimestamp(),
        }, { merge: true });

        // Update group's member count
        transaction.update(groupRef, {
          memberCount: increment(action === 'subscribe' ? 1 : -1),
          updatedAt: serverTimestamp(),
        });
      });

      // Handle FCM topic subscription separately (after database transaction succeeds)
      if (hasValidFCMToken) {
        try {
          await manageFCMTopicSubscription(userId, group.topicId, action);
          
          const actionText = action === 'subscribe' 
            ? t('modules.userManagement.groups.subscribedTo') || 'subscribed to'
            : t('modules.userManagement.groups.unsubscribedFrom') || 'unsubscribed from';
          
          setAlert({
            type: 'success',
            message: `${t('modules.userManagement.groups.user') || 'User'} ${actionText} ${t('modules.userManagement.groups.group') || 'group'} "${getGroupName(group)}" ${t('modules.userManagement.groups.successfully') || 'successfully'}. ${t('modules.userManagement.groups.pushNotificationsActive') || 'Push notifications are active'}.`,
          });
        } catch (fcmError: any) {
          console.error('FCM subscription error:', fcmError);
          
          const actionText = action === 'subscribe' 
            ? t('modules.userManagement.groups.subscription') || 'subscription'
            : t('modules.userManagement.groups.unsubscription') || 'unsubscription';
          
          // Database was updated successfully but FCM failed
          setAlert({
            type: 'warning',
            message: `${t('modules.userManagement.groups.groupSubscriptionUpdated') || 'Group subscription updated'} ${t('modules.userManagement.groups.butFcmFailed') || 'but FCM topic'} ${actionText} ${t('modules.userManagement.groups.failed') || 'failed'}: ${fcmError.message}. ${t('modules.userManagement.groups.mayNotReceiveNotifications') || 'User may not receive push notifications'}.`,
          });
        }
      } else {
        const actionText = action === 'subscribe' 
          ? t('modules.userManagement.groups.subscribedTo') || 'subscribed to'
          : t('modules.userManagement.groups.unsubscribedFrom') || 'unsubscribed from';
        
        setAlert({
          type: 'success',
          message: `${t('modules.userManagement.groups.user') || 'User'} ${actionText} ${t('modules.userManagement.groups.group') || 'group'} "${getGroupName(group)}" ${t('modules.userManagement.groups.successfully') || 'successfully'}. ${t('modules.userManagement.groups.note') || 'Note'}: ${t('modules.userManagement.groups.noMessagingTokenForNotifications') || 'No messaging token found for push notifications'}.`,
        });
      }

    } catch (error: any) {
      console.error('Error managing group subscription:', error);
      const actionText = action === 'subscribe' 
        ? t('modules.userManagement.groups.subscribe') || 'subscribe'
        : t('modules.userManagement.groups.unsubscribe') || 'unsubscribe';
      
      setAlert({
        type: 'error',
        message: `${t('modules.userManagement.groups.failedTo') || 'Failed to'} ${actionText} ${t('modules.userManagement.groups.user') || 'user'}: ${error.message}`,
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

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            {t('modules.userManagement.groups.title') || 'Messaging Groups'}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8">
            <AlertCircle className="h-12 w-12 text-destructive mx-auto mb-4" />
            <h3 className="text-lg font-medium mb-2">{t('modules.userManagement.groups.errorLoadingGroups') || 'Error loading groups'}</h3>
            <p className="text-muted-foreground">{error.message}</p>
          </div>
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
          {hasValidFCMToken ? (
            <Badge variant="default" className="text-xs">
              <Wifi className="h-3 w-3 mr-1" />
              {t('modules.userManagement.groups.fcmActive') || 'FCM Active'}
            </Badge>
          ) : (
            <Badge variant="secondary" className="text-xs">
              <WifiOff className="h-3 w-3 mr-1" />
              {t('modules.userManagement.groups.noFcmToken') || 'No FCM Token'}
            </Badge>
          )}
        </CardTitle>
        <CardDescription>
          {t('modules.userManagement.groups.userSubscription') || 'Manage user group subscriptions for targeted messaging'}
          {!hasValidFCMToken && (
            <span className="block text-orange-600 mt-1">
              ⚠️ {t('modules.userManagement.groups.noMessagingTokenWarning') || 'User has no messaging token. Subscriptions will be saved but push notifications won\'t work.'}
            </span>
          )}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {alert && (
          <div className={`flex items-center gap-2 p-3 rounded-lg border ${
            alert.type === 'error' 
              ? 'bg-destructive/10 border-destructive text-destructive' 
              : alert.type === 'warning'
              ? 'bg-orange-50 border-orange-200 text-orange-800'
              : 'bg-green-50 border-green-200 text-green-800'
          }`}>
            {alert.type === 'error' ? (
              <AlertCircle className="h-4 w-4" />
            ) : alert.type === 'warning' ? (
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
                          {!group.isActive && (
                            <Badge variant="secondary" className="text-xs">
                              {t('common.inactive') || 'Inactive'}
                            </Badge>
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground">
                          {getGroupDescription(group) || `${t('modules.userManagement.groups.topic') || 'Topic'}: ${group.topicId}`}
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