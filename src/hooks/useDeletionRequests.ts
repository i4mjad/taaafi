'use client';

import { useCollection, useDocument } from 'react-firebase-hooks/firestore';
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  limit, 
  DocumentData, 
  doc, 
  updateDoc, 
  deleteDoc, 
  writeBatch, 
  serverTimestamp,
  getDocs,
  setDoc,
  documentId,
  startAfter,
  QueryDocumentSnapshot
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useState, useCallback, useEffect } from 'react';

interface AccountDeleteRequest {
  id: string;
  userId: string;
  userEmail: string;
  userName: string;
  requestedAt: Date;
  reasonId: string;
  reasonDetails?: string;
  reasonCategory: string;
  isCanceled: boolean;
  isProcessed: boolean;
  canceledAt?: Date;
  processedAt?: Date;
  processedBy?: string;
  adminNotes?: string;
}

export function useDeletionRequests(userId?: string) {
  const [allRequests, setAllRequests] = useState<AccountDeleteRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchAllRequests = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const queryRef = userId
        ? query(
            collection(db, 'accountDeleteRequests'),
            where('userId', '==', userId),
            orderBy('requestedAt', 'asc')
          )
        : query(
            collection(db, 'accountDeleteRequests'),
            orderBy('requestedAt', 'asc'),
            limit(500) // Fetch more requests to ensure we get all statuses
          );

      const snapshot = await getDocs(queryRef);
      
      const requests: AccountDeleteRequest[] = snapshot.docs.map((doc) => {
        const data = doc.data() as DocumentData;
        return {
          id: doc.id,
          userId: data.userId,
          userEmail: data.userEmail,
          userName: data.userName,
          requestedAt: data.requestedAt?.toDate() || new Date(),
          reasonId: data.reasonId,
          reasonDetails: data.reasonDetails,
          reasonCategory: data.reasonCategory,
          isCanceled: data.isCanceled || false,
          isProcessed: data.isProcessed || false,
          canceledAt: data.canceledAt?.toDate(),
          processedAt: data.processedAt?.toDate(),
          processedBy: data.processedBy,
          adminNotes: data.adminNotes,
        };
      });

      // Apply client-side sorting
      requests.sort((a, b) => {
        const getPriority = (request: AccountDeleteRequest) => {
          if (request.isProcessed) return 2; // Processed last
          if (request.isCanceled) return 1; // Canceled middle
          return 0; // Pending first
        };
        
        const priorityA = getPriority(a);
        const priorityB = getPriority(b);
        
        if (priorityA !== priorityB) {
          return priorityA - priorityB;
        }
        
        return a.requestedAt.getTime() - b.requestedAt.getTime();
      });

      setAllRequests(requests);
      
      // Debug logging
      if (!userId) {
        const statusBreakdown = {
          pending: requests.filter(r => !r.isProcessed && !r.isCanceled).length,
          canceled: requests.filter(r => r.isCanceled).length,
          processed: requests.filter(r => r.isProcessed).length,
          total: requests.length
        };
        console.log('🔍 Deletion Requests Breakdown:', statusBreakdown);
      }
      
    } catch (err) {
      console.error('🔍 Deletion Requests Error:', err);
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    fetchAllRequests();
  }, [fetchAllRequests]);

  const [processing, setProcessing] = useState(false);

  // Update deletion request status using Firebase hooks
  const updateDeletionRequest = async (requestId: string, updates: any) => {
    try {
      const requestRef = doc(db, 'accountDeleteRequests', requestId);
      await updateDoc(requestRef, {
        ...updates,
        processedAt: serverTimestamp(),
      });
    } catch (error) {
      console.error('Error updating deletion request:', error);
      throw error;
    }
  };

  // Approve deletion request and execute deletion
  const approveRequest = async (requestId: string, adminNotes?: string, processedBy?: string) => {
    setProcessing(true);
    try {
      // Update request status
      await updateDeletionRequest(requestId, {
        isProcessed: true,
        status: 'approved',
        processedBy: processedBy || 'admin',
        adminNotes: adminNotes || '',
      });

      // Execute deletion process - this will be handled by the component using useUserDeletion hook
      // await executeUserDeletion(userId!, processedBy || 'admin');
      
      return { success: true, message: 'Deletion request approved and user deleted successfully' };
    } catch (error) {
      console.error('Error approving deletion request:', error);
      throw error;
    } finally {
      setProcessing(false);
    }
  };

  // Reject deletion request
  const rejectRequest = async (requestId: string, adminNotes?: string, processedBy?: string) => {
    setProcessing(true);
    try {
      // Update request status
      await updateDeletionRequest(requestId, {
        isProcessed: true,
        status: 'rejected',
        processedBy: processedBy || 'admin',
        adminNotes: adminNotes || '',
      });

      // Update user document to remove deletion flag
      if (userId) {
        const userRef = doc(db, 'users', userId);
        await updateDoc(userRef, {
          isRequestedToBeDeleted: false
        });
      }

      return { success: true, message: 'Deletion request rejected successfully' };
    } catch (error) {
      console.error('Error rejecting deletion request:', error);
      throw error;
    } finally {
      setProcessing(false);
    }
  };

  // Update admin notes
  const updateAdminNotes = async (requestId: string, adminNotes: string, processedBy?: string) => {
    try {
      const requestRef = doc(db, 'accountDeleteRequests', requestId);
      await updateDoc(requestRef, {
        adminNotes,
        updatedAt: serverTimestamp(),
        lastUpdatedBy: processedBy || 'admin',
      });
      return { success: true, message: 'Admin notes updated successfully' };
    } catch (error) {
      console.error('Error updating admin notes:', error);
      throw error;
    }
  };

  return {
    deletionRequests: allRequests,
    loading,
    error,
    processing,
    approveRequest,
    rejectRequest,
    updateAdminNotes,
    refetch: fetchAllRequests,
  };
}

