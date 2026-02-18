'use client';

import { useState, useMemo, useEffect } from 'react';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, where, orderBy, limit as firestoreLimit, doc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useTranslation } from '@/contexts/TranslationContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { 
  AlertTriangle, 
  RefreshCw, 
  CheckCircle, 
  XCircle, 
  Eye,
  Filter
} from 'lucide-react';
import { FraudDetailsModal } from './FraudDetailsModal';

interface FlaggedUser {
  userId: string;
  displayName?: string;
  email?: string;
  fraudScore: number;
  fraudFlags: string[];
  referrerId?: string;
  referrerName?: string;
  verificationStatus: string;
  signupDate: any;
  lastCheckedAt: any;
}

export function FraudQueueTable() {
  const { t } = useTranslation();
  const [selectedUsers, setSelectedUsers] = useState<Set<string>>(new Set());
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [scoreFilter, setScoreFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [isBulkApproving, setIsBulkApproving] = useState(false);
  const [isBulkBlocking, setIsBulkBlocking] = useState(false);
  const [usersData, setUsersData] = useState<Map<string, { displayName: string; email: string }>>(new Map());
  const [loadingUsers, setLoadingUsers] = useState(false);

  // Query for flagged users (fraud score >= 40)
  const [snapshot, loading, error] = useCollection(
    query(
      collection(db, 'referralVerifications'),
      where('fraudScore', '>=', 40),
      orderBy('fraudScore', 'desc'),
      firestoreLimit(100)
    )
  );

  // Fetch user data for each flagged user
  useEffect(() => {
    if (!snapshot) return;

    const fetchUsersData = async () => {
      setLoadingUsers(true);
      const userIds = snapshot.docs.map(doc => doc.id);
      const usersMap = new Map<string, { displayName: string; email: string }>();

      await Promise.all(
        userIds.map(async (userId) => {
          try {
            const userDoc = await getDoc(doc(db, 'users', userId));
            if (userDoc.exists()) {
              const userData = userDoc.data();
              usersMap.set(userId, {
                displayName: userData.displayName || userData.email || 'Unknown User',
                email: userData.email || ''
              });
            }
          } catch (err) {
            console.error(`Error fetching user ${userId}:`, err);
          }
        })
      );

      setUsersData(usersMap);
      setLoadingUsers(false);
    };

    fetchUsersData();
  }, [snapshot]);

  // Process and filter data
  const flaggedUsers = useMemo(() => {
    if (!snapshot) return [];

    let users = snapshot.docs.map(doc => {
      const data = doc.data();
      const userData = usersData.get(doc.id);
      
      return {
        userId: doc.id,
        displayName: userData?.displayName || 'Unknown User',
        email: userData?.email || '',
        fraudScore: data.fraudScore || 0,
        fraudFlags: data.fraudFlags || [],
        referrerId: data.referrerId || '',
        referrerName: data.referrerName || '',
        verificationStatus: data.verificationStatus || 'pending',
        signupDate: data.signupDate,
        lastCheckedAt: data.lastCheckedAt,
      } as FlaggedUser;
    });

    // Apply score filter
    if (scoreFilter !== 'all') {
      if (scoreFilter === 'medium') {
        users = users.filter(u => u.fraudScore >= 40 && u.fraudScore < 71);
      } else if (scoreFilter === 'high') {
        users = users.filter(u => u.fraudScore >= 71);
      }
    }

    // Apply status filter
    if (statusFilter !== 'all') {
      users = users.filter(u => u.verificationStatus === statusFilter);
    }

    return users;
  }, [snapshot, scoreFilter, statusFilter, usersData]);

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedUsers(new Set(flaggedUsers.map(u => u.userId)));
    } else {
      setSelectedUsers(new Set());
    }
  };

  const handleSelectUser = (userId: string, checked: boolean) => {
    const newSelected = new Set(selectedUsers);
    if (checked) {
      newSelected.add(userId);
    } else {
      newSelected.delete(userId);
    }
    setSelectedUsers(newSelected);
  };

  const handleViewDetails = (userId: string) => {
    setSelectedUserId(userId);
    setIsDetailsModalOpen(true);
  };

  const handleBulkApprove = async () => {
    if (selectedUsers.size === 0) return;

    const confirmed = window.confirm(
      `Are you sure you want to approve ${selectedUsers.size} user(s)? This will clear their fraud flags and mark them as verified.`
    );

    if (!confirmed) return;

    setIsBulkApproving(true);
    try {
      const response = await fetch('/api/admin/referrals/approve', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userIds: Array.from(selectedUsers),
          adminUid: 'admin', // TODO: Get from auth context
          reason: 'Bulk approval from fraud queue'
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to approve users');
      }

      const result = await response.json();
      alert(`Successfully approved ${result.approved} user(s). Failed: ${result.failed}`);
      
      // Clear selection
      setSelectedUsers(new Set());
    } catch (error) {
      console.error('Error bulk approving users:', error);
      alert('Failed to approve users. Please try again.');
    } finally {
      setIsBulkApproving(false);
    }
  };

  const handleBulkBlock = async () => {
    if (selectedUsers.size === 0) return;

    const reason = prompt(`Please provide a reason for blocking ${selectedUsers.size} user(s):`);
    if (!reason || reason.trim().length === 0) {
      alert('A reason is required to block users.');
      return;
    }

    const confirmed = window.confirm(
      `Are you sure you want to block ${selectedUsers.size} user(s)? This action cannot be easily undone.`
    );

    if (!confirmed) return;

    setIsBulkBlocking(true);
    try {
      const response = await fetch('/api/admin/referrals/block', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userIds: Array.from(selectedUsers),
          adminUid: 'admin', // TODO: Get from auth context
          reason: reason
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to block users');
      }

      const result = await response.json();
      alert(`Successfully blocked ${result.blocked} user(s). Failed: ${result.failed}`);
      
      // Clear selection
      setSelectedUsers(new Set());
    } catch (error) {
      console.error('Error bulk blocking users:', error);
      alert('Failed to block users. Please try again.');
    } finally {
      setIsBulkBlocking(false);
    }
  };

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

  if (loading || loadingUsers) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center py-12">
          <div className="text-center">
            <RefreshCw className="h-8 w-8 animate-spin mx-auto text-muted-foreground" />
            <p className="text-sm text-muted-foreground mt-4">
              {t('modules.userManagement.fraudQueue.loading')}
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center py-12">
          <div className="text-center">
            <AlertTriangle className="h-8 w-8 mx-auto text-red-600" />
            <h3 className="text-lg font-semibold mt-4">
              {t('modules.userManagement.fraudQueue.errorLoading')}
            </h3>
            <p className="text-sm text-muted-foreground mt-2">{error.message}</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <CardTitle className="flex items-center gap-2">
                <AlertTriangle className="h-5 w-5 text-orange-600" />
                {t('modules.userManagement.fraudQueue.title')}
              </CardTitle>
              <CardDescription className="mt-1">
                {t('modules.userManagement.fraudQueue.description')}
              </CardDescription>
            </div>
            
            {selectedUsers.size > 0 && (
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  className="gap-2"
                  onClick={handleBulkApprove}
                  disabled={isBulkApproving || isBulkBlocking}
                >
                  {isBulkApproving ? (
                    <RefreshCw className="h-4 w-4 animate-spin" />
                  ) : (
                    <CheckCircle className="h-4 w-4" />
                  )}
                  {t('modules.userManagement.fraudQueue.bulkApprove')} ({selectedUsers.size})
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  className="gap-2"
                  onClick={handleBulkBlock}
                  disabled={isBulkApproving || isBulkBlocking}
                >
                  {isBulkBlocking ? (
                    <RefreshCw className="h-4 w-4 animate-spin" />
                  ) : (
                    <XCircle className="h-4 w-4" />
                  )}
                  {t('modules.userManagement.fraudQueue.bulkBlock')} ({selectedUsers.size})
                </Button>
              </div>
            )}
          </div>

          {/* Filters */}
          <div className="flex flex-col sm:flex-row gap-4 mt-4">
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-muted-foreground" />
              <Select value={scoreFilter} onValueChange={setScoreFilter}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder={t('modules.userManagement.fraudQueue.filters.scoreRange')} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('modules.userManagement.fraudQueue.filters.allScores')}</SelectItem>
                  <SelectItem value="medium">{t('modules.userManagement.fraudQueue.filters.mediumRisk')}</SelectItem>
                  <SelectItem value="high">{t('modules.userManagement.fraudQueue.filters.highRisk')}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder={t('modules.userManagement.fraudQueue.filters.status')} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">{t('modules.userManagement.fraudQueue.filters.allStatuses')}</SelectItem>
                <SelectItem value="pending">{t('modules.userManagement.fraudQueue.filters.pending')}</SelectItem>
                <SelectItem value="blocked">{t('modules.userManagement.fraudQueue.filters.blocked')}</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>

        <CardContent>
          {flaggedUsers.length === 0 ? (
            <div className="text-center py-12">
              <CheckCircle className="h-12 w-12 mx-auto text-green-600" />
              <h3 className="text-lg font-semibold mt-4">
                {t('modules.userManagement.fraudQueue.noFlaggedUsers')}
              </h3>
              <p className="text-sm text-muted-foreground mt-2">
                {t('modules.userManagement.fraudQueue.noFlaggedUsersDesc')}
              </p>
            </div>
          ) : (
            <div className="rounded-md border overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-12">
                      <Checkbox
                        checked={selectedUsers.size === flaggedUsers.length && flaggedUsers.length > 0}
                        onCheckedChange={handleSelectAll}
                      />
                    </TableHead>
                    <TableHead>{t('modules.userManagement.fraudQueue.table.user')}</TableHead>
                    <TableHead>{t('modules.userManagement.fraudQueue.table.fraudScore')}</TableHead>
                    <TableHead>{t('modules.userManagement.fraudQueue.table.flags')}</TableHead>
                    <TableHead>{t('modules.userManagement.fraudQueue.table.referrer')}</TableHead>
                    <TableHead>{t('modules.userManagement.fraudQueue.table.status')}</TableHead>
                    <TableHead className="text-right">{t('modules.userManagement.fraudQueue.table.actions')}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {flaggedUsers.map((user) => (
                    <TableRow key={user.userId}>
                      <TableCell>
                        <Checkbox
                          checked={selectedUsers.has(user.userId)}
                          onCheckedChange={(checked) => handleSelectUser(user.userId, checked as boolean)}
                        />
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-col">
                          <span className="font-medium">{user.displayName}</span>
                          <span className="text-xs text-muted-foreground">{user.email}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Badge className={getFraudScoreBadgeColor(user.fraudScore)}>
                            {user.fraudScore}
                          </Badge>
                          <span className="text-sm text-muted-foreground">
                            {getFraudScoreLabel(user.fraudScore)}
                          </span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-1">
                          {user.fraudFlags.slice(0, 2).map((flag, idx) => (
                            <Badge key={idx} variant="outline" className="text-xs">
                              {flag.replace(/_/g, ' ')}
                            </Badge>
                          ))}
                          {user.fraudFlags.length > 2 && (
                            <Badge variant="outline" className="text-xs">
                              +{user.fraudFlags.length - 2}
                            </Badge>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="text-sm">{user.referrerName || user.referrerId || 'N/A'}</span>
                      </TableCell>
                      <TableCell>
                        <Badge variant={user.verificationStatus === 'blocked' ? 'destructive' : 'secondary'}>
                          {user.verificationStatus}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => handleViewDetails(user.userId)}
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Fraud Details Modal */}
      <FraudDetailsModal
        userId={selectedUserId}
        open={isDetailsModalOpen}
        onOpenChange={setIsDetailsModalOpen}
      />
    </>
  );
}

