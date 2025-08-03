'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';

import { Separator } from '@/components/ui/separator';

import {
  AlertTriangle,
  CheckCircle,
  Clock,
  User,
  Shield,
  FileText,
  Trash2,
  MessageSquare,
  X,
  Loader2,
} from 'lucide-react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useDeletionRequests, useUserDeletion } from '@/hooks/useDeletionRequests';
import { toast } from 'sonner';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Progress } from '@/components/ui/progress';
import { 
  collection, 
  doc,
  setDoc,
  serverTimestamp
} from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface DeletionManagementCardProps {
  userId: string;
  userDisplayName?: string;
  userEmail?: string;
}

export default function DeletionManagementCard({ 
  userId, 
  userDisplayName, 
  userEmail 
}: DeletionManagementCardProps) {
  const { t, locale } = useTranslation();
  const { 
    deletionRequests, 
    loading, 
    error, 
    processing: requestProcessing,
    approveRequest,
    rejectRequest,
    updateAdminNotes
  } = useDeletionRequests(userId);
  
  const { executeUserDeletion, processing: deletionProcessing, progress } = useUserDeletion();

  // Minimal logging for errors only
  if (error) {
    console.error('DeletionManagementCard Error:', error.message);
  }

  const [adminNotes, setAdminNotes] = useState('');
  const [showApproveDialog, setShowApproveDialog] = useState(false);
  const [showRejectDialog, setShowRejectDialog] = useState(false);
  const [showNotesDialog, setShowNotesDialog] = useState(false);
  const [showForceDeleteDialog, setShowForceDeleteDialog] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState<any>(null);
  const [forceDeleteReason, setForceDeleteReason] = useState('');

  const formatDate = (date: Date | string | null | undefined) => {
    if (!date) return t('common.never') || 'Never';
    
    const dateObj = date instanceof Date ? date : new Date(date);
    
    if (isNaN(dateObj.getTime())) {
      return t('common.unknown') || 'Unknown';
    }
    
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      calendar: 'gregory',
    }).format(dateObj);
  };

  const getStatusBadge = (request: any) => {
    if (request.isCanceled) {
      return (
        <Badge variant="outline" className="text-gray-600">
          <X className="h-3 w-3 mr-1" />
          {t('modules.userManagement.accountDeletion.isCanceled') || 'Canceled'}
        </Badge>
      );
    }
    
    if (request.isProcessed) {
      return (
        <Badge variant="default" className="text-green-600 bg-green-50 border-green-200">
          <CheckCircle className="h-3 w-3 mr-1" />
          {t('modules.userManagement.accountDeletion.isProcessed') || 'Processed'}
        </Badge>
      );
    }
    
    return (
      <Badge variant="outline" className="text-orange-600 bg-orange-50 border-orange-200">
        <Clock className="h-3 w-3 mr-1" />
        {t('modules.userManagement.accountDeletion.pendingDeletion') || 'Pending'}
      </Badge>
    );
  };

  const getReasonLabel = (reasonId: string) => {
    return t(`modules.userManagement.accountDeletion.reasons.${reasonId}`) || reasonId;
  };

  const getCategoryLabel = (category: string) => {
    return t(`modules.userManagement.accountDeletion.categories.${category}`) || category;
  };

  const handleApprove = (request: any) => {
    console.log('🟢 Approve button clicked for request:', request.id);
    setSelectedRequest(request);
    setAdminNotes(request.adminNotes || '');
    setShowApproveDialog(true);
  };

  const handleReject = (request: any) => {
    setSelectedRequest(request);
    setAdminNotes(request.adminNotes || '');
    setShowRejectDialog(true);
  };

  const handleAddNotes = (request: any) => {
    setSelectedRequest(request);
    setAdminNotes(request.adminNotes || '');
    setShowNotesDialog(true);
  };

  const confirmApproval = async () => {
    if (!selectedRequest) return;
    
    console.log('🚀 Starting approval process for request:', selectedRequest.id);
    
    try {
      // First approve the request
      console.log('📝 Approving request...');
      await approveRequest(selectedRequest.id, adminNotes, 'admin-user');
      
      // Then execute the actual deletion
      console.log('🗑️ Executing user deletion...');
      await executeUserDeletion(userId, 'admin-user');
      
      console.log('✅ Deletion completed successfully');
      toast.success(t('modules.userManagement.accountDeletion.approveSuccess') || 'Deletion request approved and user deleted successfully');
      setShowApproveDialog(false);
      setSelectedRequest(null);
      setAdminNotes('');
    } catch (error: any) {
      console.error('❌ Error approving deletion:', error);
      
      // Check if rollback occurred
      if (error?.message?.includes('Rollback completed successfully')) {
        toast.warning(t('modules.userManagement.accountDeletion.rollbackSuccess') || 'Rollback completed successfully - user data restored');
      } else if (error?.message?.includes('Rollback failed')) {
        toast.error(t('modules.userManagement.accountDeletion.rollbackFailed') || 'Rollback failed - manual intervention may be required');
      } else if (error?.message?.includes('Rollback not possible')) {
        toast.error(t('modules.userManagement.accountDeletion.rollbackNotPossible') || 'Rollback not possible - some operations cannot be undone');
      } else {
        toast.error(t('modules.userManagement.accountDeletion.approveError') || 'Failed to approve deletion request');
      }
    }
  };

  const confirmRejection = async () => {
    if (!selectedRequest) return;
    
    try {
      await rejectRequest(selectedRequest.id, adminNotes, 'admin-user');
      toast.success(t('modules.userManagement.accountDeletion.rejectSuccess') || 'Deletion request rejected successfully');
      setShowRejectDialog(false);
      setSelectedRequest(null);
      setAdminNotes('');
    } catch (error) {
      console.error('Error rejecting deletion:', error);
      toast.error(t('modules.userManagement.accountDeletion.rejectError') || 'Failed to reject deletion request');
    }
  };

  const saveNotes = async () => {
    if (!selectedRequest) return;
    
    try {
      await updateAdminNotes(selectedRequest.id, adminNotes, 'admin-user');
      toast.success(t('modules.userManagement.accountDeletion.notesUpdateSuccess') || 'Admin notes updated successfully');
      setShowNotesDialog(false);
      setSelectedRequest(null);
      setAdminNotes('');
    } catch (error) {
      console.error('Error updating notes:', error);
      toast.error(t('modules.userManagement.accountDeletion.notesUpdateError') || 'Failed to update admin notes');
    }
  };

  const handleForceDelete = () => {
    console.log('🔴 Force delete initiated for user:', userId);
    setForceDeleteReason('');
    setShowForceDeleteDialog(true);
  };

  const confirmForceDelete = async () => {
    console.log('🚀 Starting force deletion process for user:', userId);
    
    try {
      // Create an admin-initiated deletion request for audit purposes
      console.log('📝 Creating admin-initiated deletion request...');
      const adminDeletionRequest = {
        userId,
        userEmail: userEmail || 'unknown',
        userName: userDisplayName || 'Unknown User',
        requestedAt: new Date(),
        reasonId: 'admin_initiated',
        reasonDetails: forceDeleteReason || 'Admin-initiated deletion without user request',
        reasonCategory: 'admin_action',
        isCanceled: false,
        isProcessed: true, // Mark as processed immediately since this is direct admin action
        processedAt: new Date(),
        processedBy: 'admin-user',
        adminNotes: `Force delete initiated by admin. Reason: ${forceDeleteReason || 'No reason provided'}`,
        status: 'admin_initiated'
      };

      // Add the deletion request to the collection for audit trail
      const requestRef = doc(collection(db, 'accountDeleteRequests'));
      await setDoc(requestRef, {
        ...adminDeletionRequest,
        requestedAt: serverTimestamp(),
        processedAt: serverTimestamp()
      });

      console.log('📋 Admin deletion request created:', requestRef.id);

      // Execute the actual deletion
      console.log('🗑️ Executing force deletion...');
      await executeUserDeletion(userId, 'admin-user');
      
      console.log('✅ Force deletion completed successfully');
      toast.success(t('modules.userManagement.accountDeletion.forceDeleteSuccess') || 'User force deletion completed successfully');
      
      // Close dialog after a short delay to show success
      setTimeout(() => {
        setShowForceDeleteDialog(false);
        setForceDeleteReason('');
      }, 1500);
    } catch (error: any) {
      console.error('❌ Error during force deletion:', error);
      
      // Check if rollback occurred
      if (error?.message?.includes('Rollback completed successfully')) {
        toast.warning(t('modules.userManagement.accountDeletion.rollbackSuccess') || 'Rollback completed successfully - user data restored');
      } else if (error?.message?.includes('Rollback failed')) {
        toast.error(t('modules.userManagement.accountDeletion.rollbackFailed') || 'Rollback failed - manual intervention may be required');
      } else if (error?.message?.includes('Rollback not possible')) {
        toast.error(t('modules.userManagement.accountDeletion.rollbackNotPossible') || 'Rollback not possible - some operations cannot be undone');
      } else {
        toast.error(t('modules.userManagement.accountDeletion.forceDeleteError') || 'Failed to execute force deletion');
      }
    }
  };

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Trash2 className="h-5 w-5" />
            {t('modules.userManagement.accountDeletion.title') || 'Account Deletion'}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin" />
          </div>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Trash2 className="h-5 w-5" />
            {t('modules.userManagement.accountDeletion.title') || 'Account Deletion'}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Alert variant="destructive">
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>
              {error.message || 'Failed to load deletion requests'}
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    );
  }

  return (
    <>
      {/* Admin Actions Section - Always shown at the top */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            {t('modules.userManagement.accountDeletion.adminActions') || 'Admin Actions'}
          </CardTitle>
          <CardDescription>
            {t('modules.userManagement.accountDeletion.forceDeleteWarning') || 'Force delete will permanently remove the user without their request. This action follows the same deletion process but is admin-initiated.'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            variant="destructive" 
            onClick={handleForceDelete}
            disabled={requestProcessing || deletionProcessing}
          >
            <Trash2 className="h-4 w-4 mr-2" />
            {t('modules.userManagement.accountDeletion.forceDeleteUser') || 'Force Delete User'}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Trash2 className="h-5 w-5" />
            {t('modules.userManagement.accountDeletion.title') || 'Account Deletion'}
          </CardTitle>
          <CardDescription>
            {t('modules.userManagement.accountDeletion.description') || 'Manage account deletion requests from users'}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {deletionProcessing && (
            <Alert>
              <Loader2 className="h-4 w-4 animate-spin" />
              <AlertDescription className="ml-2">
                <div className="space-y-2">
                  <p className="font-medium">
                    {t('modules.userManagement.accountDeletion.processingRequest') || 'Processing deletion...'}
                  </p>
                  {progress && <p className="text-sm text-muted-foreground">{progress}</p>}
                  <Progress value={50} className="w-full" />
                </div>
              </AlertDescription>
            </Alert>
          )}

          {deletionRequests.length > 0 ? (
            <div className="space-y-4">
              {deletionRequests.map((request) => (
                <Card key={request.id} className="border-2">
                  <CardHeader className="pb-4">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <Shield className="h-4 w-4 text-muted-foreground" />
                        <span className="text-sm font-medium">
                          {t('modules.userManagement.accountDeletion.requestId') || 'Request ID'}: 
                          <span className="ml-1 font-mono text-xs">{request.id}</span>
                        </span>
                      </div>
                      {getStatusBadge(request)}
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    {/* Request Details Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="space-y-3">
                        <div>
                          <p className="text-sm font-medium text-muted-foreground">
                            {t('modules.userManagement.accountDeletion.reasonCategory') || 'Reason Category'}
                          </p>
                          <p className="text-sm">{getCategoryLabel(request.reasonCategory)}</p>
                        </div>
                        
                        {request.reasonDetails && (
                          <div>
                            <p className="text-sm font-medium text-muted-foreground">
                              {t('modules.userManagement.accountDeletion.reasonDetails') || 'Reason Details'}
                            </p>
                            <p className="text-sm bg-muted p-2 rounded">{request.reasonDetails}</p>
                          </div>
                        )}
                      </div>

                      <div className="space-y-3">
                        <div>
                          <p className="text-sm font-medium text-muted-foreground">
                            {t('modules.userManagement.accountDeletion.requestedAt') || 'Requested At'}
                          </p>
                          <p className="text-sm">{formatDate(request.requestedAt)}</p>
                        </div>
                        
                        {request.processedAt && (
                          <div>
                            <p className="text-sm font-medium text-muted-foreground">
                              {t('modules.userManagement.accountDeletion.processedAt') || 'Processed At'}
                            </p>
                            <p className="text-sm">{formatDate(request.processedAt)}</p>
                          </div>
                        )}
                        
                        {request.processedBy && (
                          <div>
                            <p className="text-sm font-medium text-muted-foreground">
                              {t('modules.userManagement.accountDeletion.processedBy') || 'Processed By'}
                            </p>
                            <p className="text-sm">{request.processedBy}</p>
                          </div>
                        )}
                      </div>
                    </div>

                    {request.adminNotes && (
                      <div className="pt-2">
                        <p className="text-sm font-medium text-muted-foreground mb-2">
                          {t('modules.userManagement.accountDeletion.adminNotes') || 'Admin Notes'}
                        </p>
                        <div className="bg-muted p-3 rounded-md">
                          <p className="text-sm whitespace-pre-wrap">{request.adminNotes}</p>
                        </div>
                      </div>
                    )}

                    {/* Action Buttons */}
                    {!request.isProcessed && !request.isCanceled && (
                      <div className="pt-4 border-t">
                        <div className="flex flex-col sm:flex-row gap-2">
                          <Button 
                            variant="destructive" 
                            size="sm" 
                            className="w-full sm:w-auto"
                            onClick={() => handleApprove(request)}
                            disabled={requestProcessing || deletionProcessing}
                          >
                            <AlertTriangle className="h-4 w-4 mr-2" />
                            <span className="hidden sm:inline">
                              {t('modules.userManagement.accountDeletion.approveRequest') || 'Approve Request'}
                            </span>
                            <span className="sm:hidden">
                              {t('common.approve') || 'Approve'}
                            </span>
                          </Button>
                          
                          <Button 
                            variant="outline" 
                            size="sm" 
                            className="w-full sm:w-auto"
                            onClick={() => handleReject(request)}
                            disabled={requestProcessing || deletionProcessing}
                          >
                            <X className="h-4 w-4 mr-2" />
                            <span className="hidden sm:inline">
                              {t('modules.userManagement.accountDeletion.rejectRequest') || 'Reject Request'}
                            </span>
                            <span className="sm:hidden">
                              {t('common.reject') || 'Reject'}
                            </span>
                          </Button>
                          
                          <Button 
                            variant="ghost" 
                            size="sm" 
                            className="w-full sm:w-auto"
                            onClick={() => handleAddNotes(request)}
                            disabled={requestProcessing || deletionProcessing}
                          >
                            <FileText className="h-4 w-4 mr-2" />
                            <span className="hidden sm:inline">
                              {t('modules.userManagement.accountDeletion.addNotes') || 'Add Notes'}
                            </span>
                            <span className="sm:hidden">
                              {t('common.notes') || 'Notes'}
                            </span>
                          </Button>
                        </div>
                      </div>
                    )}
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : (
            <Card>
              <CardContent className="pt-6">
                <div className="text-center py-8 space-y-4">
                  <div className="flex items-center justify-center">
                    <div className="rounded-full bg-green-100 p-3">
                      <CheckCircle className="h-8 w-8 text-green-600" />
                    </div>
                  </div>
                  <div className="space-y-2">
                    <p className="font-medium">
                      {t('modules.userManagement.accountDeletion.noDeletionRequest') || 'No Deletion Request'}
                    </p>
                    <p className="text-sm text-muted-foreground">
                      {t('modules.userManagement.accountDeletion.userHasNotRequested') || 'This user has not requested account deletion. Their account is in normal status.'}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </CardContent>
      </Card>

      {/* Approve Dialog */}
      <Dialog open={showApproveDialog} onOpenChange={setShowApproveDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-destructive" />
              {t('modules.userManagement.accountDeletion.approveDeletionTitle') || 'Approve Account Deletion'}
            </DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.accountDeletion.approveDeletionDescription') || 'Are you sure you want to approve this account deletion request? This action will permanently delete the user\'s account and cannot be undone.'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-2 block">
                {t('modules.userManagement.accountDeletion.adminNotes') || 'Admin Notes'} ({t('common.optional') || 'Optional'})
              </label>
              <Textarea
                value={adminNotes}
                onChange={(e) => setAdminNotes(e.target.value)}
                placeholder={t('modules.userManagement.accountDeletion.addNotesPlaceholder') || 'Add any notes about this approval...'}
                className="min-h-[80px]"
              />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setShowApproveDialog(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button 
              variant="destructive" 
              onClick={confirmApproval}
              disabled={requestProcessing || deletionProcessing}
            >
              {(requestProcessing || deletionProcessing) && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              {t('common.approve') || 'Approve'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Reject Dialog */}
      <Dialog open={showRejectDialog} onOpenChange={setShowRejectDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <X className="h-5 w-5" />
              {t('modules.userManagement.accountDeletion.rejectDeletionTitle') || 'Reject Account Deletion'}
            </DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.accountDeletion.rejectDeletionDescription') || 'Are you sure you want to reject this account deletion request? The user will be notified and can request deletion again.'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-2 block">
                {t('modules.userManagement.accountDeletion.adminNotes') || 'Admin Notes'} ({t('common.optional') || 'Optional'})
              </label>
              <Textarea
                value={adminNotes}
                onChange={(e) => setAdminNotes(e.target.value)}
                placeholder={t('modules.userManagement.accountDeletion.addNotesPlaceholder') || 'Add any notes about this rejection...'}
                className="min-h-[80px]"
              />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setShowRejectDialog(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button 
              onClick={confirmRejection}
              disabled={requestProcessing}
            >
              {requestProcessing && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
              {t('common.reject') || 'Reject'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Notes Dialog */}
      <Dialog open={showNotesDialog} onOpenChange={setShowNotesDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              {t('modules.userManagement.accountDeletion.addNotes') || 'Add Notes'}
            </DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.accountDeletion.addNotesDescription') || 'Add or update admin notes for this deletion request.'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-2 block">
                {t('modules.userManagement.accountDeletion.adminNotes') || 'Admin Notes'}
              </label>
              <Textarea
                value={adminNotes}
                onChange={(e) => setAdminNotes(e.target.value)}
                placeholder={t('modules.userManagement.accountDeletion.addNotesPlaceholder') || 'Add your notes here...'}
                className="min-h-[120px]"
              />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setShowNotesDialog(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button onClick={saveNotes}>
              {t('common.save') || 'Save'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Force Delete Dialog */}
      <Dialog open={showForceDeleteDialog} onOpenChange={setShowForceDeleteDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-destructive" />
              {t('modules.userManagement.accountDeletion.forceDeleteTitle') || 'Force Delete User Account'}
            </DialogTitle>
            <DialogDescription>
              <div className="space-y-2">
                <div className="text-sm">
                  {t('modules.userManagement.accountDeletion.forceDeleteDescription') || 'You are about to force delete this user account without their request. This action will:'}
                </div>
                <ul className="text-xs space-y-1 pl-4 list-disc text-muted-foreground">
                  <li>{t('modules.userManagement.accountDeletion.forceDeleteStep1') || 'Soft delete community data (posts, comments, profiles)'}</li>
                  <li>{t('modules.userManagement.accountDeletion.forceDeleteStep2') || 'Hard delete personal data (vault, activities, emotions)'}</li>
                  <li>{t('modules.userManagement.accountDeletion.forceDeleteStep3') || 'Delete Firebase authentication'}</li>
                  <li>{t('modules.userManagement.accountDeletion.forceDeleteStep4') || 'Create admin audit trail'}</li>
                </ul>
                <div className="text-xs text-destructive font-medium">
                  {t('modules.userManagement.accountDeletion.forceDeleteWarning2') || 'This action cannot be undone after the hard delete phase begins.'}
                </div>
              </div>
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            {/* Show progress if deletion is in progress */}
            {deletionProcessing && (
              <Alert>
                <Loader2 className="h-4 w-4 animate-spin" />
                <AlertDescription className="ml-2">
                  <div className="space-y-2">
                    <p className="font-medium">
                      {t('modules.userManagement.accountDeletion.processingRequest') || 'Processing deletion...'}
                    </p>
                    {progress && <p className="text-sm text-muted-foreground">{progress}</p>}
                    <Progress value={50} className="w-full" />
                  </div>
                </AlertDescription>
              </Alert>
            )}

            {/* Show form only if not processing */}
            {!deletionProcessing && (
              <>
                <div>
                  <label className="text-sm font-medium mb-2 block">
                    {t('modules.userManagement.accountDeletion.deletionReason') || 'Reason for Deletion'} ({t('common.required') || 'Required'})
                  </label>
                  <Textarea
                    value={forceDeleteReason}
                    onChange={(e) => setForceDeleteReason(e.target.value)}
                    placeholder={t('modules.userManagement.accountDeletion.forceDeleteReasonPlaceholder') || 'Explain why this user account is being force deleted...'}
                    className="min-h-[80px]"
                    required
                  />
                </div>
                
                <Alert variant="destructive">
                  <AlertTriangle className="h-4 w-4" />
                  <AlertDescription className="text-xs">
                    {t('modules.userManagement.accountDeletion.forceDeleteConfirmText') || 'User: '}<strong>{userDisplayName || userEmail}</strong>
                  </AlertDescription>
                </Alert>
              </>
            )}
          </div>
          <DialogFooter className="gap-2">
            {/* Hide cancel button during processing to prevent accidental cancellation */}
            {!deletionProcessing && (
              <Button variant="outline" onClick={() => setShowForceDeleteDialog(false)}>
                {t('common.cancel') || 'Cancel'}
              </Button>
            )}
            {/* Show confirm button only if not processing */}
            {!deletionProcessing && (
              <Button 
                variant="destructive" 
                onClick={confirmForceDelete}
                disabled={!forceDeleteReason.trim() || requestProcessing || deletionProcessing}
              >
                {t('modules.userManagement.accountDeletion.confirmForceDelete') || 'Confirm Force Delete'}
              </Button>
            )}
            {/* Show processing state */}
            {deletionProcessing && (
              <div className="flex items-center justify-center w-full py-2">
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  {t('modules.userManagement.accountDeletion.processingRequest') || 'Processing deletion...'}
                </div>
              </div>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}