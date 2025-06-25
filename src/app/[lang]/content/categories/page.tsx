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
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Plus,
  Search,
  MoreHorizontal,
  Edit,
  Trash2,
  Tag,
  Eye,
  EyeOff,
} from 'lucide-react';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, addDoc, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Category, CreateCategoryRequest, UpdateCategoryRequest } from '@/types/content';
import CategoryForm from './components/CategoryForm';
import { toast } from 'sonner';

export default function CategoriesPage() {
  const { t, locale } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<Category | undefined>();
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [categoryToDelete, setCategoryToDelete] = useState<Category | undefined>();
  const [toggleDialogOpen, setToggleDialogOpen] = useState(false);
  const [categoryToToggle, setCategoryToToggle] = useState<Category | undefined>();
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Firestore queries
  const [categoriesSnapshot, loading, error] = useCollection(
    query(collection(db, 'contentCategories'), orderBy('categoryName'))
  );

  const categories = categoriesSnapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    createdAt: doc.data().createdAt?.toDate(),
    updatedAt: doc.data().updatedAt?.toDate(),
  })) as Category[] || [];

  const filteredCategories = categories.filter(category =>
    category.categoryName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (category.categoryNameAr && category.categoryNameAr.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const handleCreateCategory = async (data: CreateCategoryRequest) => {
    try {
      setIsSubmitting(true);
      await addDoc(collection(db, 'contentCategories'), {
        ...data,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      toast.success(t('content.categories.createSuccess') || 'Category created successfully');
      setShowForm(false);
      setSelectedCategory(undefined);
    } catch (error) {
      console.error('Error creating category:', error);
      toast.error(t('content.categories.createError') || 'Failed to create category');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleUpdateCategory = async (data: UpdateCategoryRequest) => {
    if (!selectedCategory) return;
    
    try {
      setIsSubmitting(true);
      await updateDoc(doc(db, 'contentCategories', selectedCategory.id), {
        ...data,
        updatedAt: new Date(),
      });
      toast.success(t('content.categories.updateSuccess') || 'Category updated successfully');
      setShowForm(false);
      setSelectedCategory(undefined);
    } catch (error) {
      console.error('Error updating category:', error);
      toast.error(t('content.categories.updateError') || 'Failed to update category');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleActive = async () => {
    if (!categoryToToggle) return;

    try {
      await updateDoc(doc(db, 'contentCategories', categoryToToggle.id), {
        isActive: !categoryToToggle.isActive,
        updatedAt: new Date(),
      });
      toast.success(t('content.categories.statusUpdateSuccess') || 'Status updated successfully');
      setToggleDialogOpen(false);
      setCategoryToToggle(undefined);
    } catch (error) {
      console.error('Error updating status:', error);
      toast.error(t('content.categories.statusUpdateError') || 'Failed to update status');
    }
  };

  const handleDeleteCategory = async () => {
    if (!categoryToDelete) return;

    try {
      await deleteDoc(doc(db, 'contentCategories', categoryToDelete.id));
      toast.success(t('content.categories.deleteSuccess') || 'Category deleted successfully');
      setDeleteDialogOpen(false);
      setCategoryToDelete(undefined);
    } catch (error) {
      console.error('Error deleting category:', error);
      toast.error(t('content.categories.deleteError') || 'Failed to delete category');
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

  const stats = {
    total: categories.length,
    active: categories.filter(category => category.isActive).length,
    inactive: categories.filter(category => !category.isActive).length,
  };



  const headerDictionary = {
    documents: t('content.categories.title') || 'Categories',
  };

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="h-full flex flex-col">
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
            <div>
              <h1 className="text-3xl font-bold tracking-tight">
                {t('content.categories.title') || 'Categories'}
              </h1>
              <p className="text-muted-foreground">
                {t('content.categories.description') || 'Organize content into categories and topics'}
              </p>
            </div>
            <Button onClick={() => setShowForm(true)}>
              <Plus className="h-4 w-4 mr-2" />
              {t('content.categories.create') || 'Create Category'}
            </Button>
          </div>

          {/* Content area */}
          <div className="flex-1 overflow-auto">
            <div className="p-6 space-y-6 max-w-none">
              {/* Stats Cards */}
              <div className="grid gap-4 md:grid-cols-3">
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      {t('content.categories.totalCategories') || 'Total Categories'}
                    </CardTitle>
                    <Tag className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{stats.total}</div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      {t('content.categories.activeCategories') || 'Active Categories'}
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
                      {t('content.categories.inactiveCategories') || 'Inactive Categories'}
                    </CardTitle>
                    <EyeOff className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold text-gray-600">{stats.inactive}</div>
                  </CardContent>
                </Card>
              </div>

              {/* Search */}
              <Card>
                <CardHeader>
                  <CardTitle>{t('common.search') || 'Search'}</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="flex gap-4">
                    <div className="flex-1">
                      <Input
                        placeholder={t('content.categories.searchPlaceholder') || 'Search categories...'}
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                      />
                    </div>
                    <Button variant="outline">
                      <Search className="h-4 w-4 mr-2" />
                      {t('common.search') || 'Search'}
                    </Button>
                  </div>
                </CardContent>
              </Card>

              {/* Categories Table */}
              <Card>
                <CardHeader>
                  <CardTitle>{t('content.categories.list') || 'Categories'}</CardTitle>
                  <CardDescription>
                    {t('content.categories.listDescription') || 'Organize content into categories and topics'}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {loading ? (
                    <div className="space-y-3">
                      {[...Array(5)].map((_, i) => (
                        <Skeleton key={i} className="h-16 w-full" />
                      ))}
                    </div>
                  ) : error ? (
                    <div className="text-center py-8 text-red-600">
                      <p>{t('common.error') || 'Error loading data'}</p>
                    </div>
                  ) : (
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>{t('content.categories.icon') || 'Icon'}</TableHead>
                          <TableHead>{t('content.categories.name') || 'Name'}</TableHead>
                          <TableHead>{t('content.categories.nameAr') || 'Name (Arabic)'}</TableHead>
                          <TableHead>{t('common.status') || 'Status'}</TableHead>
                          <TableHead className="text-end">{t('common.actions') || 'Actions'}</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {filteredCategories.map((category) => (
                          <TableRow key={category.id}>
                            <TableCell>
                              <div className="w-8 h-8 bg-muted rounded flex items-center justify-center">
                                <Tag className="h-4 w-4" />
                              </div>
                            </TableCell>
                            <TableCell className="font-medium">{category.categoryName}</TableCell>
                            <TableCell className="text-muted-foreground">
                              {category.categoryNameAr || '-'}
                            </TableCell>
                            <TableCell>{getStatusBadge(category.isActive)}</TableCell>
                            <TableCell className="text-end">
                              <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                  <Button variant="ghost" className="h-8 w-8 p-0">
                                    <MoreHorizontal className="h-4 w-4" />
                                  </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end">
                                  <DropdownMenuItem
                                    onClick={() => {
                                      setSelectedCategory(category);
                                      setShowForm(true);
                                    }}
                                  >
                                    <Edit className="h-4 w-4 mr-2" />
                                    {t('common.edit') || 'Edit'}
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={() => {
                                      setCategoryToToggle(category);
                                      setToggleDialogOpen(true);
                                    }}
                                  >
                                    {category.isActive ? (
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
                                  <DropdownMenuSeparator />
                                  <DropdownMenuItem
                                    onClick={() => {
                                      setCategoryToDelete(category);
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

                  {!loading && filteredCategories.length === 0 && (
                    <div className="text-center py-8">
                      <Tag className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                      <p className="text-lg font-medium">{t('common.noData') || 'No data'}</p>
                      <p className="text-muted-foreground">
                        {t('content.categories.noCategoriesFound') || 'No categories found'}
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </div>
        </div>

      {/* Form Dialog */}
      <Dialog open={showForm} onOpenChange={(open: boolean) => {
        setShowForm(open);
        if (!open) setSelectedCategory(undefined);
      }}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>
              {selectedCategory 
                ? (t('content.categories.edit') || 'Edit Category')
                : (t('content.categories.create') || 'Create Category')
              }
            </DialogTitle>
            <DialogDescription>
              {selectedCategory
                ? (t('content.categories.editDescription') || 'Update category information')
                : (t('content.categories.createDescription') || 'Add a new category')
              }
            </DialogDescription>
          </DialogHeader>
          <CategoryForm
            category={selectedCategory}
            onSubmit={selectedCategory 
              ? (data) => handleUpdateCategory(data as UpdateCategoryRequest)
              : (data) => handleCreateCategory(data as CreateCategoryRequest)
            }
            onCancel={() => {
              setShowForm(false);
              setSelectedCategory(undefined);
            }}
            isLoading={isSubmitting}
            t={t}
            locale={locale}
          />
        </DialogContent>
      </Dialog>

      {/* Toggle Status Dialog */}
      <Dialog open={toggleDialogOpen} onOpenChange={setToggleDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {categoryToToggle?.isActive 
                ? (t('content.categories.deactivateTitle') || 'Deactivate Category')
                : (t('content.categories.activateTitle') || 'Activate Category')
              }
            </DialogTitle>
            <DialogDescription>
              {categoryToToggle?.isActive
                ? (t('content.categories.deactivateDescription') || 'Are you sure you want to deactivate this category? It will no longer be available for selection.')
                : (t('content.categories.activateDescription') || 'Are you sure you want to activate this category? It will be available for selection.')
              }
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setToggleDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button onClick={handleToggleActive}>
              {categoryToToggle?.isActive 
                ? (t('common.deactivate') || 'Deactivate')
                : (t('common.activate') || 'Activate')
              }
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('content.categories.deleteTitle') || 'Delete Category'}</DialogTitle>
            <DialogDescription>
              {t('content.categories.deleteDescription') || 'Are you sure you want to delete this category? This action cannot be undone.'}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button variant="destructive" onClick={handleDeleteCategory}>
              {t('common.delete') || 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
} 