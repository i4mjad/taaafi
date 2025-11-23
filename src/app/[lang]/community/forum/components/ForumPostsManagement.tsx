'use client';

import { useState, useMemo, useRef, useEffect } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { collection, query, orderBy, where, deleteDoc, doc, updateDoc, getDocs, QueryDocumentSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Checkbox } from '@/components/ui/checkbox';
import { Search, MessageSquare, User, MoreHorizontal, Eye, Edit, Trash2, EyeOff, Plus, Pin, PinOff, X, AlertCircle, Shield, RefreshCw } from 'lucide-react';
import { ForumModerationBadge } from '@/components/forum/ForumModerationBadge';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import ModerationActionDialog from './ModerationActionDialog';
import { format } from 'date-fns';
import { ForumPost, Comment, Interaction } from '@/types/community';
import { toast } from 'sonner';
import { useRouter, useParams } from 'next/navigation';
import ForumPostForm from './ForumPostForm';
import PostDetailContent from './PostDetailContent';

export default function ForumPostsManagement() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const lang = params.lang as string;
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [genderFilter, setGenderFilter] = useState<'all' | 'male' | 'female' | 'other'>('all');
  const [moderationFilter, setModerationFilter] = useState<'all' | 'approved' | 'manual_review' | 'blocked' | 'pending'>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [selectedPost, setSelectedPost] = useState<ForumPost | null>(null);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showHideDialog, setShowHideDialog] = useState(false);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [moderationOpen, setModerationOpen] = useState(false);
  const [moderationPost, setModerationPost] = useState<ForumPost | null>(null);
  const [selectedPosts, setSelectedPosts] = useState<string[]>([]);
  const [showBulkDeleteDialog, setShowBulkDeleteDialog] = useState(false);
  const [showBulkSoftDeleteDialog, setShowBulkSoftDeleteDialog] = useState(false);
  const [bulkActionLoading, setBulkActionLoading] = useState(false);
  const [previewPostId, setPreviewPostId] = useState<string | null>(null);

  // Fetch data (one-time fetch instead of real-time listeners)
  const [postsValue, setPostsValue] = useState<any>(null);
  const [postsLoading, setPostsLoading] = useState(true);
  const [postsError, setPostsError] = useState<Error | null>(null);
  const [commentsValue, setCommentsValue] = useState<any>(null);
  const [interactionsValue, setInteractionsValue] = useState<any>(null);
  const [categoriesValue, setCategoriesValue] = useState<any>(null);
  const [profilesValue, setProfilesValue] = useState<any>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setPostsLoading(true);
        const [postsSnap, commentsSnap, interactionsSnap, categoriesSnap, profilesSnap] = await Promise.all([
          getDocs(query(collection(db, 'forumPosts'), orderBy('createdAt', 'desc'))),
          getDocs(query(collection(db, 'comments'), orderBy('createdAt', 'desc'))),
          getDocs(query(collection(db, 'interactions'), orderBy('createdAt', 'desc'))),
          getDocs(query(collection(db, 'postCategories'), orderBy('sortOrder'))),
          getDocs(query(collection(db, 'communityProfiles')))
        ]);
        
        setPostsValue(postsSnap);
        setCommentsValue(commentsSnap);
        setInteractionsValue(interactionsSnap);
        setCategoriesValue(categoriesSnap);
        setProfilesValue(profilesSnap);
        setPostsError(null);
      } catch (error) {
        console.error('Error fetching forum data:', error);
        setPostsError(error as Error);
      } finally {
        setPostsLoading(false);
      }
    };
    
    fetchData();
  }, []); // Only fetch once on mount

  // Refresh function to manually reload data
  const handleRefresh = async () => {
    try {
      setPostsLoading(true);
      const [postsSnap, commentsSnap, interactionsSnap, categoriesSnap, profilesSnap] = await Promise.all([
        getDocs(query(collection(db, 'forumPosts'), orderBy('createdAt', 'desc'))),
        getDocs(query(collection(db, 'comments'), orderBy('createdAt', 'desc'))),
        getDocs(query(collection(db, 'interactions'), orderBy('createdAt', 'desc'))),
        getDocs(query(collection(db, 'postCategories'), orderBy('sortOrder'))),
        getDocs(query(collection(db, 'communityProfiles')))
      ]);
      
      setPostsValue(postsSnap);
      setCommentsValue(commentsSnap);
      setInteractionsValue(interactionsSnap);
      setCategoriesValue(categoriesSnap);
      setProfilesValue(profilesSnap);
      setPostsError(null);
      toast.success(t('common.refreshSuccess') || 'Data refreshed');
    } catch (error) {
      console.error('Error refreshing forum data:', error);
      setPostsError(error as Error);
      toast.error(t('common.refreshError') || 'Failed to refresh data');
    } finally {
      setPostsLoading(false);
    }
  };

  const posts = useMemo(() => {
    if (!postsValue) return [];
    
    return postsValue.docs.map((doc: QueryDocumentSnapshot) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as ForumPost[];
  }, [postsValue]);

  const comments = useMemo(() => {
    if (!commentsValue) return [];
    
    return commentsValue.docs.map((doc: QueryDocumentSnapshot) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as Comment[];
  }, [commentsValue]);

  const interactions = useMemo(() => {
    if (!interactionsValue) return [];
    
    return interactionsValue.docs.map((doc: QueryDocumentSnapshot) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as Interaction[];
  }, [interactionsValue]);

  const categories = useMemo(() => {
    if (!categoriesValue) return [] as Array<{ id: string; name: string; nameAr: string; [key: string]: any }>;
    
    return categoriesValue.docs.map((doc: QueryDocumentSnapshot) => ({
      id: doc.id,
      name: doc.data().name || 'Unknown',
      nameAr: doc.data().nameAr || 'غير معروف',
      ...doc.data(),
    })) as Array<{ id: string; name: string; nameAr: string; [key: string]: any }>;
  }, [categoriesValue]);

  const cpGenderById = useMemo(() => {
    const map = new Map<string, 'male' | 'female' | 'other'>();
    if (!profilesValue) return map;
    for (const d of profilesValue.docs) {
      const g = (d.data().gender as 'male' | 'female' | 'other') || 'other';
      map.set(d.id, g);
    }
    return map;
  }, [profilesValue]);

  // Apply filters
  const filteredPosts = useMemo(() => {
    return posts.filter(post => {
      const matchesSearch = !search || 
        post.title.toLowerCase().includes(search.toLowerCase()) ||
        post.body.toLowerCase().includes(search.toLowerCase());
      
      const matchesCategory = categoryFilter === 'all' || post.category === categoryFilter;
      const matchesGender = genderFilter === 'all' || cpGenderById.get(post.authorCPId) === genderFilter;
      
      const matchesModeration = moderationFilter === 'all' || 
        (moderationFilter === 'pending' && !post.moderation) ||
        post.moderation?.status === moderationFilter;
      
      return matchesSearch && matchesCategory && matchesGender && matchesModeration;
    });
  }, [posts, search, categoryFilter, genderFilter, moderationFilter, cpGenderById]);

  // Get paginated posts
  const paginatedPosts = useMemo(() => {
    const startIndex = (currentPage - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    return filteredPosts.slice(startIndex, endIndex);
  }, [filteredPosts, currentPage, pageSize]);

  const totalPages = Math.ceil(filteredPosts.length / pageSize);

  // Get comments count for a post
  const getPostCommentsCount = (postId: string) => {
    return comments.filter(comment => comment.postId === postId).length;
  };

  // Get category name
  const getCategoryName = (categoryId: string) => {
    const category = categories.find(cat => cat.id === categoryId);
    return category?.name || categoryId;
  };

  // Calculate stats
  const stats = useMemo(() => {
    const total = posts.length;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todaysPosts = posts.filter(post => post.createdAt >= today).length;
    const totalComments = comments.length;
    const totalInteractions = interactions.filter(i => i.targetType === 'post').length;

    return { total, todaysPosts, totalComments, totalInteractions };
  }, [posts, comments, interactions]);

  const handleViewDetails = (post: ForumPost) => {
    // Open preview dialog for the post
    setPreviewPostId(post.id);
  };

  const openModerationForPost = (post: ForumPost) => {
    setModerationPost(post);
    setModerationOpen(true);
  };

  const handleDeletePost = async () => {
    if (!selectedPost) return;

    try {
      console.log('Deleting post:', selectedPost.id);
      
      // Soft delete: mark as deleted instead of removing from database
      await updateDoc(doc(db, 'forumPosts', selectedPost.id), {
        isDeleted: true,
        updatedAt: new Date(),
      });
      
      console.log('Post marked as deleted successfully');
      toast.success(t('modules.community.posts.deleteSuccess'));
      setShowDeleteDialog(false);
      setSelectedPost(null);
    } catch (error) {
      console.error('Error deleting post:', error);
      toast.error(t('modules.community.posts.deleteError'));
    }
  };

  const handleHidePost = async () => {
    if (!selectedPost) return;

    try {
      await updateDoc(doc(db, 'forumPosts', selectedPost.id), {
        isHidden: !selectedPost.isHidden,
        updatedAt: new Date(),
      });
      toast.success(selectedPost.isHidden ? 
        t('modules.community.posts.unhideSuccess') : 
        t('modules.community.posts.hideSuccess')
      );
      setShowHideDialog(false);
      setSelectedPost(null);
    } catch (error) {
      console.error('Error hiding post:', error);
      toast.error(t('modules.community.posts.hideError'));
    }
  };

  const handleCreatePostSuccess = () => {
    // The ForumPostsManagement component will automatically refresh
    // due to the real-time Firestore listener
    setShowCreateDialog(false);
  };

  // Bulk selection handlers
  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedPosts(paginatedPosts.map(post => post.id));
    } else {
      setSelectedPosts([]);
    }
  };

  const handleSelectPost = (postId: string, checked: boolean) => {
    if (checked) {
      setSelectedPosts(prev => [...prev, postId]);
    } else {
      setSelectedPosts(prev => prev.filter(id => id !== postId));
    }
  };

  const clearSelection = () => {
    setSelectedPosts([]);
  };

  // Bulk actions
  const handleBulkSoftDelete = async () => {
    setBulkActionLoading(true);
    try {
      const batch = selectedPosts.map(postId => 
        updateDoc(doc(db, 'forumPosts', postId), {
          isDeleted: true,
          updatedAt: new Date(),
        })
      );
      await Promise.all(batch);
      toast.success(t('modules.community.posts.bulkSoftDeleteSuccess', { count: selectedPosts.length }));
      clearSelection();
      setShowBulkSoftDeleteDialog(false);
    } catch (error) {
      console.error('Error soft deleting posts:', error);
      toast.error(t('modules.community.posts.bulkActionError'));
    } finally {
      setBulkActionLoading(false);
    }
  };

  const handleBulkHardDelete = async () => {
    setBulkActionLoading(true);
    try {
      const batch = selectedPosts.map(postId => 
        deleteDoc(doc(db, 'forumPosts', postId))
      );
      await Promise.all(batch);
      toast.success(t('modules.community.posts.bulkHardDeleteSuccess', { count: selectedPosts.length }));
      clearSelection();
      setShowBulkDeleteDialog(false);
    } catch (error) {
      console.error('Error hard deleting posts:', error);
      toast.error(t('modules.community.posts.bulkActionError'));
    } finally {
      setBulkActionLoading(false);
    }
  };

  const handleBulkPin = async () => {
    setBulkActionLoading(true);
    try {
      const batch = selectedPosts.map(postId => 
        updateDoc(doc(db, 'forumPosts', postId), {
          isPinned: true,
          updatedAt: new Date(),
        })
      );
      await Promise.all(batch);
      toast.success(t('modules.community.posts.bulkPinSuccess', { count: selectedPosts.length }));
      clearSelection();
    } catch (error) {
      console.error('Error pinning posts:', error);
      toast.error(t('modules.community.posts.bulkActionError'));
    } finally {
      setBulkActionLoading(false);
    }
  };

  const handleBulkUnpin = async () => {
    setBulkActionLoading(true);
    try {
      const batch = selectedPosts.map(postId => 
        updateDoc(doc(db, 'forumPosts', postId), {
          isPinned: false,
          updatedAt: new Date(),
        })
      );
      await Promise.all(batch);
      toast.success(t('modules.community.posts.bulkUnpinSuccess', { count: selectedPosts.length }));
      clearSelection();
    } catch (error) {
      console.error('Error unpinning posts:', error);
      toast.error(t('modules.community.posts.bulkActionError'));
    } finally {
      setBulkActionLoading(false);
    }
  };

  const isAllSelected = paginatedPosts.length > 0 && selectedPosts.length === paginatedPosts.length;
  const isIndeterminate = selectedPosts.length > 0 && selectedPosts.length < paginatedPosts.length;
  const selectAllCheckboxRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (selectAllCheckboxRef.current) {
      // Find the input element within the button (Radix UI structure)
      const input = selectAllCheckboxRef.current.querySelector('input[type="checkbox"]') as HTMLInputElement;
      if (input) {
        input.indeterminate = isIndeterminate;
      }
    }
  }, [isIndeterminate]);

  if (postsLoading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <Card key={i}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  <div className="h-4 bg-muted rounded animate-pulse" />
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-8 bg-muted rounded animate-pulse mb-2" />
                <div className="h-3 bg-muted rounded animate-pulse" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  if (postsError) {
    return (
      <div className="text-center py-8">
        <p className="text-destructive">{t('common.error')}</p>
        <Button 
          onClick={() => window.location.reload()} 
          variant="outline" 
          className="mt-4"
        >
          {t('common.retry')}
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-start">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">{t('modules.community.posts.title')}</h2>
          <p className="text-muted-foreground">
            {t('modules.community.posts.description')}
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={handleRefresh} disabled={postsLoading}>
            <RefreshCw className={`mr-2 h-4 w-4 ${postsLoading ? 'animate-spin' : ''}`} />
            {t('common.refresh') || 'Refresh'}
          </Button>
          <Button onClick={() => setShowCreateDialog(true)}>
            <Plus className="mr-2 h-4 w-4" />
            {t('modules.community.posts.createPost')}
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.posts.totalPosts')}
            </CardTitle>
            <MessageSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.features.percentOfTotal', { percent: '100' })}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.posts.todaysPosts')}
            </CardTitle>
            <MessageSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.todaysPosts}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.today')}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.posts.totalComments')}
            </CardTitle>
            <MessageSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalComments}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.comments.title')}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.posts.totalInteractions')}
            </CardTitle>
            <User className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalInteractions}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.interactions.title')}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Bulk Actions Toolbar */}
      {selectedPosts.length > 0 && (
        <Card className="border-primary/20 bg-primary/5">
          <CardContent className="py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <span className="text-sm font-medium">
                  {t('modules.community.posts.bulkActions.selected', { count: selectedPosts.length })}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={clearSelection}
                >
                  <X className="mr-2 h-4 w-4" />
                  {t('modules.community.posts.bulkActions.clearSelection')}
                </Button>
              </div>
              <div className="flex items-center space-x-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleBulkPin}
                  disabled={bulkActionLoading}
                >
                  <Pin className="mr-2 h-4 w-4" />
                  {t('modules.community.posts.bulkActions.pin')}
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleBulkUnpin}
                  disabled={bulkActionLoading}
                >
                  <PinOff className="mr-2 h-4 w-4" />
                  {t('modules.community.posts.bulkActions.unpin')}
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setShowBulkSoftDeleteDialog(true)}
                  disabled={bulkActionLoading}
                >
                  <EyeOff className="mr-2 h-4 w-4" />
                  {t('modules.community.posts.bulkActions.softDelete')}
                </Button>
                <Button
                  variant="destructive"
                  size="sm"
                  onClick={() => setShowBulkDeleteDialog(true)}
                  disabled={bulkActionLoading}
                >
                  <Trash2 className="mr-2 h-4 w-4" />
                  {t('modules.community.posts.bulkActions.hardDelete')}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-4">
        <div className="flex-1">
          <div className="relative">
            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder={t('modules.community.posts.searchPlaceholder')}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-8"
            />
          </div>
        </div>
        <Select value={categoryFilter} onValueChange={setCategoryFilter}>
          <SelectTrigger className="w-[200px]">
            <SelectValue placeholder={t('modules.community.posts.filterByCategory')} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('common.all')}</SelectItem>
            {categories.map((category) => (
              <SelectItem key={category.id} value={category.id}>
                {category.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={genderFilter} onValueChange={(v) => setGenderFilter(v as any)}>
          <SelectTrigger className="w-[200px]">
            <SelectValue placeholder={t('modules.community.posts.filterByGender')} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('common.all')}</SelectItem>
            <SelectItem value="male">{t('modules.community.profiles.male')}</SelectItem>
            <SelectItem value="female">{t('modules.community.profiles.female')}</SelectItem>
            <SelectItem value="other">{t('modules.community.profiles.other')}</SelectItem>
          </SelectContent>
        </Select>
        <Select value={moderationFilter} onValueChange={(v) => setModerationFilter(v as any)}>
          <SelectTrigger className="w-[200px]">
            <SelectValue placeholder={t('modules.community.forum.moderation.filterByStatus')} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('common.all')}</SelectItem>
            <SelectItem value="pending">{t('modules.community.forum.moderation.status.pending')}</SelectItem>
            <SelectItem value="approved">{t('modules.community.forum.moderation.status.approved')}</SelectItem>
            <SelectItem value="manual_review">{t('modules.community.forum.moderation.status.manual_review')}</SelectItem>
            <SelectItem value="blocked">{t('modules.community.forum.moderation.status.blocked')}</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Posts Table */}
      <Card>
        <CardContent>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12">
                    <Checkbox
                      ref={selectAllCheckboxRef}
                      checked={isAllSelected}
                      onCheckedChange={handleSelectAll}
                      aria-label={t('modules.community.posts.table.selectAll')}
                    />
                  </TableHead>
                  <TableHead>{t('modules.community.posts.table.columns.title')}</TableHead>
                  <TableHead>{t('modules.community.posts.table.columns.category')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.forum.moderation.status.label')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.posts.table.columns.comments')}</TableHead>
                  <TableHead>{t('modules.community.posts.table.columns.createdAt')}</TableHead>
                  <TableHead className="text-right">{t('modules.community.posts.table.columns.actions')}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {paginatedPosts.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center">
                      {t('modules.community.posts.table.noData')}
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedPosts.map((post) => (
                    <TableRow
                      key={post.id}
                      onClick={() => handleViewDetails(post)}
                      className={`cursor-pointer hover:bg-accent/40 ${post.isHidden ? 'opacity-50' : ''} ${post.isDeleted ? 'border-destructive bg-destructive/5' : ''}`}
                    >
                      <TableCell onClick={(e) => e.stopPropagation()}>
                        <Checkbox
                          checked={selectedPosts.includes(post.id)}
                          onCheckedChange={(checked) => handleSelectPost(post.id, !!checked)}
                          aria-label={t('modules.community.posts.table.selectPost')}
                          onClick={(e) => e.stopPropagation()}
                        />
                      </TableCell>
                      <TableCell className="font-medium max-w-[300px] truncate">
                        {post.title}
                        {post.isAnonymous && (
                          <Badge variant="secondary" className="ml-2 text-xs">
                            {t('modules.community.posts.anonymous')}
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">
                          {getCategoryName(post.category)}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-center">
                        <div className="flex items-center justify-center gap-1">
                          <ForumModerationBadge status={post.moderation?.status} showIcon={false} />
                          {post.moderation?.finalDecision && post.moderation.finalDecision.confidence >= 0.85 && (
                            <Shield className="h-3 w-3 text-yellow-600" />
                          )}
                        </div>
                      </TableCell>
                      <TableCell className="text-center">
                        <div className="flex items-center justify-center space-x-1">
                          <MessageSquare className="h-3 w-3 text-blue-600" />
                          <span>{getPostCommentsCount(post.id)}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="text-sm text-muted-foreground">
                          {format(post.createdAt, 'MMM dd, yyyy')}
                        </span>
                      </TableCell>
                      <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="h-8 w-8 p-0" onClick={(e) => e.stopPropagation()}>
                              <span className="sr-only">{t('modules.community.posts.table.accessibility.openMenu')}</span>
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => handleViewDetails(post)}>
                              <Eye className="mr-2 h-4 w-4" />
                              {t('modules.community.posts.table.actions.viewDetails')}
                            </DropdownMenuItem>
                              <DropdownMenuItem onClick={() => openModerationForPost(post)}>
                                <AlertCircle className="mr-2 h-4 w-4" />
                                {t('modules.community.posts.moderation.quickModerate')}
                              </DropdownMenuItem>
                            <DropdownMenuItem>
                              <Edit className="mr-2 h-4 w-4" />
                              {t('modules.community.posts.table.actions.editPost')}
                            </DropdownMenuItem>
                            <DropdownMenuItem 
                              onClick={() => {
                                setSelectedPost(post);
                                setShowHideDialog(true);
                              }}
                            >
                              <EyeOff className="mr-2 h-4 w-4" />
                              {post.isHidden ? 
                                t('modules.community.posts.detailPage.actions.unhidePost') : 
                                t('modules.community.posts.table.actions.hidePost')
                              }
                            </DropdownMenuItem>
                            {!post.isDeleted && (
                              <DropdownMenuItem 
                                onClick={() => {
                                  setSelectedPost(post);
                                  setShowDeleteDialog(true);
                                }}
                                className="text-destructive"
                              >
                                <Trash2 className="mr-2 h-4 w-4" />
                                {t('modules.community.posts.table.actions.deletePost')}
                              </DropdownMenuItem>
                            )}
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between space-x-2 py-4">
              <div className="flex items-center space-x-2">
                <p className="text-sm font-medium">
                  {t('modules.community.posts.table.rowsPerPage')}
                </p>
                <Select
                  value={`${pageSize}`}
                  onValueChange={(value) => {
                    setPageSize(Number(value));
                    setCurrentPage(1);
                  }}
                >
                  <SelectTrigger className="h-8 w-[70px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent side="top">
                    {[5, 10, 20, 30, 50].map((size) => (
                      <SelectItem key={size} value={`${size}`}>
                        {size}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div className="flex items-center space-x-2">
                <p className="text-sm font-medium">
                  {t('modules.community.posts.table.pagination.page', { 
                    current: currentPage, 
                    total: totalPages 
                  })}
                </p>
                <div className="flex items-center space-x-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setCurrentPage(currentPage - 1)}
                    disabled={currentPage <= 1}
                  >
                    {t('modules.community.posts.table.pagination.previous')}
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setCurrentPage(currentPage + 1)}
                    disabled={currentPage >= totalPages}
                  >
                    {t('modules.community.posts.table.pagination.next')}
                  </Button>
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Post Preview Dialog */}
      <Dialog open={!!previewPostId} onOpenChange={(open) => !open && setPreviewPostId(null)}>
        <DialogContent className="max-w-[90vw] w-[1200px] h-[80vh] overflow-auto">
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.detailPage.title')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.posts.detailPage.viewingPost') || 'Viewing post details'}
            </DialogDescription>
          </DialogHeader>
          {previewPostId && (
            <div className="w-full">
              <PostDetailContent postId={previewPostId} lang={lang} hideHeader />
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.detailPage.deleteConfirm.title')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.posts.detailPage.deleteConfirm.description')}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDeleteDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button variant="destructive" onClick={handleDeletePost}>
              {t('common.delete')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Hide Confirmation Dialog */}
      <Dialog open={showHideDialog} onOpenChange={setShowHideDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.detailPage.hideConfirm.title')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.posts.detailPage.hideConfirm.description')}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowHideDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleHidePost}>
              {selectedPost?.isHidden ? 
                t('modules.community.posts.detailPage.actions.unhidePost') : 
                t('modules.community.posts.detailPage.actions.hidePost')
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Bulk Soft Delete Confirmation Dialog */}
      <Dialog open={showBulkSoftDeleteDialog} onOpenChange={setShowBulkSoftDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.bulkActions.softDeleteConfirm.title')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.posts.bulkActions.softDeleteConfirm.description', { count: selectedPosts.length })}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowBulkSoftDeleteDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button 
              variant="destructive" 
              onClick={handleBulkSoftDelete}
              disabled={bulkActionLoading}
            >
              {bulkActionLoading ? t('common.processing') : t('modules.community.posts.bulkActions.softDelete')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Bulk Hard Delete Confirmation Dialog */}
      <Dialog open={showBulkDeleteDialog} onOpenChange={setShowBulkDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.bulkActions.hardDeleteConfirm.title')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.posts.bulkActions.hardDeleteConfirm.description', { count: selectedPosts.length })}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowBulkDeleteDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button 
              variant="destructive" 
              onClick={handleBulkHardDelete}
              disabled={bulkActionLoading}
            >
              {bulkActionLoading ? t('common.processing') : t('modules.community.posts.bulkActions.hardDelete')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Create Post Dialog */}
      <ForumPostForm
        isOpen={showCreateDialog}
        onClose={() => setShowCreateDialog(false)}
        onSuccess={handleCreatePostSuccess}
      />

      {/* Moderation Dialog */}
      {moderationPost && (
        <ModerationActionDialog
          isOpen={moderationOpen}
          onOpenChange={setModerationOpen}
          targetType="post"
          targetId={moderationPost.id}
          targetTitle={moderationPost.title}
          authorCPId={moderationPost.authorCPId}
          contentStatus={{ isHidden: !!moderationPost.isHidden, isDeleted: !!moderationPost.isDeleted }}
        />
      )}
    </div>
  );
} 