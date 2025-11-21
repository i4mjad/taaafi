'use client';

import { useEffect, useState } from 'react';
import { useDocument, useCollection } from 'react-firebase-hooks/firestore';
import { collection, doc, query, where, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useTranslation } from '@/contexts/TranslationContext';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  User,
  Mail,
  Calendar,
  TrendingUp,
  Shield,
  Award,
  Users,
  Clock,
  Download,
  X,
  Loader2,
} from 'lucide-react';
import { ReferredUsersTable } from './ReferredUsersTable';
import { ReferralTimeline } from './ReferralTimeline';
import { Separator } from '@/components/ui/separator';

interface UserDetailsModalProps {
  userId: string;
  open: boolean;
  onClose: () => void;
}

export function UserDetailsModal({ userId, open, onClose }: UserDetailsModalProps) {
  const { t } = useTranslation();

  // Fetch user document
  const [userSnapshot, userLoading, userError] = useDocument(doc(db, 'users', userId));

  // Fetch referral stats
  const [statsSnapshot, statsLoading, statsError] = useDocument(
    doc(db, 'referralStats', userId)
  );

  // Fetch referral verification
  const [verificationSnapshot, verificationLoading, verificationError] = useDocument(
    doc(db, 'referralVerifications', userId)
  );

  const userData = userSnapshot?.data();
  const statsData = statsSnapshot?.data();
  const verificationData = verificationSnapshot?.data();

  const isLoading = userLoading || statsLoading || verificationLoading;
  const hasError = userError || statsError || verificationError;

  // Log errors for debugging
  useEffect(() => {
    if (userError) {
      console.error('[UserDetailsModal] User document error:', userError);
    }
    if (statsError) {
      console.error('[UserDetailsModal] Stats document error:', statsError);
    }
    if (verificationError) {
      console.error('[UserDetailsModal] Verification document error:', verificationError);
    }
  }, [userError, statsError, verificationError]);

  const getInitials = (name: string) => {
    return name
      ?.split(' ')
      .map((n) => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2) || '?';
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    const date = timestamp?.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString();
  };

  const handleExport = async () => {
    try {
      // Prepare export data
      const exportData = {
        user: {
          id: userId,
          name: userData?.displayName || 'N/A',
          email: userData?.email || 'N/A',
          createdAt: formatDate(userData?.createdAt),
        },
        stats: {
          referralCode: statsData?.referralCode || 'N/A',
          totalReferred: statsData?.totalReferred || 0,
          totalVerified: statsData?.totalVerified || 0,
          totalPending: statsData?.totalPending || 0,
          totalBlocked: statsData?.blockedReferrals || 0,
          totalRewards: statsData?.totalRewardsEarned || 0,
        },
        verification: verificationData
          ? {
              status: verificationData.verificationStatus,
              fraudScore: verificationData.fraudScore || 0,
              isBlocked: verificationData.isBlocked || false,
              referrerId: verificationData.referrerId || null,
            }
          : null,
      };

      // Convert to CSV
      const csvContent = [
        'Field,Value',
        `User ID,${exportData.user.id}`,
        `Name,${exportData.user.name}`,
        `Email,${exportData.user.email}`,
        `Created At,${exportData.user.createdAt}`,
        '',
        'Referral Stats',
        `Referral Code,${exportData.stats.referralCode}`,
        `Total Referred,${exportData.stats.totalReferred}`,
        `Total Verified,${exportData.stats.totalVerified}`,
        `Total Pending,${exportData.stats.totalPending}`,
        `Total Blocked,${exportData.stats.totalBlocked}`,
        `Total Rewards,${exportData.stats.totalRewards}`,
        '',
        ...(exportData.verification
          ? [
              'Verification Info',
              `Status,${exportData.verification.status}`,
              `Fraud Score,${exportData.verification.fraudScore}`,
              `Is Blocked,${exportData.verification.isBlocked}`,
              `Referrer ID,${exportData.verification.referrerId || 'None'}`,
            ]
          : ['No verification data']),
      ].join('\n');

      // Download file
      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      const url = URL.createObjectURL(blob);
      link.setAttribute('href', url);
      link.setAttribute('download', `referral_data_${userId}_${Date.now()}.csv`);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    } catch (error) {
      console.error('Export error:', error);
    }
  };

  if (hasError) {
    return (
      <Dialog open={open} onOpenChange={onClose}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{t('modules.userManagement.referralDashboard.userDetails.error')}</DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.referralDashboard.userDetails.errorMessage')}
            </DialogDescription>
          </DialogHeader>
          <Button onClick={onClose} variant="outline">
            {t('modules.userManagement.referralDashboard.userDetails.close')}
          </Button>
        </DialogContent>
      </Dialog>
    );
  }

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-6xl max-h-[90vh] overflow-y-auto">
        <DialogHeader className="flex flex-row items-start justify-between">
          <div>
            <DialogTitle>
              {t('modules.userManagement.referralDashboard.userDetails.title')}
            </DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.referralDashboard.userDetails.description')}
            </DialogDescription>
          </div>
          <div className="flex gap-2">
            <Button onClick={handleExport} variant="outline" size="sm" disabled={isLoading}>
              <Download className="h-4 w-4 mr-2" />
              {t('modules.userManagement.referralDashboard.userDetails.export')}
            </Button>
          </div>
        </DialogHeader>

        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        ) : (
          <div className="space-y-6">
            {/* User Profile Card */}
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-start gap-4">
                  <Avatar className="h-16 w-16">
                    <AvatarImage src={userData?.photoURL || undefined} />
                    <AvatarFallback>{getInitials(userData?.displayName || 'User')}</AvatarFallback>
                  </Avatar>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <h3 className="text-xl font-bold">{userData?.displayName || 'N/A'}</h3>
                      {verificationData?.isBlocked && (
                        <Badge variant="destructive">
                          {t('modules.userManagement.referralDashboard.userDetails.blocked')}
                        </Badge>
                      )}
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm text-muted-foreground">
                      <div className="flex items-center gap-2">
                        <Mail className="h-4 w-4" />
                        <span>{userData?.email || 'N/A'}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Calendar className="h-4 w-4" />
                        <span>
                          {t('modules.userManagement.referralDashboard.userDetails.joined')}{' '}
                          {formatDate(userData?.createdAt)}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <User className="h-4 w-4" />
                        <span>ID: {userId}</span>
                      </div>
                      {statsData?.referralCode && (
                        <div className="flex items-center gap-2">
                          <TrendingUp className="h-4 w-4" />
                          <span>
                            {t('modules.userManagement.referralDashboard.userDetails.code')}:{' '}
                            <span className="font-mono font-bold">{statsData.referralCode}</span>
                          </span>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Stats Grid */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <Card>
                <CardHeader className="pb-3">
                  <CardDescription>
                    {t('modules.userManagement.referralDashboard.userDetails.stats.totalReferred')}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-3xl font-bold">{statsData?.totalReferred || 0}</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-3">
                  <CardDescription>
                    {t('modules.userManagement.referralDashboard.userDetails.stats.verified')}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-3xl font-bold text-green-600">
                    {statsData?.totalVerified || 0}
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-3">
                  <CardDescription>
                    {t('modules.userManagement.referralDashboard.userDetails.stats.pending')}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-3xl font-bold text-orange-600">
                    {statsData?.totalPending || 0}
                  </p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-3">
                  <CardDescription>
                    {t('modules.userManagement.referralDashboard.userDetails.stats.rewards')}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-3xl font-bold text-purple-600">
                    {statsData?.totalRewardsEarned || 0}
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Verification Info */}
            {verificationData && (
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">
                    {t('modules.userManagement.referralDashboard.userDetails.verificationTitle')}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div>
                      <p className="text-muted-foreground mb-1">
                        {t('modules.userManagement.referralDashboard.userDetails.verificationStatus')}
                      </p>
                      <Badge>{verificationData.verificationStatus}</Badge>
                    </div>
                    <div>
                      <p className="text-muted-foreground mb-1">
                        {t('modules.userManagement.referralDashboard.userDetails.fraudScore')}
                      </p>
                      <p className="text-lg font-bold">{verificationData.fraudScore || 0}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground mb-1">
                        {t('modules.userManagement.referralDashboard.userDetails.referrerId')}
                      </p>
                      <p className="text-xs font-mono">{verificationData.referrerId || 'N/A'}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground mb-1">
                        {t('modules.userManagement.referralDashboard.userDetails.verifiedAt')}
                      </p>
                      <p className="text-sm">{formatDate(verificationData.verifiedAt)}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Tabs for Referred Users and Timeline */}
            <Tabs defaultValue="referred" className="w-full">
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="referred">
                  <Users className="h-4 w-4 mr-2" />
                  {t('modules.userManagement.referralDashboard.userDetails.tabs.referredUsers')}
                </TabsTrigger>
                <TabsTrigger value="timeline">
                  <Clock className="h-4 w-4 mr-2" />
                  {t('modules.userManagement.referralDashboard.userDetails.tabs.timeline')}
                </TabsTrigger>
              </TabsList>
              <TabsContent value="referred" className="mt-4">
                <ReferredUsersTable referrerId={userId} />
              </TabsContent>
              <TabsContent value="timeline" className="mt-4">
                <ReferralTimeline userId={userId} />
              </TabsContent>
            </Tabs>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}

