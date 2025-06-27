'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  ResponsiveDialog as Dialog,
  ResponsiveDialogContent as DialogContent,
  ResponsiveDialogDescription as DialogDescription,
  ResponsiveDialogFooter as DialogFooter,
  ResponsiveDialogHeader as DialogHeader,
  ResponsiveDialogTitle as DialogTitle,
} from '@/components/ui/responsive-dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, addDoc, updateDoc, deleteDoc, doc, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { ContentList, CreateContentListRequest, UpdateContentListRequest, Content } from '@/types/content';
import { toast } from 'sonner';
import { List, Plus, Star, Eye, EyeOff, MoreHorizontal, Edit, Trash2 } from 'lucide-react';
import ContentListForm from './components/ContentListForm';

export default function ContentListsPage() {
  const { t, locale } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedList, setSelectedList] = useState<ContentList | undefined>();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [toggleActiveDialogOpen, setToggleActiveDialogOpen] = useState(false);
  const [toggleFeaturedDialogOpen, setToggleFeaturedDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [listToToggleActive, setListToToggleActive] = useState<ContentList | undefined>();
  const [listToToggleFeatured, setListToToggleFeatured] = useState<ContentList | undefined>();
  const [listToDelete, setListToDelete] = useState<ContentList | undefined>();

  // Firestore queries
  const [contentListsSnapshot, loading] = useCollection(
    query(collection(db, 'contentLists'), orderBy('listName'))
  );

  const [contentItemsSnapshot] = useCollection(
    query(collection(db, 'content'), where('isDeleted', '==', false), where('isActive', '==', true))
  );

  const contentLists = contentListsSnapshot?.docs.map(doc => ({
    ...doc.data(),
    id: doc.id, // Ensure document ID is set after spreading doc.data()
    createdAt: doc.data().createdAt?.toDate(),
    updatedAt: doc.data().updatedAt?.toDate(),
  })) as ContentList[] || [];

  const contentItems = contentItemsSnapshot?.docs.map(doc => ({
    ...doc.data(),
    id: doc.id, // Ensure document ID is set after spreading doc.data()
    createdAt: doc.data().createdAt?.toDate(),
    updatedAt: doc.data().updatedAt?.toDate(),
  })) as Content[] || [];

  const filteredContentLists = contentLists.filter(list =>
    list.listName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (list.listNameAr && list.listNameAr.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const handleSubmitList = async (data: CreateContentListRequest | UpdateContentListRequest) => {
    setIsSubmitting(true);
    
    // Store the list ID in a local variable to prevent it from being lost
    const listId = selectedList?.id;
    const isUpdate = !!selectedList && !!listId;
    
    try {
      // Filter out undefined values to prevent Firebase errors
      const cleanData = Object.fromEntries(
        Object.entries(data).filter(([_, value]) => value !== undefined)
      );
      
      if (isUpdate) {
        // Validate that we have a valid ID
        if (!listId || typeof listId !== 'string') {
          throw new Error(`Invalid list ID: ${listId}`);
        }
        
        // Update existing list
        await updateDoc(doc(db, 'contentLists', listId), {
          ...cleanData,
          updatedAt: new Date(),
        });
        toast.success(t('content.lists.updateSuccess') || 'Content list updated successfully');
      } else {
        // Create new list
        await addDoc(collection(db, 'contentLists'), {
          ...cleanData,
          createdAt: new Date(),
          updatedAt: new Date(),
        });
        toast.success(t('content.lists.createSuccess') || 'Content list created successfully');
      }
      
      setShowForm(false);
      setSelectedList(undefined);
    } catch (error) {
      console.error('Error submitting content list:', error);
      toast.error(
        isUpdate
          ? (t('content.lists.updateError') || 'Failed to update content list')
          : (t('content.lists.createError') || 'Failed to create content list')
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCancel = () => {
    setShowForm(false);
    setSelectedList(undefined);
  };

  const handleEditList = (list: ContentList) => {
    setSelectedList(list);
    setShowForm(true);
  };

  const handleToggleActive = async () => {
    if (!listToToggleActive) return;

    try {
      await updateDoc(doc(db, 'contentLists', listToToggleActive.id), {
        isActive: !listToToggleActive.isActive,
        updatedAt: new Date(),
      });
      toast.success(t('content.lists.statusUpdateSuccess') || 'Status updated successfully');
      setToggleActiveDialogOpen(false);
      setListToToggleActive(undefined);
    } catch (error) {
      console.error('Error updating status:', error);
      toast.error(t('content.lists.statusUpdateError') || 'Failed to update status');
    }
  };

  const handleToggleFeatured = async () => {
    if (!listToToggleFeatured) return;

    try {
      await updateDoc(doc(db, 'contentLists', listToToggleFeatured.id), {
        isFeatured: !listToToggleFeatured.isFeatured,
        updatedAt: new Date(),
      });
      toast.success(t('content.lists.statusUpdateSuccess') || 'Status updated successfully');
      setToggleFeaturedDialogOpen(false);
      setListToToggleFeatured(undefined);
    } catch (error) {
      console.error('Error updating featured status:', error);
      toast.error(t('content.lists.statusUpdateError') || 'Failed to update status');
    }
  };

  const handleDeleteList = async () => {
    if (!listToDelete) return;

    try {
      await deleteDoc(doc(db, 'contentLists', listToDelete.id));
      toast.success(t('content.lists.deleteSuccess') || 'Content list deleted successfully');
      setDeleteDialogOpen(false);
      setListToDelete(undefined);
    } catch (error) {
      console.error('Error deleting content list:', error);
      toast.error(t('content.lists.deleteError') || 'Failed to delete content list');
    }
  };

  const getStatusBadge = (isActive: boolean) => {
    return (
      <Badge variant={isActive ? 'default' : 'secondary'}>
        {isActive ? (
          <>
            <Eye className="h-3 w-3 mr-1" />
            {t('common.active') || 'Active'}
          </>
        ) : (
          <>
            <EyeOff className="h-3 w-3 mr-1" />
            {t('common.inactive') || 'Inactive'}
          </>
        )}
      </Badge>
    );
  };

  const getFeaturedBadge = (isFeatured: boolean) => {
    return isFeatured ? (
      <Badge variant="default">
        <Star className="h-3 w-3 mr-1" />
        {t('content.lists.featured') || 'Featured'}
      </Badge>
    ) : null;
  };

  const stats = {
    total: contentLists.length,
    active: contentLists.filter(list => list.isActive).length,
    featured: contentLists.filter(list => list.isFeatured).length,
  };



  return (
    <>
      <SiteHeader dictionary={{ documents: t('content.lists.title') || 'Content Lists' }} />
      <div className="h-full flex flex-col">
          <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
            <div>
              <h1 className="text-3xl font-bold tracking-tight">
                {t('content.lists.title') || 'Content Lists'}
              </h1>
              <p className="text-muted-foreground">
                {t('content.lists.description') || 'Create and manage curated content collections'}
              </p>
            </div>
            <Button onClick={() => setShowForm(true)}>
              <Plus className="h-4 w-4 mr-2" />
              {t('content.lists.create') || 'Create List'}
            </Button>
          </div>

          <div className="flex-1 overflow-auto">
            <div className="p-6 space-y-6">
              {/* Stats Cards */}
              <div className="grid gap-4 md:grid-cols-3">
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      {t('content.lists.totalLists') || 'Total Lists'}
                    </CardTitle>
                    <List className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{stats.total}</div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      {t('content.lists.activeLists') || 'Active Lists'}
                    </CardTitle>
                    <Eye className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold text-green-600">{stats.active}</div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      {t('content.lists.featuredLists') || 'Featured Lists'}
                    </CardTitle>
                    <Star className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold text-yellow-600">{stats.featured}</div>
                  </CardContent>
                </Card>
              </div>

              <Card>
                <CardHeader>
                  <CardTitle>{t('content.lists.list') || 'Content Lists'}</CardTitle>
                  <CardDescription>
                    {t('content.lists.listDescription') || 'Create and manage curated content collections'}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="mb-4">
                    <Input
                      placeholder={t('content.lists.searchPlaceholder') || 'Search content lists...'}
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
                          <TableHead>{t('content.lists.name') || 'Name'}</TableHead>
                          <TableHead>{t('content.lists.nameAr') || 'Name (Arabic)'}</TableHead>
                          <TableHead>{t('content.lists.contentCount') || 'Content Count'}</TableHead>
                          <TableHead>{t('common.status') || 'Status'}</TableHead>
                          <TableHead>{t('content.lists.featured') || 'Featured'}</TableHead>
                          <TableHead className="text-end">{t('common.actions') || 'Actions'}</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {filteredContentLists.map((list) => (
                          <TableRow key={list.id}>
                            <TableCell className="font-medium">{list.listName}</TableCell>
                            <TableCell>{list.listNameAr || '-'}</TableCell>
                            <TableCell>{list.listContentIds?.length || 0}</TableCell>
                            <TableCell>{getStatusBadge(list.isActive)}</TableCell>
                            <TableCell>{getFeaturedBadge(list.isFeatured)}</TableCell>
                            <TableCell className="text-end">
                              <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                  <Button variant="ghost" className="h-8 w-8 p-0">
                                    <MoreHorizontal className="h-4 w-4" />
                                  </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end">
                                  <DropdownMenuItem onClick={() => handleEditList(list)}>
                                    <Edit className="h-4 w-4 mr-2" />
                                    {t('common.edit') || 'Edit'}
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={() => {
                                      setListToToggleActive(list);
                                      setToggleActiveDialogOpen(true);
                                    }}
                                  >
                                    {list.isActive ? (
                                      <>
                                        <EyeOff className="h-4 w-4 mr-2" />
                                        {t('common.deactivate') || 'Deactivate'}
                                      </>
                                    ) : (
                                      <>
                                        <Eye className="h-4 w-4 mr-2" />
                                        {t('common.activate') || 'Activate'}
                                      </>
                                    )}
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={() => {
                                      setListToToggleFeatured(list);
                                      setToggleFeaturedDialogOpen(true);
                                    }}
                                  >
                                    {list.isFeatured ? (
                                      <>
                                        <Star className="h-4 w-4 mr-2" />
                                        {t('content.lists.unfeatured') || 'Remove Featured'}
                                      </>
                                    ) : (
                                      <>
                                        <Star className="h-4 w-4 mr-2" />
                                        {t('content.lists.makeFeatured') || 'Make Featured'}
                                      </>
                                    )}
                                  </DropdownMenuItem>
                                  <DropdownMenuSeparator />
                                  <DropdownMenuItem
                                    onClick={() => {
                                      setListToDelete(list);
                                      setDeleteDialogOpen(true);
                                    }}
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

                  {!loading && filteredContentLists.length === 0 && (
                    <div className="text-center py-8">
                      <List className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                      <p className="text-lg font-medium">{t('common.noData') || 'No data'}</p>
                      <p className="text-muted-foreground">
                        {t('content.lists.noListsFound') || 'No content lists found'}
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </div>
      </div>

      {/* Toggle Active Dialog */}
      <Dialog open={toggleActiveDialogOpen} onOpenChange={setToggleActiveDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {listToToggleActive?.isActive 
                ? (t('content.lists.deactivateTitle') || 'Deactivate Content List')
                : (t('content.lists.activateTitle') || 'Activate Content List')
              }
            </DialogTitle>
            <DialogDescription>
              {listToToggleActive?.isActive
                ? (t('content.lists.deactivateDescription') || 'Are you sure you want to deactivate this content list? It will no longer be visible to users.')
                : (t('content.lists.activateDescription') || 'Are you sure you want to activate this content list? It will be visible to users.')
              }
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setToggleActiveDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button onClick={handleToggleActive}>
              {listToToggleActive?.isActive 
                ? (t('common.deactivate') || 'Deactivate')
                : (t('common.activate') || 'Activate')
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Toggle Featured Dialog */}
      <Dialog open={toggleFeaturedDialogOpen} onOpenChange={setToggleFeaturedDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {listToToggleFeatured?.isFeatured 
                ? (t('content.lists.unfeaturedTitle') || 'Remove Featured Status')
                : (t('content.lists.makeFeaturedTitle') || 'Make Content List Featured')
              }
            </DialogTitle>
            <DialogDescription>
              {listToToggleFeatured?.isFeatured
                ? (t('content.lists.unfeaturedDescription') || 'Are you sure you want to remove the featured status from this content list?')
                : (t('content.lists.makeFeaturedDescription') || 'Are you sure you want to make this content list featured? It will be highlighted to users.')
              }
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setToggleFeaturedDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button onClick={handleToggleFeatured}>
              {listToToggleFeatured?.isFeatured 
                ? (t('content.lists.unfeatured') || 'Remove Featured')
                : (t('content.lists.makeFeatured') || 'Make Featured')
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('content.lists.deleteTitle') || 'Delete Content List'}</DialogTitle>
            <DialogDescription>
              {t('content.lists.deleteDescription') || 'Are you sure you want to delete this content list? This action cannot be undone.'}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button variant="destructive" onClick={handleDeleteList}>
              {t('common.delete') || 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Content List Form Dialog */}
      <Dialog open={showForm} onOpenChange={setShowForm}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {selectedList
                ? (t('content.lists.editList') || 'Edit Content List')
                : (t('content.lists.createList') || 'Create Content List')
              }
            </DialogTitle>
            <DialogDescription>
              {selectedList
                ? (t('content.lists.editDescription') || 'Update the content list details below.')
                : (t('content.lists.createDescription') || 'Fill out the form below to create a new content list.')
              }
            </DialogDescription>
          </DialogHeader>
          <ContentListForm
            contentList={selectedList}
            onSubmit={handleSubmitList}
            onCancel={handleCancel}
            isLoading={isSubmitting}
            t={t}
            locale={locale}
            contentItems={contentItems}
          />
        </DialogContent>
      </Dialog>
    </>
  );
}
