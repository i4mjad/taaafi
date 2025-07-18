'use client';

import { useState, useMemo } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Search, MessageSquare, ThumbsUp, ThumbsDown, User, ChevronDown, ChevronRight, Eye, Edit, Trash2, MoreHorizontal } from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible';
import { format } from 'date-fns';
import { ForumPost, Comment, Interaction } from '@/types/community';
import { toast } from 'sonner';

export default function ForumPostsManagement() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [selectedPost, setSelectedPost] = useState<ForumPost | null>(null);
  const [showDetails, setShowDetails] = useState(false);
  const [expandedPosts, setExpandedPosts] = useState<Set<string>>(new Set());

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

  // Get comments for a specific post
  const getPostComments = (postId: string) => {
    return comments.filter(comment => comment.postId === postId);
  };

  // Get interactions for a specific post
  const getPostInteractions = (postId: string) => {
    return interactions.filter(interaction => 
      interaction.targetType === 'post' && interaction.targetId === postId
    );
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

  const togglePostExpansion = (postId: string) => {
    const newExpanded = new Set(expandedPosts);
    if (newExpanded.has(postId)) {
      newExpanded.delete(postId);
    } else {
      newExpanded.add(postId);
    }
    setExpandedPosts(newExpanded);
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
              {t('modules.community.comments.totalComments')}
            </CardTitle>
            <MessageSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalComments}</div>
            <p className="text-xs text-muted-foreground">
              Total across all posts
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.interactions.totalInteractions')}
            </CardTitle>
            <ThumbsUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalInteractions}</div>
            <p className="text-xs text-muted-foreground">
              Likes and dislikes
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">{t('modules.content.items.filters')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">{t('common.search')}</label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder={t('modules.community.posts.searchPlaceholder')}
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">{t('modules.community.posts.filterByCategory')}</label>
              <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                <SelectTrigger>
                  <SelectValue placeholder={t('modules.community.posts.selectCategory')} />
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
          </div>
        </CardContent>
      </Card>

      {/* Posts List */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.posts.list')}</CardTitle>
          <CardDescription>
            {t('modules.community.posts.listDescription')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {filteredPosts.length === 0 ? (
            <div className="text-center py-8">
              <MessageSquare className="mx-auto h-12 w-12 text-muted-foreground/50" />
              <h3 className="mt-4 text-lg font-semibold">{t('modules.community.posts.noPostsFound')}</h3>
              <p className="text-muted-foreground">
                {posts.length === 0 
                  ? t('common.noData')
                  : 'Try adjusting your search or filter criteria'
                }
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {filteredPosts.map((post) => {
                const postComments = getPostComments(post.id);
                const postInteractions = getPostInteractions(post.id);
                const isExpanded = expandedPosts.has(post.id);
                
                return (
                  <Card key={post.id} className="overflow-hidden">
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center space-x-2 mb-2">
                            <h3 className="font-semibold text-lg">{post.title}</h3>
                            {post.isAnonymous && (
                              <Badge variant="secondary">Anonymous</Badge>
                            )}
                          </div>
                          <p className="text-sm text-muted-foreground line-clamp-2">
                            {post.body}
                          </p>
                          <div className="flex items-center space-x-4 mt-3 text-sm text-muted-foreground">
                            <span>By: {post.authorCPId}</span>
                            <span>{format(post.createdAt, 'MMM dd, yyyy')}</span>
                            <div className="flex items-center space-x-2">
                              <ThumbsUp className="h-4 w-4" />
                              <span>{post.likeCount}</span>
                              <ThumbsDown className="h-4 w-4" />
                              <span>{post.dislikeCount}</span>
                              <MessageSquare className="h-4 w-4" />
                              <span>{postComments.length}</span>
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => togglePostExpansion(post.id)}
                          >
                            {isExpanded ? (
                              <>
                                <ChevronDown className="h-4 w-4 mr-1" />
                                {t('modules.community.posts.collapseComments')}
                              </>
                            ) : (
                              <>
                                <ChevronRight className="h-4 w-4 mr-1" />
                                {t('modules.community.posts.expandComments')}
                              </>
                            )}
                          </Button>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" className="h-8 w-8 p-0">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onClick={() => {
                                setSelectedPost(post);
                                setShowDetails(true);
                              }}>
                                <Eye className="mr-2 h-4 w-4" />
                                {t('modules.community.posts.viewPost')}
                              </DropdownMenuItem>
                              <DropdownMenuItem onClick={() => {
                                toast.info('Edit functionality coming soon');
                              }}>
                                <Edit className="mr-2 h-4 w-4" />
                                {t('modules.community.posts.editPost')}
                              </DropdownMenuItem>
                              <DropdownMenuItem 
                                onClick={() => {
                                  toast.info('Delete functionality coming soon');
                                }}
                                className="text-destructive"
                              >
                                <Trash2 className="mr-2 h-4 w-4" />
                                {t('modules.community.posts.deletePost')}
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      </div>
                    </CardHeader>
                    
                    <Collapsible open={isExpanded}>
                      <CollapsibleContent>
                        <CardContent className="pt-0">
                          <div className="border-t pt-4">
                            <h4 className="font-medium mb-3">
                              {t('modules.community.posts.commentCount', { count: postComments.length })}
                            </h4>
                            {postComments.length === 0 ? (
                              <p className="text-sm text-muted-foreground">No comments yet</p>
                            ) : (
                              <div className="space-y-3">
                                {postComments.slice(0, 5).map((comment) => (
                                  <div key={comment.id} className="flex space-x-3 p-3 bg-muted/50 rounded-lg">
                                    <User className="h-4 w-4 mt-1 text-muted-foreground" />
                                    <div className="flex-1">
                                      <div className="flex items-center space-x-2 mb-1">
                                        <span className="text-sm font-medium">{comment.authorCPId}</span>
                                        <span className="text-xs text-muted-foreground">
                                          {format(comment.createdAt, 'MMM dd, HH:mm')}
                                        </span>
                                        {comment.isAnonymous && (
                                          <Badge variant="secondary" className="text-xs">Anonymous</Badge>
                                        )}
                                      </div>
                                      <p className="text-sm">{comment.body}</p>
                                      <div className="flex items-center space-x-2 mt-2 text-xs text-muted-foreground">
                                        <ThumbsUp className="h-3 w-3" />
                                        <span>{comment.likeCount}</span>
                                        <ThumbsDown className="h-3 w-3" />
                                        <span>{comment.dislikeCount}</span>
                                      </div>
                                    </div>
                                  </div>
                                ))}
                                {postComments.length > 5 && (
                                  <p className="text-sm text-muted-foreground">
                                    ...and {postComments.length - 5} more comments
                                  </p>
                                )}
                              </div>
                            )}
                          </div>
                        </CardContent>
                      </CollapsibleContent>
                    </Collapsible>
                  </Card>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Post Details Dialog */}
      <Dialog open={showDetails} onOpenChange={setShowDetails}>
        <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{t('modules.community.posts.postDetails')}</DialogTitle>
            <DialogDescription>
              Detailed view of the selected forum post
            </DialogDescription>
          </DialogHeader>
          
          {selectedPost && (
            <div className="space-y-6">
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-semibold">{selectedPost.title}</h3>
                  <div className="flex items-center space-x-4 mt-2 text-sm text-muted-foreground">
                    <span>Author: {selectedPost.authorCPId}</span>
                    <span>Category: {selectedPost.category}</span>
                    <span>Created: {format(selectedPost.createdAt, 'MMMM dd, yyyy HH:mm')}</span>
                    {selectedPost.isAnonymous && (
                      <Badge variant="secondary">Anonymous</Badge>
                    )}
                  </div>
                </div>
                
                <div className="prose max-w-none">
                  <p>{selectedPost.body}</p>
                </div>
                
                <div className="flex items-center space-x-6 text-sm">
                  <div className="flex items-center space-x-1">
                    <ThumbsUp className="h-4 w-4" />
                    <span>{selectedPost.likeCount} likes</span>
                  </div>
                  <div className="flex items-center space-x-1">
                    <ThumbsDown className="h-4 w-4" />
                    <span>{selectedPost.dislikeCount} dislikes</span>
                  </div>
                  <div className="flex items-center space-x-1">
                    <MessageSquare className="h-4 w-4" />
                    <span>{getPostComments(selectedPost.id).length} comments</span>
                  </div>
                  <div>
                    Score: {selectedPost.score}
                  </div>
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
} 