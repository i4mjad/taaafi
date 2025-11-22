'use client';

import { useMemo, useState } from 'react';
import { useDocument } from 'react-firebase-hooks/firestore';
import { doc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useTranslation } from '@/contexts/TranslationContext';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Separator } from '@/components/ui/separator';
import { 
  AlertTriangle, 
  CheckCircle, 
  XCircle, 
  RefreshCw,
  Shield,
  User,
  Calendar,
  AlertCircle
} from 'lucide-react';
import { format } from 'date-fns';

interface FraudDetailsModalProps {
  userId: string | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

interface FraudCheckDetail {
  checkName: string;
  score: number;
  flag: string | null;
  description: string;
}

export function FraudDetailsModal({ userId, open, onOpenChange }: FraudDetailsModalProps) {
  const { t } = useTranslation();

  // Fetch verification document
  const [verificationSnapshot, verificationLoading, verificationError] = useDocument(
    userId ? doc(db, 'referralVerifications', userId) : null
  );

  // Fetch user document for additional details
  const [userSnapshot, userLoading] = useDocument(
    userId ? doc(db, 'users', userId) : null
  );

  const verificationData = verificationSnapshot?.data();
  const userData = userSnapshot?.data();

  // Parse fraud flags into detailed checks
  const fraudChecks = useMemo<FraudCheckDetail[]>(() => {
    if (!verificationData) return [];

    const checks: FraudCheckDetail[] = [];
    const flags = verificationData.fraudFlags || [];

    // Map flags to check details (based on Sprint 06 implementation)
    if (flags.includes('device_overlap')) {
      checks.push({
        checkName: 'Device Overlap',
        score: 50,
        flag: 'device_overlap',
        description: 'Same device ID detected between referee and referrer'
      });
    }

    if (flags.includes('interaction_concentration')) {
      checks.push({
        checkName: 'Interaction Concentration',
        score: 40,
        flag: 'interaction_concentration',
        description: 'High interactions with few unique users'
      });
    }

    if (flags.includes('rapid_group_messaging')) {
      checks.push({
        checkName: 'Rapid Group Messaging',
        score: 30,
        flag: 'rapid_group_messaging',
        description: 'Sending group messages too quickly'
      });
    }

    if (flags.includes('activity_burst')) {
      checks.push({
        checkName: 'Activity Burst',
        score: 30,
        flag: 'activity_burst',
        description: 'High activity in new account (< 24 hours)'
      });
    }

    if (flags.includes('rapid_posting')) {
      checks.push({
        checkName: 'Rapid Posting',
        score: 25,
        flag: 'rapid_posting',
        description: 'Forum posts created too quickly (< 2 min avg)'
      });
    }

    if (flags.includes('low_content_quality')) {
      checks.push({
        checkName: 'Low Content Quality',
        score: 20,
        flag: 'low_content_quality',
        description: 'Forum posts have low word count (< 10 words avg)'
      });
    }

    if (flags.includes('gmail_alias')) {
      checks.push({
        checkName: 'Gmail Alias',
        score: 10,
        flag: 'gmail_alias',
        description: 'Email uses Gmail alias pattern (user+1@gmail.com)'
      });
    }

    if (flags.includes('needs_manual_review')) {
      checks.push({
        checkName: 'Manual Review Required',
        score: 0,
        flag: 'needs_manual_review',
        description: 'Flagged for manual admin review'
      });
    }

    return checks;
  }, [verificationData]);

  const [isApproving, setIsApproving] = useState(false);
  const [isBlocking, setIsBlocking] = useState(false);

  const handleApprove = async () => {
    if (!userId) return;
    
    setIsApproving(true);
    try {
      const response = await fetch('/api/admin/referrals/approve', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userIds: [userId],
          adminUid: 'admin', // TODO: Get from auth context
          reason: 'Admin manual approval from fraud queue'
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to approve user');
      }

      // Close modal and refresh data
      onOpenChange(false);
      // The parent component should refetch data automatically via react-firebase-hooks
    } catch (error) {
      console.error('Error approving user:', error);
      alert('Failed to approve user. Please try again.');
    } finally {
      setIsApproving(false);
    }
  };

  const handleBlock = async () => {
    if (!userId) return;

    const reason = prompt('Please provide a reason for blocking this user:');
    if (!reason || reason.trim().length === 0) {
      alert('A reason is required to block a user.');
      return;
    }
    
    setIsBlocking(true);
    try {
      const response = await fetch('/api/admin/referrals/block', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userIds: [userId],
          adminUid: 'admin', // TODO: Get from auth context
          reason: reason
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to block user');
      }

      // Close modal and refresh data
      onOpenChange(false);
      // The parent component should refetch data automatically via react-firebase-hooks
    } catch (error) {
      console.error('Error blocking user:', error);
      alert('Failed to block user. Please try again.');
    } finally {
      setIsBlocking(false);
    }
  };

  if (!userId) return null;

  const loading = verificationLoading || userLoading;
  const fraudScore = verificationData?.fraudScore || 0;
  const verificationStatus = verificationData?.verificationStatus || 'pending';

  const getFraudScoreBadgeColor = (score: number) => {
    if (score >= 71) return 'bg-red-600 text-white';
    if (score >= 40) return 'bg-orange-600 text-white';
    return 'bg-green-600 text-white';
  };

  const getFraudScoreLabel = (score: number) => {
    if (score >= 71) return t('modules.userManagement.fraudQueue.riskLevels.high');
    if (score >= 40) return t('modules.userManagement.fraudQueue.riskLevels.medium');
    return t('modules.userManagement.fraudQueue.riskLevels.low');
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5 text-orange-600" />
            {t('modules.userManagement.fraudQueue.detailsModal.title')}
          </DialogTitle>
          <DialogDescription>
            {t('modules.userManagement.fraudQueue.detailsModal.description')}
          </DialogDescription>
        </DialogHeader>

        {loading ? (
          <div className="flex items-center justify-center py-12">
            <RefreshCw className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        ) : verificationError ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <AlertTriangle className="h-8 w-8 mx-auto text-red-600" />
              <p className="text-sm text-muted-foreground mt-4">{verificationError.message}</p>
            </div>
          </div>
        ) : (
          <div className="space-y-6">
            {/* User Information */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <User className="h-4 w-4" />
                  {t('modules.userManagement.fraudQueue.detailsModal.userInfo')}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">
                      {t('modules.userManagement.fraudQueue.detailsModal.displayName')}
                    </p>
                    <p className="text-sm">{userData?.displayName || verificationData?.displayName || 'Unknown'}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">
                      {t('modules.userManagement.fraudQueue.detailsModal.email')}
                    </p>
                    <p className="text-sm">{userData?.email || verificationData?.email || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">
                      {t('modules.userManagement.fraudQueue.detailsModal.signupDate')}
                    </p>
                    <p className="text-sm">
                      {verificationData?.signupDate?.toDate ? 
                        format(verificationData.signupDate.toDate(), 'PPP') : 
                        'N/A'
                      }
                    </p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">
                      {t('modules.userManagement.fraudQueue.detailsModal.status')}
                    </p>
                    <Badge variant={verificationStatus === 'blocked' ? 'destructive' : 'secondary'}>
                      {verificationStatus}
                    </Badge>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Fraud Score Overview */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base">
                  <AlertCircle className="h-4 w-4" />
                  {t('modules.userManagement.fraudQueue.detailsModal.fraudScore')}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-3">
                      <Badge className={`${getFraudScoreBadgeColor(fraudScore)} text-2xl px-4 py-2`}>
                        {fraudScore}
                      </Badge>
                      <div>
                        <p className="font-semibold">{getFraudScoreLabel(fraudScore)}</p>
                        <p className="text-sm text-muted-foreground">
                          {t('modules.userManagement.fraudQueue.detailsModal.scoreOutOf100')}
                        </p>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-muted-foreground">
                      {t('modules.userManagement.fraudQueue.detailsModal.lastChecked')}
                    </p>
                    <p className="text-sm">
                      {verificationData?.lastCheckedAt?.toDate ? 
                        format(verificationData.lastCheckedAt.toDate(), 'PPp') : 
                        'N/A'
                      }
                    </p>
                  </div>
                </div>

                {/* Threshold indicators */}
                <div className="mt-4 space-y-2">
                  <div className="flex items-center gap-2 text-sm">
                    <div className="w-3 h-3 rounded-full bg-green-600" />
                    <span className="text-muted-foreground">
                      {t('modules.userManagement.fraudQueue.detailsModal.lowRiskThreshold')}
                    </span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <div className="w-3 h-3 rounded-full bg-orange-600" />
                    <span className="text-muted-foreground">
                      {t('modules.userManagement.fraudQueue.detailsModal.mediumRiskThreshold')}
                    </span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <div className="w-3 h-3 rounded-full bg-red-600" />
                    <span className="text-muted-foreground">
                      {t('modules.userManagement.fraudQueue.detailsModal.highRiskThreshold')}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Fraud Check Breakdown */}
            <Card>
              <CardHeader>
                <CardTitle className="text-base">
                  {t('modules.userManagement.fraudQueue.detailsModal.checkBreakdown')}
                </CardTitle>
                <CardDescription>
                  {t('modules.userManagement.fraudQueue.detailsModal.checkBreakdownDesc')}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {fraudChecks.length === 0 ? (
                  <div className="text-center py-8">
                    <CheckCircle className="h-8 w-8 mx-auto text-green-600" />
                    <p className="text-sm text-muted-foreground mt-2">
                      {t('modules.userManagement.fraudQueue.detailsModal.noFlagsDetected')}
                    </p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {fraudChecks.map((check, idx) => (
                      <div key={idx} className="flex items-start gap-3 p-3 rounded-lg border">
                        <AlertTriangle className="h-5 w-5 text-orange-600 flex-shrink-0 mt-0.5" />
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <p className="font-medium text-sm">{check.checkName}</p>
                            {check.score > 0 && (
                              <Badge variant="outline" className="text-xs">
                                +{check.score} {t('modules.userManagement.fraudQueue.detailsModal.points')}
                              </Badge>
                            )}
                          </div>
                          <p className="text-sm text-muted-foreground mt-1">{check.description}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Referrer Information */}
            {verificationData?.referrerId && (
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">
                    {t('modules.userManagement.fraudQueue.detailsModal.referrerInfo')}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-sm font-medium text-muted-foreground">
                        {t('modules.userManagement.fraudQueue.detailsModal.referrerId')}
                      </p>
                      <p className="text-sm font-mono">{verificationData.referrerId}</p>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-muted-foreground">
                        {t('modules.userManagement.fraudQueue.detailsModal.referralCode')}
                      </p>
                      <p className="text-sm font-mono">{verificationData.referralCode || 'N/A'}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}
          </div>
        )}

        <DialogFooter>
          <div className="flex flex-col sm:flex-row gap-2 w-full sm:w-auto">
            <Button
              variant="outline"
              onClick={() => onOpenChange(false)}
              className="w-full sm:w-auto"
            >
              {t('modules.userManagement.fraudQueue.detailsModal.close')}
            </Button>
            {verificationStatus !== 'blocked' && (
              <>
                <Button
                  variant="default"
                  onClick={handleApprove}
                  disabled={loading || isApproving || isBlocking}
                  className="w-full sm:w-auto"
                >
                  {isApproving ? (
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  ) : (
                    <CheckCircle className="h-4 w-4 mr-2" />
                  )}
                  {t('modules.userManagement.fraudQueue.detailsModal.approve')}
                </Button>
                <Button
                  variant="destructive"
                  onClick={handleBlock}
                  disabled={loading || isApproving || isBlocking}
                  className="w-full sm:w-auto"
                >
                  {isBlocking ? (
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  ) : (
                    <XCircle className="h-4 w-4 mr-2" />
                  )}
                  {t('modules.userManagement.fraudQueue.detailsModal.block')}
                </Button>
              </>
            )}
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

