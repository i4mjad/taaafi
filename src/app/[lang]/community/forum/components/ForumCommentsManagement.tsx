'use client';

import { useMemo, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, doc, orderBy, query, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { MessageSquare, MoreHorizontal, Eye, EyeOff, Trash2, ExternalLink, AlertCircle, User, Shield } from 'lucide-react';
import { ForumModerationBadge } from '@/components/forum/ForumModerationBadge';
import { format } from 'date-fns';
import { Comment } from '@/types/community';
import ModerationActionDialog from './ModerationActionDialog';
import { toast } from 'sonner';

export default function ForumCommentsManagement() {
  const { t } = useTranslation();
  const params = useParams();
  const lang = params.lang as string;
  const router = useRouter();

  const [search, setSearch] = useState('');
  const [moderationFilter, setModerationFilter] = useState<'all' | 'approved' | 'manual_review' | 'blocked' | 'pending'>('all');
  const [selectedComment, setSelectedComment] = useState<Comment | null>(null);
  const [moderationOpen, setModerationOpen] = useState(false);
  const [moderationComment, setModerationComment] = useState<Comment | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  const [commentsValue, commentsLoading, commentsError] = useCollection(
    query(collection(db, 'comments'), orderBy('createdAt', 'desc'))
  );
  const [postsValue] = useCollection(
    query(collection(db, 'forumPosts'), orderBy('createdAt', 'desc'))
  );

  const comments = useMemo(() => {
    if (!commentsValue) return [] as Comment[];
    return commentsValue.docs.map((d) => ({
      id: d.id,
      ...d.data(),
      createdAt: d.data().createdAt?.toDate() || new Date(),
      updatedAt: d.data().updatedAt?.toDate(),
    })) as unknown as Comment[];
  }, [commentsValue]);

  const postTitleById = useMemo(() => {
    const map = new Map<string, string>();
    if (!postsValue) return map;
    for (const d of postsValue.docs) {
      const data = d.data() as any;
      map.set(d.id, data.title || d.id);
    }
    return map;
  }, [postsValue]);

  const filteredComments = useMemo(() => {
    const q = search.trim().toLowerCase();
    return comments.filter((c) => {
      const matchesSearch = !q || c.body.toLowerCase().includes(q) || (postTitleById.get(c.postId) || '').toLowerCase().includes(q);
      const matchesModeration = moderationFilter === 'all' || 
        (moderationFilter === 'pending' && !c.moderation) ||
        c.moderation?.status === moderationFilter;
      return matchesSearch && matchesModeration;
    });
  }, [comments, search, moderationFilter, postTitleById]);

  const paginatedComments = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    const end = start + pageSize;
    return filteredComments.slice(start, end);
  }, [filteredComments, currentPage, pageSize]);

  const totalPages = Math.ceil(filteredComments.length / pageSize) || 1;

  // Calculate stats
  const stats = useMemo(() => {
    const total = comments.length;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todaysComments = comments.filter(comment => comment.createdAt >= today).length;
    const uniquePosts = new Set(comments.map(c => c.postId)).size;

    return { total, todaysComments, uniquePosts };
  }, [comments]);

  const handleHideToggle = async (comment: Comment) => {
    try {
      await updateDoc(doc(db, 'comments', comment.id), {
        isHidden: !comment.isHidden,
        updatedAt: new Date(),
      });
      toast.success(
        comment.isHidden
          ? t('modules.community.comments.unhideSuccess')
          : t('modules.community.comments.hideSuccess')
      );
    } catch (e) {
      toast.error(t('modules.community.comments.hideError'));
    }
  };

  const handleSoftDelete = async (comment: Comment) => {
    try {
      await updateDoc(doc(db, 'comments', comment.id), {
        isDeleted: true,
        updatedAt: new Date(),
      });
      toast.success(t('modules.community.comments.deleteSuccess'));
    } catch (e) {
      toast.error(t('modules.community.comments.deleteError'));
    }
  };

  const openModeration = (comment: Comment) => {
    setModerationComment(comment);
    setModerationOpen(true);
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">{t('modules.community.comments.title')}</h2>
        <p className="text-muted-foreground">{t('modules.community.comments.listDescription')}</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.comments.totalComments')}
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
              {t('modules.community.comments.todaysComments')}
            </CardTitle>
            <MessageSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.todaysComments}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.today')}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.comments.postsWithComments')}
            </CardTitle>
            <User className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.uniquePosts}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.community.posts.title')}
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="flex flex-col md:flex-row gap-4">
        <div className="flex-1">
          <div className="relative">
            <MessageSquare className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder={t('modules.community.comments.searchPlaceholder')}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-8"
            />
          </div>
        </div>
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

      <Card>
        <CardContent>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t('modules.community.comments.body')}</TableHead>
                  <TableHead>{t('modules.community.comments.author')}</TableHead>
                  <TableHead>{t('modules.community.comments.postTitle')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.posts.table.columns.status')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.forum.moderation.status.label')}</TableHead>
                  <TableHead>{t('modules.community.posts.table.columns.createdAt')}</TableHead>
                  <TableHead className="text-right">{t('modules.community.posts.table.columns.actions')}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {commentsLoading ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center">
                      {t('common.loading')}
                    </TableCell>
                  </TableRow>
                ) : commentsError ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center text-destructive">
                      {t('common.error')}
                    </TableCell>
                  </TableRow>
                ) : filteredComments.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="h-24 text-center">
                      {t('modules.community.comments.noCommentsFound')}
                    </TableCell>
                  </TableRow>
                ) : (
                  paginatedComments.map((comment) => (
                    <TableRow
                      key={comment.id}
                      onClick={() => router.push(`/${lang}/community/forum/posts/${comment.postId}`)}
                      className={`cursor-pointer hover:bg-accent/40 ${comment.isHidden ? 'opacity-50' : ''} ${comment.isDeleted ? 'border-destructive bg-destructive/5' : ''}`}
                    >
                      <TableCell className="max-w-[360px] truncate">
                        {comment.body}
                        {comment.isAnonymous && (
                          <Badge variant="secondary" className="ml-2 text-xs">
                            {t('modules.community.posts.anonymous')}
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2 text-sm">
                          <User className="h-4 w-4 text-muted-foreground" />
                          <span>{comment.authorCPId}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <span className="text-sm truncate max-w-[240px]">{postTitleById.get(comment.postId) || comment.postId}</span>
                          <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => router.push(`/${lang}/community/forum/posts/${comment.postId}`)}>
                            <ExternalLink className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                      <TableCell className="text-center">
                        <div className="flex items-center justify-center gap-1">
                          {comment.isDeleted && (
                            <Badge variant="destructive" className="text-xs">{t('modules.community.posts.deleted')}</Badge>
                          )}
                          {comment.isHidden && (
                            <Badge variant="secondary" className="text-xs">{t('modules.community.posts.hidden')}</Badge>
                          )}
                        </div>
                      </TableCell>
                      <TableCell className="text-center">
                        <div className="flex items-center justify-center gap-1">
                          <ForumModerationBadge status={comment.moderation?.status} showIcon={false} />
                          {comment.moderation?.finalDecision && comment.moderation.finalDecision.confidence >= 0.85 && (
                            <Shield className="h-3 w-3 text-yellow-600" />
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="text-sm text-muted-foreground">{format(comment.createdAt, 'MMM dd, yyyy')}</span>
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
                            <DropdownMenuItem onClick={() => router.push(`/${lang}/community/forum/posts/${comment.postId}`)}>
                              <Eye className="mr-2 h-4 w-4" />
                              {t('modules.community.posts.viewPost')}
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => openModeration(comment)}>
                              <AlertCircle className="mr-2 h-4 w-4" />
                              {t('modules.community.posts.moderation.quickModerate')}
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleHideToggle(comment)}>
                              {comment.isHidden ? (
                                <Eye className="mr-2 h-4 w-4" />
                              ) : (
                                <EyeOff className="mr-2 h-4 w-4" />
                              )}
                              {comment.isHidden
                                ? t('modules.community.posts.detailPage.commentActions.unhide')
                                : t('modules.community.posts.detailPage.commentActions.hide')}
                            </DropdownMenuItem>
                            {!comment.isDeleted && (
                              <DropdownMenuItem className="text-destructive" onClick={() => handleSoftDelete(comment)}>
                                <Trash2 className="mr-2 h-4 w-4" />
                                {t('modules.community.posts.detailPage.commentActions.delete')}
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
                    total: totalPages,
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

      {moderationComment && (
        <ModerationActionDialog
          isOpen={moderationOpen}
          onOpenChange={setModerationOpen}
          targetType="comment"
          targetId={moderationComment.id}
          authorCPId={moderationComment.authorCPId}
          contentStatus={{ isHidden: !!moderationComment.isHidden, isDeleted: !!moderationComment.isDeleted }}
        />
      )}
    </div>
  );
}


