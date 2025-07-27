'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import { SiteHeader } from '@/components/site-header';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import {
  ArrowLeft,
  Users,
  Plus,
  Edit,
  Trash2,
  MoreHorizontal,
  Settings,
  AlertTriangle,
} from 'lucide-react';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import Link from 'next/link';
import { useTranslation } from "@/contexts/TranslationContext";
import CreateGroupDialog from '../components/CreateGroupDialog';
import EditGroupDialog from './components/EditGroupDialog';
// Firebase imports
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, doc, deleteDoc, writeBatch } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface Group {
  id: string;
  name: string;
  nameAr: string;
  description?: string;
  descriptionAr?: string;
  topicId: string;
  memberCount: number;
  isActive: boolean;
  isForPlusUsers?: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export default function GroupsManagementPage() {
  const { t, locale } = useTranslation();
  const params = useParams();
  
  const [deleteLoading, setDeleteLoading] = useState<string | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [groupToDelete, setGroupToDelete] = useState<Group | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [groupToEdit, setGroupToEdit] = useState<Group | null>(null);

  const headerDictionary = {
    documents: t('modules.userManagement.groups.title') || 'Messaging Groups',
  };

  // Use Firebase hooks to fetch groups
  const [groupsSnapshot, loading, error] = useCollection(
    query(collection(db, 'usersMessagingGroups'), orderBy('createdAt', 'desc'))
  );

  // Convert Firestore documents to Group objects
  const groups: Group[] = groupsSnapshot?.docs.map(doc => {
    const data = doc.data();
    return {
      id: doc.id,
      name: data.name,
      nameAr: data.nameAr,
      description: data.description,
      descriptionAr: data.descriptionAr,
      topicId: data.topicId,
      memberCount: data.memberCount || 0,
      isActive: data.isActive !== false, // Default to true if not specified
      isForPlusUsers: data.isForPlusUsers || false, // Default to false if not specified
      createdAt: data.createdAt?.toDate() || new Date(),
      updatedAt: data.updatedAt?.toDate() || new Date(),
    };
  }) || [];

  const handleDeleteGroup = async () => {
    if (!groupToDelete) return;

    try {
      setDeleteLoading(groupToDelete.id);
      
      // Create a batch operation for deleting group and updating memberships
      const batch = writeBatch(db);
      
      // Delete the group document
      const groupRef = doc(db, 'usersMessagingGroups', groupToDelete.id);
      batch.delete(groupRef);

      // TODO: Remove group from user memberships (if using userGroupMemberships collection)
      // This would require querying userGroupMemberships and updating each document
      // For now, we'll just delete the group document

      // Execute batch operations
      await batch.commit();

      setDeleteDialogOpen(false);
      setGroupToDelete(null);
    } catch (error) {
      console.error('Error deleting group:', error);
    } finally {
      setDeleteLoading(null);
    }
  };

  const formatDate = (date: Date | string | null | undefined) => {
    if (!date) return t('common.never') || 'Never';
    
    // Handle both Date objects and date strings
    const dateObj = date instanceof Date ? date : new Date(date);
    
    // Check if the date is valid
    if (isNaN(dateObj.getTime())) {
      return t('common.unknown') || 'Unknown';
    }
    
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(dateObj);
  };

  const getGroupName = (group: Group): string => {
    return locale === 'ar' && group.nameAr ? group.nameAr : group.name;
  };

  const getGroupDescription = (group: Group): string => {
    const desc = locale === 'ar' && group.descriptionAr ? group.descriptionAr : group.description;
    return desc || '';
  };

  if (loading) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex flex-1 flex-col">
          <div className="@container/main flex flex-1 flex-col gap-2">
            <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
              <Skeleton className="h-8 w-64" />
              <Skeleton className="h-96" />
            </div>
          </div>
        </div>
      </>
    );
  }

  if (error) {
    return (
      <>
        <SiteHeader dictionary={headerDictionary} />
        <div className="flex flex-1 flex-col">
          <div className="@container/main flex flex-1 flex-col gap-2">
            <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
              <div className="text-center py-12">
                <AlertTriangle className="h-12 w-12 mx-auto mb-4 text-destructive" />
                <h3 className="text-lg font-medium mb-2">Error loading groups</h3>
                <p className="text-muted-foreground">{error.message}</p>
              </div>
            </div>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex flex-1 flex-col">
        <div className="@container/main flex flex-1 flex-col gap-2">
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
            {/* Header */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <Button variant="outline" size="sm" asChild>
                  <Link href={`/${locale}/user-management/settings`}>
                    <ArrowLeft className="h-4 w-4 mr-2" />
                    {t('common.back') || 'Back'}
                  </Link>
                </Button>
                <div>
                  <h1 className="text-3xl font-bold tracking-tight">
                    {t('modules.userManagement.groups.title') || 'Messaging Groups'}
                  </h1>
                  <p className="text-muted-foreground">
                    {t('modules.userManagement.groups.manageDescription') || 'Create and manage user groups for targeted messaging'}
                  </p>
                </div>
              </div>
              <CreateGroupDialog 
                trigger={
                  <Button>
                    <Plus className="h-4 w-4 mr-2" />
                    {t('modules.userManagement.groups.createGroup') || 'Create Group'}
                  </Button>
                }
              />
            </div>

            {/* Groups Table */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Users className="h-5 w-5" />
                  {t('modules.userManagement.groups.allGroups') || 'All Groups'}
                </CardTitle>
                <CardDescription>
                  {t('modules.userManagement.groups.allGroupsDescription') || 'Manage all messaging groups and their settings'}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {groups.length === 0 ? (
                  <div className="text-center py-12">
                    <Users className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
                    <h3 className="text-lg font-medium mb-2">
                      {t('modules.userManagement.groups.noGroups') || 'No groups found'}
                    </h3>
                    <p className="text-muted-foreground mb-4">
                      {t('modules.userManagement.groups.noGroupsDescription') || 'Create your first messaging group to get started'}
                    </p>
                    <CreateGroupDialog 
                      trigger={
                        <Button>
                          <Plus className="h-4 w-4 mr-2" />
                          {t('modules.userManagement.groups.createFirstGroup') || 'Create First Group'}
                        </Button>
                      }
                    />
                  </div>
                ) : (
                  <div className="overflow-x-auto">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>{t('modules.userManagement.groups.groupName') || 'Group Name'}</TableHead>
                          <TableHead>{t('modules.userManagement.groups.topicId') || 'Topic ID'}</TableHead>
                          <TableHead>{t('modules.userManagement.groups.members') || 'Members'}</TableHead>
                          <TableHead>{t('modules.userManagement.groups.status') || 'Status'}</TableHead>
                          <TableHead>{t('modules.userManagement.groups.created') || 'Created'}</TableHead>
                          <TableHead>{t('modules.userManagement.groups.isPlusUsers') || 'Is Plus Users'}</TableHead>
                          <TableHead className="w-[50px]">{t('common.actions') || 'Actions'}</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {groups.map((group) => (
                          <TableRow key={group.id}>
                            <TableCell>
                              <div>
                                <div className="font-medium">{getGroupName(group)}</div>
                                {getGroupDescription(group) && (
                                  <div className="text-sm text-muted-foreground">
                                    {getGroupDescription(group)}
                                  </div>
                                )}
                              </div>
                            </TableCell>
                            <TableCell>
                              <code className="px-2 py-1 bg-muted rounded text-sm">
                                {group.topicId}
                              </code>
                            </TableCell>
                            <TableCell>
                              <Badge variant="outline">
                                {group.memberCount} {t('modules.userManagement.groups.members') || 'members'}
                              </Badge>
                            </TableCell>
                            <TableCell>
                              <Badge variant={group.isActive ? "default" : "secondary"}>
                                {group.isActive 
                                  ? (t('common.active') || 'Active')
                                  : (t('common.inactive') || 'Inactive')
                                }
                              </Badge>
                            </TableCell>
                            <TableCell>
                              <div className="text-sm text-muted-foreground">
                                {formatDate(group.createdAt)}
                              </div>
                            </TableCell>
                            <TableCell>
                              <Badge variant={group.isForPlusUsers ? "default" : "secondary"}>
                                {group.isForPlusUsers ? (t('common.yes') || 'Yes') : (t('common.no') || 'No')}
                              </Badge>
                            </TableCell>
                            <TableCell>
                              <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                  <Button variant="ghost" size="sm">
                                    <MoreHorizontal className="h-4 w-4" />
                                  </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end">
                                  <DropdownMenuItem
                                    onClick={() => {
                                      setGroupToEdit(group);
                                      setEditDialogOpen(true);
                                    }}
                                  >
                                    <Edit className="h-4 w-4 mr-2" />
                                    {t('common.edit') || 'Edit'}
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={() => {
                                      setGroupToDelete(group);
                                      setDeleteDialogOpen(true);
                                    }}
                                    className="text-destructive"
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
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-destructive" />
              {t('modules.userManagement.groups.deleteGroup') || 'Delete Group'}
            </DialogTitle>
            <DialogDescription>
              {t('modules.userManagement.groups.deleteConfirmation') || 'Are you sure you want to delete this group? This action cannot be undone and will remove all user subscriptions to this group.'}
              {groupToDelete && (
                <div className="mt-2 p-3 bg-muted rounded">
                  <strong>{getGroupName(groupToDelete)}</strong>
                  <br />
                  <span className="text-sm text-muted-foreground">
                    {groupToDelete.memberCount} {t('modules.userManagement.groups.members') || 'members'} • Topic: {groupToDelete.topicId}
                  </span>
                </div>
              )}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button
              onClick={handleDeleteGroup}
              disabled={deleteLoading === groupToDelete?.id}
              variant="destructive"
            >
              {deleteLoading === groupToDelete?.id ? (
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent mr-2" />
              ) : (
                <Trash2 className="h-4 w-4 mr-2" />
              )}
              {t('common.delete') || 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Group Dialog */}
      {groupToEdit && (
        <EditGroupDialog
          open={editDialogOpen}
          onOpenChange={setEditDialogOpen}
          group={groupToEdit}
          onGroupUpdated={() => {
            setEditDialogOpen(false);
            setGroupToEdit(null);
          }}
        />
      )}
    </>
  );
} 