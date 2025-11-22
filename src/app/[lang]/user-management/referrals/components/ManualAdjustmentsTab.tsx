'use client';

import { useState } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { 
  Search, 
  Award, 
  RefreshCw, 
  ShieldOff, 
  TrendingUp,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Loader2,
} from 'lucide-react';

interface UserSearchResult {
  userId: string;
  displayName: string;
  email: string;
  stats: any;
  verification: any;
}

type AdjustmentType = 'rewards' | 'verification' | 'fraud' | 'stats';

export function ManualAdjustmentsTab() {
  const { t } = useTranslation();
  
  // Search state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUser, setSelectedUser] = useState<UserSearchResult | null>(null);
  const [isSearching, setIsSearching] = useState(false);
  
  // Adjustment state
  const [adjustmentType, setAdjustmentType] = useState<AdjustmentType>('rewards');
  const [adjustmentValue, setAdjustmentValue] = useState('');
  const [reason, setReason] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);
  
  // Result state
  const [successMessage, setSuccessMessage] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  // Stats update fields (for manual stat correction)
  const [statsUpdates, setStatsUpdates] = useState({
    totalReferred: '',
    totalVerified: '',
    totalPending: '',
    totalBlocked: '',
    totalRewardsEarned: '',
  });

  const handleSearchUser = async () => {
    if (!searchQuery.trim()) return;
    
    setIsSearching(true);
    setErrorMessage('');
    setSuccessMessage('');
    
    try {
      const response = await fetch(
        `/api/admin/referrals/search?q=${encodeURIComponent(searchQuery)}&type=all`
      );
      
      if (!response.ok) throw new Error('Failed to search user');
      
      const data = await response.json();
      
      if (data.results && data.results.length > 0) {
        setSelectedUser(data.results[0]);
      } else {
        setErrorMessage(t('modules.userManagement.referralDashboard.manualAdjustments.userNotFound'));
      }
    } catch (error) {
      console.error('Search error:', error);
      setErrorMessage(t('modules.userManagement.referralDashboard.manualAdjustments.searchError'));
    } finally {
      setIsSearching(false);
    }
  };

  const handleConfirmAdjustment = () => {
    setShowConfirmDialog(true);
  };

  const handleSubmitAdjustment = async () => {
    if (!selectedUser || !reason.trim()) {
      setErrorMessage(t('modules.userManagement.referralDashboard.manualAdjustments.reasonRequired'));
      return;
    }

    setIsSubmitting(true);
    setErrorMessage('');
    setSuccessMessage('');
    setShowConfirmDialog(false);

    try {
      let endpoint = '';
      let body: any = {
        userId: selectedUser.userId,
        reason: reason.trim(),
        adminUid: 'admin', // TODO: Get actual admin UID from auth context
      };

      switch (adjustmentType) {
        case 'rewards':
          endpoint = '/api/admin/referrals/adjust-rewards';
          body.adjustmentDays = parseInt(adjustmentValue) || 0;
          break;
        
        case 'verification':
          endpoint = '/api/admin/referrals/reset-verification';
          break;
        
        case 'fraud':
          endpoint = '/api/admin/referrals/override-fraud';
          break;
        
        case 'stats':
          endpoint = '/api/admin/referrals/update-stats';
          const updates: any = {};
          if (statsUpdates.totalReferred) updates.totalReferred = parseInt(statsUpdates.totalReferred);
          if (statsUpdates.totalVerified) updates.totalVerified = parseInt(statsUpdates.totalVerified);
          if (statsUpdates.totalPending) updates.totalPending = parseInt(statsUpdates.totalPending);
          if (statsUpdates.totalBlocked) updates.totalBlocked = parseInt(statsUpdates.totalBlocked);
          if (statsUpdates.totalRewardsEarned) updates.totalRewardsEarned = parseInt(statsUpdates.totalRewardsEarned);
          body.updates = updates;
          break;
      }

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to apply adjustment');
      }

      setSuccessMessage(t('modules.userManagement.referralDashboard.manualAdjustments.adjustmentSuccess'));
      
      // Reset form
      setAdjustmentValue('');
      setReason('');
      setStatsUpdates({
        totalReferred: '',
        totalVerified: '',
        totalPending: '',
        totalBlocked: '',
        totalRewardsEarned: '',
      });
      
      // Refresh user data
      handleSearchUser();
    } catch (error) {
      console.error('Adjustment error:', error);
      setErrorMessage(error instanceof Error ? error.message : t('modules.userManagement.referralDashboard.manualAdjustments.adjustmentError'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const renderAdjustmentForm = () => {
    switch (adjustmentType) {
      case 'rewards':
        return (
          <div className="space-y-4">
            <div>
              <Label htmlFor="adjustmentValue">
                {t('modules.userManagement.referralDashboard.manualAdjustments.rewardDays')}
              </Label>
              <Input
                id="adjustmentValue"
                type="number"
                placeholder="e.g., 30 or -15"
                value={adjustmentValue}
                onChange={(e) => setAdjustmentValue(e.target.value)}
                className="mt-1"
              />
              <p className="text-sm text-muted-foreground mt-1">
                {t('modules.userManagement.referralDashboard.manualAdjustments.rewardDaysHint')}
              </p>
            </div>
          </div>
        );
      
      case 'verification':
        return (
          <Alert>
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>
              {t('modules.userManagement.referralDashboard.manualAdjustments.verificationResetWarning')}
            </AlertDescription>
          </Alert>
        );
      
      case 'fraud':
        return (
          <Alert>
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>
              {t('modules.userManagement.referralDashboard.manualAdjustments.fraudOverrideWarning')}
            </AlertDescription>
          </Alert>
        );
      
      case 'stats':
        return (
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              {t('modules.userManagement.referralDashboard.manualAdjustments.statsUpdateHint')}
            </p>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <Label htmlFor="totalReferred">
                  {t('modules.userManagement.referralDashboard.manualAdjustments.totalReferred')}
                </Label>
                <Input
                  id="totalReferred"
                  type="number"
                  value={statsUpdates.totalReferred}
                  onChange={(e) => setStatsUpdates({ ...statsUpdates, totalReferred: e.target.value })}
                  placeholder={selectedUser?.stats?.totalReferred?.toString() || '0'}
                  className="mt-1"
                />
              </div>
              <div>
                <Label htmlFor="totalVerified">
                  {t('modules.userManagement.referralDashboard.manualAdjustments.totalVerified')}
                </Label>
                <Input
                  id="totalVerified"
                  type="number"
                  value={statsUpdates.totalVerified}
                  onChange={(e) => setStatsUpdates({ ...statsUpdates, totalVerified: e.target.value })}
                  placeholder={selectedUser?.stats?.totalVerified?.toString() || '0'}
                  className="mt-1"
                />
              </div>
              <div>
                <Label htmlFor="totalPending">
                  {t('modules.userManagement.referralDashboard.manualAdjustments.totalPending')}
                </Label>
                <Input
                  id="totalPending"
                  type="number"
                  value={statsUpdates.totalPending}
                  onChange={(e) => setStatsUpdates({ ...statsUpdates, totalPending: e.target.value })}
                  placeholder={selectedUser?.stats?.totalPending?.toString() || '0'}
                  className="mt-1"
                />
              </div>
              <div>
                <Label htmlFor="totalBlocked">
                  {t('modules.userManagement.referralDashboard.manualAdjustments.totalBlocked')}
                </Label>
                <Input
                  id="totalBlocked"
                  type="number"
                  value={statsUpdates.totalBlocked}
                  onChange={(e) => setStatsUpdates({ ...statsUpdates, totalBlocked: e.target.value })}
                  placeholder={selectedUser?.stats?.totalBlocked?.toString() || '0'}
                  className="mt-1"
                />
              </div>
              <div>
                <Label htmlFor="totalRewardsEarned">
                  {t('modules.userManagement.referralDashboard.manualAdjustments.totalRewards')}
                </Label>
                <Input
                  id="totalRewardsEarned"
                  type="number"
                  value={statsUpdates.totalRewardsEarned}
                  onChange={(e) => setStatsUpdates({ ...statsUpdates, totalRewardsEarned: e.target.value })}
                  placeholder={selectedUser?.stats?.totalRewardsEarned?.toString() || '0'}
                  className="mt-1"
                />
              </div>
            </div>
          </div>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h3 className="text-lg font-semibold">
          {t('modules.userManagement.referralDashboard.manualAdjustments.title')}
        </h3>
        <p className="text-sm text-muted-foreground mt-1">
          {t('modules.userManagement.referralDashboard.manualAdjustments.description')}
        </p>
      </div>

      {/* Search User */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.userManagement.referralDashboard.manualAdjustments.searchUser')}</CardTitle>
          <CardDescription>
            {t('modules.userManagement.referralDashboard.manualAdjustments.searchUserDesc')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex gap-2">
            <Input
              placeholder={t('modules.userManagement.referralDashboard.manualAdjustments.searchPlaceholder')}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearchUser()}
            />
            <Button onClick={handleSearchUser} disabled={isSearching || !searchQuery.trim()}>
              {isSearching ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Search className="h-4 w-4" />
              )}
            </Button>
          </div>

          {/* Selected User Card */}
          {selectedUser && (
            <div className="mt-4 p-4 border rounded-lg bg-muted/30">
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium">{selectedUser.displayName}</p>
                  <p className="text-sm text-muted-foreground">{selectedUser.email}</p>
                  <p className="text-xs text-muted-foreground mt-1">ID: {selectedUser.userId}</p>
                </div>
                <div className="text-right text-sm">
                  <p>
                    <Badge variant="secondary">
                      {t('modules.userManagement.referralDashboard.manualAdjustments.referred')}: {selectedUser.stats?.totalReferred || 0}
                    </Badge>
                  </p>
                  <p className="mt-1">
                    <Badge variant="secondary">
                      {t('modules.userManagement.referralDashboard.manualAdjustments.verified')}: {selectedUser.stats?.totalVerified || 0}
                    </Badge>
                  </p>
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Adjustment Form */}
      {selectedUser && (
        <Card>
          <CardHeader>
            <CardTitle>{t('modules.userManagement.referralDashboard.manualAdjustments.selectAction')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Adjustment Type Selector */}
            <div>
              <Label htmlFor="adjustmentType">
                {t('modules.userManagement.referralDashboard.manualAdjustments.actionType')}
              </Label>
              <Select value={adjustmentType} onValueChange={(value) => setAdjustmentType(value as AdjustmentType)}>
                <SelectTrigger className="mt-1">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="rewards">
                    <div className="flex items-center gap-2">
                      <Award className="h-4 w-4" />
                      {t('modules.userManagement.referralDashboard.manualAdjustments.adjustRewards')}
                    </div>
                  </SelectItem>
                  <SelectItem value="verification">
                    <div className="flex items-center gap-2">
                      <RefreshCw className="h-4 w-4" />
                      {t('modules.userManagement.referralDashboard.manualAdjustments.resetVerification')}
                    </div>
                  </SelectItem>
                  <SelectItem value="fraud">
                    <div className="flex items-center gap-2">
                      <ShieldOff className="h-4 w-4" />
                      {t('modules.userManagement.referralDashboard.manualAdjustments.overrideFraud')}
                    </div>
                  </SelectItem>
                  <SelectItem value="stats">
                    <div className="flex items-center gap-2">
                      <TrendingUp className="h-4 w-4" />
                      {t('modules.userManagement.referralDashboard.manualAdjustments.updateStats')}
                    </div>
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Adjustment-specific form */}
            {renderAdjustmentForm()}

            {/* Reason */}
            <div>
              <Label htmlFor="reason">
                {t('modules.userManagement.referralDashboard.manualAdjustments.reason')} *
              </Label>
              <Textarea
                id="reason"
                placeholder={t('modules.userManagement.referralDashboard.manualAdjustments.reasonPlaceholder')}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                className="mt-1"
                rows={3}
              />
            </div>

            {/* Messages */}
            {successMessage && (
              <Alert className="bg-green-50 dark:bg-green-950 border-green-200 dark:border-green-900">
                <CheckCircle className="h-4 w-4 text-green-600 dark:text-green-400" />
                <AlertDescription className="text-green-800 dark:text-green-200">
                  {successMessage}
                </AlertDescription>
              </Alert>
            )}

            {errorMessage && (
              <Alert variant="destructive">
                <XCircle className="h-4 w-4" />
                <AlertDescription>{errorMessage}</AlertDescription>
              </Alert>
            )}

            {/* Submit Button */}
            <Button
              onClick={handleConfirmAdjustment}
              disabled={isSubmitting || !reason.trim()}
              className="w-full"
            >
              {isSubmitting && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              {t('modules.userManagement.referralDashboard.manualAdjustments.applyAdjustment')}
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Confirmation Dialog */}
      <Dialog open={showConfirmDialog} onOpenChange={setShowConfirmDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {t('modules.userManagement.referralDashboard.manualAdjustments.confirmTitle')}
            </DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.referralDashboard.manualAdjustments.confirmDescription')}
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <p className="text-sm">
              <strong>{t('modules.userManagement.referralDashboard.manualAdjustments.user')}:</strong>{' '}
              {selectedUser?.displayName} ({selectedUser?.email})
            </p>
            <p className="text-sm mt-2">
              <strong>{t('modules.userManagement.referralDashboard.manualAdjustments.action')}:</strong>{' '}
              {adjustmentType}
            </p>
            <p className="text-sm mt-2">
              <strong>{t('modules.userManagement.referralDashboard.manualAdjustments.reason')}:</strong>{' '}
              {reason}
            </p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowConfirmDialog(false)}>
              {t('modules.userManagement.referralDashboard.manualAdjustments.cancel')}
            </Button>
            <Button onClick={handleSubmitAdjustment} disabled={isSubmitting}>
              {isSubmitting && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              {t('modules.userManagement.referralDashboard.manualAdjustments.confirm')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

