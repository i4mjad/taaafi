'use client';

import { useState, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection, useDocument } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where, doc, deleteDoc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Separator } from '@/components/ui/separator';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { 
  ArrowLeft, 
  MessageSquare, 
  ThumbsUp, 
  ThumbsDown, 
  User, 
  MoreHorizontal, 
  Edit, 
  Trash2, 
  EyeOff, 
  Eye,
  Pin,
  PinOff,
  Lock,
  Unlock,
  AlertCircle,
  ExternalLink
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { format } from 'date-fns';
import Link from 'next/link';
import { ForumPost, Comment, Interaction } from '@/types/community';
import { UserReport, REPORT_TYPE_IDS, ReportWithContext } from '@/types/reports';
import { toast } from 'sonner';
import ModerationActionDialog from '../../components/ModerationActionDialog';

export default function PostDetailPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const postId = params.postId as string;
  const lang = params.lang as string;

  const [selectedComment, setSelectedComment] = useState<Comment | null>(null);
  const [showDeletePostDialog, setShowDeletePostDialog] = useState(false);
  const [showHidePostDialog, setShowHidePostDialog] = useState(false);
  const [showPinPostDialog, setShowPinPostDialog] = useState(false);
  const [showDeleteCommentDialog, setShowDeleteCommentDialog] = useState(false);
  const [showHideCommentDialog, setShowHideCommentDialog] = useState(false);
  const [isEditingPost, setIsEditingPost] = useState(false);
  const [editFormData, setEditFormData] = useState({
    title: '',
    body: '',
    category: ''
  });
  const [editErrors, setEditErrors] = useState<Record<string, string>>({});
  const [moderationOpen, setModerationOpen] = useState(false);
  const [moderationTarget, setModerationTarget] = useState<
    | { kind: 'post'; id: string; title: string; authorCPId: string; isHidden?: boolean; isDeleted?: boolean }
    | { kind: 'comment'; id: string; title?: string; authorCPId: string; isHidden?: boolean; isDeleted?: boolean }
    | null
  >(null);

  // Fetch the specific post
  const [postValue, postLoading, postError] = useDocument(
    doc(db, 'forumPosts', postId)
  );

  // Fetch comments for this post - using a stable query that won't be affected by updates
  const [commentsValue, commentsLoading, commentsError] = useCollection(
    query(
      collection(db, 'comments'), 
      where('postId', '==', postId),
      orderBy('createdAt', 'desc')
    ),
    {
      snapshotListenOptions: { includeMetadataChanges: false }
    }
  );

  // Fetch interactions for this post
  const [interactionsValue] = useCollection(
    query(
      collection(db, 'interactions'), 
      where('targetType', '==', 'post'),
      where('targetId', '==', postId),
      orderBy('createdAt', 'desc')
    )
  );

  // Fetch community profiles for author details (name, gender, anonymity preference)
  const [profilesValue] = useCollection(
    query(collection(db, 'communityProfiles'))
  );

  // Fetch post categories
  const [categoriesValue] = useCollection(
    query(collection(db, 'postCategories'), orderBy('sortOrder'))
  );

  // Fetch reports for this post
  const [postReportsValue] = useCollection(
    query(
      collection(db, 'usersReports'),
      where('targetType', '==', 'post'),
      where('targetId', '==', postId),
      orderBy('time', 'desc')
    )
  );

  // Fetch reports for comments in this post
  const [commentReportsValue] = useCollection(
    query(
      collection(db, 'usersReports'),
      where('targetType', '==', 'comment'),
      where('reportTypeId', '==', REPORT_TYPE_IDS.COMMENT),
      orderBy('time', 'desc')
    )
  );

  const post = useMemo(() => {
    if (!postValue || !postValue.exists()) return null;
    
    return {
      id: postValue.id,
      ...postValue.data(),
      createdAt: postValue.data()?.createdAt?.toDate() || new Date(),
      updatedAt: postValue.data()?.updatedAt?.toDate(),
    } as ForumPost;
  }, [postValue]);

  const comments = useMemo(() => {
    if (!commentsValue) return [];
    
    const processedComments = commentsValue.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as Comment[];

    // Debug logging to help identify the issue
    console.log('Comments raw count:', commentsValue.docs.length);
    console.log('Processed comments:', processedComments.length);
    console.log('Comments with isDeleted:', processedComments.filter(c => c.isDeleted).length);
    
    return processedComments;
  }, [commentsValue]);

  const interactions = useMemo(() => {
    if (!interactionsValue) return [];
    
    return interactionsValue.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as Interaction[];
  }, [interactionsValue]);

  const categories = useMemo(() => {
    if (!categoriesValue) return [];
    
    return categoriesValue.docs.map(doc => ({
      id: doc.id,
      name: doc.data().name || 'Unknown',
      nameAr: doc.data().nameAr || 'غير معروف',
      isForAdminOnly: doc.data().isForAdminOnly || false,
      ...doc.data(),
    }));
  }, [categoriesValue]);

  const profilesById = useMemo(() => {
    const map = new Map<string, { displayName: string; gender: 'male' | 'female' | 'other'; isAnonymous?: boolean }>();
    if (!profilesValue) return map;
    for (const d of profilesValue.docs) {
      const data = d.data();
      map.set(d.id, {
        displayName: data.displayName || 'Unknown',
        gender: (data.gender as 'male' | 'female' | 'other') || 'other',
        isAnonymous: data.isAnonymous,
      });
    }
    return map;
  }, [profilesValue]);

  const postReports = useMemo(() => {
    if (!postReportsValue) return [];
    
    return postReportsValue.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      time: doc.data().time?.toDate() || new Date(),
      lastUpdated: doc.data().lastUpdated?.toDate() || new Date(),
    })) as UserReport[];
  }, [postReportsValue]);

  const commentReports = useMemo(() => {
    if (!commentReportsValue) return [];
    
    return commentReportsValue.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      time: doc.data().time?.toDate() || new Date(),
      lastUpdated: doc.data().lastUpdated?.toDate() || new Date(),
    })) as UserReport[];
  }, [commentReportsValue]);

  // Filter comment reports by comments in this post
  const filteredCommentReports = useMemo(() => {
    const commentIds = comments.map(c => c.id);
    return commentReports.filter(report => 
      report.targetId && commentIds.includes(report.targetId)
    );
  }, [commentReports, comments]);

  // Get category name
  const getCategoryName = (categoryId: string) => {
    const category = categories.find(cat => cat.id === categoryId);
    return category?.name || categoryId;
  };

  // Get report count for specific comment
  const getCommentReportCount = (commentId: string) => {
    return filteredCommentReports.filter(report => report.targetId === commentId).length;
  };

  // Get pending report count for specific comment
  const getCommentPendingReportCount = (commentId: string) => {
    return filteredCommentReports.filter(report => 
      report.targetId === commentId && report.status === 'pending'
    ).length;
  };

  // Initialize edit form when entering edit mode
  const initializeEditForm = () => {
    if (post) {
      setEditFormData({
        title: post.title,
        body: post.body,
        category: post.category
      });
      setEditErrors({});
      setIsEditingPost(true);
    }
  };

  // Validate edit form
  const validateEditForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!editFormData.title.trim()) {
      newErrors.title = t('modules.community.posts.errors.titleRequired');
    }

    if (!editFormData.body.trim()) {
      newErrors.body = t('modules.community.posts.errors.bodyRequired');
    }

    if (!editFormData.category) {
      newErrors.category = t('modules.community.posts.errors.categoryRequired');
    }

    setEditErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Handle edit form input changes
  const handleEditInputChange = (field: keyof typeof editFormData, value: string) => {
    setEditFormData(prev => ({ ...prev, [field]: value }));
    if (editErrors[field]) {
      setEditErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  // Custom hook for post updates using react-firebase-hooks pattern
  const usePostUpdate = () => {
    const [isUpdating, setIsUpdating] = useState(false);

    const updatePost = async (postId: string, data: Partial<typeof editFormData>) => {
      setIsUpdating(true);
      try {
        await updateDoc(doc(db, 'forumPosts', postId), {
          ...data,
          updatedAt: new Date(),
        });
        return { success: true, error: null };
      } catch (error) {
        return { success: false, error };
      } finally {
        setIsUpdating(false);
      }
    };

    return { updatePost, isUpdating };
  };

  const { updatePost, isUpdating } = usePostUpdate();

  // Handle save edit
  const handleSaveEdit = async () => {
    if (!validateEditForm() || !post) return;

    const result = await updatePost(post.id, editFormData);
    
    if (result.success) {
      toast.success(t('modules.community.posts.editSuccess'));
      setIsEditingPost(false);
    } else {
      console.error('Error updating post:', result.error);
      toast.error(t('modules.community.posts.editError'));
    }
  };

  // Handle cancel edit
  const handleCancelEdit = () => {
    setIsEditingPost(false);
    setEditFormData({ title: '', body: '', category: '' });
    setEditErrors({});
  };

  // Handle post actions
  const handleDeletePost = async () => {
    if (!post) return;

    try {
      console.log('Deleting post:', post.id);
      
      // Soft delete: mark as deleted instead of removing from database
      await updateDoc(doc(db, 'forumPosts', post.id), {
        isDeleted: true,
        updatedAt: new Date(),
      });
      
      console.log('Post marked as deleted successfully');
      toast.success(t('modules.community.posts.deleteSuccess'));
      router.push(`/${lang}/community/forum`);
    } catch (error) {
      console.error('Error deleting post:', error);
      toast.error(t('modules.community.posts.deleteError'));
    }
  };

  const handleHidePost = async () => {
    if (!post) return;

    try {
      await updateDoc(doc(db, 'forumPosts', post.id), {
        isHidden: !post.isHidden,
        updatedAt: new Date(),
      });
      toast.success(post.isHidden ? 
        t('modules.community.posts.unhideSuccess') : 
        t('modules.community.posts.hideSuccess')
      );
      setShowHidePostDialog(false);
    } catch (error) {
      console.error('Error hiding post:', error);
      toast.error(t('modules.community.posts.hideError'));
    }
  };

  const openModerationForPost = () => {
    if (!post) return;
    setModerationTarget({
      kind: 'post',
      id: post.id,
      title: post.title,
      authorCPId: post.authorCPId,
      isHidden: post.isHidden,
      isDeleted: post.isDeleted,
    });
    setModerationOpen(true);
  };
  const openModerationForComment = (comment: Comment) => {
    setModerationTarget({
      kind: 'comment',
      id: comment.id,
      title: undefined,
      authorCPId: comment.authorCPId,
      isHidden: comment.isHidden,
      isDeleted: comment.isDeleted,
    });
    setModerationOpen(true);
  };

  const handlePinPost = async () => {
    if (!post) return;

    try {
      await updateDoc(doc(db, 'forumPosts', post.id), {
        isPinned: !post.isPinned,
        updatedAt: new Date(),
      });
      toast.success(post.isPinned ? 
        t('modules.community.posts.unpinSuccess') : 
        t('modules.community.posts.pinSuccess')
      );
      setShowPinPostDialog(false);
    } catch (error) {
      console.error('Error pinning post:', error);
      toast.error(t('modules.community.posts.pinError'));
    }
  };

  // Handle comment actions
  const handleDeleteComment = async () => {
    if (!selectedComment) return;

    try {
      console.log('Deleting comment:', selectedComment.id);
      
      // Soft delete: mark as deleted instead of removing from database
      await updateDoc(doc(db, 'comments', selectedComment.id), {
        isDeleted: true,
        updatedAt: new Date(),
      });
      
      console.log('Comment marked as deleted successfully');
      toast.success(t('modules.community.comments.deleteSuccess'));
      setShowDeleteCommentDialog(false);
      setSelectedComment(null);
    } catch (error) {
      console.error('Error deleting comment:', error);
      toast.error(t('modules.community.comments.deleteError'));
    }
  };

  const handleHideComment = async () => {
    if (!selectedComment) return;

    try {
      await updateDoc(doc(db, 'comments', selectedComment.id), {
        isHidden: !selectedComment.isHidden,
        updatedAt: new Date(),
      });
      toast.success(selectedComment.isHidden ? 
        t('modules.community.comments.unhideSuccess') : 
        t('modules.community.comments.hideSuccess')
      );
      setShowHideCommentDialog(false);
      setSelectedComment(null);
    } catch (error) {
      console.error('Error hiding comment:', error);
      toast.error(t('modules.community.comments.hideError'));
    }
  };

  if (postLoading) {
    return (
      <div className="p-6 space-y-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-muted rounded w-1/3" />
          <div className="h-4 bg-muted rounded w-2/3" />
          <div className="h-32 bg-muted rounded" />
        </div>
      </div>
    );
  }

  if (postError || !post) {
    return (
      <div className="p-6 text-center">
        <h1 className="text-2xl font-bold text-destructive mb-4">
          {t('common.error')}
        </h1>
        <p className="text-muted-foreground mb-4">
          {t('modules.community.posts.postNotFound')}
        </p>
        <Button onClick={() => router.push(`/${lang}/community/forum`)}>
          {t('modules.community.posts.detailPage.backToList')}
        </Button>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center space-x-4">
        <Button 
          variant="ghost" 
          onClick={() => router.push(`/${lang}/community/forum`)}
          className="px-2"
        >
          <ArrowLeft className="h-4 w-4 mr-2" />
          {t('modules.community.posts.detailPage.backToList')}
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">
            {t('modules.community.posts.detailPage.title')}
          </h1>
          <p className="text-muted-foreground">
            {post.title}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Post Content */}
        <div className="lg:col-span-2 space-y-6">
          <Card className={post.isDeleted ? 'border-destructive bg-destructive/5' : ''}>
            <CardHeader>
              <div className="flex items-start justify-between">
                <div>
                  <CardTitle className="text-xl">
                    {post.title}
                    {post.isAnonymous && (
                      <Badge variant="secondary" className="ml-2">
                        {t('modules.community.posts.anonymous')}
                      </Badge>
                    )}
                    {post.isHidden && (
                      <Badge variant="destructive" className="ml-2">
                        {t('modules.community.posts.detailPage.hidden')}
                      </Badge>
                    )}
                    {post.isPinned && (
                      <Badge variant="default" className="ml-2">
                        <Pin className="h-3 w-3 mr-1" />
                        {t('modules.community.posts.pinned')}
                      </Badge>
                    )}
                    {post.isDeleted && (
                      <Badge variant="destructive" className="ml-2">
                        {t('modules.community.posts.detailPage.deleted')}
                      </Badge>
                    )}
                  </CardTitle>
                  <CardDescription className="mt-2">
                    <div className="flex items-center space-x-4 text-sm">
                      <span className="flex items-center space-x-1">
                        <User className="h-3 w-3" />
                        <span>{post.authorCPId}</span>
                      </span>
                      <Badge variant="outline">
                        {getCategoryName(post.category)}
                      </Badge>
                      <span>{format(post.createdAt, 'MMM dd, yyyy HH:mm')}</span>
                    </div>
                  </CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {isEditingPost ? (
                <div className="space-y-4">
                  {/* Edit Form */}
                  <div className="space-y-2">
                    <Label htmlFor="edit-title">{t('modules.community.posts.title')}</Label>
                    <Input
                      id="edit-title"
                      value={editFormData.title}
                      onChange={(e) => handleEditInputChange('title', e.target.value)}
                      className={editErrors.title ? 'border-destructive' : ''}
                      placeholder={t('modules.community.posts.titlePlaceholder')}
                    />
                    {editErrors.title && (
                      <p className="text-sm text-destructive">{editErrors.title}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="edit-category">{t('modules.community.posts.category')}</Label>
                    <Select
                      value={editFormData.category}
                      onValueChange={(value) => handleEditInputChange('category', value)}
                    >
                      <SelectTrigger className={editErrors.category ? 'border-destructive' : ''}>
                        <SelectValue placeholder={t('modules.community.posts.selectCategory')} />
                      </SelectTrigger>
                      <SelectContent>
                        {categories.map((category) => (
                          <SelectItem key={category.id} value={category.id}>
                            {category.name}
                            {category.isForAdminOnly && (
                              <span className="ml-2 text-xs text-muted-foreground">
                                ({t('modules.community.postCategories.adminOnly')})
                              </span>
                            )}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    {editErrors.category && (
                      <p className="text-sm text-destructive">{editErrors.category}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="edit-body">{t('modules.community.posts.body')}</Label>
                    <Textarea
                      id="edit-body"
                      value={editFormData.body}
                      onChange={(e) => handleEditInputChange('body', e.target.value)}
                      className={`min-h-[120px] ${editErrors.body ? 'border-destructive' : ''}`}
                      placeholder={t('modules.community.posts.bodyPlaceholder')}
                    />
                    {editErrors.body && (
                      <p className="text-sm text-destructive">{editErrors.body}</p>
                    )}
                  </div>

                  {/* Edit Actions */}
                  <div className="flex space-x-2 pt-2">
                    <Button 
                      onClick={handleSaveEdit}
                      disabled={isUpdating}
                    >
                      {isUpdating ? t('common.saving') : t('common.save')}
                    </Button>
                    <Button 
                      variant="outline" 
                      onClick={handleCancelEdit}
                      disabled={isUpdating}
                    >
                      {t('common.cancel')}
                    </Button>
                  </div>
                </div>
              ) : (
                <div className="prose max-w-none">
                  <p className={`whitespace-pre-wrap ${post.isDeleted ? 'line-through text-muted-foreground italic' : ''}`}>
                    {post.isDeleted ? t('modules.community.posts.detailPage.deletedPostText') : post.body}
                  </p>
                </div>
              )}
              
              <Separator />
              
              <div className="flex items-center space-x-6 text-sm">
                <div className="flex items-center space-x-1"> 
                  <ThumbsUp className="h-4 w-4 text-green-600" />
                  <span>{t('modules.community.posts.likes').replaceAll('{count}', post.likeCount.toString())}</span>
                </div>
                <div className="flex items-center space-x-1">
                  <ThumbsDown className="h-4 w-4 text-red-600" />
                  <span>{t('modules.community.posts.dislikes').replaceAll('{count}', post.dislikeCount.toString())}</span>
                </div>
                <div className="flex items-center space-x-1">
                  <MessageSquare className="h-4 w-4 text-blue-600" />
                  <span>{t('modules.community.posts.comments').replaceAll('{count}', comments.length.toString())}</span>
                </div>
                <div>
                  <Badge variant={post.score >= 0 ? 'default' : 'destructive'}>
                    {t('modules.community.posts.score').replaceAll('{score}', post.score.toString())}
                  </Badge>
                </div>
                {postReports.length > 0 && (
                  <div className="flex items-center space-x-1">
                    <Badge variant="destructive">
                      {postReports.length} {t('modules.community.posts.reports')}
                    </Badge>
                    {postReports.filter(r => r.status === 'pending').length > 0 && (
                      <Badge variant="outline" className="text-orange-600">
                        {postReports.filter(r => r.status === 'pending').length} {t('modules.community.posts.pendingReports')}
                      </Badge>
                    )}
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Comments Section */}
          <Card>
            <CardHeader>
              <CardTitle>{t('modules.community.posts.detailPage.commentsSection')}</CardTitle>
              <CardDescription>
                {t('modules.community.posts.commentCount').replaceAll('{count}', comments.length.toString())}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {commentsError && (
                <div className="text-center text-destructive py-4 mb-4 border border-destructive rounded p-4">
                  <p>Error loading comments: {commentsError.message}</p>
                  <Button variant="outline" size="sm" onClick={() => window.location.reload()} className="mt-2">
                    Reload Page
                  </Button>
                </div>
              )}
              {commentsLoading && (
                <div className="text-center py-8">
                  <div className="animate-pulse space-y-4">
                    <div className="h-4 bg-muted rounded w-3/4" />
                    <div className="h-4 bg-muted rounded w-1/2" />
                    <div className="h-4 bg-muted rounded w-2/3" />
                  </div>
                </div>
              )}
              {!commentsLoading && !commentsError && comments.length === 0 ? (
                <p className="text-center text-muted-foreground py-8">
                  {t('modules.community.posts.detailPage.noComments')}
                </p>
              ) : !commentsLoading && !commentsError && (
                <div className="space-y-4">
                  {comments.map((comment) => (
                    <Card key={comment.id} className={`${comment.isHidden ? 'opacity-50' : ''} ${comment.isDeleted ? 'border-destructive bg-destructive/5' : ''}`}>
                      <CardContent className="pt-4">
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center space-x-2 mb-2">
                              <User className="h-3 w-3 text-muted-foreground" />
                              <span className="text-sm font-medium">{comment.authorCPId}</span>
                              {(() => {
                                const profile = profilesById.get(comment.authorCPId);
                                if (!profile) return null;
                                return (
                                  <>
                                    <span className="text-xs text-muted-foreground">• {profile.displayName}</span>
                                    <Badge variant="outline" className="text-xs">
                                      {profile.gender === 'male' && (t('modules.community.profiles.male') || 'Male')}
                                      {profile.gender === 'female' && (t('modules.community.profiles.female') || 'Female')}
                                      {profile.gender === 'other' && (t('modules.community.profiles.other') || 'Other')}
                                    </Badge>
                                  </>
                                );
                              })()}
                              <span className="text-xs text-muted-foreground">
                                {format(comment.createdAt, 'MMM dd, yyyy HH:mm')}
                              </span>
                              {comment.isAnonymous && (
                                <Badge variant="secondary" className="text-xs">
                                  {t('modules.community.posts.anonymous')}
                                </Badge>
                              )}
                              {comment.isHidden && (
                                <Badge variant="destructive" className="text-xs">
                                  {t('modules.community.posts.detailPage.hidden')}
                                </Badge>
                              )}
                              {comment.isDeleted && (
                                <Badge variant="destructive" className="text-xs">
                                  {t('modules.community.posts.detailPage.deleted')}
                                </Badge>
                              )}
                            </div>
                            <p className={`text-sm whitespace-pre-wrap mb-2 ${comment.isDeleted ? 'line-through text-muted-foreground italic' : ''}`}>
                              {comment.isDeleted ? t('modules.community.posts.detailPage.deletedCommentText') : comment.body}
                            </p>
                            <div className="flex items-center space-x-3 text-xs text-muted-foreground">
                              <div className="flex items-center space-x-1">
                                <ThumbsUp className="h-3 w-3 text-green-600" />
                                <span>{t('modules.community.posts.likes').replaceAll('{count}', comment.likeCount.toString())}</span>
                              </div>
                              <div className="flex items-center space-x-1">
                                <ThumbsDown className="h-3 w-3 text-red-600" />
                                <span>{t('modules.community.posts.dislikes').replaceAll('{count}', comment.dislikeCount.toString())}</span>
                              </div>
                              <Badge variant={comment.score >= 0 ? 'outline' : 'destructive'} className="text-xs">
                                {t('modules.community.posts.score').replaceAll('{score}', comment.score.toString())}
                              </Badge>
                              {getCommentReportCount(comment.id) > 0 && (
                                <Badge variant="destructive" className="text-xs">
                                  {getCommentReportCount(comment.id)} {t('modules.community.comments.reports')}
                                </Badge>
                              )}
                              {getCommentPendingReportCount(comment.id) > 0 && (
                                <Badge variant="outline" className="text-orange-600 text-xs">
                                  {getCommentPendingReportCount(comment.id)} {t('modules.community.comments.pendingReports')}
                                </Badge>
                              )}
                            </div>
                          </div>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" className="h-8 w-8 p-0">
                                <span className="sr-only">{t('modules.community.posts.detailPage.accessibility.openMenu')}</span>
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem 
                                onClick={() => {
                                  setSelectedComment(comment);
                                  setShowHideCommentDialog(true);
                                }}
                              >
                                <EyeOff className="mr-2 h-4 w-4" />
                                {comment.isHidden ? 
                                  t('modules.community.posts.detailPage.commentActions.unhide') : 
                                  t('modules.community.posts.detailPage.commentActions.hide')
                                }
                              </DropdownMenuItem>
                              <DropdownMenuItem onClick={() => openModerationForComment(comment)}>
                                <AlertCircle className="mr-2 h-4 w-4" />
                                {t('modules.community.posts.moderation.quickModerate')}
                              </DropdownMenuItem>
                              {!comment.isDeleted && (
                                <DropdownMenuItem 
                                  onClick={() => {
                                    setSelectedComment(comment);
                                    setShowDeleteCommentDialog(true);
                                  }}
                                  className="text-destructive"
                                >
                                  <Trash2 className="mr-2 h-4 w-4" />
                                  {t('modules.community.posts.detailPage.commentActions.delete')}
                                </DropdownMenuItem>
                              )}
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Post Actions */}
          <Card>
            <CardHeader>
              <CardTitle>{t('modules.community.posts.detailPage.postActions')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <Button 
                variant="outline" 
                className="w-full justify-start"
                onClick={initializeEditForm}
                disabled={isEditingPost}
              >
                <Edit className="mr-2 h-4 w-4" />
                {t('modules.community.posts.detailPage.actions.editPost')}
              </Button>
              <Button 
                variant="outline" 
                className="w-full justify-start"
                onClick={() => setShowHidePostDialog(true)}
              >
                {post.isHidden ? <Eye className="mr-2 h-4 w-4" /> : <EyeOff className="mr-2 h-4 w-4" />}
                {post.isHidden ? 
                  t('modules.community.posts.detailPage.actions.unhidePost') : 
                  t('modules.community.posts.detailPage.actions.hidePost')
                }
              </Button>
              <Button 
                variant="outline" 
                className="w-full justify-start"
                onClick={openModerationForPost}
              >
                <AlertCircle className="mr-2 h-4 w-4" />
                {t('modules.community.posts.moderation.quickModerate')}
              </Button>
              <Button 
                variant="outline" 
                className="w-full justify-start"
                onClick={() => setShowPinPostDialog(true)}
              >
                {post.isPinned ? <PinOff className="mr-2 h-4 w-4" /> : <Pin className="mr-2 h-4 w-4" />}
                {post.isPinned ? 
                  t('modules.community.posts.detailPage.actions.unpinPost') : 
                  t('modules.community.posts.detailPage.actions.pinPost')
                }
              </Button>
              <Button variant="outline" className="w-full justify-start">
                <Lock className="mr-2 h-4 w-4" />
                {t('modules.community.posts.detailPage.actions.lockComments')}
              </Button>
              {!post.isDeleted && (
                <Button 
                  variant="destructive" 
                  className="w-full justify-start"
                  onClick={() => setShowDeletePostDialog(true)}
                >
                  <Trash2 className="mr-2 h-4 w-4" />
                  {t('modules.community.posts.detailPage.actions.deletePost')}
                </Button>
              )}
            </CardContent>
          </Card>

          {/* Reports */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <AlertCircle className="h-4 w-4" />
                <span>{t('modules.community.posts.detailPage.reportsSection')}</span>
              </CardTitle>
              <CardDescription>
                {(postReports.length + filteredCommentReports.length)} {t('modules.community.posts.detailPage.totalReports')}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {(postReports.length === 0 && filteredCommentReports.length === 0) ? (
                <p className="text-sm text-muted-foreground text-center py-4">
                  {t('modules.community.posts.detailPage.noReports')}
                </p>
              ) : (
                <div className="space-y-4">
                  {/* Post Reports */}
                  {postReports.length > 0 && (
                    <div>
                      <h4 className="text-sm font-medium mb-2">
                        {t('modules.community.posts.detailPage.postReports')} ({postReports.length})
                      </h4>
                      <div className="space-y-2">
                        {postReports.slice(0, 5).map((report) => (
                          <div key={report.id} className="flex items-center justify-between text-sm border rounded p-2">
                            <div className="flex-1">
                              <div className="flex items-center space-x-2">
                                <Badge variant={
                                  report.status === 'pending' ? 'destructive' :
                                  report.status === 'inProgress' ? 'default' :
                                  report.status === 'closed' ? 'outline' : 'secondary'
                                } className="text-xs">
                                  {report.status}
                                </Badge>
                                                                 <span className="text-xs text-muted-foreground">
                                   {format(report.time instanceof Date ? report.time : report.time.toDate(), 'MMM dd')}
                                 </span>
                              </div>
                              <p className="text-xs text-muted-foreground mt-1 truncate">
                                {report.initialMessage.substring(0, 60)}...
                              </p>
                            </div>
                            <Button 
                              variant="ghost" 
                              size="sm" 
                              asChild
                              className="h-6 w-6 p-0"
                            >
                              <Link href={`/${lang}/user-management/reports/${report.id}`}>
                                <ExternalLink className="h-3 w-3" />
                              </Link>
                            </Button>
                          </div>
                        ))}
                        {postReports.length > 5 && (
                          <Button variant="outline" size="sm" className="w-full" asChild>
                            <Link href={`/${lang}/user-management/reports?targetType=post&targetId=${postId}`}>
                              {t('modules.community.posts.detailPage.viewAllPostReports')}
                            </Link>
                          </Button>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Comment Reports */}
                  {filteredCommentReports.length > 0 && (
                    <div>
                      <h4 className="text-sm font-medium mb-2">
                        {t('modules.community.posts.detailPage.commentReports')} ({filteredCommentReports.length})
                      </h4>
                      <div className="space-y-2">
                        {filteredCommentReports.slice(0, 5).map((report) => {
                          const relatedComment = comments.find(c => c.id === report.targetId);
                          return (
                            <div key={report.id} className="flex items-center justify-between text-sm border rounded p-2">
                              <div className="flex-1">
                                <div className="flex items-center space-x-2">
                                  <Badge variant={
                                    report.status === 'pending' ? 'destructive' :
                                    report.status === 'inProgress' ? 'default' :
                                    report.status === 'closed' ? 'outline' : 'secondary'
                                  } className="text-xs">
                                    {report.status}
                                  </Badge>
                                                                     <span className="text-xs text-muted-foreground">
                                     {format(report.time instanceof Date ? report.time : report.time.toDate(), 'MMM dd')}
                                   </span>
                                </div>
                                <p className="text-xs text-muted-foreground mt-1 truncate">
                                  {t('modules.community.posts.detailPage.commentByAuthor').replaceAll('{author}', relatedComment?.authorCPId || 'Unknown')}
                                </p>
                              </div>
                              <Button 
                                variant="ghost" 
                                size="sm" 
                                asChild
                                className="h-6 w-6 p-0"
                              >
                                <Link href={`/${lang}/user-management/reports/${report.id}`}>
                                  <ExternalLink className="h-3 w-3" />
                                </Link>
                              </Button>
                            </div>
                          );
                        })}
                        {filteredCommentReports.length > 5 && (
                          <Button variant="outline" size="sm" className="w-full" asChild>
                            <Link href={`/${lang}/user-management/reports?targetType=comment`}>
                              {t('modules.community.posts.detailPage.viewAllCommentReports')}
                            </Link>
                          </Button>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Interactions */}
          <Card>
            <CardHeader>
              <CardTitle>{t('modules.community.posts.detailPage.interactionsSection')}</CardTitle>
            </CardHeader>
            <CardContent>
              {interactions.length === 0 ? (
                <p className="text-sm text-muted-foreground text-center py-4">
                  {t('modules.community.posts.detailPage.noInteractions')}
                </p>
              ) : (
                <div className="space-y-2">
                  {interactions.slice(0, 10).map((interaction) => (
                    <div key={interaction.id} className="flex items-center justify-between text-sm">
                      <div className="flex items-center space-x-2">
                        <User className="h-3 w-3 text-muted-foreground" />
                        <span>{interaction.userCPId}</span>
                      </div>
                      <div className="flex items-center space-x-1">
                        {interaction.value > 0 ? (
                          <ThumbsUp className="h-3 w-3 text-green-600" />
                        ) : (
                          <ThumbsDown className="h-3 w-3 text-red-600" />
                        )}
                        <span className="text-xs text-muted-foreground">
                          {format(interaction.createdAt, 'MMM dd')}
                        </span>
                      </div>
                    </div>
                  ))}
                  {interactions.length > 10 && (
                    <p className="text-xs text-muted-foreground text-center pt-2">
                      +{t('modules.community.posts.detailPage.moreInteractions').replaceAll('{count}', (interactions.length - 10).toString())}
                    </p>
                  )}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Delete Post Dialog */}
      <Dialog open={showDeletePostDialog} onOpenChange={setShowDeletePostDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.detailPage.deleteConfirm.title')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.posts.detailPage.deleteConfirm.description')}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDeletePostDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button variant="destructive" onClick={handleDeletePost}>
              {t('common.delete')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Hide Post Dialog */}
      <Dialog open={showHidePostDialog} onOpenChange={setShowHidePostDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.detailPage.hideConfirm.title')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.posts.detailPage.hideConfirm.description')}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowHidePostDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleHidePost}>
              {post.isHidden ? 
                t('modules.community.posts.detailPage.actions.unhidePost') : 
                t('modules.community.posts.detailPage.actions.hidePost')
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Pin Post Dialog */}
      <Dialog open={showPinPostDialog} onOpenChange={setShowPinPostDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {post.isPinned ? 
                t('modules.community.posts.detailPage.actions.unpinPost') : 
                t('modules.community.posts.detailPage.actions.pinPost')
              }
            </DialogTitle>
            <DialogDescription>
              {post.isPinned ? 
                t('modules.community.posts.detailPage.unpinConfirm.description') : 
                t('modules.community.posts.detailPage.pinConfirm.description')
              }
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowPinPostDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handlePinPost}>
              {post.isPinned ? 
                t('modules.community.posts.detailPage.actions.unpinPost') : 
                t('modules.community.posts.detailPage.actions.pinPost')
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Comment Dialog */}
      <Dialog open={showDeleteCommentDialog} onOpenChange={setShowDeleteCommentDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.detailPage.deleteCommentConfirm.title')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.posts.detailPage.deleteCommentConfirm.description')}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDeleteCommentDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button variant="destructive" onClick={handleDeleteComment}>
              {t('common.delete')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Hide Comment Dialog */}
      <Dialog open={showHideCommentDialog} onOpenChange={setShowHideCommentDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.detailPage.hideCommentConfirm.title')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.posts.detailPage.hideCommentConfirm.description')}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowHideCommentDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleHideComment}>
              {selectedComment?.isHidden ? 
                t('modules.community.posts.detailPage.commentActions.unhide') : 
                t('modules.community.posts.detailPage.commentActions.hide')
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Moderation Action Dialog */}
      {moderationTarget && (
        <ModerationActionDialog
          isOpen={moderationOpen}
          onOpenChange={(open) => {
            setModerationOpen(open);
            if (!open) setModerationTarget(null);
          }}
          targetType={moderationTarget.kind === 'post' ? 'post' : 'comment'}
          targetId={moderationTarget.id}
          targetTitle={moderationTarget.title}
          authorCPId={moderationTarget.authorCPId}
          contentStatus={{ isHidden: !!moderationTarget.isHidden, isDeleted: !!moderationTarget.isDeleted }}
        />
      )}
    </div>
  );
} 