export function useDeletionRequestsByStatus(status: 'pending' | 'processed' | 'canceled') {
  // Build query based on status with proper conditions
  let queryConstraints;
  if (status === 'pending') {
    queryConstraints = [
      where('isProcessed', '==', false),
      where('isCanceled', '==', false),
      orderBy('requestedAt', 'asc'),
      limit(100)
    ];
  } else if (status === 'processed') {
    queryConstraints = [
      where('isProcessed', '==', true),
      orderBy('requestedAt', 'asc'),
      limit(100)
    ];
  } else { // canceled
    queryConstraints = [
      where('isCanceled', '==', true),
      orderBy('requestedAt', 'asc'),
      limit(100)
    ];
  }

  const [snapshot, loading, error] = useCollection(
    query(collection(db, 'accountDeleteRequests'), ...queryConstraints)
  );

  const deletionRequests: AccountDeleteRequest[] = 
    snapshot?.docs.map((doc) => {
      const data = doc.data() as DocumentData;
      return {
        id: doc.id,
        userId: data.userId,
        userEmail: data.userEmail,
        userName: data.userName,
        requestedAt: data.requestedAt?.toDate() || new Date(),
        reasonId: data.reasonId,
        reasonDetails: data.reasonDetails,
        reasonCategory: data.reasonCategory,
        isCanceled: data.isCanceled || false,
        isProcessed: data.isProcessed || false,
        canceledAt: data.canceledAt?.toDate(),
        processedAt: data.processedAt?.toDate(),
        processedBy: data.processedBy,
        adminNotes: data.adminNotes,
      };
    }) || [];

  return {
    deletionRequests,
    loading,
    error,
  };
}

export function useDeletionRequestStats() {
  const [pendingSnapshot, pendingLoading] = useCollection(
    query(
      collection(db, 'accountDeleteRequests'),
      where('isProcessed', '==', false),
      where('isCanceled', '==', false)
    )
  );

  const [processedSnapshot, processedLoading] = useCollection(
    query(
      collection(db, 'accountDeleteRequests'),
      where('isProcessed', '==', true)
    )
  );

  const [canceledSnapshot, canceledLoading] = useCollection(
    query(
      collection(db, 'accountDeleteRequests'),
      where('isCanceled', '==', true)
    )
  );

  const loading = pendingLoading || processedLoading || canceledLoading;

  const stats = {
    pending: pendingSnapshot?.size || 0,
    processed: processedSnapshot?.size || 0,
    canceled: canceledSnapshot?.size || 0,
    total: (pendingSnapshot?.size || 0) + (processedSnapshot?.size || 0) + (canceledSnapshot?.size || 0),
  };

  return {
    stats,
    loading,
  };
}

