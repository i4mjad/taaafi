'use client';

import { useState, useMemo, useEffect } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, limit, where, writeBatch, startAfter, endBefore, limitToLast, getDocs, QueryDocumentSnapshot, DocumentData } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Skeleton } from '@/components/ui/skeleton';
import { Checkbox } from '@/components/ui/checkbox';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { StatusBadge } from './StatusBadge';
import { MessageDetailModal } from './MessageDetailModal';
import { Eye, Trash2, CheckCircle, XCircle, EyeOff, ChevronLeft, ChevronRight } from 'lucide-react';
import { format } from 'date-fns';
import { doc, updateDoc, Timestamp } from 'firebase/firestore';
import { useAuth } from '@/auth/AuthProvider';
import { toast } from 'sonner';

export function AllMessages() {
  const { t } = useTranslation();
  const { user } = useAuth();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedMessage, setSelectedMessage] = useState<any>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  
  // Pagination states
  const [pageSize, setPageSize] = useState(20);
  const [currentPage, setCurrentPage] = useState(1);
  const [firstDoc, setFirstDoc] = useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [hasNextPage, setHasNextPage] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  
  // Bulk action states
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [showBulkDialog, setShowBulkDialog] = useState(false);
  const [bulkAction, setBulkAction] = useState<'approve' | 'block' | 'delete'>('approve');
  const [bulkReason, setBulkReason] = useState('');
  const [isProcessingBulk, setIsProcessingBulk] = useState(false);
  
  // Individual moderation dialog
  const [showModerationDialog, setShowModerationDialog] = useState(false);
  const [moderationAction, setModerationAction] = useState<'approve' | 'block' | 'hide' | 'delete'>('block');
  const [moderationReason, setModerationReason] = useState('');
  const [violationType, setViolationType] = useState('');
  const [messageToModerate, setMessageToModerate] = useState<any>(null);
  
  // Build Firestore query with pagination
  const messagesQuery = useMemo(() => {
    let constraints: any[] = [];
    
    if (statusFilter && statusFilter !== 'all') {
      constraints.push(where('moderation.status', '==', statusFilter));
    }
    
    constraints.push(orderBy('createdAt', 'desc'));
    
    // Add pagination
    if (currentPage > 1 && lastDoc) {
      constraints.push(startAfter(lastDoc));
    }
    
    constraints.push(limit(pageSize + 1)); // +1 to check if there's a next page
    
    return query(collection(db, 'direct_messages'), ...constraints);
  }, [statusFilter, pageSize, currentPage, lastDoc]);
  
  const [snapshot, loading, error] = useCollection(messagesQuery);
  
  // Extract data from snapshot, handle pagination, and add document IDs
  const messages = useMemo(() => {
    if (!snapshot) return [];
    
    const docs = snapshot.docs;
    
    // Check if there's a next page
    if (docs.length > pageSize) {
      setHasNextPage(true);
      // Remove the extra document used for pagination check
      const displayDocs = docs.slice(0, pageSize);
      
      // Update pagination cursors
      if (displayDocs.length > 0) {
        setFirstDoc(displayDocs[0]);
        setLastDoc(displayDocs[displayDocs.length - 1]);
      }
      
      return displayDocs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
    } else {
      setHasNextPage(false);
      
      // Update pagination cursors
      if (docs.length > 0) {
        setFirstDoc(docs[0]);
        setLastDoc(docs[docs.length - 1]);
      }
      
      return docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
    }
  }, [snapshot, pageSize]);
  
  // Get total count (only when filters change)
  useEffect(() => {
    const fetchTotalCount = async () => {
      try {
        let constraints: any[] = [];
        
        if (statusFilter && statusFilter !== 'all') {
          constraints.push(where('moderation.status', '==', statusFilter));
        }
        
        const countQuery = query(collection(db, 'direct_messages'), ...constraints);
        const countSnapshot = await getDocs(countQuery);
        setTotalCount(countSnapshot.size);
      } catch (error) {
        console.error('Error fetching total count:', error);
      }
    };
    
    fetchTotalCount();
  }, [statusFilter]);
  
  // Filter messages by search term (client-side)
  const filteredMessages = useMemo(() => {
    if (!messages) return [];
    if (!searchTerm) return messages;
    
    return messages.filter((msg: any) =>
      msg.body?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      msg.senderCpId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      msg.id?.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [messages, searchTerm]);
  
  // Handle view message
  const handleViewMessage = (message: any) => {
    // Transform to match modal structure
    const transformedMessage = {
      ...message,
      sender: {
        id: message.senderCpId,
        displayName: message.senderCpId?.slice(0, 8) || 'Unknown',
        userUID: message.senderCpId,
        photoURL: undefined,
      },
    };
    setSelectedMessage(transformedMessage);
    setIsModalOpen(true);
  };
  
  // Handle individual moderation action
  const handleModerationClick = (message: any, action: 'approve' | 'block' | 'hide' | 'delete') => {
    setMessageToModerate(message);
    setModerationAction(action);
    setModerationReason('');
    setViolationType('');
    setShowModerationDialog(true);
  };
  
  // Execute individual moderation
  const executeModeration = async () => {
    if (!messageToModerate) return;
    
    setIsProcessingBulk(true);
    try {
      const messageRef = doc(db, 'direct_messages', messageToModerate.id);
      const updates: any = {
        'moderation.status': moderationAction === 'approve' ? 'approved' : 'blocked',
        'moderation.moderatedBy': user?.uid,
        'moderation.moderatedAt': Timestamp.now(),
      };
      
      // Only add reason if provided (Firestore doesn't allow undefined)
      if (moderationReason) {
        updates['moderation.reason'] = moderationReason;
      }
      
      // Only add violation type if provided
      if (violationType) {
        updates['moderation.ai.violationType'] = violationType;
      }
      
      if (moderationAction === 'hide' || moderationAction === 'block') {
        updates.isHidden = true;
      } else if (moderationAction === 'delete') {
        updates.isDeleted = true;
        updates.deletedAt = Timestamp.now();
        updates.deletedBy = user?.uid;
      } else if (moderationAction === 'approve') {
        updates.isHidden = false;
      }
      
      await updateDoc(messageRef, updates);
      toast.success(t('modules.community.directMessages.notifications.moderationSuccess') || 'Message moderated successfully');
      setShowModerationDialog(false);
      setMessageToModerate(null);
    } catch (error) {
      console.error('Error moderating message:', error);
      toast.error(t('modules.community.directMessages.notifications.error') || 'Failed to moderate message');
    } finally {
      setIsProcessingBulk(false);
    }
  };
  
  // Handle bulk action
  const handleBulkAction = (action: 'approve' | 'block' | 'delete') => {
    if (selectedIds.length === 0) {
      toast.error('Please select messages first');
      return;
    }
    setBulkAction(action);
    setBulkReason('');
    setShowBulkDialog(true);
  };
  
  // Execute bulk action
  const executeBulkAction = async () => {
    if (selectedIds.length === 0) return;
    
    setIsProcessingBulk(true);
    try {
      const batch = writeBatch(db);
      
      selectedIds.forEach(messageId => {
        const messageRef = doc(db, 'direct_messages', messageId);
        const updates: any = {
          'moderation.status': bulkAction === 'approve' ? 'approved' : 'blocked',
          'moderation.moderatedBy': user?.uid,
          'moderation.moderatedAt': Timestamp.now(),
        };
        
        // Only add reason if provided (Firestore doesn't allow undefined)
        if (bulkReason) {
          updates['moderation.reason'] = bulkReason;
        }
        
        if (bulkAction === 'block') {
          updates.isHidden = true;
        } else if (bulkAction === 'delete') {
          updates.isDeleted = true;
          updates.deletedAt = Timestamp.now();
          updates.deletedBy = user?.uid;
        } else if (bulkAction === 'approve') {
          updates.isHidden = false;
        }
        
        batch.update(messageRef, updates);
      });
      
      await batch.commit();
      toast.success(`${selectedIds.length} messages ${bulkAction}d successfully`);
      setSelectedIds([]);
      setShowBulkDialog(false);
    } catch (error) {
      console.error('Error processing bulk action:', error);
      toast.error('Failed to process bulk action');
    } finally {
      setIsProcessingBulk(false);
    }
  };
  
  // Toggle selection
  const toggleSelection = (messageId: string) => {
    setSelectedIds(prev =>
      prev.includes(messageId)
        ? prev.filter(id => id !== messageId)
        : [...prev, messageId]
    );
  };
  
  // Select/deselect all
  const toggleSelectAll = () => {
    if (selectedIds.length === filteredMessages.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(filteredMessages.map((m: any) => m.id));
    }
  };
  
  // Dummy handlers for modal (messages here are already moderated)
  const handleApproveMessage = async () => {
    toast.info('Message is already in the database. Use Moderation Queue for pending items.');
    setIsModalOpen(false);
  };
  
  const handleRejectMessage = async () => {
    toast.info('Message is already in the database. Use Moderation Queue for pending items.');
    setIsModalOpen(false);
  };
  
  // Pagination handlers
  const handleNextPage = () => {
    if (hasNextPage) {
      setCurrentPage(prev => prev + 1);
      setSelectedIds([]); // Clear selection when changing pages
    }
  };
  
  const handlePreviousPage = () => {
    if (currentPage > 1) {
      setCurrentPage(prev => prev - 1);
      setLastDoc(null); // Reset to trigger new query
      setSelectedIds([]); // Clear selection when changing pages
    }
  };
  
  const handlePageSizeChange = (newSize: string) => {
    setPageSize(parseInt(newSize));
    setCurrentPage(1); // Reset to first page
    setLastDoc(null);
    setSelectedIds([]);
  };
  
  // Reset to first page when filters change
  useEffect(() => {
    setCurrentPage(1);
    setLastDoc(null);
    setSelectedIds([]);
  }, [statusFilter]);
  
  if (loading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3, 4, 5].map((i) => (
          <Skeleton key={i} className="h-16 w-full" />
        ))}
      </div>
    );
  }
  
  if (error) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="space-y-2">
            <p className="text-destructive font-semibold">{t('modules.community.directMessages.common.error')}</p>
            <p className="text-sm text-muted-foreground">{error.message}</p>
            {error.code && <p className="text-xs text-muted-foreground">Error Code: {error.code}</p>}
          </div>
        </CardContent>
      </Card>
    );
  }
  
  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.directMessages.messages.title')}</CardTitle>
          <CardDescription>
            {t('modules.community.directMessages.messages.description')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input
              placeholder={t('modules.community.directMessages.common.search')}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger>
                <SelectValue placeholder={t('modules.community.directMessages.messages.filters.moderationStatus')} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All</SelectItem>
                <SelectItem value="pending">{t('modules.community.directMessages.statuses.pending')}</SelectItem>
                <SelectItem value="approved">{t('modules.community.directMessages.statuses.approved')}</SelectItem>
                <SelectItem value="blocked">{t('modules.community.directMessages.statuses.blocked')}</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>
      
      {/* Bulk Action Toolbar */}
      {selectedIds.length > 0 && (
        <Card>
          <CardContent className="py-4">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">
                {selectedIds.length} {t('modules.community.directMessages.common.selected') || 'selected'}
              </span>
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkAction('approve')}
                  className="text-green-600 hover:text-green-700"
                >
                  <CheckCircle className="h-4 w-4 mr-2" />
                  {t('modules.community.directMessages.actions.approve')}
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkAction('block')}
                  className="text-orange-600 hover:text-orange-700"
                >
                  <XCircle className="h-4 w-4 mr-2" />
                  {t('modules.community.directMessages.actions.block')}
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkAction('delete')}
                  className="text-red-600 hover:text-red-700"
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  {t('modules.community.directMessages.actions.delete')}
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => setSelectedIds([])}
                >
                  {t('common.cancel')}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
      
      <Card>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-12">
                <Checkbox
                  checked={selectedIds.length === filteredMessages.length && filteredMessages.length > 0}
                  onCheckedChange={toggleSelectAll}
                />
              </TableHead>
              <TableHead>{t('modules.community.directMessages.messages.columns.messageId')}</TableHead>
              <TableHead>{t('modules.community.directMessages.messages.columns.sender')}</TableHead>
              <TableHead>{t('modules.community.directMessages.messages.columns.preview')}</TableHead>
              <TableHead>{t('modules.community.directMessages.messages.columns.moderationStatus')}</TableHead>
              <TableHead>{t('modules.community.directMessages.messages.columns.createdAt')}</TableHead>
              <TableHead>{t('modules.community.directMessages.messages.columns.actions')}</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredMessages.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-8">
                  {t('modules.community.directMessages.messages.empty')}
                </TableCell>
              </TableRow>
            ) : (
              filteredMessages.map((message: any) => (
                <TableRow key={message.id}>
                  <TableCell>
                    <Checkbox
                      checked={selectedIds.includes(message.id)}
                      onCheckedChange={() => toggleSelection(message.id)}
                    />
                  </TableCell>
                  <TableCell>
                    <code className="text-xs">{message.id?.slice(0, 12) || 'N/A'}...</code>
                  </TableCell>
                  <TableCell>
                    <code className="text-xs">{message.senderCpId?.slice(0, 8) || 'N/A'}...</code>
                  </TableCell>
                  <TableCell>
                    <p className="text-sm max-w-md truncate">{message.body || 'N/A'}</p>
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={message.moderation?.status || 'pending'} type="moderation" />
                  </TableCell>
                  <TableCell>
                    <span className="text-xs text-muted-foreground">
                      {message.createdAt ? format(message.createdAt.toDate(), 'PP') : 'N/A'}
                    </span>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      <Button 
                        size="sm" 
                        variant="ghost"
                        onClick={() => handleViewMessage(message)}
                        title="View details"
                      >
                        <Eye className="h-4 w-4" />
                      </Button>
                      <Button 
                        size="sm" 
                        variant="ghost"
                        onClick={() => handleModerationClick(message, 'approve')}
                        className="text-green-600 hover:text-green-700"
                        title="Approve"
                      >
                        <CheckCircle className="h-4 w-4" />
                      </Button>
                      <Button 
                        size="sm" 
                        variant="ghost"
                        onClick={() => handleModerationClick(message, 'block')}
                        className="text-orange-600 hover:text-orange-700"
                        title="Block"
                      >
                        <XCircle className="h-4 w-4" />
                      </Button>
                      <Button 
                        size="sm" 
                        variant="ghost"
                        onClick={() => handleModerationClick(message, 'hide')}
                        className="text-gray-600 hover:text-gray-700"
                        title="Hide"
                      >
                        <EyeOff className="h-4 w-4" />
                      </Button>
                      <Button 
                        size="sm" 
                        variant="ghost"
                        onClick={() => handleModerationClick(message, 'delete')}
                        className="text-red-600 hover:text-red-700"
                        title="Delete"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </Card>
      
      {/* Pagination Controls */}
      <Card>
        <CardContent className="py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">
                  {t('modules.community.directMessages.common.pagination.itemsPerPage')}:
                </span>
                <Select value={pageSize.toString()} onValueChange={handlePageSizeChange}>
                  <SelectTrigger className="w-20">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="10">10</SelectItem>
                    <SelectItem value="20">20</SelectItem>
                    <SelectItem value="50">50</SelectItem>
                    <SelectItem value="100">100</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="text-sm text-muted-foreground">
                {t('modules.community.directMessages.common.pagination.showing')} {(currentPage - 1) * pageSize + 1} {t('modules.community.directMessages.common.pagination.to')} {Math.min(currentPage * pageSize, totalCount)} {t('modules.community.directMessages.common.pagination.of')} {totalCount} {t('modules.community.directMessages.common.pagination.items')}
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={handlePreviousPage}
                disabled={currentPage === 1 || loading}
              >
                <ChevronLeft className="h-4 w-4 mr-1" />
                {t('modules.community.directMessages.common.pagination.previous')}
              </Button>
              
              <div className="text-sm font-medium">
                {t('modules.community.directMessages.common.pagination.page')} {currentPage}
              </div>
              
              <Button
                variant="outline"
                size="sm"
                onClick={handleNextPage}
                disabled={!hasNextPage || loading}
              >
                {t('modules.community.directMessages.common.pagination.next')}
                <ChevronRight className="h-4 w-4 ml-1" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
      
      {/* Message Detail Modal */}
      {selectedMessage && (
        <MessageDetailModal
          message={selectedMessage}
          isOpen={isModalOpen}
          onClose={() => {
            setIsModalOpen(false);
            setSelectedMessage(null);
          }}
          onApprove={handleApproveMessage}
          onReject={handleRejectMessage}
          onBanUser={(cpId) => {
            console.log('Ban user:', cpId);
            toast.info('Ban functionality would be implemented here');
          }}
          onViewConversation={(conversationId) => {
            console.log('View conversation:', conversationId);
            toast.info('Conversation view would be implemented here');
          }}
        />
      )}
      
      {/* Bulk Action Dialog */}
      <Dialog open={showBulkDialog} onOpenChange={setShowBulkDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {bulkAction === 'approve' && 'Approve Messages'}
              {bulkAction === 'block' && 'Block Messages'}
              {bulkAction === 'delete' && 'Delete Messages'}
            </DialogTitle>
            <DialogDescription>
              You are about to {bulkAction} {selectedIds.length} message(s). This action will affect all selected messages.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label htmlFor="bulkReason">Reason (optional)</Label>
              <Textarea
                id="bulkReason"
                placeholder={`Reason for ${bulkAction}ing these messages...`}
                value={bulkReason}
                onChange={(e) => setBulkReason(e.target.value)}
                rows={3}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowBulkDialog(false)} disabled={isProcessingBulk}>
              Cancel
            </Button>
            <Button 
              onClick={executeBulkAction} 
              disabled={isProcessingBulk}
              variant={bulkAction === 'delete' ? 'destructive' : 'default'}
            >
              {isProcessingBulk ? 'Processing...' : `${bulkAction.charAt(0).toUpperCase() + bulkAction.slice(1)} All`}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      
      {/* Individual Moderation Dialog */}
      <Dialog open={showModerationDialog} onOpenChange={setShowModerationDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {moderationAction === 'approve' && 'Approve Message'}
              {moderationAction === 'block' && 'Block Message'}
              {moderationAction === 'hide' && 'Hide Message'}
              {moderationAction === 'delete' && 'Delete Message'}
            </DialogTitle>
            <DialogDescription>
              Review and take action on this message.
            </DialogDescription>
          </DialogHeader>
          
          {/* Message Preview */}
          {messageToModerate && (
            <div className="mt-2 p-3 bg-muted rounded-md">
              <div className="text-sm font-medium">Message Preview:</div>
              <div className="text-sm mt-1">{messageToModerate.body?.slice(0, 150) || 'N/A'}{(messageToModerate.body?.length || 0) > 150 ? '...' : ''}</div>
            </div>
          )}
          <div className="space-y-4">
            {(moderationAction === 'block' || moderationAction === 'hide') && (
              <div>
                <Label htmlFor="violationType">Violation Type</Label>
                <Select value={violationType} onValueChange={setViolationType}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select violation type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="spam">Spam</SelectItem>
                    <SelectItem value="harassment">Harassment</SelectItem>
                    <SelectItem value="hate_speech">Hate Speech</SelectItem>
                    <SelectItem value="explicit_content">Explicit Content</SelectItem>
                    <SelectItem value="violence">Violence</SelectItem>
                    <SelectItem value="self_harm">Self Harm</SelectItem>
                    <SelectItem value="misinformation">Misinformation</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            )}
            <div>
              <Label htmlFor="moderationReason">Reason (optional)</Label>
              <Textarea
                id="moderationReason"
                placeholder={`Reason for ${moderationAction}ing this message...`}
                value={moderationReason}
                onChange={(e) => setModerationReason(e.target.value)}
                rows={3}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowModerationDialog(false)} disabled={isProcessingBulk}>
              Cancel
            </Button>
            <Button 
              onClick={executeModeration} 
              disabled={isProcessingBulk}
              variant={moderationAction === 'delete' ? 'destructive' : 'default'}
            >
              {isProcessingBulk ? 'Processing...' : `${moderationAction.charAt(0).toUpperCase() + moderationAction.slice(1)}`}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

