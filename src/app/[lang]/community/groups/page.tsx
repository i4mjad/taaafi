'use client';

import { useState, useMemo } from 'react';
import { useTranslation } from "@/contexts/TranslationContext";
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, addDoc, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Search, Users, Plus, Eye, Edit, Trash2, MoreHorizontal, UserPlus } from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { format } from 'date-fns';
import { Group } from '@/types/community';
import { toast } from 'sonner';

export default function GroupsPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [genderFilter, setGenderFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedGroup, setSelectedGroup] = useState<Group | null>(null);
  const [showDetails, setShowDetails] = useState(false);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [editingGroup, setEditingGroup] = useState<Group | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form state for create/edit
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    capacity: 50,
    gender: 'mixed' as 'male' | 'female' | 'mixed' | 'other',
    isActive: true,
  });

  // Fetch groups
  const [value, loading, error] = useCollection(
    query(collection(db, 'groups'), orderBy('createdAt', 'desc'))
  );

  const groups = useMemo(() => {
    if (!value) return [];
    
    return value.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as Group[];
  }, [value]);

  // Apply filters
  const filteredGroups = useMemo(() => {
    return groups.filter(group => {
      const matchesSearch = !search || 
        group.name.toLowerCase().includes(search.toLowerCase()) ||
        group.description.toLowerCase().includes(search.toLowerCase());
      
      const matchesGender = genderFilter === 'all' || group.gender === genderFilter;
      const matchesStatus = statusFilter === 'all' || 
        (statusFilter === 'active' && group.isActive) ||
        (statusFilter === 'inactive' && !group.isActive);
      
      return matchesSearch && matchesGender && matchesStatus;
    });
  }, [groups, search, genderFilter, statusFilter]);

  // Calculate stats
  const stats = useMemo(() => {
    const total = groups.length;
    const active = groups.filter(g => g.isActive).length;
    const full = groups.filter(g => g.memberCount >= g.capacity).length;
    const totalMembers = groups.reduce((sum, g) => sum + g.memberCount, 0);

    return { total, active, full, totalMembers };
  }, [groups]);

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      capacity: 50,
      gender: 'mixed',
      isActive: true,
    });
  };

  const handleCreateGroup = async () => {
    if (!formData.name.trim() || !formData.description.trim()) {
      toast.error(t('modules.community.supportGroups.errors.nameRequired'));
      return;
    }

    setIsSubmitting(true);
    try {
      await addDoc(collection(db, 'groups'), {
        ...formData,
        memberCount: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      
      toast.success(t('modules.community.supportGroups.createSuccess'));
      setShowCreateDialog(false);
      resetForm();
    } catch (error) {
      console.error('Error creating group:', error);
      toast.error(t('modules.community.supportGroups.createError'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEditGroup = async () => {
    if (!editingGroup || !formData.name.trim() || !formData.description.trim()) {
      toast.error(t('modules.community.supportGroups.errors.nameRequired'));
      return;
    }

    setIsSubmitting(true);
    try {
      await updateDoc(doc(db, 'groups', editingGroup.id), {
        ...formData,
        updatedAt: new Date(),
      });
      
      toast.success(t('modules.community.supportGroups.updateSuccess'));
      setShowEditDialog(false);
      setEditingGroup(null);
      resetForm();
    } catch (error) {
      console.error('Error updating group:', error);
      toast.error(t('modules.community.supportGroups.updateError'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteGroup = async (group: Group) => {
    if (!confirm(t('modules.community.supportGroups.deleteDescription'))) {
      return;
    }

    try {
      await deleteDoc(doc(db, 'groups', group.id));
      toast.success(t('modules.community.supportGroups.deleteSuccess'));
    } catch (error) {
      console.error('Error deleting group:', error);
      toast.error(t('modules.community.supportGroups.deleteError'));
    }
  };

  const openEditDialog = (group: Group) => {
    setEditingGroup(group);
    setFormData({
      name: group.name,
      description: group.description,
      capacity: group.capacity,
      gender: group.gender,
      isActive: group.isActive ?? true,
    });
    setShowEditDialog(true);
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <Card key={i}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  <div className="h-4 bg-muted rounded animate-pulse" />
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-8 bg-muted rounded animate-pulse mb-2" />
                <div className="h-3 bg-muted rounded animate-pulse" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <p className="text-destructive">{t('common.error')}</p>
        <Button 
          onClick={() => window.location.reload()} 
          variant="outline" 
          className="mt-4"
        >
          {t('common.retry')}
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{t('appSidebar.groups')}</h1>
          <p className="text-muted-foreground">
            {t('modules.community.supportGroups.description')}
          </p>
        </div>
        <Button onClick={() => setShowCreateDialog(true)}>
          <Plus className="h-4 w-4 mr-2" />
          {t('modules.community.supportGroups.createGroup')}
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.supportGroups.totalGroups')}
            </CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
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
              {t('modules.community.supportGroups.activeGroups')}
            </CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.active}</div>
            <p className="text-xs text-muted-foreground">
              {stats.total > 0 
                ? `${Math.round((stats.active / stats.total) * 100)}% ${t('modules.features.ofTotal')}`
                : '0%'
              }
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.supportGroups.fullGroups')}
            </CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.full}</div>
            <p className="text-xs text-muted-foreground">
              At capacity
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Total Members
            </CardTitle>
            <UserPlus className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalMembers}</div>
            <p className="text-xs text-muted-foreground">
              Across all groups
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">{t('modules.content.items.filters')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">{t('common.search')}</label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder={t('modules.community.supportGroups.searchPlaceholder')}
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">{t('modules.community.supportGroups.filterByGender')}</label>
              <Select value={genderFilter} onValueChange={setGenderFilter}>
                <SelectTrigger>
                  <SelectValue placeholder={t('modules.community.supportGroups.selectGender')} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('common.all')}</SelectItem>
                  <SelectItem value="male">{t('modules.community.supportGroups.male')}</SelectItem>
                  <SelectItem value="female">{t('modules.community.supportGroups.female')}</SelectItem>
                  <SelectItem value="mixed">{t('modules.community.supportGroups.mixed')}</SelectItem>
                  <SelectItem value="other">{t('modules.community.supportGroups.other')}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">{t('modules.community.supportGroups.filterByStatus')}</label>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger>
                  <SelectValue placeholder="Filter by status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('common.all')}</SelectItem>
                  <SelectItem value="active">Active</SelectItem>
                  <SelectItem value="inactive">Inactive</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Groups List */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.supportGroups.list')}</CardTitle>
          <CardDescription>
            {t('modules.community.supportGroups.listDescription')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {filteredGroups.length === 0 ? (
            <div className="text-center py-8">
              <Users className="mx-auto h-12 w-12 text-muted-foreground/50" />
              <h3 className="mt-4 text-lg font-semibold">{t('modules.community.supportGroups.noGroupsFound')}</h3>
              <p className="text-muted-foreground">
                {groups.length === 0 
                  ? 'Create your first group to get started'
                  : 'Try adjusting your search or filter criteria'
                }
              </p>
              {groups.length === 0 && (
                <Button 
                  onClick={() => setShowCreateDialog(true)} 
                  className="mt-4"
                >
                  {t('modules.community.supportGroups.createGroup')}
                </Button>
              )}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full border-collapse">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-4 font-medium">{t('modules.community.supportGroups.name')}</th>
                    <th className="text-left py-3 px-4 font-medium">{t('modules.community.supportGroups.memberCount')}</th>
                    <th className="text-left py-3 px-4 font-medium">{t('modules.community.supportGroups.gender')}</th>
                    <th className="text-left py-3 px-4 font-medium">{t('common.status')}</th>
                    <th className="text-left py-3 px-4 font-medium">{t('modules.community.supportGroups.createdAt')}</th>
                    <th className="text-left py-3 px-4 font-medium">{t('common.actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredGroups.map((group) => (
                    <tr key={group.id} className="border-b hover:bg-muted/50">
                      <td className="py-3 px-4">
                        <div>
                          <div className="font-medium">{group.name}</div>
                          <div className="text-sm text-muted-foreground line-clamp-1">
                            {group.description}
                          </div>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center space-x-2">
                          <span>{group.memberCount} / {group.capacity}</span>
                          {group.memberCount >= group.capacity && (
                            <Badge variant="destructive">Full</Badge>
                          )}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <Badge variant="outline">
                          {group.gender === 'male' && t('modules.community.supportGroups.male')}
                          {group.gender === 'female' && t('modules.community.supportGroups.female')}
                          {group.gender === 'mixed' && t('modules.community.supportGroups.mixed')}
                          {group.gender === 'other' && t('modules.community.supportGroups.other')}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        <Badge variant={group.isActive ? 'default' : 'secondary'}>
                          {group.isActive ? 'Active' : 'Inactive'}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        <div className="text-sm">
                          {format(group.createdAt, 'MMM dd, yyyy')}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="h-8 w-8 p-0">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => {
                              setSelectedGroup(group);
                              setShowDetails(true);
                            }}>
                              <Eye className="mr-2 h-4 w-4" />
                              {t('modules.community.supportGroups.viewGroup')}
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => openEditDialog(group)}>
                              <Edit className="mr-2 h-4 w-4" />
                              {t('modules.community.supportGroups.editGroup')}
                            </DropdownMenuItem>
                            <DropdownMenuItem 
                              onClick={() => handleDeleteGroup(group)}
                              className="text-destructive"
                            >
                              <Trash2 className="mr-2 h-4 w-4" />
                              {t('modules.community.supportGroups.deleteGroup')}
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Create Group Dialog */}
      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.supportGroups.createGroup')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.supportGroups.createDescription')}
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">{t('modules.community.supportGroups.name')}</Label>
              <Input
                id="name"
                placeholder={t('modules.community.supportGroups.namePlaceholder')}
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">{t('modules.community.supportGroups.description')}</Label>
              <Textarea
                id="description"
                placeholder={t('modules.community.supportGroups.descriptionPlaceholder')}
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="capacity">{t('modules.community.supportGroups.capacity')}</Label>
                <Input
                  id="capacity"
                  type="number"
                  min="1"
                  max="1000"
                  placeholder={t('modules.community.supportGroups.capacityPlaceholder')}
                  value={formData.capacity}
                  onChange={(e) => setFormData({ ...formData, capacity: parseInt(e.target.value) || 50 })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="gender">{t('modules.community.supportGroups.gender')}</Label>
                <Select 
                  value={formData.gender} 
                  onValueChange={(value: 'male' | 'female' | 'mixed' | 'other') => 
                    setFormData({ ...formData, gender: value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue placeholder={t('modules.community.supportGroups.selectGender')} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="male">{t('modules.community.supportGroups.male')}</SelectItem>
                    <SelectItem value="female">{t('modules.community.supportGroups.female')}</SelectItem>
                    <SelectItem value="mixed">{t('modules.community.supportGroups.mixed')}</SelectItem>
                    <SelectItem value="other">{t('modules.community.supportGroups.other')}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="flex items-center space-x-2">
              <Switch
                id="isActive"
                checked={formData.isActive}
                onCheckedChange={(checked) => setFormData({ ...formData, isActive: checked })}
              />
              <Label htmlFor="isActive">{t('modules.community.supportGroups.isActive')}</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowCreateDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleCreateGroup} disabled={isSubmitting}>
              {isSubmitting ? t('common.creating') : t('common.create')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Edit Group Dialog */}
      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.supportGroups.editGroup')}</DialogTitle>
            <DialogDescription>
              Update group information and settings
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="edit-name">{t('modules.community.supportGroups.name')}</Label>
              <Input
                id="edit-name"
                placeholder={t('modules.community.supportGroups.namePlaceholder')}
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="edit-description">{t('modules.community.supportGroups.description')}</Label>
              <Textarea
                id="edit-description"
                placeholder={t('modules.community.supportGroups.descriptionPlaceholder')}
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="edit-capacity">{t('modules.community.supportGroups.capacity')}</Label>
                <Input
                  id="edit-capacity"
                  type="number"
                  min="1"
                  max="1000"
                  placeholder={t('modules.community.supportGroups.capacityPlaceholder')}
                  value={formData.capacity}
                  onChange={(e) => setFormData({ ...formData, capacity: parseInt(e.target.value) || 50 })}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="edit-gender">{t('modules.community.supportGroups.gender')}</Label>
                <Select 
                  value={formData.gender} 
                  onValueChange={(value: 'male' | 'female' | 'mixed' | 'other') => 
                    setFormData({ ...formData, gender: value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue placeholder={t('modules.community.supportGroups.selectGender')} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="male">{t('modules.community.supportGroups.male')}</SelectItem>
                    <SelectItem value="female">{t('modules.community.supportGroups.female')}</SelectItem>
                    <SelectItem value="mixed">{t('modules.community.supportGroups.mixed')}</SelectItem>
                    <SelectItem value="other">{t('modules.community.supportGroups.other')}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="flex items-center space-x-2">
              <Switch
                id="edit-isActive"
                checked={formData.isActive}
                onCheckedChange={(checked) => setFormData({ ...formData, isActive: checked })}
              />
              <Label htmlFor="edit-isActive">{t('modules.community.supportGroups.isActive')}</Label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowEditDialog(false)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleEditGroup} disabled={isSubmitting}>
              {isSubmitting ? t('common.updating') : t('common.update')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Group Details Dialog */}
      <Dialog open={showDetails} onOpenChange={setShowDetails}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{t('modules.community.supportGroups.groupDetails')}</DialogTitle>
            <DialogDescription>
              Detailed information about the selected group
            </DialogDescription>
          </DialogHeader>
          
          {selectedGroup && (
            <div className="space-y-6">
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-semibold">{selectedGroup.name}</h3>
                  <p className="text-muted-foreground mt-1">{selectedGroup.description}</p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium">{t('modules.community.supportGroups.memberCount')}</label>
                    <p className="text-sm">
                      {selectedGroup.memberCount} / {selectedGroup.capacity} members
                      {selectedGroup.memberCount >= selectedGroup.capacity && (
                        <Badge variant="destructive" className="ml-2">Full</Badge>
                      )}
                    </p>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">{t('modules.community.supportGroups.gender')}</label>
                    <p className="text-sm">
                      {selectedGroup.gender === 'male' && t('modules.community.supportGroups.male')}
                      {selectedGroup.gender === 'female' && t('modules.community.supportGroups.female')}
                      {selectedGroup.gender === 'mixed' && t('modules.community.supportGroups.mixed')}
                      {selectedGroup.gender === 'other' && t('modules.community.supportGroups.other')}
                    </p>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">{t('common.status')}</label>
                    <p className="text-sm">
                      <Badge variant={selectedGroup.isActive ? 'default' : 'secondary'}>
                        {selectedGroup.isActive ? 'Active' : 'Inactive'}
                      </Badge>
                    </p>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium">{t('modules.community.supportGroups.createdAt')}</label>
                    <p className="text-sm">
                      {format(selectedGroup.createdAt, 'MMMM dd, yyyy HH:mm')}
                    </p>
                  </div>

                  {selectedGroup.updatedAt && (
                    <div className="space-y-2">
                      <label className="text-sm font-medium">{t('modules.community.supportGroups.updatedAt')}</label>
                      <p className="text-sm">
                        {format(selectedGroup.updatedAt, 'MMMM dd, yyyy HH:mm')}
                      </p>
                    </div>
                  )}
                </div>
              </div>

              <div className="flex space-x-2">
                <Button 
                  variant="outline" 
                  onClick={() => openEditDialog(selectedGroup)}
                >
                  <Edit className="h-4 w-4 mr-2" />
                  {t('modules.community.supportGroups.editGroup')}
                </Button>
                <Button 
                  variant="outline" 
                  onClick={() => {
                    toast.info('Member management coming soon');
                  }}
                >
                  <UserPlus className="h-4 w-4 mr-2" />
                  {t('modules.community.supportGroups.groupMembers')}
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
} 