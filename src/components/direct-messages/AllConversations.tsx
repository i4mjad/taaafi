'use client';

import { useState, useMemo, useEffect } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, limit, startAfter, getDocs, QueryDocumentSnapshot, DocumentData } from 'firebase/firestore';
import { db } from '@/lib/firebase';
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
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Eye, Download, Trash2, ChevronLeft, ChevronRight } from 'lucide-react';
import { format } from 'date-fns';
import { Skeleton } from '@/components/ui/skeleton';

export function AllConversations() {
  const { t } = useTranslation();
  const [searchTerm, setSearchTerm] = useState('');
  
  // Pagination states
  const [pageSize, setPageSize] = useState(20);
  const [currentPage, setCurrentPage] = useState(1);
  const [firstDoc, setFirstDoc] = useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [lastDoc, setLastDoc] = useState<QueryDocumentSnapshot<DocumentData> | null>(null);
  const [hasNextPage, setHasNextPage] = useState(false);
  const [totalCount, setTotalCount] = useState(0);
  
  const conversationsQuery = useMemo(() => {
    let constraints: any[] = [
      orderBy('lastActivityAt', 'desc'),
    ];
    
    // Add pagination
    if (currentPage > 1 && lastDoc) {
      constraints.push(startAfter(lastDoc));
    }
    
    constraints.push(limit(pageSize + 1)); // +1 to check if there's a next page
    
    return query(collection(db, 'direct_conversations'), ...constraints);
  }, [pageSize, currentPage, lastDoc]);
  
  const [snapshot, loading, error] = useCollection(conversationsQuery);
  
  // Extract data from snapshot, handle pagination, and add document IDs
  const conversations = useMemo(() => {
    if (!snapshot) return [];
    
    const docs = snapshot.docs;
    
    // Check if there's a next page
    if (docs.length > pageSize) {
      setHasNextPage(true);
      const displayDocs = docs.slice(0, pageSize);
      
      if (displayDocs.length > 0) {
        setFirstDoc(displayDocs[0]);
        setLastDoc(displayDocs[displayDocs.length - 1]);
      }
      
      return displayDocs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
    } else {
      setHasNextPage(false);
      
      if (docs.length > 0) {
        setFirstDoc(docs[0]);
        setLastDoc(docs[docs.length - 1]);
      }
      
      return docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
    }
  }, [snapshot, pageSize]);
  
  // Get total count
  useEffect(() => {
    const fetchTotalCount = async () => {
      try {
        const countQuery = query(collection(db, 'direct_conversations'));
        const countSnapshot = await getDocs(countQuery);
        setTotalCount(countSnapshot.size);
      } catch (error) {
        console.error('Error fetching total count:', error);
      }
    };
    
    fetchTotalCount();
  }, []);
  
  const filteredConversations = useMemo(() => {
    if (!conversations) return [];
    if (!searchTerm) return conversations;
    
    return conversations.filter((conv: any) =>
      conv.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      conv.participantCpIds.some((id: string) => id.toLowerCase().includes(searchTerm.toLowerCase()))
    );
  }, [conversations, searchTerm]);
  
  // Pagination handlers
  const handleNextPage = () => {
    if (hasNextPage) {
      setCurrentPage(prev => prev + 1);
    }
  };
  
  const handlePreviousPage = () => {
    if (currentPage > 1) {
      setCurrentPage(prev => prev - 1);
      setLastDoc(null);
    }
  };
  
  const handlePageSizeChange = (newSize: string) => {
    setPageSize(parseInt(newSize));
    setCurrentPage(1);
    setLastDoc(null);
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
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.directMessages.conversations.title')}</CardTitle>
          <CardDescription>
            {t('modules.community.directMessages.conversations.description')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Input
            placeholder={t('modules.community.directMessages.common.search')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </CardContent>
      </Card>
      
      <Card>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>{t('modules.community.directMessages.conversations.columns.conversationId')}</TableHead>
              <TableHead>{t('modules.community.directMessages.conversations.columns.participants')}</TableHead>
              <TableHead>{t('modules.community.directMessages.conversations.columns.lastMessage')}</TableHead>
              <TableHead>{t('modules.community.directMessages.conversations.columns.lastActivity')}</TableHead>
              <TableHead>{t('modules.community.directMessages.conversations.columns.actions')}</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredConversations.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-8">
                  {t('modules.community.directMessages.conversations.empty')}
                </TableCell>
              </TableRow>
            ) : (
              filteredConversations.map((conversation: any) => (
                <TableRow key={conversation.id}>
                  <TableCell>
                    <code className="text-xs">{conversation.id?.slice(0, 12) || 'N/A'}...</code>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      {conversation.participantCpIds?.map((cpId: string, idx: number) => (
                        <Badge key={`${conversation.id}-${cpId || idx}`} variant="outline">{cpId?.slice(0, 8) || 'N/A'}...</Badge>
                      ))}
                    </div>
                  </TableCell>
                  <TableCell>
                    <p className="text-sm max-w-md truncate">{conversation.lastMessage || 'N/A'}</p>
                  </TableCell>
                  <TableCell>
                    <span className="text-xs text-muted-foreground">
                      {conversation.lastActivityAt ? format(conversation.lastActivityAt.toDate(), 'PP') : 'N/A'}
                    </span>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-2">
                      <Button size="sm" variant="ghost">
                        <Eye className="h-4 w-4" />
                      </Button>
                      <Button size="sm" variant="ghost">
                        <Download className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </Card>
      
      {/* Pagination Controls */}
      <Card>
        <CardContent className="py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">
                  {t('modules.community.directMessages.common.pagination.itemsPerPage')}:
                </span>
                <Select value={pageSize.toString()} onValueChange={handlePageSizeChange}>
                  <SelectTrigger className="w-20">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="10">10</SelectItem>
                    <SelectItem value="20">20</SelectItem>
                    <SelectItem value="50">50</SelectItem>
                    <SelectItem value="100">100</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="text-sm text-muted-foreground">
                {t('modules.community.directMessages.common.pagination.showing')} {(currentPage - 1) * pageSize + 1} {t('modules.community.directMessages.common.pagination.to')} {Math.min(currentPage * pageSize, totalCount)} {t('modules.community.directMessages.common.pagination.of')} {totalCount} {t('modules.community.directMessages.common.pagination.items')}
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={handlePreviousPage}
                disabled={currentPage === 1 || loading}
              >
                <ChevronLeft className="h-4 w-4 mr-1" />
                {t('modules.community.directMessages.common.pagination.previous')}
              </Button>
              
              <div className="text-sm font-medium">
                {t('modules.community.directMessages.common.pagination.page')} {currentPage}
              </div>
              
              <Button
                variant="outline"
                size="sm"
                onClick={handleNextPage}
                disabled={!hasNextPage || loading}
              >
                {t('modules.community.directMessages.common.pagination.next')}
                <ChevronRight className="h-4 w-4 ml-1" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

