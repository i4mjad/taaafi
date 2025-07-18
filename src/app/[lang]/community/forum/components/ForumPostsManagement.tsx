'use client';

import { useState, useMemo } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where, deleteDoc, doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Search, MessageSquare, ThumbsUp, ThumbsDown, User, MoreHorizontal, Eye, Edit, Trash2, EyeOff } from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { format } from 'date-fns';
import { ForumPost, Comment, Interaction } from '@/types/community';
import { toast } from 'sonner';
import { useRouter, useParams } from 'next/navigation';

export default function ForumPostsManagement() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const lang = params.lang as string;
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [selectedPost, setSelectedPost] = useState<ForumPost | null>(null);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showHideDialog, setShowHideDialog] = useState(false);

  // Fetch forum posts
  const [postsValue, postsLoading, postsError] = useCollection(
    query(collection(db, 'forumPosts'), orderBy('createdAt', 'desc'))
  );

  // Fetch comments
  const [commentsValue] = useCollection(
    query(collection(db, 'comments'), orderBy('createdAt', 'desc'))
  );

  // Fetch interactions
  const [interactionsValue] = useCollection(
    query(collection(db, 'interactions'), orderBy('createdAt', 'desc'))
  );

  // Fetch post categories
  const [categoriesValue] = useCollection(
    query(collection(db, 'postCategories'), orderBy('sortOrder'))
  );

  const posts = useMemo(() => {
    if (!postsValue) return [];
    
    return postsValue.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as ForumPost[];
  }, [postsValue]);

  const comments = useMemo(() => {
    if (!commentsValue) return [];
    
    return commentsValue.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as Comment[];
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
      ...doc.data(),
    }));
  }, [categoriesValue]);

  // Apply filters
  const filteredPosts = useMemo(() => {
    return posts.filter(post => {
      const matchesSearch = !search || 
        post.title.toLowerCase().includes(search.toLowerCase()) ||
        post.body.toLowerCase().includes(search.toLowerCase());
      
      const matchesCategory = categoryFilter === 'all' || post.category === categoryFilter;
      
      return matchesSearch && matchesCategory;
    });
  }, [posts, search, categoryFilter]);

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
    // Navigate to post detail page
    router.push(`/${lang}/community/forum/posts/${post.id}`);
  };

  const handleDeletePost = async () => {
    if (!selectedPost) return;

    try {
      await deleteDoc(doc(db, 'forumPosts', selectedPost.id));
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
      <div>
        <h2 className="text-2xl font-bold tracking-tight">{t('modules.community.posts.title')}</h2>
        <p className="text-muted-foreground">
          {t('modules.community.posts.description')}
        </p>
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
            <ThumbsUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalInteractions}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.interactions.title')}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
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
      </div>

      {/* Posts Table */}
      <Card>
        <CardContent>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t('modules.community.posts.table.columns.title')}</TableHead>
                  <TableHead>{t('modules.community.posts.table.columns.author')}</TableHead>
                  <TableHead>{t('modules.community.posts.table.columns.category')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.posts.table.columns.likes')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.posts.table.columns.dislikes')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.posts.table.columns.comments')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.posts.table.columns.score')}</TableHead>
                  <TableHead>{t('modules.community.posts.table.columns.createdAt')}</TableHead>
                  <TableHead className="text-right">{t('modules.community.posts.table.columns.actions')}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {paginatedPosts.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={9} className="h-24 text-center">
                      {t('modules.community.posts.table.noData')}
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedPosts.map((post) => (
                    <TableRow key={post.id} className={post.isHidden ? 'opacity-50' : ''}>
                      <TableCell className="font-medium max-w-[300px] truncate">
                        {post.title}
                        {post.isAnonymous && (
                          <Badge variant="secondary" className="ml-2 text-xs">
                            {t('modules.community.posts.anonymous')}
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center space-x-2">
                          <User className="h-4 w-4 text-muted-foreground" />
                          <span className="text-sm">{post.authorCPId}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">
                          {getCategoryName(post.category)}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-center">
                        <div className="flex items-center justify-center space-x-1">
                          <ThumbsUp className="h-3 w-3 text-green-600" />
                          <span>{post.likeCount}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-center">
                        <div className="flex items-center justify-center space-x-1">
                          <ThumbsDown className="h-3 w-3 text-red-600" />
                          <span>{post.dislikeCount}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-center">
                        <div className="flex items-center justify-center space-x-1">
                          <MessageSquare className="h-3 w-3 text-blue-600" />
                          <span>{getPostCommentsCount(post.id)}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-center">
                        <Badge variant={post.score >= 0 ? 'default' : 'destructive'}>
                          {post.score}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <span className="text-sm text-muted-foreground">
                          {format(post.createdAt, 'MMM dd, yyyy')}
                        </span>
                      </TableCell>
                      <TableCell className="text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="h-8 w-8 p-0">
                              <span className="sr-only">{t('modules.community.posts.table.accessibility.openMenu')}</span>
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => handleViewDetails(post)}>
                              <Eye className="mr-2 h-4 w-4" />
                              {t('modules.community.posts.table.actions.viewDetails')}
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
    </div>
  );
} 