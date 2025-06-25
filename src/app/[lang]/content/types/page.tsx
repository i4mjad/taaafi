'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
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
  FileText,
  Eye,
  EyeOff,
} from 'lucide-react';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, addDoc, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { ContentType, CreateContentTypeRequest, UpdateContentTypeRequest } from '@/types/content';
import ContentTypeForm from './components/ContentTypeForm';
import { toast } from 'sonner';

export default function ContentTypesPage() {
  const { t, locale } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedType, setSelectedType] = useState<ContentType | undefined>();
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [typeToDelete, setTypeToDelete] = useState<ContentType | undefined>();
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Firestore queries
  const [contentTypesSnapshot, loading, error] = useCollection(
    query(collection(db, 'contentTypes'), orderBy('contentTypeName'))
  );

  const contentTypes = contentTypesSnapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    createdAt: doc.data().createdAt?.toDate(),
    updatedAt: doc.data().updatedAt?.toDate(),
  })) as ContentType[] || [];

  const filteredContentTypes = contentTypes.filter(type =>
    type.contentTypeName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (type.contentTypeNameAr && type.contentTypeNameAr.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const handleCreateType = async (data: CreateContentTypeRequest) => {
    try {
      setIsSubmitting(true);
      await addDoc(collection(db, 'contentTypes'), {
        ...data,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      toast.success(t('content.types.createSuccess') || 'Content type created successfully');
      setShowForm(false);
      setSelectedType(undefined);
    } catch (error) {
      console.error('Error creating content type:', error);
      toast.error(t('content.types.createError') || 'Failed to create content type');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleUpdateType = async (data: UpdateContentTypeRequest) => {
    if (!selectedType) return;
    
    try {
      setIsSubmitting(true);
      await updateDoc(doc(db, 'contentTypes', selectedType.id), {
        ...data,
        updatedAt: new Date(),
      });
      toast.success(t('content.types.updateSuccess') || 'Content type updated successfully');
      setShowForm(false);
      setSelectedType(undefined);
    } catch (error) {
      console.error('Error updating content type:', error);
      toast.error(t('content.types.updateError') || 'Failed to update content type');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleActive = async (type: ContentType) => {
    try {
      await updateDoc(doc(db, 'contentTypes', type.id), {
        isActive: !type.isActive,
        updatedAt: new Date(),
      });
      toast.success(t('content.types.statusUpdateSuccess') || 'Status updated successfully');
    } catch (error) {
      console.error('Error updating status:', error);
      toast.error(t('content.types.statusUpdateError') || 'Failed to update status');
    }
  };

  const handleDeleteType = async () => {
    if (!typeToDelete) return;

    try {
      await deleteDoc(doc(db, 'contentTypes', typeToDelete.id));
      toast.success(t('content.types.deleteSuccess') || 'Content type deleted successfully');
      setDeleteDialogOpen(false);
      setTypeToDelete(undefined);
    } catch (error) {
      console.error('Error deleting content type:', error);
      toast.error(t('content.types.deleteError') || 'Failed to delete content type');
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
    total: contentTypes.length,
    active: contentTypes.filter(type => type.isActive).length,
    inactive: contentTypes.filter(type => !type.isActive).length,
  };

  const headerDictionary = {
    documents: t('siteHeader.documents') || 'Documents',
  };

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="h-full flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">
              {t('content.types.title') || 'Content Types'}
            </h1>
            <p className="text-muted-foreground">
              {t('content.types.description') || 'Manage different types of content (articles, videos, resources)'}
            </p>
          </div>
          <Button onClick={() => setShowForm(true)}>
            <Plus className="h-4 w-4 mr-2" />
            {t('content.types.create') || 'Create Type'}
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
                    {t('content.types.totalTypes') || 'Total Types'}
                  </CardTitle>
                  <FileText className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.total}</div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('content.types.activeTypes') || 'Active Types'}
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
                    {t('content.types.inactiveTypes') || 'Inactive Types'}
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
                      placeholder={t('content.types.searchPlaceholder') || 'Search content types...'}
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

            {/* Content Types Table */}
            <Card>
              <CardHeader>
                <CardTitle>{t('content.types.list') || 'Content Types'}</CardTitle>
                <CardDescription>
                  {t('content.types.listDescription') || 'Manage and organize content types'}
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
                        <TableHead>{t('content.types.icon') || 'Icon'}</TableHead>
                        <TableHead>{t('content.types.nameEn') || 'Name (EN)'}</TableHead>
                        <TableHead>{t('content.types.nameAr') || 'Name (AR)'}</TableHead>
                        <TableHead>{t('common.status') || 'Status'}</TableHead>
                        <TableHead>{t('common.active') || 'Active'}</TableHead>
                        <TableHead className="text-right">{t('common.actions') || 'Actions'}</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredContentTypes.map((type) => (
                        <TableRow key={type.id}>
                          <TableCell>
                            <div className="w-8 h-8 bg-muted rounded flex items-center justify-center">
                              {type.contentTypeIconName}
                            </div>
                          </TableCell>
                          <TableCell className="font-medium">{type.contentTypeName}</TableCell>
                          <TableCell className="text-muted-foreground">
                            {type.contentTypeNameAr || '-'}
                          </TableCell>
                          <TableCell>{getStatusBadge(type.isActive)}</TableCell>
                          <TableCell>
                            <Switch
                              checked={type.isActive}
                              onCheckedChange={() => handleToggleActive(type)}
                            />
                          </TableCell>
                          <TableCell className="text-right">
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" className="h-8 w-8 p-0">
                                  <MoreHorizontal className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                <DropdownMenuItem
                                  onClick={() => {
                                    setSelectedType(type);
                                    setShowForm(true);
                                  }}
                                >
                                  <Edit className="h-4 w-4 mr-2" />
                                  {t('common.edit') || 'Edit'}
                                </DropdownMenuItem>
                                <DropdownMenuSeparator />
                                <DropdownMenuItem
                                  onClick={() => {
                                    setTypeToDelete(type);
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

                {!loading && filteredContentTypes.length === 0 && (
                  <div className="text-center py-8">
                    <FileText className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                    <p className="text-lg font-medium">{t('common.noData') || 'No data'}</p>
                    <p className="text-muted-foreground">
                      {t('content.types.noTypesFound') || 'No content types found'}
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
        if (!open) setSelectedType(undefined);
      }}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>
              {selectedType 
                ? (t('content.types.edit') || 'Edit Content Type')
                : (t('content.types.create') || 'Create Content Type')
              }
            </DialogTitle>
            <DialogDescription>
              {selectedType
                ? (t('content.types.editDescription') || 'Update content type information')
                : (t('content.types.createDescription') || 'Add a new content type')
              }
            </DialogDescription>
          </DialogHeader>
          <ContentTypeForm
            contentType={selectedType}
            onSubmit={selectedType 
              ? (data) => handleUpdateType(data as UpdateContentTypeRequest)
              : (data) => handleCreateType(data as CreateContentTypeRequest)
            }
            onCancel={() => {
              setShowForm(false);
              setSelectedType(undefined);
            }}
            isLoading={isSubmitting}
            t={t}
            locale={locale}
          />
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('content.types.deleteTitle') || 'Delete Content Type'}</DialogTitle>
            <DialogDescription>
              {t('content.types.deleteDescription') || 'Are you sure you want to delete this content type? This action cannot be undone.'}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button variant="destructive" onClick={handleDeleteType}>
              {t('common.delete') || 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
} 