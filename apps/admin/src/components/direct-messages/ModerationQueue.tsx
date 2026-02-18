'use client';

import { useState, useMemo } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection, useDocumentData } from 'react-firebase-hooks/firestore';
import { collection, query, where, orderBy, limit, doc, updateDoc, writeBatch, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/auth/AuthProvider';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Skeleton } from '@/components/ui/skeleton';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from './StatusBadge';
import { PriorityBadge } from './PriorityBadge';
import { SeverityBadge } from './SeverityBadge';
import { ConfidenceIndicator } from './ConfidenceIndicator';
import { ViolationTypeBadge } from './ViolationTypeBadge';
import { MessageDetailModal } from './MessageDetailModal';
import { Eye, CheckCircle, XCircle, Trash2, MessageSquare, User } from 'lucide-react';
import { format } from 'date-fns';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { toast } from 'sonner';
import { ModerationQueueFilters, QueueItemWithSender, CommunityProfile } from '@/types/directMessages';

export function ModerationQueue() {
  const { t } = useTranslation();
  const { user } = useAuth();
  const [filters, setFilters] = useState<ModerationQueueFilters>({
    status: 'pending',
    priority: 'all',
    messageType: 'direct_message',
    violationType: 'all',
  });
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());
  const [selectedMessage, setSelectedMessage] = useState<QueueItemWithSender | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Build Firestore query based on filters
  const queueQuery = useMemo(() => {
    let constraints: any[] = [
      where('messageType', '==', 'direct_message'),
    ];
    
    // Note: Removed status filter from Firestore query because existing documents don't have it
    // Status filtering is now done client-side after normalizing the data
    
    if (filters.priority && filters.priority !== 'all') {
      constraints.push(where('priority', '==', filters.priority));
    }
    
    constraints.push(orderBy('createdAt', 'desc'));
    constraints.push(limit(50));
    
    return query(collection(db, 'moderation_queue'), ...constraints);
  }, [filters.priority]);
  
  const [snapshot, loading, error] = useCollection(queueQuery);
  
  // Extract data from snapshot and add document IDs
  const queueItems = useMemo(() => {
    if (!snapshot) return [];
    
    return snapshot.docs.map(doc => ({
      id: doc.id, // This is the actual document ID from Firestore
      ...doc.data(),
    }));
  }, [snapshot]);
  
  // Normalize data: set status to 'pending' if undefined (for existing documents)
  const normalizedItems = useMemo(() => {
    if (!queueItems) return [];
    
    return queueItems.map((item: any) => ({
      ...item,
      status: item.status || 'pending', // Default to 'pending' for documents without status field
    }));
  }, [queueItems]);
  
  // Filter items by status, search term, and violation type (client-side)
  const filteredItems = useMemo(() => {
    let items = [...normalizedItems];
    
    // Filter by status
    if (filters.status && filters.status !== 'all') {
      items = items.filter((item: any) => item.status === filters.status);
    }
    
    // Filter by violation type
    if (filters.violationType && filters.violationType !== 'all') {
      items = items.filter((item: any) => {
        const violationType = item.finalDecision?.violationType || item.openaiAnalysis?.violationType;
        return violationType === filters.violationType;
      });
    }
    
    // Filter by search term
    if (searchTerm) {
      items = items.filter((item: any) => 
        item.messageBody?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.senderCpId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.id?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    
    return items;
  }, [normalizedItems, filters.status, filters.violationType, searchTerm]);
  
  // Handle bulk actions
  const handleBulkApprove = async () => {
    if (selectedItems.size === 0) return;
    
    try {
      const batch = writeBatch(db);
      
      selectedItems.forEach((itemId) => {
        const item = normalizedItems?.find((i: any) => i.id === itemId);
        if (!item) return;
        
        // Update queue item
        const queueRef = doc(db, 'moderation_queue', itemId);
        batch.update(queueRef, {
          status: 'reviewed',
          reviewedAt: Timestamp.now(),
          reviewedBy: user?.uid,
          reviewAction: 'approve',
        });
        
        // Update message in top-level direct_messages collection
        if ((item as any).messageId) {
          const messageRef = doc(db, 'direct_messages', (item as any).messageId);
          batch.update(messageRef, {
            'moderation.status': 'approved',
            'moderation.reviewedAt': Timestamp.now(),
            'moderation.reviewedBy': user?.uid,
            'moderation.reviewAction': 'approve',
          });
        }
      });
      
      await batch.commit();
      toast.success(t('modules.community.directMessages.notifications.approved'));
      setSelectedItems(new Set());
    } catch (error) {
      console.error('Error bulk approving:', error);
      toast.error(t('modules.community.directMessages.notifications.error'));
    }
  };
  
  const handleBulkReject = async () => {
    if (selectedItems.size === 0) return;
    
    try {
      const batch = writeBatch(db);
      
      selectedItems.forEach((itemId) => {
        const item = normalizedItems?.find((i: any) => i.id === itemId);
        if (!item) return;
        
        // Update queue item
        const queueRef = doc(db, 'moderation_queue', itemId);
        batch.update(queueRef, {
          status: 'reviewed',
          reviewedAt: Timestamp.now(),
          reviewedBy: user?.uid,
          reviewAction: 'reject',
        });
        
        // Update message in top-level direct_messages collection
        if ((item as any).messageId) {
          const messageRef = doc(db, 'direct_messages', (item as any).messageId);
          batch.update(messageRef, {
            'moderation.status': 'blocked',
            'moderation.reviewedAt': Timestamp.now(),
            'moderation.reviewedBy': user?.uid,
            'moderation.reviewAction': 'reject',
          });
        }
      });
      
      await batch.commit();
      toast.success(t('modules.community.directMessages.notifications.rejected'));
      setSelectedItems(new Set());
    } catch (error) {
      console.error('Error bulk rejecting:', error);
      toast.error(t('modules.community.directMessages.notifications.error'));
    }
  };
  
  const handleBulkDismiss = async () => {
    if (selectedItems.size === 0) return;
    
    try {
      const batch = writeBatch(db);
      
      selectedItems.forEach((itemId) => {
        const queueRef = doc(db, 'moderation_queue', itemId);
        batch.update(queueRef, {
          status: 'dismissed',
          reviewedAt: Timestamp.now(),
          reviewedBy: user?.uid,
        });
      });
      
      await batch.commit();
      toast.success(t('modules.community.directMessages.notifications.dismissed'));
      setSelectedItems(new Set());
    } catch (error) {
      console.error('Error bulk dismissing:', error);
      toast.error(t('modules.community.directMessages.notifications.error'));
    }
  };
  
  // Handle individual actions
  const handleApproveMessage = async (messageId: string, notes?: string) => {
    // The messageId passed is actually the message.id from the transformed message
    // We need to find the queue item using its queueItemId
    const queueItem = selectedMessage as any;
    if (!queueItem?.queueItemId || !queueItem?.id) {
      console.error('Missing queue item ID or message ID');
      return;
    }
    
    const batch = writeBatch(db);
    
    // Update queue item using the stored queueItemId
    const queueRef = doc(db, 'moderation_queue', queueItem.queueItemId);
    batch.update(queueRef, {
      status: 'reviewed',
      reviewedAt: Timestamp.now(),
      reviewedBy: user?.uid,
      reviewAction: 'approve',
      reviewNotes: notes || null,
    });
    
    // Update message in top-level direct_messages collection
    const messageRef = doc(db, 'direct_messages', queueItem.id);
    batch.update(messageRef, {
      'moderation.status': 'approved',
      'moderation.reviewedAt': Timestamp.now(),
      'moderation.reviewedBy': user?.uid,
      'moderation.reviewAction': 'approve',
      'moderation.reviewNotes': notes || null,
    });
    
    await batch.commit();
    toast.success(t('modules.community.directMessages.notifications.approved'));
  };
  
  const handleRejectMessage = async (messageId: string, notes?: string) => {
    // The messageId passed is actually the message.id from the transformed message
    // We need to find the queue item using its queueItemId
    const queueItem = selectedMessage as any;
    
    if (!queueItem?.queueItemId || !queueItem?.id) {
      console.error('Missing queue item ID or message ID');
      return;
    }
    
    const batch = writeBatch(db);
    
    // Update queue item using the stored queueItemId
    const queueRef = doc(db, 'moderation_queue', queueItem.queueItemId);
    batch.update(queueRef, {
      status: 'reviewed',
      reviewedAt: Timestamp.now(),
      reviewedBy: user?.uid,
      reviewAction: 'reject',
      reviewNotes: notes || null,
    });
    
    // Update message in top-level direct_messages collection
    const messageRef = doc(db, 'direct_messages', queueItem.id);
    batch.update(messageRef, {
      'moderation.status': 'blocked',
      'moderation.reviewedAt': Timestamp.now(),
      'moderation.reviewedBy': user?.uid,
      'moderation.reviewAction': 'reject',
      'moderation.reviewNotes': notes || null,
    });
    
    await batch.commit();
    toast.success(t('modules.community.directMessages.notifications.rejected'));
  };
  
  const handleToggleSelection = (itemId: string) => {
    const newSelection = new Set(selectedItems);
    if (newSelection.has(itemId)) {
      newSelection.delete(itemId);
    } else {
      newSelection.add(itemId);
    }
    setSelectedItems(newSelection);
  };
  
  const handleSelectAll = () => {
    if (selectedItems.size === filteredItems.length) {
      setSelectedItems(new Set());
    } else {
      setSelectedItems(new Set(filteredItems.map((item: any) => item.id)));
    }
  };
  
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
      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.directMessages.moderationQueue.title')}</CardTitle>
          <CardDescription>
            {t('modules.community.directMessages.moderationQueue.description')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Input
              placeholder={t('modules.community.directMessages.common.search')}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            
            <Select
              value={filters.status || 'all'}
              onValueChange={(value) => setFilters({ ...filters, status: value as any })}
            >
              <SelectTrigger>
                <SelectValue placeholder={t('modules.community.directMessages.moderationQueue.filters.status')} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All</SelectItem>
                <SelectItem value="pending">{t('modules.community.directMessages.statuses.pending')}</SelectItem>
                <SelectItem value="reviewed">{t('modules.community.directMessages.statuses.reviewed')}</SelectItem>
                <SelectItem value="dismissed">{t('modules.community.directMessages.statuses.dismissed')}</SelectItem>
              </SelectContent>
            </Select>
            
            <Select
              value={filters.priority || 'all'}
              onValueChange={(value) => setFilters({ ...filters, priority: value as any })}
            >
              <SelectTrigger>
                <SelectValue placeholder={t('modules.community.directMessages.moderationQueue.filters.priority')} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All</SelectItem>
                <SelectItem value="critical">{t('modules.community.directMessages.priorities.critical')}</SelectItem>
                <SelectItem value="high">{t('modules.community.directMessages.priorities.high')}</SelectItem>
                <SelectItem value="medium">{t('modules.community.directMessages.priorities.medium')}</SelectItem>
                <SelectItem value="low">{t('modules.community.directMessages.priorities.low')}</SelectItem>
              </SelectContent>
            </Select>
            
            <Select
              value={filters.violationType || 'all'}
              onValueChange={(value) => setFilters({ ...filters, violationType: value as any })}
            >
              <SelectTrigger>
                <SelectValue placeholder={t('modules.community.directMessages.moderationQueue.filters.violationType')} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All</SelectItem>
                <SelectItem value="social_media_sharing">
                  {t('modules.community.directMessages.violationTypes.social_media_sharing')}
                </SelectItem>
                <SelectItem value="sexual_content">
                  {t('modules.community.directMessages.violationTypes.sexual_content')}
                </SelectItem>
                <SelectItem value="harassment">
                  {t('modules.community.directMessages.violationTypes.harassment')}
                </SelectItem>
                <SelectItem value="spam">
                  {t('modules.community.directMessages.violationTypes.spam')}
                </SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>
      
      {/* Bulk Actions */}
      {selectedItems.size > 0 && (
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <p className="text-sm">
                {t('modules.community.directMessages.common.selected').replace('{count}', selectedItems.size.toString())}
              </p>
              <div className="flex gap-2">
                <Button onClick={handleBulkApprove} size="sm">
                  <CheckCircle className="h-4 w-4 mr-2" />
                  {t('modules.community.directMessages.moderationQueue.bulkActions.approveSelected')}
                </Button>
                <Button onClick={handleBulkReject} size="sm" variant="destructive">
                  <XCircle className="h-4 w-4 mr-2" />
                  {t('modules.community.directMessages.moderationQueue.bulkActions.rejectSelected')}
                </Button>
                <Button onClick={handleBulkDismiss} size="sm" variant="outline">
                  <Trash2 className="h-4 w-4 mr-2" />
                  {t('modules.community.directMessages.moderationQueue.bulkActions.dismissSelected')}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
      
      {/* Queue Table */}
      <Card>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-12">
                <Checkbox
                  checked={selectedItems.size === filteredItems.length && filteredItems.length > 0}
                  onCheckedChange={handleSelectAll}
                />
              </TableHead>
              <TableHead>{t('modules.community.directMessages.moderationQueue.columns.sender')}</TableHead>
              <TableHead>{t('modules.community.directMessages.moderationQueue.columns.preview')}</TableHead>
              <TableHead>{t('modules.community.directMessages.moderationQueue.columns.violationType')}</TableHead>
              <TableHead>{t('modules.community.directMessages.moderationQueue.columns.confidence')}</TableHead>
              <TableHead>{t('modules.community.directMessages.moderationQueue.columns.severity')}</TableHead>
              <TableHead>{t('modules.community.directMessages.moderationQueue.columns.priority')}</TableHead>
              <TableHead>{t('modules.community.directMessages.moderationQueue.columns.status')}</TableHead>
              <TableHead>{t('modules.community.directMessages.moderationQueue.columns.createdAt')}</TableHead>
              <TableHead>{t('modules.community.directMessages.moderationQueue.columns.actions')}</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredItems.length === 0 ? (
              <TableRow>
                <TableCell colSpan={10} className="text-center py-8">
                  {t('modules.community.directMessages.moderationQueue.empty')}
                </TableCell>
              </TableRow>
            ) : (
              filteredItems.map((item: any, idx: number) => {
                const violationType = item.finalDecision?.violationType || item.openaiAnalysis?.violationType;
                const confidence = item.finalDecision?.confidence || item.openaiAnalysis?.confidence || 0;
                const severity = item.openaiAnalysis?.severity || 'low';
                
                return (
                  <TableRow key={item.id || `item-${idx}`}>
                    <TableCell>
                      <Checkbox
                        checked={selectedItems.has(item.id)}
                        onCheckedChange={() => handleToggleSelection(item.id)}
                      />
                    </TableCell>
                    <TableCell>
                      <div className="text-sm">
                        <p className="font-medium">{item.senderCpId?.slice(0, 8) || 'N/A'}...</p>
                      </div>
                    </TableCell>
                    <TableCell>
                      <p className="text-sm max-w-md truncate">{item.messageBody}</p>
                    </TableCell>
                    <TableCell>
                      <ViolationTypeBadge violationType={violationType} />
                    </TableCell>
                    <TableCell>
                      <ConfidenceIndicator confidence={confidence} />
                    </TableCell>
                    <TableCell>
                      <SeverityBadge severity={severity} />
                    </TableCell>
                    <TableCell>
                      <PriorityBadge priority={item.priority} />
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={item.status} type="queue" />
                    </TableCell>
                    <TableCell>
                      <span className="text-xs text-muted-foreground">
                        {item.createdAt && format(item.createdAt.toDate(), 'PP')}
                      </span>
                    </TableCell>
                    <TableCell>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => {
                          // Transform queue item to match MessageDetailModal expected structure
                          const transformedMessage = {
                            ...item,
                            id: item.messageId, // This is the actual message ID from direct_messages
                            queueItemId: item.id, // This is the queue item ID from moderation_queue
                            body: item.messageBody,
                            sender: {
                              id: item.senderCpId,
                              displayName: item.senderCpId?.slice(0, 8) || 'Unknown',
                              userUID: item.senderCpId,
                              photoURL: undefined,
                            },
                            moderation: {
                              status: item.status || 'pending',
                              ai: item.openaiAnalysis,
                              customRules: item.customRuleResults,
                              reviewedAt: item.reviewedAt,
                              reviewedBy: item.reviewedBy,
                              reviewAction: item.reviewAction,
                              reviewNotes: item.reviewNotes,
                            },
                          };
                          
                          setSelectedMessage(transformedMessage as any);
                          setIsModalOpen(true);
                        }}
                      >
                        <Eye className="h-4 w-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </Card>
      
      {/* Message Detail Modal */}
      {selectedMessage && (
        <MessageDetailModal
          message={selectedMessage as any}
          isOpen={isModalOpen}
          onClose={() => {
            setIsModalOpen(false);
            setSelectedMessage(null);
          }}
          onApprove={handleApproveMessage}
          onReject={handleRejectMessage}
          onBanUser={(cpId) => {
            // Navigate to ban creation
            console.log('Ban user:', cpId);
          }}
          onViewConversation={(conversationId) => {
            // Navigate to conversation detail
            console.log('View conversation:', conversationId);
          }}
        />
      )}
    </div>
  );
}

