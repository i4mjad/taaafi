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
  Users,
  Eye,
  EyeOff,
} from 'lucide-react';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, addDoc, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { ContentOwner, CreateContentOwnerRequest, UpdateContentOwnerRequest } from '@/types/content';
import ContentOwnerForm from './components/ContentOwnerForm';
import { toast } from 'sonner';

export default function ContentOwnersPage() {
  const { t, locale } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedOwner, setSelectedOwner] = useState<ContentOwner | undefined>();
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [ownerToDelete, setOwnerToDelete] = useState<ContentOwner | undefined>();
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Firestore queries
  const [contentOwnersSnapshot, loading, error] = useCollection(
    query(collection(db, 'contentOwners'), orderBy('ownerName'))
  );

  const contentOwners = contentOwnersSnapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    createdAt: doc.data().createdAt?.toDate(),
    updatedAt: doc.data().updatedAt?.toDate(),
  })) as ContentOwner[] || [];

  const filteredContentOwners = contentOwners.filter(owner =>
    owner.ownerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (owner.ownerNameAr && owner.ownerNameAr.toLowerCase().includes(searchQuery.toLowerCase())) ||
    owner.ownerSource.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleCreateOwner = async (data: CreateContentOwnerRequest) => {
    try {
      setIsSubmitting(true);
      await addDoc(collection(db, 'contentOwners'), {
        ...data,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      toast.success(t('content.owners.createSuccess') || 'Content owner created successfully');
      setShowForm(false);
      setSelectedOwner(undefined);
    } catch (error) {
      console.error('Error creating content owner:', error);
      toast.error(t('content.owners.createError') || 'Failed to create content owner');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleUpdateOwner = async (data: UpdateContentOwnerRequest) => {
    if (!selectedOwner) return;
    
    try {
      setIsSubmitting(true);
      await updateDoc(doc(db, 'contentOwners', selectedOwner.id), {
        ...data,
        updatedAt: new Date(),
      });
      toast.success(t('content.owners.updateSuccess') || 'Content owner updated successfully');
      setShowForm(false);
      setSelectedOwner(undefined);
    } catch (error) {
      console.error('Error updating content owner:', error);
      toast.error(t('content.owners.updateError') || 'Failed to update content owner');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleActive = async (owner: ContentOwner) => {
    try {
      await updateDoc(doc(db, 'contentOwners', owner.id), {
        isActive: !owner.isActive,
        updatedAt: new Date(),
      });
      toast.success(t('content.owners.statusUpdateSuccess') || 'Status updated successfully');
    } catch (error) {
      console.error('Error updating status:', error);
      toast.error(t('content.owners.statusUpdateError') || 'Failed to update status');
    }
  };

  const handleDeleteOwner = async () => {
    if (!ownerToDelete) return;

    try {
      await deleteDoc(doc(db, 'contentOwners', ownerToDelete.id));
      toast.success(t('content.owners.deleteSuccess') || 'Content owner deleted successfully');
      setDeleteDialogOpen(false);
      setOwnerToDelete(undefined);
    } catch (error) {
      console.error('Error deleting content owner:', error);
      toast.error(t('content.owners.deleteError') || 'Failed to delete content owner');
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
    total: contentOwners.length,
    active: contentOwners.filter(owner => owner.isActive).length,
    inactive: contentOwners.filter(owner => !owner.isActive).length,
  };



  const headerDictionary = {
    documents: t('content.owners.title') || 'Content Owners',
  };

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="h-full flex flex-col">
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">
            {t('content.owners.title') || 'Content Owners'}
          </h1>
          <p className="text-muted-foreground">
            {t('content.owners.description') || 'Manage content creators and their permissions'}
          </p>
        </div>
        <Button onClick={() => setShowForm(true)}>
          <Plus className="h-4 w-4 mr-2" />
          {t('content.owners.create') || 'Create Owner'}
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
                  {t('content.owners.totalOwners') || 'Total Owners'}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.total}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('content.owners.activeOwners') || 'Active Owners'}
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
                  {t('content.owners.inactiveOwners') || 'Inactive Owners'}
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
                    placeholder={t('content.owners.searchPlaceholder') || 'Search content owners...'}
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

          {/* Content Owners Table */}
          <Card>
            <CardHeader>
              <CardTitle>{t('content.owners.list') || 'Content Owners'}</CardTitle>
              <CardDescription>
                {t('content.owners.listDescription') || 'Manage content creators and contributors'}
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
                      <TableHead>{t('content.owners.nameEn') || 'Name (EN)'}</TableHead>
                      <TableHead>{t('content.owners.nameAr') || 'Name (AR)'}</TableHead>
                      <TableHead>{t('content.owners.source') || 'Source'}</TableHead>
                      <TableHead>{t('common.status') || 'Status'}</TableHead>
                      <TableHead>{t('common.active') || 'Active'}</TableHead>
                      <TableHead className="text-right">{t('common.actions') || 'Actions'}</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredContentOwners.map((owner) => (
                      <TableRow key={owner.id}>
                        <TableCell className="font-medium">{owner.ownerName}</TableCell>
                        <TableCell className="text-muted-foreground">
                          {owner.ownerNameAr || '-'}
                        </TableCell>
                        <TableCell>{owner.ownerSource}</TableCell>
                        <TableCell>{getStatusBadge(owner.isActive)}</TableCell>
                        <TableCell>
                          <Switch
                            checked={owner.isActive}
                            onCheckedChange={() => handleToggleActive(owner)}
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
                                  setSelectedOwner(owner);
                                  setShowForm(true);
                                }}
                              >
                                <Edit className="h-4 w-4 mr-2" />
                                {t('common.edit') || 'Edit'}
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              <DropdownMenuItem
                                onClick={() => {
                                  setOwnerToDelete(owner);
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

              {!loading && filteredContentOwners.length === 0 && (
                <div className="text-center py-8">
                  <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                  <p className="text-lg font-medium">{t('common.noData') || 'No data'}</p>
                  <p className="text-muted-foreground">
                    {t('content.owners.noOwnersFound') || 'No content owners found'}
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
        if (!open) setSelectedOwner(undefined);
      }}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>
              {selectedOwner 
                ? (t('content.owners.edit') || 'Edit Content Owner')
                : (t('content.owners.create') || 'Create Content Owner')
              }
            </DialogTitle>
            <DialogDescription>
              {selectedOwner
                ? (t('content.owners.editDescription') || 'Update content owner information')
                : (t('content.owners.createDescription') || 'Add a new content owner')
              }
            </DialogDescription>
          </DialogHeader>
          <ContentOwnerForm
            contentOwner={selectedOwner}
            onSubmit={selectedOwner 
              ? (data) => handleUpdateOwner(data as UpdateContentOwnerRequest)
              : (data) => handleCreateOwner(data as CreateContentOwnerRequest)
            }
            onCancel={() => {
              setShowForm(false);
              setSelectedOwner(undefined);
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
            <DialogTitle>{t('content.owners.deleteTitle') || 'Delete Content Owner'}</DialogTitle>
            <DialogDescription>
              {t('content.owners.deleteDescription') || 'Are you sure you want to delete this content owner? This action cannot be undone.'}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button variant="destructive" onClick={handleDeleteOwner}>
              {t('common.delete') || 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
} 