// Debug hook to test collection access
export function useDebugDeletionRequests() {
  const [snapshot, loading, error] = useCollection(
    collection(db, 'accountDeleteRequests')
  );

  console.log('🔍 Debug Collection Access:', {
    loading,
    error: error?.message,
    snapshotExists: !!snapshot,
    totalDocs: snapshot?.size || 0,
    docs: snapshot?.docs?.map(doc => ({
      id: doc.id,
      userId: doc.data()?.userId,
      userEmail: doc.data()?.userEmail,
      requestedAt: doc.data()?.requestedAt
    })) || []
  });

  return {
    allRequests: snapshot?.docs || [],
    loading,
    error,
  };
}

// Alternative collection names to test
export function useAlternativeDeletionRequests(userId?: string) {
  // Test different possible collection names
  const collectionNames = [
    'accountDeleteRequests',
    'account_delete_requests', 
    'deletion_requests',
    'deletionRequests',
    'user_deletion_requests'
  ];

  const results = collectionNames.map(name => {
    const [snapshot, loading, error] = useCollection(
      userId
        ? query(collection(db, name), where('userId', '==', userId))
        : collection(db, name)
    );
    
    console.log(`Testing collection "${name}":`, {
      exists: !!snapshot,
      docs: snapshot?.size || 0,
      error: error?.message
    });

    return {
      collectionName: name,
      snapshot,
      loading,
      error,
      docCount: snapshot?.size || 0
    };
  });

  return results;
}

