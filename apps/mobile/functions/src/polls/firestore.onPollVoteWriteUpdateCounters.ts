import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function: onPollVoteWriteUpdateCounters
 * 
 * Trigger: on create/update of forumPosts/{postId}/attachments/{pollId}/votes/{cpId}
 * 
 * Purpose: Update poll aggregates (totalVotes, optionCounts) when votes are created or updated.
 * Uses transaction for consistency and handles both create and update events.
 */
export const onPollVoteWriteUpdateCounters = functions
  .region('us-central1')
  .firestore
  .document('forumPosts/{postId}/attachments/{pollId}/votes/{cpId}')
  .onWrite(async (change, context) => {
    const { postId, pollId, cpId } = context.params;
    const db = admin.firestore();
    
    try {
      console.log(`[POLL_VOTE] Processing vote change for poll ${pollId} by ${cpId}`);
      
      const pollRef = db
        .collection('forumPosts')
        .doc(postId)
        .collection('attachments')
        .doc(pollId);
      
      await db.runTransaction(async (transaction) => {
        // Get poll document
        const pollDoc = await transaction.get(pollRef);
        
        if (!pollDoc.exists) {
          console.error(`[POLL_VOTE] Poll attachment ${pollId} not found`);
          return;
        }
        
        const pollData = pollDoc.data()!;
        
        // Validate this is a poll attachment
        if (pollData.type !== 'poll') {
          console.error(`[POLL_VOTE] Attachment ${pollId} is not a poll`);
          return;
        }
        
        // Check if poll is closed
        if (pollData.isClosed) {
          console.log(`[POLL_VOTE] Poll ${pollId} is closed, ignoring vote`);
          return;
        }
        
        // Get all votes for this poll
        const votesSnap = await transaction.get(
          db.collection('forumPosts')
            .doc(postId)
            .collection('attachments')
            .doc(pollId)
            .collection('votes')
        );
        
        // Recompute aggregates from scratch for consistency
        const options: Array<{ id: string; text: string }> = pollData.options || [];
        const optionIndex: Record<string, number> = {};
        options.forEach((opt, idx) => (optionIndex[opt.id] = idx));
        
        const optionCounts = new Array(options.length).fill(0);
        let totalVotes = 0;
        
        votesSnap.docs.forEach((voteDoc) => {
          const voteData = voteDoc.data();
          const selectedOptionIds: string[] = voteData.selectedOptionIds || [];
          
          if (selectedOptionIds.length > 0) {
            totalVotes += 1;
            
            selectedOptionIds.forEach((optionId) => {
              const index = optionIndex[optionId];
              if (typeof index === 'number') {
                optionCounts[index] += 1;
              }
            });
          }
        });
        
        // Update poll document with new aggregates
        transaction.update(pollRef, {
          totalVotes,
          optionCounts,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`[POLL_VOTE] Updated poll ${pollId} aggregates: totalVotes=${totalVotes}`);
      });
      
    } catch (error) {
      console.error(`[POLL_VOTE] Error updating poll counters for ${pollId}:`, error);
      throw error;
    }
  });
