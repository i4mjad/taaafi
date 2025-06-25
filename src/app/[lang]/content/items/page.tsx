'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, addDoc, updateDoc, doc, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Content, CreateContentRequest, UpdateContentRequest, ContentType, ContentOwner, Category } from '@/types/content';
import { toast } from 'sonner';
import { FileText, Plus, Eye, EyeOff, ExternalLink, Globe } from 'lucide-react';

export default function ContentItemsPage() {
  const { t, locale } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedContent, setSelectedContent] = useState<Content | undefined>();

  // Firestore queries  
  const [contentSnapshot, loading] = useCollection(
    query(collection(db, 'content'), orderBy('contentName'))
  );

  const [contentTypesSnapshot] = useCollection(
    query(collection(db, 'contentTypes'), where('isActive', '==', true))
  );

  const [contentOwnersSnapshot] = useCollection(
    query(collection(db, 'contentOwners'), where('isActive', '==', true))
  );

  const [categoriesSnapshot] = useCollection(
    query(collection(db, 'contentCategories'), where('isActive', '==', true))
  );

  const contentItems = contentSnapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    createdAt: doc.data().createdAt?.toDate(),
    updatedAt: doc.data().updatedAt?.toDate(),
  })) as Content[] || [];

  const contentTypes = contentTypesSnapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
  })) as ContentType[] || [];

  const contentOwners = contentOwnersSnapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
  })) as ContentOwner[] || [];

  const categories = categoriesSnapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
  })) as Category[] || [];

  const filteredContent = contentItems.filter(item =>
    item.contentName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (item.contentNameAr && item.contentNameAr.toLowerCase().includes(searchQuery.toLowerCase()))
  );



  return (
    <>
      <SiteHeader dictionary={{ documents: t('siteHeader.documents') || 'Documents' }} />
      <div className="h-full flex flex-col">
          <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
            <div>
              <h1 className="text-3xl font-bold tracking-tight">
                {t('content.items.title') || 'Content Items'}
              </h1>
              <p className="text-muted-foreground">
                {t('content.items.description') || 'Manage individual content pieces and their metadata'}
              </p>
            </div>
            <Button onClick={() => setShowForm(true)}>
              <Plus className="h-4 w-4 mr-2" />
              {t('content.items.create') || 'Create Content'}
            </Button>
          </div>

          <div className="flex-1 overflow-auto">
            <div className="p-6 space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>{t('content.items.list') || 'Content Items'}</CardTitle>
                  <CardDescription>
                    {t('content.items.listDescription') || 'Manage individual content pieces and their metadata'}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="mb-4">
                    <Input
                      placeholder={t('content.items.searchPlaceholder') || 'Search content...'}
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                    />
                  </div>
                  
                  {loading ? (
                    <div className="text-center py-8">
                      <p>{t('common.loading') || 'Loading...'}</p>
                    </div>
                  ) : (
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>{t('content.items.nameEn') || 'Name (EN)'}</TableHead>
                          <TableHead>{t('content.items.nameAr') || 'Name (AR)'}</TableHead>
                          <TableHead>{t('content.items.type') || 'Type'}</TableHead>
                          <TableHead>{t('content.items.link') || 'Link'}</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {filteredContent.filter(item => !item.isDeleted).map((item) => (
                          <TableRow key={item.id}>
                            <TableCell className="font-medium">{item.contentName}</TableCell>
                            <TableCell>{item.contentNameAr || '-'}</TableCell>
                            <TableCell>
                              {contentTypes.find(t => t.id === item.contentTypeId)?.contentTypeName || '-'}
                            </TableCell>
                            <TableCell>
                              {item.contentLink && (
                                <a href={item.contentLink} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                                  <ExternalLink className="h-4 w-4" />
                                </a>
                              )}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  )}

                  {!loading && filteredContent.filter(item => !item.isDeleted).length === 0 && (
                    <div className="text-center py-8">
                      <FileText className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                      <p className="text-lg font-medium">{t('common.noData') || 'No data'}</p>
                      <p className="text-muted-foreground">
                        {t('content.items.noItemsFound') || 'No content items found'}
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </div>
      </div>
    </>
  );
}
