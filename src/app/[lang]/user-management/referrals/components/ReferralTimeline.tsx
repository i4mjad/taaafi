'use client';

import { useEffect, useState } from 'react';
import { useDocument, useCollection } from 'react-firebase-hooks/firestore';
import { collection, doc, query, where, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useTranslation } from '@/contexts/TranslationContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
  UserPlus,
  CheckCircle,
  AlertCircle,
  Award,
  ShieldAlert,
  Clock,
  Loader2,
  TrendingUp,
} from 'lucide-react';

interface ReferralTimelineProps {
  userId: string;
}

interface TimelineEvent {
  id: string;
  type: 'signup' | 'verification' | 'reward' | 'fraud' | 'referral_made';
  title: string;
  description: string;
  timestamp: Date;
  icon: React.ReactNode;
  color: string;
}

export function ReferralTimeline({ userId }: ReferralTimelineProps) {
  const { t } = useTranslation();
  const [events, setEvents] = useState<TimelineEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch user data
  const [userSnapshot] = useDocument(doc(db, 'users', userId));

  // Fetch referral stats
  const [statsSnapshot] = useDocument(doc(db, 'referralStats', userId));

  // Fetch referral verification
  const [verificationSnapshot] = useDocument(doc(db, 'referralVerifications', userId));

  // Fetch fraud logs for this user
  // Note: Requires composite index: referralFraudLogs (userId Ascending, timestamp Descending)
  const [fraudLogsSnapshot, fraudLogsLoading, fraudLogsError] = useCollection(
    userId
      ? query(
          collection(db, 'referralFraudLogs'),
          where('userId', '==', userId),
          orderBy('timestamp', 'desc'),
          limit(10)
        )
      : null
  );

  // Fetch referred users (to show when they signed up)
  // Note: Requires composite index: referralVerifications (referrerId Ascending, createdAt Descending)
  const [referredUsersSnapshot, referredUsersLoading, referredUsersError] = useCollection(
    userId
      ? query(
          collection(db, 'referralVerifications'),
          where('referrerId', '==', userId),
          orderBy('createdAt', 'desc'),
          limit(10)
        )
      : null
  );

  // Log errors for debugging
  useEffect(() => {
    if (fraudLogsError) {
      console.error('[ReferralTimeline] Fraud logs query error:', fraudLogsError);
      console.error('Error details:', {
        message: fraudLogsError.message,
        code: (fraudLogsError as any).code,
        userId,
      });
    }
    if (referredUsersError) {
      console.error('[ReferralTimeline] Referred users query error:', referredUsersError);
      console.error('Error details:', {
        message: referredUsersError.message,
        code: (referredUsersError as any).code,
        userId,
      });
    }
  }, [fraudLogsError, referredUsersError, userId]);

  useEffect(() => {
    const buildTimeline = () => {
      const timelineEvents: TimelineEvent[] = [];

      // Add signup event
      if (userSnapshot?.data()?.createdAt) {
        const createdAt = userSnapshot.data()?.createdAt?.toDate();
        timelineEvents.push({
          id: 'signup',
          type: 'signup',
          title: t('modules.userManagement.referralDashboard.timeline.userSignedUp'),
          description: t('modules.userManagement.referralDashboard.timeline.userJoinedPlatform'),
          timestamp: createdAt,
          icon: <UserPlus className="h-4 w-4" />,
          color: 'bg-blue-500',
        });
      }

      // Add verification events
      const verificationData = verificationSnapshot?.data();
      if (verificationData) {
        if (verificationData.verifiedAt) {
          const verifiedAt = verificationData.verifiedAt?.toDate();
          timelineEvents.push({
            id: 'verified',
            type: 'verification',
            title: t('modules.userManagement.referralDashboard.timeline.verified'),
            description: t('modules.userManagement.referralDashboard.timeline.verifiedDesc'),
            timestamp: verifiedAt,
            icon: <CheckCircle className="h-4 w-4" />,
            color: 'bg-green-500',
          });
        }

        if (verificationData.isBlocked && verificationData.blockedAt) {
          const blockedAt = verificationData.blockedAt?.toDate();
          timelineEvents.push({
            id: 'blocked',
            type: 'fraud',
            title: t('modules.userManagement.referralDashboard.timeline.blocked'),
            description:
              verificationData.blockedReason ||
              t('modules.userManagement.referralDashboard.timeline.blockedDesc'),
            timestamp: blockedAt,
            icon: <ShieldAlert className="h-4 w-4" />,
            color: 'bg-red-500',
          });
        }
      }

      // Add fraud log events
      fraudLogsSnapshot?.docs.forEach((doc) => {
        const logData = doc.data();
        const timestamp = logData.timestamp?.toDate();
        if (timestamp) {
          timelineEvents.push({
            id: doc.id,
            type: 'fraud',
            title:
              logData.action === 'approved'
                ? t('modules.userManagement.referralDashboard.timeline.adminApproved')
                : t('modules.userManagement.referralDashboard.timeline.adminBlocked'),
            description:
              logData.reason || t('modules.userManagement.referralDashboard.timeline.adminAction'),
            timestamp,
            icon: <ShieldAlert className="h-4 w-4" />,
            color: logData.action === 'approved' ? 'bg-green-500' : 'bg-red-500',
          });
        }
      });

      // Add referral made events
      referredUsersSnapshot?.docs.forEach((doc) => {
        const refData = doc.data();
        const timestamp = refData.createdAt?.toDate();
        if (timestamp) {
          timelineEvents.push({
            id: `referred-${doc.id}`,
            type: 'referral_made',
            title: t('modules.userManagement.referralDashboard.timeline.referredUser'),
            description: t('modules.userManagement.referralDashboard.timeline.referredUserDesc', {
              userId: doc.id.substring(0, 8),
            }),
            timestamp,
            icon: <TrendingUp className="h-4 w-4" />,
            color: 'bg-purple-500',
          });
        }
      });

      // Sort by timestamp (newest first)
      timelineEvents.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());

      setEvents(timelineEvents);
      setIsLoading(false);
    };

    // Only build timeline if all queries are loaded (or errored)
    const allQueriesReady =
      userSnapshot !== undefined &&
      statsSnapshot !== undefined &&
      verificationSnapshot !== undefined &&
      (fraudLogsSnapshot !== undefined || fraudLogsError) &&
      (referredUsersSnapshot !== undefined || referredUsersError);

    if (allQueriesReady) {
      buildTimeline();
    }
  }, [
    userSnapshot,
    statsSnapshot,
    verificationSnapshot,
    fraudLogsSnapshot,
    referredUsersSnapshot,
    t,
  ]);

  // Show error if queries failed
  if (fraudLogsError || referredUsersError) {
    return (
      <Card className="border-destructive">
        <CardContent className="pt-6">
          <div className="text-center py-8">
            <AlertCircle className="h-12 w-12 mx-auto text-destructive mb-4" />
            <h3 className="text-lg font-semibold mb-2 text-destructive">
              {t('modules.userManagement.referralDashboard.timeline.error')}
            </h3>
            <p className="text-sm text-muted-foreground mb-4">
              {fraudLogsError?.message || referredUsersError?.message}
            </p>
            <p className="text-xs text-muted-foreground">
              {t('modules.userManagement.referralDashboard.timeline.errorHint')}
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (isLoading) {
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

  if (events.length === 0) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="text-center py-8">
            <Clock className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
            <h3 className="text-lg font-semibold mb-2">
              {t('modules.userManagement.referralDashboard.timeline.noEvents')}
            </h3>
            <p className="text-sm text-muted-foreground">
              {t('modules.userManagement.referralDashboard.timeline.noEventsDesc')}
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  const formatTimestamp = (date: Date) => {
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">
          {t('modules.userManagement.referralDashboard.timeline.title')}
        </CardTitle>
        <CardDescription>
          {t('modules.userManagement.referralDashboard.timeline.description')}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="relative space-y-4">
          {/* Timeline line */}
          <div className="absolute left-[21px] top-0 bottom-0 w-0.5 bg-border" />

          {events.map((event, index) => (
            <div key={event.id} className="relative flex gap-4">
              {/* Icon */}
              <div
                className={`relative z-10 flex h-10 w-10 items-center justify-center rounded-full ${event.color} text-white shrink-0`}
              >
                {event.icon}
              </div>

              {/* Content */}
              <div className="flex-1 pb-4">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1">
                    <h4 className="font-semibold text-sm">{event.title}</h4>
                    <p className="text-sm text-muted-foreground mt-1">{event.description}</p>
                  </div>
                  <span className="text-xs text-muted-foreground whitespace-nowrap">
                    {formatTimestamp(event.timestamp)}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

