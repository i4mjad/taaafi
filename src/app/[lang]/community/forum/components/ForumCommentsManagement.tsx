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
import { MessageSquare, MoreHorizontal, Eye, EyeOff, Trash2, ExternalLink, AlertCircle, User, ThumbsUp, ThumbsDown } from 'lucide-react';
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
    if (!q) return comments;
    return comments.filter((c) =>
      c.body.toLowerCase().includes(q) || (postTitleById.get(c.postId) || '').toLowerCase().includes(q)
    );
  }, [comments, search, postTitleById]);

  const paginatedComments = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    const end = start + pageSize;
    return filteredComments.slice(start, end);
  }, [filteredComments, currentPage, pageSize]);

  const totalPages = Math.ceil(filteredComments.length / pageSize) || 1;

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
                  <TableHead className="text-center">{t('modules.community.posts.table.columns.likes')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.posts.table.columns.dislikes')}</TableHead>
                  <TableHead className="text-center">{t('modules.community.posts.table.columns.score')}</TableHead>
                  <TableHead>{t('modules.community.posts.table.columns.createdAt')}</TableHead>
                  <TableHead className="text-right">{t('modules.community.posts.table.columns.actions')}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {commentsLoading ? (
                  <TableRow>
                    <TableCell colSpan={9} className="h-24 text-center">
                      {t('common.loading')}
                    </TableCell>
                  </TableRow>
                ) : commentsError ? (
                  <TableRow>
                    <TableCell colSpan={9} className="h-24 text-center text-destructive">
                      {t('common.error')}
                    </TableCell>
                  </TableRow>
                ) : filteredComments.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={9} className="h-24 text-center">
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
                          <ThumbsUp className="h-3 w-3 text-green-600" />
                          <span>{comment.likeCount}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-center">
                        <div className="flex items-center justify-center gap-1">
                          <ThumbsDown className="h-3 w-3 text-red-600" />
                          <span>{comment.dislikeCount}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-center">
                        <Badge variant={comment.score >= 0 ? 'default' : 'destructive'}>{comment.score}</Badge>
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