// Hook for executing user deletion using React Firebase hooks
export function useUserDeletion() {
  const [processing, setProcessing] = useState(false);
  const [progress, setProgress] = useState<string>('');

  const executeUserDeletion = async (userId: string, processedBy: string) => {
    setProcessing(true);
    setProgress('Starting deletion process...');
    
    const auditRecord = {
      userId,
      userEmail: '',
      deletionStartedAt: new Date(),
      deletionCompletedAt: undefined as Date | undefined,
      totalDuration: undefined as number | undefined,
      processedBy,
      collectionsProcessed: {
        communityProfiles: { updated: 0, errors: 0 },
        forumPosts: { found: 0, errors: 0 },
        comments: { found: 0, errors: 0 },
        interactions: { found: 0, errors: 0 },
        communityInterest: { deleted: 0, errors: 0 },
        activities: { deleted: 0, errors: 0 },
        emotions: { deleted: 0, errors: 0 },
        followups: { deleted: 0, errors: 0 },
        diaries: { deleted: 0, errors: 0 },
        mainUserDocument: { deleted: 0, errors: 0 },
        firebaseAuth: { deleted: 0, errors: 0 }
      },
      errors: [] as string[],
      success: false,
      rollbackInfo: {
        communityProfilesOriginalData: [] as any[],
        softDeletesPerformed: [] as any[],
        hardDeletesPerformed: [] as string[],
        canRollback: true
      }
    };

    try {
      // Step 0: Validation Phase
      setProgress('Validating user data...');
      await validateUserForDeletion(userId, auditRecord);

      // Step 1: Community Data Soft Deletion (Reversible)
      setProgress('Processing community data...');
      await softDeleteCommunityDataWithRollback(userId, auditRecord);

      // Step 2: Vault Data Hard Deletion (Point of no return)
      setProgress('Deleting vault data...');
      auditRecord.rollbackInfo.canRollback = false; // Past point of no return
      await hardDeleteVaultData(userId, auditRecord);

      // Step 3: User Profile Hard Deletion
      setProgress('Deleting user profile...');
      await hardDeleteUserProfile(userId, auditRecord);

      // Step 4: Firebase Auth Deletion (using Admin API)
      setProgress('Deleting authentication...');
      await deleteFirebaseAuth(userId, auditRecord);

      // Mark as successful
      auditRecord.success = true;
      auditRecord.deletionCompletedAt = new Date();
      auditRecord.totalDuration = auditRecord.deletionCompletedAt.getTime() - auditRecord.deletionStartedAt.getTime();

      // Step 5: Create Audit Trail
      setProgress('Creating audit trail...');
      const auditRef = doc(db, 'deletedUsers', userId);
      await setDoc(auditRef, auditRecord);

      setProgress('Deletion completed successfully');
      return auditRecord;

    } catch (error) {
      console.error('Error during user deletion:', error);
      auditRecord.errors.push(`Fatal error: ${error}`);
      auditRecord.deletionCompletedAt = new Date();
      auditRecord.totalDuration = auditRecord.deletionCompletedAt.getTime() - auditRecord.deletionStartedAt.getTime();

      // Attempt rollback if possible
      if (auditRecord.rollbackInfo.canRollback && auditRecord.rollbackInfo.softDeletesPerformed.length > 0) {
        setProgress('Attempting rollback...');
        try {
          await performRollback(userId, auditRecord);
          auditRecord.errors.push('Rollback completed successfully');
        } catch (rollbackError) {
          console.error('Rollback failed:', rollbackError);
          auditRecord.errors.push(`Rollback failed: ${rollbackError}`);
        }
      } else {
        auditRecord.errors.push('Rollback not possible - hard deletes already performed');
      }

      // Still create audit record even on failure
      try {
        const auditRef = doc(db, 'deletedUsers', userId);
        await setDoc(auditRef, auditRecord);
      } catch (auditError) {
        console.error('Failed to create audit record:', auditError);
      }

      throw error;
    } finally {
      setProcessing(false);
      setProgress('');
    }
  };

  // Note: The old softDeleteCommunityData function has been replaced with 
  // softDeleteCommunityDataWithRollback for enhanced error recovery

  const hardDeleteVaultData = async (userId: string, auditRecord: any) => {
    const subcollections = ['activities', 'emotions', 'followups', 'diaries'];
    
    for (const subcollection of subcollections) {
      try {
        const subcollectionQuery = query(collection(db, 'users', userId, subcollection));
        const snapshot = await getDocs(subcollectionQuery);
        
        const batch = writeBatch(db);
        let batchCount = 0;
        
        for (const docSnap of snapshot.docs) {
          if (batchCount >= 490) {
            await batch.commit();
            batchCount = 0;
          }
          
          batch.delete(docSnap.ref);
          batchCount++;
          (auditRecord.collectionsProcessed as any)[subcollection].deleted++;
        }
        
        if (batchCount > 0) {
          await batch.commit();
        }
        
      } catch (error) {
        (auditRecord.collectionsProcessed as any)[subcollection].errors++;
        auditRecord.errors.push(`${subcollection} deletion error: ${error}`);
      }
    }
  };

  const hardDeleteUserProfile = async (userId: string, auditRecord: any) => {
    try {
      const userRef = doc(db, 'users', userId);
      await deleteDoc(userRef);
      auditRecord.collectionsProcessed.mainUserDocument.deleted++;
    } catch (error) {
      auditRecord.collectionsProcessed.mainUserDocument.errors++;
      auditRecord.errors.push(`User profile deletion error: ${error}`);
      throw error;
    }
  };

  const deleteFirebaseAuth = async (userId: string, auditRecord: any) => {
    try {
      // Call the admin API to delete Firebase Auth user
      const response = await fetch(`/api/admin/users/${userId}/deletion`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to delete Firebase Auth user');
      }

      auditRecord.collectionsProcessed.firebaseAuth.deleted++;
    } catch (error) {
      auditRecord.collectionsProcessed.firebaseAuth.errors++;
      auditRecord.errors.push(`Firebase Auth deletion error: ${error}`);
      throw error;
    }
  };

  // Validation function to check if user can be deleted
  const validateUserForDeletion = async (userId: string, auditRecord: any) => {
    try {
      // Check if user exists
      const userRef = doc(db, 'users', userId);
      const userDoc = await getDocs(query(collection(db, 'users'), where(documentId(), '==', userId)));
      
      if (userDoc.empty) {
        throw new Error(`User ${userId} not found in users collection`);
      }

      // Check if user has community profiles
      const communityProfilesQuery = query(collection(db, 'communityProfiles'), where('userUID', '==', userId));
      const communityProfilesSnapshot = await getDocs(communityProfilesQuery);
      
      console.log(`Validation: Found ${communityProfilesSnapshot.docs.length} community profiles for user ${userId}`);
      
      // Check for active processes that might interfere
      const pendingDeletionQuery = query(
        collection(db, 'accountDeleteRequests'), 
        where('userId', '==', userId),
        where('isProcessed', '==', false),
        where('isCanceled', '==', false)
      );
      const pendingDeletions = await getDocs(pendingDeletionQuery);
      
      if (pendingDeletions.docs.length === 0) {
        console.warn('No pending deletion request found - proceeding anyway');
      }

      return true;
    } catch (error) {
      auditRecord.errors.push(`Validation failed: ${error}`);
      throw error;
    }
  };

  // Enhanced soft delete with rollback capability
  const softDeleteCommunityDataWithRollback = async (userId: string, auditRecord: any) => {
    const batch = writeBatch(db);
    let batchCount = 0;
    let communityProfileIds: string[] = [];

    try {
      // 1. Store original community profiles data for rollback
      const communityProfilesQuery = query(collection(db, 'communityProfiles'), where('userUID', '==', userId));
      const communityProfilesSnapshot = await getDocs(communityProfilesQuery);
      
      // Store original data
      auditRecord.rollbackInfo.communityProfilesOriginalData = communityProfilesSnapshot.docs.map(doc => ({
        id: doc.id,
        data: doc.data()
      }));
      
      communityProfileIds = communityProfilesSnapshot.docs.map(doc => doc.id);
      
      // Update community profiles
      for (const profileDoc of communityProfilesSnapshot.docs) {
        if (batchCount >= 490) {
          await batch.commit();
          batchCount = 0;
        }
        
        const originalData = profileDoc.data();
        
        batch.update(profileDoc.ref, {
          isDeleted: true,
          deletedAt: serverTimestamp(),
          displayName: 'Deleted User',
          avatarUrl: null,
          updatedAt: serverTimestamp(),
          // Store original data for potential rollback
          _rollbackData: {
            displayName: originalData.displayName,
            avatarUrl: originalData.avatarUrl,
            isDeleted: originalData.isDeleted || false
          }
        });
        batchCount++;
        auditRecord.collectionsProcessed.communityProfiles.updated++;
        
        // Track for rollback
        auditRecord.rollbackInfo.softDeletesPerformed.push({
          collection: 'communityProfiles',
          docId: profileDoc.id,
          type: 'community_profile_soft_delete'
        });
      }
      
      console.log(`Found ${communityProfilesSnapshot.docs.length} community profiles for user ${userId}`);

      // NOTE: Posts, comments, and interactions are kept visible but their authors show as "Deleted User"
      // This preserves content while indicating the author is no longer a member
      const profileIdsToCheck = communityProfileIds.length > 0 ? communityProfileIds : [userId];
      
      // Count existing posts/comments/interactions for audit purposes (but don't modify them)
      for (const profileId of profileIdsToCheck) {
        // Count forum posts (for audit trail only - not deleting)
        const postsQuery = query(collection(db, 'forumPosts'), where('authorCPId', '==', profileId));
        const postsSnapshot = await getDocs(postsQuery);
        auditRecord.collectionsProcessed.forumPosts.found = (auditRecord.collectionsProcessed.forumPosts.found || 0) + postsSnapshot.size;
        
        // Count comments (for audit trail only - not deleting)
        const commentsQuery = query(collection(db, 'comments'), where('authorCPId', '==', profileId));
        const commentsSnapshot = await getDocs(commentsQuery);
        auditRecord.collectionsProcessed.comments.found = (auditRecord.collectionsProcessed.comments.found || 0) + commentsSnapshot.size;
        
        // Count interactions (for audit trail only - not deleting)
        const interactionsQuery = query(collection(db, 'interactions'), where('userCPId', '==', profileId));
        const interactionsSnapshot = await getDocs(interactionsQuery);
        auditRecord.collectionsProcessed.interactions.found = (auditRecord.collectionsProcessed.interactions.found || 0) + interactionsSnapshot.size;
      }

      // Handle communityInterest deletion (hard delete - not rollback-able)
      try {
        if (batchCount >= 490) {
          await batch.commit();
          batchCount = 0;
        }
        
        // First try direct document ID approach
        try {
          const communityInterestRef = doc(db, 'communityInterest', userId);
          batch.delete(communityInterestRef);
          batchCount++;
          auditRecord.collectionsProcessed.communityInterest.deleted++;
          auditRecord.rollbackInfo.hardDeletesPerformed.push(`communityInterest/${userId}`);
        } catch (directDeleteError) {
          // If direct delete fails, try querying by userUID field
          console.log('Direct delete failed, trying query approach for communityInterest');
          const communityInterestQuery = query(collection(db, 'communityInterest'), where('userUID', '==', userId));
          const communityInterestSnapshot = await getDocs(communityInterestQuery);
          
          for (const interestDoc of communityInterestSnapshot.docs) {
            if (batchCount >= 490) {
              await batch.commit();
              batchCount = 0;
            }
            
            batch.delete(interestDoc.ref);
            batchCount++;
            auditRecord.collectionsProcessed.communityInterest.deleted++;
            auditRecord.rollbackInfo.hardDeletesPerformed.push(`communityInterest/${interestDoc.id}`);
          }
        }
      } catch (error) {
        auditRecord.collectionsProcessed.communityInterest.errors++;
        auditRecord.errors.push(`Community interest error: ${error}`);
      }

      // Commit final batch
      if (batchCount > 0) {
        await batch.commit();
      }

      console.log(`✅ Soft delete completed. ${auditRecord.rollbackInfo.softDeletesPerformed.length} operations can be rolled back.`);

    } catch (error) {
      auditRecord.errors.push(`Community data soft deletion error: ${error}`);
      throw error;
    }
  };

  // Rollback function to reverse soft deletes
  const performRollback = async (userId: string, auditRecord: any) => {
    console.log('🔄 Starting rollback process...');
    
    const rollbackBatch = writeBatch(db);
    let rollbackCount = 0;
    
    try {
      // Rollback soft deletes
      for (const operation of auditRecord.rollbackInfo.softDeletesPerformed) {
        if (rollbackCount >= 490) {
          await rollbackBatch.commit();
          rollbackCount = 0;
        }
        
        const docRef = doc(db, operation.collection, operation.docId);
        
        // Get current document to extract rollback data
        const docSnapshot = await getDocs(query(collection(db, operation.collection), where(documentId(), '==', operation.docId)));
        
        if (!docSnapshot.empty) {
          const currentData = docSnapshot.docs[0].data();
          const rollbackData = currentData._rollbackData;
          
          if (rollbackData) {
            // Restore original values and remove rollback data
            const restoreUpdate: any = {
              isDeleted: rollbackData.isDeleted,
              updatedAt: serverTimestamp(),
              _rollbackData: null // Remove rollback data
            };
            
            // Restore collection-specific fields
            if (operation.type === 'community_profile_soft_delete') {
              restoreUpdate.displayName = rollbackData.displayName;
              restoreUpdate.avatarUrl = rollbackData.avatarUrl;
              restoreUpdate.deletedAt = null;
            } else if (operation.type === 'forum_post_soft_delete') {
              restoreUpdate.title = rollbackData.title;
              restoreUpdate.body = rollbackData.body;
              restoreUpdate.deletedAt = null;
            } else if (operation.type === 'comment_soft_delete') {
              restoreUpdate.body = rollbackData.body;
              restoreUpdate.deletedAt = null;
            } else if (operation.type === 'interaction_soft_delete') {
              restoreUpdate.deletedAt = null;
            }
            
            rollbackBatch.update(docRef, restoreUpdate);
            rollbackCount++;
          }
        }
      }
      
      // Commit rollback batch
      if (rollbackCount > 0) {
        await rollbackBatch.commit();
        console.log(`✅ Rollback completed. Restored ${rollbackCount} documents.`);
      }
      
    } catch (error) {
      console.error('❌ Rollback failed:', error);
      throw error;
    }
  };

  return {
    executeUserDeletion,
    processing,
    progress
  };
}

