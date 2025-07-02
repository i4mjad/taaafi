'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { SiteHeader } from '@/components/site-header';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Skeleton } from '@/components/ui/skeleton';
import { Separator } from '@/components/ui/separator';
import {
  ArrowLeft,
  Edit,
  Shield,
  Mail,
  Calendar,
  Globe,
  Activity,
  User,
  AlertTriangle,
  CheckCircle,
  Smartphone,
  Clock,
  Languages,
  Cake,
  UserCircle,
  MessageSquare,
  Send,
  Users,
} from 'lucide-react';
import Link from 'next/link';
import { useTranslation } from "@/contexts/TranslationContext";
import { NotificationDialog } from './NotificationDialog';
import UserGroupsCard from './UserGroupsCard';
import MigrationManagementCard from './MigrationManagementCard';
import WarningManagementCard from './components/WarningManagementCard';
import BanManagementCard from './components/BanManagementCard';
// Firebase imports
import { useDocument } from 'react-firebase-hooks/firestore';
import { doc } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface UserProfile {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  role: 'admin' | 'moderator' | 'user';
  status: 'active' | 'inactive' | 'suspended';
  createdAt: Date;
  updatedAt: Date;
  lastLoginAt?: Date | null;
  emailVerified: boolean;
  dayOfBirth?: Date | null;
  gender?: string;
  locale?: string;
  lastTokenUpdate?: Date | null;
  messagingToken?: string;
  platform?: string;
  userFirstDate?: Date | null;
  devicesIds?: string[];
  // Legacy array fields for migration
  userRelapses?: string[];
  userMasturbatingWithoutWatching?: string[];
  userWatchingWithoutMasturbating?: string[];
  metadata: {
    loginCount: number;
    lastIpAddress?: string;
    userAgent?: string;
  };
}

