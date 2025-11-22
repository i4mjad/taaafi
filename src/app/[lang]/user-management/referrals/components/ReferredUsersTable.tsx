'use client';

import { useEffect } from 'react';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, where, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useTranslation } from '@/contexts/TranslationContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Loader2, User, AlertCircle } from 'lucide-react';
import { useDocument } from 'react-firebase-hooks/firestore';
import { doc } from 'firebase/firestore';

interface ReferredUsersTableProps {
  referrerId: string;
}

function ReferredUserRow({ userId }: { userId: string }) {
  const { t } = useTranslation();

  // Fetch user data
  const [userSnapshot, userLoading] = useDocument(doc(db, 'users', userId));
  
  // Fetch verification data
  const [verificationSnapshot, verificationLoading] = useDocument(
    doc(db, 'referralVerifications', userId)
  );

  const userData = userSnapshot?.data();
  const verificationData = verificationSnapshot?.data();

  if (userLoading || verificationLoading) {
    return (
      <TableRow>
        <TableCell colSpan={5} className="text-center py-4">
          <Loader2 className="h-4 w-4 animate-spin inline-block" />
        </TableCell>
      </TableRow>
    );
  }

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

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'verified':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
      case 'pending':
        return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200';
      case 'blocked':
        return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200';
    }
  };

  const getFraudScoreColor = (score: number) => {
    if (score >= 70) return 'text-red-600 font-bold';
    if (score >= 40) return 'text-orange-600 font-semibold';
    return 'text-green-600';
  };

  return (
    <TableRow>
      <TableCell>
        <div className="flex items-center gap-2">
          <Avatar className="h-8 w-8">
            <AvatarImage src={userData?.photoURL || undefined} />
            <AvatarFallback>{getInitials(userData?.displayName || 'User')}</AvatarFallback>
          </Avatar>
          <div>
            <p className="font-medium text-sm">{userData?.displayName || 'N/A'}</p>
            <p className="text-xs text-muted-foreground">{userData?.email || 'N/A'}</p>
          </div>
        </div>
      </TableCell>
      <TableCell>
        <Badge className={getStatusColor(verificationData?.verificationStatus || 'unknown')}>
          {verificationData?.verificationStatus || 'unknown'}
        </Badge>
      </TableCell>
      <TableCell className="text-center">
        <span className={getFraudScoreColor(verificationData?.fraudScore || 0)}>
          {verificationData?.fraudScore || 0}
        </span>
      </TableCell>
      <TableCell className="text-sm text-muted-foreground">
        {formatDate(userData?.createdAt)}
      </TableCell>
      <TableCell className="text-sm">
        {verificationData?.verifiedAt
          ? formatDate(verificationData.verifiedAt)
          : t('modules.userManagement.referralDashboard.referredUsers.notVerified')}
      </TableCell>
    </TableRow>
  );
}

export function ReferredUsersTable({ referrerId }: ReferredUsersTableProps) {
  const { t } = useTranslation();

  // Query referral verifications where referrerId matches
  // Note: Requires composite index: referralVerifications (referrerId Ascending, createdAt Descending)
  // Create it in Firebase Console or use the error link provided in console
  const [snapshot, loading, error] = useCollection(
    referrerId
      ? query(
          collection(db, 'referralVerifications'),
          where('referrerId', '==', referrerId),
          orderBy('createdAt', 'desc')
        )
      : null
  );

  // Log errors for debugging
  useEffect(() => {
    if (error) {
      console.error('[ReferredUsersTable] Query error:', error);
      console.error('Error details:', {
        message: error.message,
        code: (error as any).code,
        referrerId,
        query: 'referralVerifications where referrerId == ' + referrerId + ' orderBy createdAt desc',
      });
      // Check if error contains index creation link
      if ((error as any).code === 'failed-precondition') {
        console.error(
          '⚠️ Missing Firestore composite index! Check the browser console for the index creation link.'
        );
      }
    }
  }, [error, referrerId]);

  if (loading) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card className="border-destructive">
        <CardContent className="pt-6">
          <div className="flex items-center justify-center py-8 text-destructive">
            <AlertCircle className="h-5 w-5 mr-2" />
            <span>{t('modules.userManagement.referralDashboard.referredUsers.error')}</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  const referredUsers = snapshot?.docs || [];

  if (referredUsers.length === 0) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="text-center py-8">
            <User className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
            <h3 className="text-lg font-semibold mb-2">
              {t('modules.userManagement.referralDashboard.referredUsers.noUsers')}
            </h3>
            <p className="text-sm text-muted-foreground">
              {t('modules.userManagement.referralDashboard.referredUsers.noUsersDesc')}
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">
          {t('modules.userManagement.referralDashboard.referredUsers.title')}
        </CardTitle>
        <CardDescription>
          {t('modules.userManagement.referralDashboard.referredUsers.description', {
            count: referredUsers.length,
          })}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="border rounded-lg overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>
                  {t('modules.userManagement.referralDashboard.referredUsers.user')}
                </TableHead>
                <TableHead>
                  {t('modules.userManagement.referralDashboard.referredUsers.status')}
                </TableHead>
                <TableHead className="text-center">
                  {t('modules.userManagement.referralDashboard.referredUsers.fraudScore')}
                </TableHead>
                <TableHead>
                  {t('modules.userManagement.referralDashboard.referredUsers.joined')}
                </TableHead>
                <TableHead>
                  {t('modules.userManagement.referralDashboard.referredUsers.verified')}
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {referredUsers.map((doc) => (
                <ReferredUserRow key={doc.id} userId={doc.id} />
              ))}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}

