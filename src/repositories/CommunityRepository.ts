import { 
  collection,
  doc,
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  Timestamp,
  writeBatch,
  increment
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { 
  CommunityProfile,
  ForumPost,
  Comment,
  Interaction,
  Group,
  PostCategory,
  FeatureInterest,
  CommunityProfileFilters,
  ForumPostFilters,
  CommentFilters,
  InteractionFilters,
  GroupFilters,
  CreateCommunityProfileRequest,
  UpdateCommunityProfileRequest,
  CreateForumPostRequest,
  UpdateForumPostRequest,
  CreateCommentRequest,
  UpdateCommentRequest,
  CreateGroupRequest,
  UpdateGroupRequest,
  CommunityAnalytics
} from '@/types/community';

export class CommunityRepository {
  // Community Profiles
  async getCommunityProfiles(filters?: CommunityProfileFilters): Promise<CommunityProfile[]> {
    try {
      let q = query(collection(db, 'communityProfiles'), orderBy('createdAt', 'desc'));
      
      if (filters?.gender) {
        q = query(q, where('gender', '==', filters.gender));
      }
      
      if (filters?.isAnonymous !== undefined) {
        q = query(q, where('isAnonymous', '==', filters.isAnonymous));
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as CommunityProfile[];
    } catch (error) {
      console.error('Error fetching community profiles:', error);
      throw error;
    }
  }

  async getCommunityProfile(id: string): Promise<CommunityProfile | null> {
    try {
      const docSnap = await getDoc(doc(db, 'communityProfiles', id));
      if (!docSnap.exists()) return null;
      
      return {
        id: docSnap.id,
        ...docSnap.data(),
        createdAt: docSnap.data().createdAt?.toDate() || new Date(),
        updatedAt: docSnap.data().updatedAt?.toDate(),
      } as CommunityProfile;
    } catch (error) {
      console.error('Error fetching community profile:', error);
      throw error;
    }
  }

  async createCommunityProfile(data: CreateCommunityProfileRequest): Promise<CommunityProfile> {
    try {
      const docRef = await addDoc(collection(db, 'communityProfiles'), {
        ...data,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
      
      const created = await this.getCommunityProfile(docRef.id);
      if (!created) throw new Error('Failed to retrieve created profile');
      return created;
    } catch (error) {
      console.error('Error creating community profile:', error);
      throw error;
    }
  }

  async updateCommunityProfile(id: string, data: UpdateCommunityProfileRequest): Promise<CommunityProfile> {
    try {
      await updateDoc(doc(db, 'communityProfiles', id), {
        ...data,
        updatedAt: Timestamp.now(),
      });
      
      const updated = await this.getCommunityProfile(id);
      if (!updated) throw new Error('Failed to retrieve updated profile');
      return updated;
    } catch (error) {
      console.error('Error updating community profile:', error);
      throw error;
    }
  }

  async deleteCommunityProfile(id: string): Promise<void> {
    try {
      await deleteDoc(doc(db, 'communityProfiles', id));
    } catch (error) {
      console.error('Error deleting community profile:', error);
      throw error;
    }
  }

  // Forum Posts
  async getForumPosts(filters?: ForumPostFilters): Promise<ForumPost[]> {
    try {
      let q = query(collection(db, 'forumPosts'), orderBy('createdAt', 'desc'));
      
      if (filters?.category) {
        q = query(q, where('category', '==', filters.category));
      }
      
      if (filters?.authorCPId) {
        q = query(q, where('authorCPId', '==', filters.authorCPId));
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as ForumPost[];
    } catch (error) {
      console.error('Error fetching forum posts:', error);
      throw error;
    }
  }

  async getForumPost(id: string): Promise<ForumPost | null> {
    try {
      const docSnap = await getDoc(doc(db, 'forumPosts', id));
      if (!docSnap.exists()) return null;
      
      return {
        id: docSnap.id,
        ...docSnap.data(),
        createdAt: docSnap.data().createdAt?.toDate() || new Date(),
        updatedAt: docSnap.data().updatedAt?.toDate(),
      } as ForumPost;
    } catch (error) {
      console.error('Error fetching forum post:', error);
      throw error;
    }
  }

  async createForumPost(data: CreateForumPostRequest): Promise<ForumPost> {
    try {
      const docRef = await addDoc(collection(db, 'forumPosts'), {
        ...data,
        score: 0,
        likeCount: 0,
        dislikeCount: 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
      
      const created = await this.getForumPost(docRef.id);
      if (!created) throw new Error('Failed to retrieve created post');
      return created;
    } catch (error) {
      console.error('Error creating forum post:', error);
      throw error;
    }
  }

  async updateForumPost(id: string, data: UpdateForumPostRequest): Promise<ForumPost> {
    try {
      await updateDoc(doc(db, 'forumPosts', id), {
        ...data,
        updatedAt: Timestamp.now(),
      });
      
      const updated = await this.getForumPost(id);
      if (!updated) throw new Error('Failed to retrieve updated post');
      return updated;
    } catch (error) {
      console.error('Error updating forum post:', error);
      throw error;
    }
  }

  async deleteForumPost(id: string): Promise<void> {
    try {
      const batch = writeBatch(db);
      
      // Delete the post
      batch.delete(doc(db, 'forumPosts', id));
      
      // Delete associated comments
      const commentsQuery = query(collection(db, 'comments'), where('postId', '==', id));
      const commentsSnapshot = await getDocs(commentsQuery);
      commentsSnapshot.docs.forEach(commentDoc => {
        batch.delete(commentDoc.ref);
      });
      
      // Delete associated interactions
      const interactionsQuery = query(collection(db, 'interactions'), where('targetId', '==', id));
      const interactionsSnapshot = await getDocs(interactionsQuery);
      interactionsSnapshot.docs.forEach(interactionDoc => {
        batch.delete(interactionDoc.ref);
      });
      
      await batch.commit();
    } catch (error) {
      console.error('Error deleting forum post:', error);
      throw error;
    }
  }

  // Comments
  async getComments(filters?: CommentFilters): Promise<Comment[]> {
    try {
      let q = query(collection(db, 'comments'), orderBy('createdAt', 'desc'));
      
      if (filters?.postId) {
        q = query(q, where('postId', '==', filters.postId));
      }
      
      if (filters?.authorCPId) {
        q = query(q, where('authorCPId', '==', filters.authorCPId));
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as Comment[];
    } catch (error) {
      console.error('Error fetching comments:', error);
      throw error;
    }
  }

  async getComment(id: string): Promise<Comment | null> {
    try {
      const docSnap = await getDoc(doc(db, 'comments', id));
      if (!docSnap.exists()) return null;
      
      return {
        id: docSnap.id,
        ...docSnap.data(),
        createdAt: docSnap.data().createdAt?.toDate() || new Date(),
        updatedAt: docSnap.data().updatedAt?.toDate(),
      } as Comment;
    } catch (error) {
      console.error('Error fetching comment:', error);
      throw error;
    }
  }

  async createComment(data: CreateCommentRequest): Promise<Comment> {
    try {
      const docRef = await addDoc(collection(db, 'comments'), {
        ...data,
        score: 0,
        likeCount: 0,
        dislikeCount: 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
      
      const created = await this.getComment(docRef.id);
      if (!created) throw new Error('Failed to retrieve created comment');
      return created;
    } catch (error) {
      console.error('Error creating comment:', error);
      throw error;
    }
  }

  async deleteComment(id: string): Promise<void> {
    try {
      const batch = writeBatch(db);
      
      // Delete the comment
      batch.delete(doc(db, 'comments', id));
      
      // Delete associated interactions
      const interactionsQuery = query(collection(db, 'interactions'), where('targetId', '==', id));
      const interactionsSnapshot = await getDocs(interactionsQuery);
      interactionsSnapshot.docs.forEach(interactionDoc => {
        batch.delete(interactionDoc.ref);
      });
      
      await batch.commit();
    } catch (error) {
      console.error('Error deleting comment:', error);
      throw error;
    }
  }

  // Interactions
  async getInteractions(filters?: InteractionFilters): Promise<Interaction[]> {
    try {
      let q = query(collection(db, 'interactions'), orderBy('createdAt', 'desc'));
      
      if (filters?.targetType) {
        q = query(q, where('targetType', '==', filters.targetType));
      }
      
      if (filters?.targetId) {
        q = query(q, where('targetId', '==', filters.targetId));
      }
      
      if (filters?.userCPId) {
        q = query(q, where('userCPId', '==', filters.userCPId));
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as Interaction[];
    } catch (error) {
      console.error('Error fetching interactions:', error);
      throw error;
    }
  }

  async getUserInteraction(userCPId: string, targetType: string, targetId: string): Promise<Interaction | null> {
    try {
      const q = query(
        collection(db, 'interactions'),
        where('userCPId', '==', userCPId),
        where('targetType', '==', targetType),
        where('targetId', '==', targetId),
        limit(1)
      );
      
      const snapshot = await getDocs(q);
      if (snapshot.empty) return null;
      
      const doc = snapshot.docs[0];
      return {
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate(),
      } as Interaction;
    } catch (error) {
      console.error('Error fetching user interaction:', error);
      throw error;
    }
  }

  async createOrUpdateInteraction(userCPId: string, targetType: 'post' | 'comment', targetId: string, value: number): Promise<void> {
    try {
      const existing = await this.getUserInteraction(userCPId, targetType, targetId);
      const batch = writeBatch(db);
      
      if (existing) {
        // Update existing interaction
        const oldValue = existing.value;
        batch.update(doc(db, 'interactions', existing.id), {
          value,
          updatedAt: Timestamp.now(),
        });
        
        // Update target counts
        const targetCollection = targetType === 'post' ? 'forumPosts' : 'comments';
        const targetRef = doc(db, targetCollection, targetId);
        
        if (oldValue !== value) {
          if (oldValue === 1 && value === -1) {
            // Changed from like to dislike
            batch.update(targetRef, {
              likeCount: increment(-1),
              dislikeCount: increment(1),
              score: increment(-2),
            });
          } else if (oldValue === -1 && value === 1) {
            // Changed from dislike to like
            batch.update(targetRef, {
              likeCount: increment(1),
              dislikeCount: increment(-1),
              score: increment(2),
            });
          } else if (oldValue === 1 && value === 0) {
            // Removed like
            batch.update(targetRef, {
              likeCount: increment(-1),
              score: increment(-1),
            });
          } else if (oldValue === -1 && value === 0) {
            // Removed dislike
            batch.update(targetRef, {
              dislikeCount: increment(-1),
              score: increment(1),
            });
          } else if (oldValue === 0 && value === 1) {
            // Added like
            batch.update(targetRef, {
              likeCount: increment(1),
              score: increment(1),
            });
          } else if (oldValue === 0 && value === -1) {
            // Added dislike
            batch.update(targetRef, {
              dislikeCount: increment(1),
              score: increment(-1),
            });
          }
        }
      } else {
        // Create new interaction
        const interactionId = `${userCPId}_${targetType}_${targetId}`;
        batch.set(doc(db, 'interactions', interactionId), {
          targetType,
          targetId,
          userCPId,
          type: 'like',
          value,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        });
        
        // Update target counts
        const targetCollection = targetType === 'post' ? 'forumPosts' : 'comments';
        const targetRef = doc(db, targetCollection, targetId);
        
        if (value === 1) {
          batch.update(targetRef, {
            likeCount: increment(1),
            score: increment(1),
          });
        } else if (value === -1) {
          batch.update(targetRef, {
            dislikeCount: increment(1),
            score: increment(-1),
          });
        }
      }
      
      await batch.commit();
    } catch (error) {
      console.error('Error creating/updating interaction:', error);
      throw error;
    }
  }

  // Groups
  async getGroups(filters?: GroupFilters): Promise<Group[]> {
    try {
      let q = query(collection(db, 'groups'), orderBy('createdAt', 'desc'));
      
      if (filters?.gender) {
        q = query(q, where('gender', '==', filters.gender));
      }
      
      if (filters?.isActive !== undefined) {
        q = query(q, where('isActive', '==', filters.isActive));
      }

      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate() || new Date(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as Group[];
    } catch (error) {
      console.error('Error fetching groups:', error);
      throw error;
    }
  }

  async getGroup(id: string): Promise<Group | null> {
    try {
      const docSnap = await getDoc(doc(db, 'groups', id));
      if (!docSnap.exists()) return null;
      
      return {
        id: docSnap.id,
        ...docSnap.data(),
        createdAt: docSnap.data().createdAt?.toDate() || new Date(),
        updatedAt: docSnap.data().updatedAt?.toDate(),
      } as Group;
    } catch (error) {
      console.error('Error fetching group:', error);
      throw error;
    }
  }

  async createGroup(data: CreateGroupRequest): Promise<Group> {
    try {
      // F3 Support Groups Schema Compliant Creation
      const groupData: any = {
        name: data.name,
        description: data.description,
        memberCapacity: data.memberCapacity,
        gender: data.gender,
        adminCpId: data.adminCpId,
        createdByCpId: data.createdByCpId,
        visibility: data.visibility,
        joinMethod: data.joinMethod,
        joinCodeExpiresAt: null,
        joinCodeMaxUses: null,
        joinCodeUseCount: 0,
        isActive: true,
        isPaused: false,
        pauseReason: null,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        // NOTE: memberCount is NOT stored per F3 schema - calculated from group_memberships
      };

      // Generate join code for code_only groups
      if (data.joinMethod === 'code_only') {
        groupData.joinCode = this.generateJoinCode();
      }

      const docRef = await addDoc(collection(db, 'groups'), groupData);
      
      const created = await this.getGroup(docRef.id);
      if (!created) throw new Error('Failed to retrieve created group');
      return created;
    } catch (error) {
      console.error('Error creating group:', error);
      throw error;
    }
  }

  // Helper method to generate join codes for code_only groups
  private generateJoinCode(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < 5; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  async updateGroup(id: string, data: UpdateGroupRequest): Promise<Group> {
    try {
      await updateDoc(doc(db, 'groups', id), {
        ...data,
        updatedAt: Timestamp.now(),
      });
      
      const updated = await this.getGroup(id);
      if (!updated) throw new Error('Failed to retrieve updated group');
      return updated;
    } catch (error) {
      console.error('Error updating group:', error);
      throw error;
    }
  }

  async deleteGroup(id: string): Promise<void> {
    try {
      await deleteDoc(doc(db, 'groups', id));
    } catch (error) {
      console.error('Error deleting group:', error);
      throw error;
    }
  }

  // Post Categories (from existing implementation)
  async getPostCategories(): Promise<PostCategory[]> {
    try {
      const q = query(collection(db, 'postCategories'), orderBy('sortOrder'));
      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate(),
        updatedAt: doc.data().updatedAt?.toDate(),
      })) as PostCategory[];
    } catch (error) {
      console.error('Error fetching post categories:', error);
      throw error;
    }
  }

  // Analytics
  async getCommunityAnalytics(): Promise<CommunityAnalytics> {
    try {
      const [postsSnapshot, commentsSnapshot, interactionsSnapshot, profilesSnapshot, groupsSnapshot] = await Promise.all([
        getDocs(collection(db, 'forumPosts')),
        getDocs(collection(db, 'comments')),
        getDocs(collection(db, 'interactions')),
        getDocs(collection(db, 'communityProfiles')),
        getDocs(query(collection(db, 'groups'), where('isActive', '==', true))),
      ]);

      const posts = postsSnapshot.docs.map(doc => ({ 
        id: doc.id, 
        ...doc.data(),
        createdAt: doc.data().createdAt,
        category: doc.data().category 
      }));
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const postsToday = posts.filter(post => {
        const postDate = post.createdAt?.toDate();
        return postDate && postDate >= today;
      }).length;

      const totalComments = commentsSnapshot.size;
      const totalPosts = postsSnapshot.size;
      const averageCommentsPerPost = totalPosts > 0 ? totalComments / totalPosts : 0;

      const totalLikes = interactionsSnapshot.docs
        .filter(doc => doc.data().value === 1)
        .length;
      const averageLikesPerPost = totalPosts > 0 ? totalLikes / totalPosts : 0;

      // Calculate most active categories
      const categoryCounts: Record<string, number> = {};
      posts.forEach(post => {
        if (post.category) {
          categoryCounts[post.category] = (categoryCounts[post.category] || 0) + 1;
        }
      });

      const mostActiveCategories = Object.entries(categoryCounts)
        .map(([categoryId, postCount]) => ({
          categoryId,
          categoryName: categoryId, // You might want to resolve this to actual category names
          postCount,
        }))
        .sort((a, b) => b.postCount - a.postCount)
        .slice(0, 5);

      return {
        totalPosts: postsSnapshot.size,
        totalComments: commentsSnapshot.size,
        totalInteractions: interactionsSnapshot.size,
        totalProfiles: profilesSnapshot.size,
        activeGroups: groupsSnapshot.size,
        postsToday,
        engagement: {
          averageCommentsPerPost,
          averageLikesPerPost,
          mostActiveCategories,
        },
      };
    } catch (error) {
      console.error('Error fetching community analytics:', error);
      throw error;
    }
  }
}

// Singleton instance
export const communityRepository = new CommunityRepository(); 