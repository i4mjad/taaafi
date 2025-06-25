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
import { FileText, Plus, Eye, EyeOff, ExternalLink, Globe, MoreHorizontal, Edit, Trash2 } from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import ContentForm from './components/ContentForm';

export default function ContentItemsPage() {
  const { t, locale } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedContent, setSelectedContent] = useState<Content | undefined>();
  const [isSubmitting, setIsSubmitting] = useState(false);

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
    ...doc.data(),
    id: doc.id, // Ensure document ID is set after spreading doc.data()
    createdAt: doc.data().createdAt?.toDate(),
    updatedAt: doc.data().updatedAt?.toDate(),
  })) as Content[] || [];

  const contentTypes = contentTypesSnapshot?.docs.map(doc => ({
    ...doc.data(),
    id: doc.id, // Ensure document ID is set after spreading doc.data()
  })) as ContentType[] || [];

  const contentOwners = contentOwnersSnapshot?.docs.map(doc => ({
    ...doc.data(),
    id: doc.id, // Ensure document ID is set after spreading doc.data()
  })) as ContentOwner[] || [];

  const categories = categoriesSnapshot?.docs.map(doc => ({
    ...doc.data(),
    id: doc.id, // Ensure document ID is set after spreading doc.data()
  })) as Category[] || [];

  const filteredContent = contentItems.filter(item =>
    item.contentName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (item.contentNameAr && item.contentNameAr.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const handleSubmitContent = async (data: CreateContentRequest | UpdateContentRequest) => {
    setIsSubmitting(true);
    try {
      // Filter out undefined values to prevent Firebase errors
      const cleanData = Object.fromEntries(
        Object.entries(data).filter(([_, value]) => value !== undefined)
      );
      
      if (selectedContent) {
        // Update existing content
        await updateDoc(doc(db, 'content', selectedContent.id), {
          ...cleanData,
          updatedAt: new Date(),
        });
        toast.success(t('content.items.updateSuccess') || 'Content updated successfully');
      } else {
        // Create new content
        await addDoc(collection(db, 'content'), {
          ...cleanData,
          isDeleted: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        });
        toast.success(t('content.items.createSuccess') || 'Content created successfully');
      }
      
      setShowForm(false);
      setSelectedContent(undefined);
    } catch (error) {
      console.error('Error submitting content:', error);
      toast.error(
        selectedContent
          ? (t('content.items.updateError') || 'Failed to update content')
          : (t('content.items.createError') || 'Failed to create content')
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCancel = () => {
    setShowForm(false);
    setSelectedContent(undefined);
  };

  const handleEditContent = (content: Content) => {
    setSelectedContent(content);
    setShowForm(true);
  };

  const handleDeleteContent = async (content: Content) => {
    try {
      await updateDoc(doc(db, 'content', content.id), {
        isDeleted: true,
        updatedAt: new Date(),
      });
      toast.success(t('content.items.deleteSuccess') || 'Content deleted successfully');
    } catch (error) {
      console.error('Error deleting content:', error);
      toast.error(t('content.items.deleteError') || 'Failed to delete content');
    }
  };



  return (
    <>
      <SiteHeader dictionary={{ documents: t('content.items.title') || 'Content Items' }} />
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
                          <TableHead>{t('content.items.name') || 'Name'}</TableHead>
                          <TableHead>{t('content.items.nameAr') || 'Name (Arabic)'}</TableHead>
                          <TableHead>{t('content.items.type') || 'Type'}</TableHead>
                          <TableHead>{t('content.items.link') || 'Link'}</TableHead>
                          <TableHead className="text-end">{t('common.actions') || 'Actions'}</TableHead>
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
                            <TableCell className="text-end">
                              <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                  <Button variant="ghost" className="h-8 w-8 p-0">
                                    <MoreHorizontal className="h-4 w-4" />
                                  </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end">
                                  <DropdownMenuItem onClick={() => handleEditContent(item)}>
                                    <Edit className="h-4 w-4 mr-2" />
                                    {t('common.edit') || 'Edit'}
                                  </DropdownMenuItem>
                                  <DropdownMenuSeparator />
                                  <DropdownMenuItem
                                    onClick={() => handleDeleteContent(item)}
                                    className="text-red-600"
                                  >
                                    <Trash2 className="h-4 w-4 mr-2" />
                                    {t('common.delete') || 'Delete'}
                                  </DropdownMenuItem>
                                </DropdownMenuContent>
                              </DropdownMenu>
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

      {/* Content Form Dialog */}
      <Dialog open={showForm} onOpenChange={setShowForm}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {selectedContent
                ? (t('content.items.editContent') || 'Edit Content')
                : (t('content.items.createContent') || 'Create Content')
              }
            </DialogTitle>
            <DialogDescription>
              {selectedContent
                ? (t('content.items.editDescription') || 'Update the content item details below.')
                : (t('content.items.createDescription') || 'Fill out the form below to create a new content item.')
              }
            </DialogDescription>
          </DialogHeader>
          <ContentForm
            content={selectedContent}
            onSubmit={handleSubmitContent}
            onCancel={handleCancel}
            isLoading={isSubmitting}
            t={t}
            locale={locale}
            contentTypes={contentTypes}
            contentOwners={contentOwners}
            categories={categories}
          />
        </DialogContent>
      </Dialog>
    </>
  );
}