export default function UserDetailsPage() {
  const { t, locale } = useTranslation();
  const params = useParams();
  const uid = params.uid as string;
  
  const [notificationDialogOpen, setNotificationDialogOpen] = useState(false);

  // Use Firebase hooks to fetch user document and group memberships
  const [userSnapshot, userLoading, userError] = useDocument(
    uid ? doc(db, 'users', uid) : null
  );

  const [userMembershipsSnapshot, userMembershipsLoading, userMembershipsError] = useDocument(
    uid ? doc(db, 'userGroupMemberships', uid) : null
  );

  // Get user subscriptions count for statistics
  const userSubscriptionsCount = userMembershipsSnapshot?.exists() 
    ? (userMembershipsSnapshot.data()?.groups || []).length 
    : 0;

  // Track last update timestamp for debugging
  const [lastSubscriptionUpdate, setLastSubscriptionUpdate] = useState<Date | null>(null);

  // Process user data from Firebase snapshot
  const user: UserProfile | null = userSnapshot?.exists() ? (() => {
    const userData = userSnapshot.data();
    return {
      uid: userSnapshot.id,
      email: userData.email || '',
      displayName: userData.displayName,
      photoURL: userData.photoURL,
      role: userData.role || 'user',
      status: userData.status || 'active',
      createdAt: userData.createdAt?.toDate() || new Date(),
      updatedAt: userData.updatedAt?.toDate() || new Date(),
      lastLoginAt: userData.lastLoginAt?.toDate() || null,
      emailVerified: userData.emailVerified || false,
      dayOfBirth: userData.dayOfBirth?.toDate() || null,
      gender: userData.gender,
      locale: userData.locale,
      lastTokenUpdate: userData.lastTokenUpdate?.toDate() || null,
      messagingToken: userData.messagingToken,
      platform: userData.platform,
      userFirstDate: userData.userFirstDate?.toDate() || null,
      devicesIds: userData.devicesIds || [],
      userRelapses: userData.userRelapses || [],
      userMasturbatingWithoutWatching: userData.userMasturbatingWithoutWatching || [],
      userWatchingWithoutMasturbating: userData.userWatchingWithoutMasturbating || [],
      metadata: {
        loginCount: userData.metadata?.loginCount || 0,
        lastIpAddress: userData.metadata?.lastIpAddress,
        userAgent: userData.metadata?.userAgent,
      },
    };
  })() : null;

  // Debug logging for subscription updates
  useEffect(() => {
    if (userMembershipsSnapshot?.exists()) {
      const groups = userMembershipsSnapshot.data()?.groups || [];
      const updateTime = new Date();
      
      setLastSubscriptionUpdate(updateTime);
    }
  }, [userMembershipsSnapshot, uid]);

  const headerDictionary = {
    documents: t('modules.userManagement.userDetails') || 'User Details',
  };



  const getStatusBadge = (status: string) => {
    const variants = {
      active: 'default',
      inactive: 'secondary',
      suspended: 'destructive',
    } as const;

    const icons = {
      active: CheckCircle,
      inactive: User,
      suspended: AlertTriangle,
    };

    const Icon = icons[status as keyof typeof icons] || User;

    return (
      <Badge variant={variants[status as keyof typeof variants] || 'secondary'}>
        <Icon className="h-3 w-3 mr-1" />
        {t(`modules.userManagement.userStatus.${status}`) || status}
      </Badge>
    );
  };

  const getRoleBadge = (role: string) => {
    const variants = {
      admin: 'default',
      moderator: 'secondary',
      user: 'outline',
    } as const;

    return (
      <Badge variant={variants[role as keyof typeof variants] || 'outline'}>
        <Shield className="h-3 w-3 mr-1" />
        {t(`modules.userManagement.userRole.${role}`) || role}
      </Badge>
    );
  };

  const formatDate = (date: Date | string | null | undefined) => {
    if (!date) return t('common.never') || 'Never';
    
    // Handle both Date objects and date strings
    const dateObj = date instanceof Date ? date : new Date(date);
    
    // Check if the date is valid
    if (isNaN(dateObj.getTime())) {
      return t('common.unknown') || 'Unknown';
    }
    
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      calendar: 'gregory',
    }).format(dateObj);
  };

  const formatDateOnly = (date: Date | string | null | undefined) => {
    if (!date) return t('modules.userManagement.notSpecified') || 'Not specified';
    
    const dateObj = date instanceof Date ? date : new Date(date);
    
    if (isNaN(dateObj.getTime())) {
      return t('common.unknown') || 'Unknown';
    }
    
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      calendar: 'gregory',
    }).format(dateObj);
  };

  const formatGender = (gender: string | undefined) => {
    if (!gender || gender.trim() === '') {
      return t('modules.userManagement.notSpecified') || 'Not specified';
    }
    return gender;
  };

  const formatLocale = (userLocale: string | undefined) => {
    if (!userLocale) {
      return t('modules.userManagement.notSpecified') || 'Not specified';
    }
    
    const localeMap: { [key: string]: string } = {
      'english': 'English',
      'arabic': 'العربية',
      'en': 'English',
      'ar': 'العربية',
    };
    
    return localeMap[userLocale.toLowerCase()] || userLocale;
  };

  const formatPlatform = (platform: string | undefined) => {
    if (!platform) {
      return t('modules.userManagement.notSpecified') || 'Not specified';
    }
    
    return platform.charAt(0).toUpperCase() + platform.slice(1);
  };

  if (userLoading) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex flex-1 flex-col">
          <div className="@container/main flex flex-1 flex-col gap-2">
            <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
              <Skeleton className="h-8 w-64" />
              <div className="grid gap-6 md:grid-cols-2">
                <Skeleton className="h-96" />
                <Skeleton className="h-96" />
              </div>
            </div>
          </div>
        </div>
      </>
    );
  }

  if (userError || !user) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex flex-1 flex-col">
          <div className="@container/main flex flex-1 flex-col gap-2">
            <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
              <div className="flex items-center gap-4">
                <Button variant="outline" size="sm" asChild>
                  <Link href={`/${locale}/user-management/users`}>
                    <ArrowLeft className="h-4 w-4 mr-2" />
                    {t('common.back') || 'Back'}
                  </Link>
                </Button>
              </div>
              <div className="text-center py-8">
                <h1 className="text-2xl font-bold">
                  {t('modules.userManagement.userNotFound') || 'User Not Found'}
                </h1>
                <p className="text-muted-foreground mt-2">
                  {userError?.message || (t('modules.userManagement.userNotFoundDescription') || 'The requested user could not be found.')}
                </p>
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
                  <Link href={`/${locale}/user-management/users`}>
                    <ArrowLeft className="h-4 w-4 mr-2" />
                    {t('common.back') || 'Back'}
                  </Link>
                </Button>
                <div>
                  <h1 className="text-3xl font-bold tracking-tight">
                    {t('modules.userManagement.userDetails') || 'User Details'}
                  </h1>
                  <p className="text-muted-foreground">
                    {t('modules.userManagement.userDetailsDescription') || 'View and manage user information'}
                  </p>
                </div>
              </div>
              <Button>
                <Edit className="h-4 w-4 mr-2" />
                {t('common.edit')}
              </Button>
            </div>

            {/* User Profile */}
            <div className="grid gap-6 lg:grid-cols-2 xl:grid-cols-2">
              {/* Basic Information */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <User className="h-5 w-5" />
                    {t('modules.userManagement.basicInformation') || 'Basic Information'}
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  {/* Avatar and Name */}
                  <div className="flex items-center gap-4">
                    <Avatar className="h-16 w-16">
                      <AvatarImage src={user.photoURL || undefined} alt={user.displayName} />
                      <AvatarFallback className="text-lg">
                        {user.displayName?.charAt(0) || user.email.charAt(0).toUpperCase()}
                      </AvatarFallback>
                    </Avatar>
                    <div className="space-y-1">
                      <h3 className="text-xl font-semibold">
                        {user.displayName || user.email}
                      </h3>
                      <div className="flex items-center gap-2">
                        {getRoleBadge(user.role)}
                        {getStatusBadge(user.status)}
                      </div>
                    </div>
                  </div>

                  <Separator />

                  {/* Contact Information */}
                  <div className="space-y-4">
                    <div className="flex items-center gap-3">
                      <Mail className="h-4 w-4 text-muted-foreground" />
                      <div>
                        <p className="text-sm font-medium">{t('modules.userManagement.email') || 'Email'}</p>
                        <p className="text-sm text-muted-foreground">{user.email}</p>
                      </div>
                      {user.emailVerified && (
                        <Badge variant="outline" className="ml-auto">
                          <CheckCircle className="h-3 w-3 mr-1" />
                          {t('modules.userManagement.verified') || 'Verified'}
                        </Badge>
                      )}
                    </div>

                    <div className="flex items-center gap-3">
                      <Shield className="h-4 w-4 text-muted-foreground" />
                      <div>
        <p className="text-sm font-medium">{t('modules.userManagement.role') || 'Role'}</p>
                        <p className="text-sm text-muted-foreground capitalize">{user.role}</p>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <UserCircle className="h-4 w-4 text-muted-foreground" />
                      <div>
                        <p className="text-sm font-medium">{t('modules.userManagement.displayName') || 'Display Name'}</p>
                        <p className="text-sm text-muted-foreground">
                          {user.displayName || t('modules.userManagement.notSpecified') || 'Not specified'}
                        </p>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Personal Information */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <UserCircle className="h-5 w-5" />
                    {t('modules.userManagement.personalInformation') || 'Personal Information'}
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center gap-3">
                    <Cake className="h-4 w-4 text-muted-foreground" />
                    <div>
                      <p className="text-sm font-medium">{t('modules.userManagement.dateOfBirth') || 'Date of Birth'}</p>
                      <p className="text-sm text-muted-foreground">{formatDateOnly(user.dayOfBirth)}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <User className="h-4 w-4 text-muted-foreground" />
                    <div>
                      <p className="text-sm font-medium">{t('modules.userManagement.gender') || 'Gender'}</p>
                      <p className="text-sm text-muted-foreground">{formatGender(user.gender)}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <Languages className="h-4 w-4 text-muted-foreground" />
                    <div>
                      <p className="text-sm font-medium">{t('modules.userManagement.locale') || 'Preferred Language'}</p>
                      <p className="text-sm text-muted-foreground">{formatLocale(user.locale)}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <Smartphone className="h-4 w-4 text-muted-foreground" />
                    <div>
                      <p className="text-sm font-medium">{t('modules.userManagement.platform') || 'Platform'}</p>
                      <p className="text-sm text-muted-foreground">{formatPlatform(user.platform)}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Activity Information */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Activity className="h-5 w-5" />
                    {t('modules.userManagement.activityInformation') || 'Activity Information'}
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="space-y-4">
                    <div className="flex items-center gap-3">
                      <Calendar className="h-4 w-4 text-muted-foreground" />
                      <div>
                        <p className="text-sm font-medium">{t('modules.userManagement.userFirstDate') || 'First Registration'}</p>
                        <p className="text-sm text-muted-foreground">{formatDate(user.userFirstDate)}</p>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <Calendar className="h-4 w-4 text-muted-foreground" />
                      <div>
                        <p className="text-sm font-medium">{t('modules.userManagement.memberSince') || 'Member Since'}</p>
                        <p className="text-sm text-muted-foreground">{formatDate(user.createdAt)}</p>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <Activity className="h-4 w-4 text-muted-foreground" />
                      <div>
                        <p className="text-sm font-medium">{t('modules.userManagement.lastLogin') || 'Last Login'}</p>
                        <p className="text-sm text-muted-foreground">
                          {formatDate(user.lastLoginAt)}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <Clock className="h-4 w-4 text-muted-foreground" />
                      <div>
                        <p className="text-sm font-medium">{t('modules.userManagement.lastTokenUpdate') || 'Last Token Update'}</p>
                        <p className="text-sm text-muted-foreground">
                          {formatDate(user.lastTokenUpdate)}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <Globe className="h-4 w-4 text-muted-foreground" />
                      <div>
                        <p className="text-sm font-medium">{t('modules.userManagement.lastIpAddress') || 'Last IP Address'}</p>
                        <p className="text-sm text-muted-foreground">
                          {user.metadata.lastIpAddress || t('common.unknown') || 'Unknown'}
                        </p>
                      </div>
                    </div>
                  </div>

                  <Separator />

                  {/* Statistics */}
                  <div className="grid grid-cols-3 gap-4">
                    <div className="text-center p-4 bg-muted rounded-lg">
                      <p className="text-2xl font-bold">{user.metadata.loginCount}</p>
                      <p className="text-sm text-muted-foreground">
                        {t('modules.userManagement.totalLogins') || 'Total Logins'}
                      </p>
                    </div>
                    <div className="text-center p-4 bg-muted rounded-lg">
                      <p className="text-2xl font-bold">
                        {Math.floor((Date.now() - user.createdAt.getTime()) / (1000 * 60 * 60 * 24))}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        {t('modules.userManagement.daysSince') || 'Days Since Joining'}
                      </p>
                    </div>
                    <div className="text-center p-4 bg-muted rounded-lg">
                      <div className="flex items-center justify-center gap-1 mb-1">
                        <Users className="h-4 w-4 text-muted-foreground" />
                        <p className="text-2xl font-bold">
                          {userMembershipsLoading ? (
                            <span className="animate-pulse">...</span>
                          ) : userMembershipsError ? (
                            <span className="text-destructive text-sm">Error</span>
                          ) : (
                            userSubscriptionsCount
                          )}
                        </p>
                      </div>
                      <p className="text-sm text-muted-foreground">
                        {t('modules.userManagement.groupSubscriptions') || 'Group Subscriptions'}
                      </p>
                      {lastSubscriptionUpdate && (
                        <p className="text-xs text-muted-foreground mt-1">
                          Last updated: {lastSubscriptionUpdate.toLocaleTimeString()}
                        </p>
                      )}
                      {userMembershipsError && (
                        <p className="text-xs text-destructive mt-1">
                          {t('modules.userManagement.errors.loadingSubscriptions') || 'Failed to load subscriptions'}
                        </p>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Device Information */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Smartphone className="h-5 w-5" />
                    {t('modules.userManagement.deviceInformation') || 'Device Information'}
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <MessageSquare className="h-4 w-4 text-muted-foreground" />
                        <p className="text-sm font-medium">{t('modules.userManagement.messagingToken') || 'Messaging Token'}</p>
                      </div>
                      {user.messagingToken && (
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => setNotificationDialogOpen(true)}
                          className="h-8"
                        >
                          <Send className="h-3 w-3 mr-1" />
                          {t('modules.userManagement.sendNotification') || 'Send Notification'}
                        </Button>
                      )}
                    </div>
                    <div className="pl-7">
                      <p className="text-xs text-muted-foreground font-mono break-all bg-muted p-2 rounded">
                        {user.messagingToken || t('modules.userManagement.notSpecified') || 'Not specified'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <Smartphone className="h-4 w-4 text-muted-foreground" />
                    <div>
                      <p className="text-sm font-medium">{t('modules.userManagement.deviceCount') || 'Registered Devices'}</p>
                      <p className="text-sm text-muted-foreground">
                        {user.devicesIds?.length || 0} {t('modules.userManagement.connectedDevices') || 'devices'}
                      </p>
                    </div>
                  </div>

                  {user.devicesIds && user.devicesIds.length > 0 && (
                    <div className="space-y-2">
                      <p className="text-sm font-medium">{t('modules.userManagement.devicesIds') || 'Device IDs'}</p>
                      <div className="space-y-1">
                        {user.devicesIds.map((deviceId, index) => (
                          <div key={index} className="p-2 bg-muted rounded text-xs font-mono break-all">
                            {deviceId}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {(!user.devicesIds || user.devicesIds.length === 0) && (
                    <div className="text-center py-4 text-muted-foreground">
                      <Smartphone className="h-8 w-8 mx-auto mb-2 opacity-50" />
                      <p className="text-sm">{t('modules.userManagement.noDevices') || 'No devices registered'}</p>
                    </div>
                  )}
                </CardContent>
              </Card>

              {/* Group Subscriptions Management - Full Width */}
              <div className="col-span-full">
                <UserGroupsCard userId={user.uid} />
              </div>

              {/* Migration Management - Full Width */}
              <div className="col-span-full">
                <MigrationManagementCard userId={user.uid} user={user} />
              </div>

              {/* Warning Management - Full Width */}
              <div className="col-span-full">
                <WarningManagementCard 
                  userId={user.uid} 
                  userDisplayName={user.displayName}
                  userDevices={user.devicesIds || []}
                />
              </div>

              {/* Ban Management - Full Width */}
              <div className="col-span-full">
                <BanManagementCard 
                  userId={user.uid} 
                  userDisplayName={user.displayName}
                  userDevices={user.devicesIds || []}
                />
              </div>
            </div>

            {/* TODO: Add more sections like user permissions, recent activity, etc. */}
          </div>
        </div>
      </div>

      {/* Notification Dialog */}
      {user?.messagingToken && (
        <NotificationDialog
          open={notificationDialogOpen}
          onOpenChange={setNotificationDialogOpen}
          messagingToken={user.messagingToken}
          userDisplayName={user.displayName}
        />
      )}
    </>
  );
} 