'use client';

import { useState, useEffect } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Plus, Edit, Trash2, Search, ChevronUp, ChevronDown } from 'lucide-react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { toast } from 'sonner';
import { cn } from '@/lib/utils';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, addDoc, updateDoc, deleteDoc, doc, query, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface PostCategory {
  id: string;
  name: string;
  nameAr: string;
  iconName: string;
  colorHex: string;
  isActive: boolean;
  isForAdminOnly?: boolean;
  sortOrder: number;
}

interface PostCategoryFormProps {
  category?: PostCategory;
  onSubmit: (category: Omit<PostCategory, 'id'>) => void;
  onCancel: () => void;
  isLoading?: boolean;
  isOpen: boolean;
}

function PostCategoryForm({ category, onSubmit, onCancel, isLoading, isOpen }: PostCategoryFormProps) {
  const { t } = useTranslation();
  const [formData, setFormData] = useState<Omit<PostCategory, 'id'>>({
    name: '',
    nameAr: '',
    iconName: '',
    colorHex: '#10B981',
    isActive: true,
    isForAdminOnly: false,
    sortOrder: 1,
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (category) {
      setFormData({
        name: category.name,
        nameAr: category.nameAr,
        iconName: category.iconName,
        colorHex: category.colorHex,
        isActive: category.isActive,
        isForAdminOnly: category.isForAdminOnly || false,
        sortOrder: category.sortOrder,
      });
    } else {
      setFormData({
        name: '',
        nameAr: '',
        iconName: '',
        colorHex: '#10B981',
        isActive: true,
        isForAdminOnly: false,
        sortOrder: 1,
      });
    }
    setErrors({});
  }, [category, isOpen]);

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = t('modules.community.postCategories.errors.nameRequired');
    }

    if (!formData.nameAr.trim()) {
      newErrors.nameAr = t('modules.community.postCategories.errors.nameArRequired');
    }

    if (!formData.iconName.trim()) {
      newErrors.iconName = t('modules.community.postCategories.errors.iconRequired');
    }

    if (!formData.colorHex.trim()) {
      newErrors.colorHex = t('modules.community.postCategories.errors.colorRequired');
    } else if (!/^#[0-9A-F]{6}$/i.test(formData.colorHex)) {
      newErrors.colorHex = t('modules.community.postCategories.errors.invalidColor');
    }

    if (!formData.sortOrder || formData.sortOrder < 1) {
      newErrors.sortOrder = t('modules.community.postCategories.errors.sortOrderInvalid');
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (validateForm()) {
      onSubmit(formData);
    }
  };

  const handleInputChange = (field: keyof typeof formData, value: string | boolean | number) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onCancel}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>
            {category ? t('modules.community.postCategories.edit') : t('modules.community.postCategories.create')}
          </DialogTitle>
          <DialogDescription>
            {category ? t('modules.community.postCategories.editDescription') : t('modules.community.postCategories.createDescription')}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="name">{t('modules.community.postCategories.nameEn')}</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => handleInputChange('name', e.target.value)}
                placeholder={t('modules.community.postCategories.nameEnPlaceholder')}
                className={errors.name ? 'border-red-500' : ''}
              />
              {errors.name && <p className="text-sm text-red-500">{errors.name}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="nameAr">{t('modules.community.postCategories.nameAr')}</Label>
              <Input
                id="nameAr"
                value={formData.nameAr}
                onChange={(e) => handleInputChange('nameAr', e.target.value)}
                placeholder={t('modules.community.postCategories.nameArPlaceholder')}
                className={errors.nameAr ? 'border-red-500' : ''}
              />
              {errors.nameAr && <p className="text-sm text-red-500">{errors.nameAr}</p>}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="iconName">{t('modules.community.postCategories.iconName')}</Label>
              <Input
                id="iconName"
                value={formData.iconName}
                onChange={(e) => handleInputChange('iconName', e.target.value)}
                placeholder={t('modules.community.postCategories.iconNamePlaceholder')}
                className={errors.iconName ? 'border-red-500' : ''}
              />
              <p className="text-sm text-muted-foreground">{t('modules.community.postCategories.iconNameHelp')}</p>
              {errors.iconName && <p className="text-sm text-red-500">{errors.iconName}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="colorHex">{t('modules.community.postCategories.colorHex')}</Label>
              <div className="flex gap-2">
                <Input
                  id="colorHex"
                  type="color"
                  value={formData.colorHex}
                  onChange={(e) => handleInputChange('colorHex', e.target.value)}
                  className="w-16 h-10 p-1"
                />
                <Input
                  value={formData.colorHex}
                  onChange={(e) => handleInputChange('colorHex', e.target.value)}
                  placeholder={t('modules.community.postCategories.colorHexPlaceholder')}
                  className={cn('flex-1', errors.colorHex ? 'border-red-500' : '')}
                />
              </div>
              <p className="text-sm text-muted-foreground">{t('modules.community.postCategories.colorHexHelp')}</p>
              {errors.colorHex && <p className="text-sm text-red-500">{errors.colorHex}</p>}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="sortOrder">{t('modules.community.postCategories.sortOrder')}</Label>
              <Input
                id="sortOrder"
                type="number"
                min="1"
                value={formData.sortOrder}
                onChange={(e) => handleInputChange('sortOrder', parseInt(e.target.value) || 1)}
                placeholder={t('modules.community.postCategories.sortOrderPlaceholder')}
                className={errors.sortOrder ? 'border-red-500' : ''}
              />
              <p className="text-sm text-muted-foreground">{t('modules.community.postCategories.sortOrderHelp')}</p>
              {errors.sortOrder && <p className="text-sm text-red-500">{errors.sortOrder}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="isActive">{t('modules.community.postCategories.isActive')}</Label>
              <div className="flex items-center space-x-2">
                <Switch
                  id="isActive"
                  checked={formData.isActive}
                  onCheckedChange={(checked) => handleInputChange('isActive', checked)}
                />
                <Label htmlFor="isActive" className="text-sm font-normal">
                  {formData.isActive ? t('common.active') : t('common.inactive')}
                </Label>
              </div>
              <p className="text-sm text-muted-foreground">{t('modules.community.postCategories.isActiveHelp')}</p>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4">
            <div className="space-y-2">
              <Label htmlFor="isForAdminOnly">{t('modules.community.postCategories.isForAdminOnly') || 'Admin Only'}</Label>
              <div className="flex items-center space-x-2">
                <Switch
                  id="isForAdminOnly"
                  checked={formData.isForAdminOnly || false}
                  onCheckedChange={(checked) => handleInputChange('isForAdminOnly', checked)}
                />
                <Label htmlFor="isForAdminOnly" className="text-sm font-normal">
                  {formData.isForAdminOnly ? (t('modules.community.postCategories.adminOnlyEnabled') || 'Admin Only') : (t('modules.community.postCategories.adminOnlyDisabled') || 'Available to All')}
                </Label>
              </div>
              <p className="text-sm text-muted-foreground">{t('modules.community.postCategories.isForAdminOnlyHelp') || 'When enabled, only admin users can create posts in this category'}</p>
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-4">
            <Button type="button" variant="outline" onClick={onCancel}>
              {t('common.cancel')}
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading ? t('common.creating') : category ? t('common.update') : t('common.create')}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function PostCategoriesManagement() {
  const { t } = useTranslation();
  
  // Firebase hooks
  const [snapshot, loading, error] = useCollection(
    query(collection(db, 'postCategories'), orderBy('sortOrder', 'asc'))
  );
  
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<PostCategory | undefined>(undefined);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [categoryToDelete, setCategoryToDelete] = useState<PostCategory | undefined>(undefined);
  const [isLoading, setIsLoading] = useState(false);
  
  // Convert Firestore documents to PostCategory objects
  const categories: PostCategory[] = snapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  } as PostCategory)) || [];

  const filteredCategories = categories.filter(category =>
    category.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    category.nameAr.includes(searchTerm)
  );

  const sortedCategories = [...filteredCategories].sort((a, b) => a.sortOrder - b.sortOrder);

  const handleCreate = () => {
    setSelectedCategory(undefined);
    setIsFormOpen(true);
  };

  const handleEdit = (category: PostCategory) => {
    setSelectedCategory(category);
    setIsFormOpen(true);
  };

  const handleDelete = (category: PostCategory) => {
    setCategoryToDelete(category);
    setIsDeleteDialogOpen(true);
  };

  const handleFormSubmit = async (formData: Omit<PostCategory, 'id'>) => {
    setIsLoading(true);
    try {
      if (selectedCategory) {
        // Update existing category
        await updateDoc(doc(db, 'postCategories', selectedCategory.id), formData);
        toast.success(t('modules.community.postCategories.updateSuccess'));
      } else {
        // Create new category
        await addDoc(collection(db, 'postCategories'), formData);
        toast.success(t('modules.community.postCategories.createSuccess'));
      }

      setIsFormOpen(false);
      setSelectedCategory(undefined);
    } catch (error) {
      console.error('Error saving category:', error);
      toast.error(
        selectedCategory
          ? t('modules.community.postCategories.updateError')
          : t('modules.community.postCategories.createError')
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleDeleteConfirm = async () => {
    if (!categoryToDelete) return;

    setIsLoading(true);
    try {
      await deleteDoc(doc(db, 'postCategories', categoryToDelete.id));
      toast.success(t('modules.community.postCategories.deleteSuccess'));
      setIsDeleteDialogOpen(false);
      setCategoryToDelete(undefined);
    } catch (error) {
      console.error('Error deleting category:', error);
      toast.error(t('modules.community.postCategories.deleteError'));
    } finally {
      setIsLoading(false);
    }
  };

  const handleStatusToggle = async (category: PostCategory) => {
    try {
      await updateDoc(doc(db, 'postCategories', category.id), {
        isActive: !category.isActive
      });
      toast.success(t('modules.community.postCategories.statusUpdateSuccess'));
    } catch (error) {
      console.error('Error toggling status:', error);
      toast.error(t('modules.community.postCategories.statusUpdateError'));
    }
  };

  const handleAdminOnlyToggle = async (category: PostCategory) => {
    try {
      await updateDoc(doc(db, 'postCategories', category.id), {
        isForAdminOnly: !category.isForAdminOnly
      });
      toast.success(t('modules.community.postCategories.statusUpdateSuccess'));
    } catch (error) {
      console.error('Error toggling admin-only status:', error);
      toast.error(t('modules.community.postCategories.statusUpdateError'));
    }
  };

  const moveCategoryUp = async (category: PostCategory) => {
    const sortedCategories = [...categories].sort((a, b) => a.sortOrder - b.sortOrder);
    const currentIndex = sortedCategories.findIndex(cat => cat.id === category.id);
    
    if (currentIndex > 0) {
      const previousCategory = sortedCategories[currentIndex - 1];
      
      try {
        // Swap sort orders
        await Promise.all([
          updateDoc(doc(db, 'postCategories', category.id), {
            sortOrder: previousCategory.sortOrder
          }),
          updateDoc(doc(db, 'postCategories', previousCategory.id), {
            sortOrder: category.sortOrder
          })
        ]);
      } catch (error) {
        console.error('Error moving category up:', error);
        toast.error('Failed to reorder category');
      }
    }
  };

  const moveCategoryDown = async (category: PostCategory) => {
    const sortedCategories = [...categories].sort((a, b) => a.sortOrder - b.sortOrder);
    const currentIndex = sortedCategories.findIndex(cat => cat.id === category.id);
    
    if (currentIndex < sortedCategories.length - 1) {
      const nextCategory = sortedCategories[currentIndex + 1];
      
      try {
        // Swap sort orders
        await Promise.all([
          updateDoc(doc(db, 'postCategories', category.id), {
            sortOrder: nextCategory.sortOrder
          }),
          updateDoc(doc(db, 'postCategories', nextCategory.id), {
            sortOrder: category.sortOrder
          })
        ]);
      } catch (error) {
        console.error('Error moving category down:', error);
        toast.error('Failed to reorder category');
      }
    }
  };

  const activeCategories = categories.filter(cat => cat.isActive);
  const inactiveCategories = categories.filter(cat => !cat.isActive);

  // Handle loading and error states
  if (loading) {
    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">{t('modules.community.postCategories.title')}</h2>
          <p className="text-muted-foreground">{t('modules.community.postCategories.description')}</p>
        </div>
        <Card>
          <CardContent className="py-8 text-center">
            <p className="text-muted-foreground">{t('common.loading')}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-6">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">{t('modules.community.postCategories.title')}</h2>
          <p className="text-muted-foreground">{t('modules.community.postCategories.description')}</p>
        </div>
        <Card>
          <CardContent className="py-8 text-center">
            <p className="text-red-500">{t('common.error')}: {error.message}</p>
            <Button 
              onClick={() => window.location.reload()} 
              variant="outline" 
              className="mt-4"
            >
              {t('common.retry')}
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-bold tracking-tight">{t('modules.community.postCategories.title')}</h2>
        <p className="text-muted-foreground">{t('modules.community.postCategories.description')}</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.postCategories.totalCategories')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{categories.length}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.postCategories.activeCategories')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeCategories.length}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.postCategories.inactiveCategories')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{inactiveCategories.length}</div>
          </CardContent>
        </Card>
      </div>

      {/* Controls */}
      <div className="flex flex-col sm:flex-row gap-4 justify-between">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder={t('modules.community.postCategories.searchPlaceholder')}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <Button onClick={handleCreate}>
          <Plus className="h-4 w-4 mr-2" />
          {t('modules.community.postCategories.create')}
        </Button>
      </div>

      {/* Categories Table */}
      <Card>
        <CardContent className="p-0">
          {sortedCategories.length === 0 ? (
            <div className="py-8 text-center">
              <p className="text-muted-foreground">{t('modules.community.postCategories.noCategoriesFound')}</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12"></TableHead>
                  <TableHead>{t('modules.community.postCategories.name')}</TableHead>
                  <TableHead>{t('modules.community.postCategories.nameAr')}</TableHead>
                  <TableHead>{t('modules.community.postCategories.iconName')}</TableHead>
                  <TableHead className="w-20">{t('modules.community.postCategories.sortOrder')}</TableHead>
                  <TableHead className="w-20 text-center">{t('modules.community.postCategories.isActive')}</TableHead>
                  <TableHead className="w-24 text-center">{t('modules.community.postCategories.isForAdminOnly') || 'Admin Only'}</TableHead>
                  <TableHead className="w-32 text-center">{t('common.actions') || 'Actions'}</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {sortedCategories.map((category) => (
                  <TableRow key={category.id}>
                    <TableCell>
                      <div
                        className="w-4 h-4 rounded-full"
                        style={{ backgroundColor: category.colorHex }}
                      />
                    </TableCell>
                    <TableCell className="font-medium">{category.name}</TableCell>
                    <TableCell>{category.nameAr}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">{category.iconName}</TableCell>
                    <TableCell className="text-center">{category.sortOrder}</TableCell>
                    <TableCell className="text-center">
                      <Switch
                        checked={category.isActive}
                        onCheckedChange={() => handleStatusToggle(category)}
                        
                      />
                    </TableCell>
                    <TableCell className="text-center">
                      <Switch
                        checked={category.isForAdminOnly || false}
                        onCheckedChange={() => handleAdminOnlyToggle(category)}
                        
                      />
                    </TableCell>
                    <TableCell className="text-center">
                      <div className="flex items-center justify-center gap-1">
                        <Button
                          variant="ghost"
                          
                          onClick={() => moveCategoryUp(category)}
                          disabled={sortedCategories.findIndex(cat => cat.id === category.id) === 0}
                        >
                          <ChevronUp className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          
                          onClick={() => moveCategoryDown(category)}
                          disabled={sortedCategories.findIndex(cat => cat.id === category.id) === sortedCategories.length - 1}
                        >
                          <ChevronDown className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          
                          onClick={() => handleEdit(category)}
                        >
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          
                          onClick={() => handleDelete(category)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Form Dialog */}
      <PostCategoryForm
        category={selectedCategory}
        onSubmit={handleFormSubmit}
        onCancel={() => {
          setIsFormOpen(false);
          setSelectedCategory(undefined);
        }}
        isLoading={isLoading}
        isOpen={isFormOpen}
      />

      {/* Delete Confirmation Dialog */}
      <Dialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{t('modules.community.postCategories.deleteTitle')}</DialogTitle>
            <DialogDescription>
              {t('modules.community.postCategories.deleteDescription')}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDeleteDialogOpen(false)}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleDeleteConfirm} disabled={isLoading}>
              {isLoading ? t('common.loading') : t('common.delete')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
} 