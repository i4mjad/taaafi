'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
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
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Plus,
  Search,
  MoreHorizontal,
  Edit,
  Trash2,
  Shield,
  Settings,
  MessageSquare,
  Video,
  Users,
  FileText,
  Camera,
  Share,
  Heart,
  Loader2
} from 'lucide-react';
import { useTranslation } from '@/contexts/TranslationContext';
import { SiteHeader } from '@/components/site-header';
import { useCollection, useCollectionData } from 'react-firebase-hooks/firestore';
import { collection, addDoc, updateDoc, deleteDoc, doc, query, orderBy, where, serverTimestamp, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { toast } from 'sonner';

interface AppFeature {
  id?: string;
  uniqueName: string;
  nameEn: string;
  nameAr: string;
  descriptionEn: string;
  descriptionAr: string;
  category: 'core' | 'social' | 'content' | 'communication' | 'settings';
  iconName: string;
  isActive: boolean;
  isBannable: boolean;
  createdAt: Timestamp | Date;
  updatedAt: Timestamp | Date;
}

// Utility functions
const generateUniqueName = (nameEn: string): string => {
  return nameEn
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s]/g, '') // Remove special characters
    .replace(/\s+/g, '_') // Replace spaces with underscores
    .replace(/_{2,}/g, '_'); // Replace multiple underscores with single
};

const convertTimestamp = (timestamp: Timestamp | Date): Date => {
  if (timestamp instanceof Timestamp) {
    return timestamp.toDate();
  }
  return timestamp;
};

export default function AppFeaturesPage() {
  const { t, locale } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [editingFeature, setEditingFeature] = useState<AppFeature | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Firestore hooks
  const featuresCollection = collection(db, 'features');
  const featuresQuery = query(featuresCollection, orderBy('createdAt', 'desc'));
  const [featuresSnapshot, featuresLoading, featuresError] = useCollection(featuresQuery);

  // Convert Firestore data to AppFeature array
  const features: AppFeature[] = featuresSnapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  } as AppFeature)) || [];

  const [formData, setFormData] = useState({
    nameEn: '',
    nameAr: '',
    descriptionEn: '',
    descriptionAr: '',
    category: 'core' as AppFeature['category'],
    iconName: '',
    isActive: true,
    isBannable: true,
  });

  const stats = {
    total: features.length,
    active: features.filter(f => f.isActive).length,
    bannable: features.filter(f => f.isBannable).length,
    categories: {
      core: features.filter(f => f.category === 'core').length,
      social: features.filter(f => f.category === 'social').length,
      content: features.filter(f => f.category === 'content').length,
      communication: features.filter(f => f.category === 'communication').length,
      settings: features.filter(f => f.category === 'settings').length,
    }
  };

  const headerDictionary = {
    documents: t('modules.features.appFeatures.title') || 'App Features',
  };

  const resetForm = () => {
    setFormData({
      nameEn: '',
      nameAr: '',
      descriptionEn: '',
      descriptionAr: '',
      category: 'core',
      iconName: '',
      isActive: true,
      isBannable: true,
    });
  };

  const handleCreate = async () => {
    if (!formData.nameEn.trim()) {
      toast.error(t('modules.features.appFeatures.errors.nameRequired'));
      return;
    }

    setIsSubmitting(true);
    try {
      const uniqueName = generateUniqueName(formData.nameEn);
      
      // Check if uniqueName already exists
      const existingQuery = query(featuresCollection, where('uniqueName', '==', uniqueName));
      const existingSnapshot = await import('firebase/firestore').then(({ getDocs }) => getDocs(existingQuery));
      
      if (!existingSnapshot.empty) {
        toast.error(t('modules.features.appFeatures.errors.uniqueNameExists') || 'A feature with this name already exists');
        setIsSubmitting(false);
        return;
      }

      const newFeature = {
        uniqueName,
        nameEn: formData.nameEn.trim(),
        nameAr: formData.nameAr.trim(),
        descriptionEn: formData.descriptionEn.trim(),
        descriptionAr: formData.descriptionAr.trim(),
        category: formData.category,
        iconName: formData.iconName.trim(),
        isActive: formData.isActive,
        isBannable: formData.isBannable,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };

      await addDoc(featuresCollection, newFeature);
      toast.success(t('modules.features.appFeatures.createSuccess'));
      setIsCreateDialogOpen(false);
      resetForm();
    } catch (error) {
      console.error('Error creating feature:', error);
      toast.error(t('modules.features.appFeatures.createError'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEdit = (feature: AppFeature) => {
    setFormData({
      nameEn: feature.nameEn,
      nameAr: feature.nameAr,
      descriptionEn: feature.descriptionEn,
      descriptionAr: feature.descriptionAr,
      category: feature.category,
      iconName: feature.iconName,
      isActive: feature.isActive,
      isBannable: feature.isBannable,
    });
    setEditingFeature(feature);
  };

  const handleUpdate = async () => {
    if (!editingFeature?.id || !formData.nameEn.trim()) {
      toast.error(t('modules.features.appFeatures.errors.nameRequired'));
      return;
    }

    setIsSubmitting(true);
    try {
      const newUniqueName = generateUniqueName(formData.nameEn);
      
      // Only check for uniqueName conflicts if it changed
      if (newUniqueName !== editingFeature.uniqueName) {
        const existingQuery = query(featuresCollection, where('uniqueName', '==', newUniqueName));
        const existingSnapshot = await import('firebase/firestore').then(({ getDocs }) => getDocs(existingQuery));
        
        if (!existingSnapshot.empty) {
          toast.error(t('modules.features.appFeatures.errors.uniqueNameExists') || 'A feature with this name already exists');
          setIsSubmitting(false);
          return;
        }
      }

      const featureRef = doc(db, 'features', editingFeature.id);
      const updatedData = {
        uniqueName: newUniqueName,
        nameEn: formData.nameEn.trim(),
        nameAr: formData.nameAr.trim(),
        descriptionEn: formData.descriptionEn.trim(),
        descriptionAr: formData.descriptionAr.trim(),
        category: formData.category,
        iconName: formData.iconName.trim(),
        isActive: formData.isActive,
        isBannable: formData.isBannable,
        updatedAt: serverTimestamp(),
      };

      await updateDoc(featureRef, updatedData);
      toast.success(t('modules.features.appFeatures.updateSuccess'));
      setEditingFeature(null);
      resetForm();
    } catch (error) {
      console.error('Error updating feature:', error);
      toast.error(t('modules.features.appFeatures.updateError'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (feature: AppFeature) => {
    if (!feature.id) return;
    
    try {
      const featureRef = doc(db, 'features', feature.id);
      await deleteDoc(featureRef);
      toast.success(t('modules.features.appFeatures.deleteSuccess'));
    } catch (error) {
      console.error('Error deleting feature:', error);
      toast.error(t('modules.features.appFeatures.deleteError'));
    }
  };

  const toggleFeatureStatus = async (feature: AppFeature) => {
    if (!feature.id) return;
    
    try {
      const featureRef = doc(db, 'features', feature.id);
      await updateDoc(featureRef, {
        isActive: !feature.isActive,
        updatedAt: serverTimestamp(),
      });
      toast.success(t('modules.features.appFeatures.statusUpdateSuccess'));
    } catch (error) {
      console.error('Error updating feature status:', error);
      toast.error(t('modules.features.appFeatures.statusUpdateError'));
    }
  };

  const getCategoryBadge = (category: string) => {
    const variants = {
      core: 'default',
      social: 'secondary',
      content: 'outline',
      communication: 'destructive',
      settings: 'secondary',
    } as const;

    return (
      <Badge variant={variants[category as keyof typeof variants] || 'outline'}>
        {t(`modules.features.appFeatures.category.${category}`) || category}
      </Badge>
    );
  };

  const filteredFeatures = features.filter(feature =>
    feature.nameEn.toLowerCase().includes(searchQuery.toLowerCase()) ||
    feature.nameAr.includes(searchQuery) ||
    feature.descriptionEn.toLowerCase().includes(searchQuery.toLowerCase()) ||
    feature.descriptionAr.includes(searchQuery)
  );

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex flex-1 flex-col">
        <div className="@container/main flex flex-1 flex-col gap-2">
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
            {/* Header */}
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-3xl font-bold tracking-tight">
                  {t('modules.features.appFeatures.title')}
                </h1>
                <p className="text-muted-foreground">
                  {t('modules.features.appFeatures.description')}
                </p>
              </div>
              <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
                <DialogTrigger asChild>
                  <Button onClick={resetForm} disabled={featuresLoading}>
                    {featuresLoading ? (
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    ) : (
                      <Plus className="h-4 w-4 mr-2" />
                    )}
                    {t('modules.features.appFeatures.create')}
                  </Button>
                </DialogTrigger>
                <DialogContent className="max-w-2xl">
                  <DialogHeader>
                    <DialogTitle>{t('modules.features.appFeatures.create')}</DialogTitle>
                    <DialogDescription>
                      {t('modules.features.appFeatures.createDescription')}
                    </DialogDescription>
                  </DialogHeader>
                  <div className="grid gap-4 py-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor="nameEn">{t('modules.features.appFeatures.nameEn')}</Label>
                        <Input
                          id="nameEn"
                          value={formData.nameEn}
                          onChange={(e) => setFormData({ ...formData, nameEn: e.target.value })}
                          placeholder={t('modules.features.appFeatures.nameEnPlaceholder')}
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="nameAr">{t('modules.features.appFeatures.nameAr')}</Label>
                        <Input
                          id="nameAr"
                          value={formData.nameAr}
                          onChange={(e) => setFormData({ ...formData, nameAr: e.target.value })}
                          placeholder={t('modules.features.appFeatures.nameArPlaceholder')}
                        />
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor="descriptionEn">{t('modules.features.appFeatures.descriptionEn')}</Label>
                        <Textarea
                          id="descriptionEn"
                          value={formData.descriptionEn}
                          onChange={(e) => setFormData({ ...formData, descriptionEn: e.target.value })}
                          placeholder={t('modules.features.appFeatures.descriptionEnPlaceholder')}
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="descriptionAr">{t('modules.features.appFeatures.descriptionAr')}</Label>
                        <Textarea
                          id="descriptionAr"
                          value={formData.descriptionAr}
                          onChange={(e) => setFormData({ ...formData, descriptionAr: e.target.value })}
                          placeholder={t('modules.features.appFeatures.descriptionArPlaceholder')}
                        />
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label htmlFor="category">{t('modules.features.appFeatures.category.label')}</Label>
                        <select
                          id="category"
                          value={formData.category}
                          onChange={(e) => setFormData({ ...formData, category: e.target.value as AppFeature['category'] })}
                          className="w-full px-3 py-2 border border-input bg-background rounded-md"
                        >
                          <option value="core">{t('modules.features.appFeatures.category.core')}</option>
                          <option value="social">{t('modules.features.appFeatures.category.social')}</option>
                          <option value="content">{t('modules.features.appFeatures.category.content')}</option>
                          <option value="communication">{t('modules.features.appFeatures.category.communication')}</option>
                          <option value="settings">{t('modules.features.appFeatures.category.settings')}</option>
                        </select>
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="iconName">{t('modules.features.appFeatures.iconName')}</Label>
                        <Input
                          id="iconName"
                          value={formData.iconName}
                          onChange={(e) => setFormData({ ...formData, iconName: e.target.value })}
                          placeholder={t('modules.features.appFeatures.iconNamePlaceholder')}
                        />
                      </div>
                    </div>
                    <div className="flex items-center space-x-4">
                      <div className="flex items-center space-x-2">
                        <Switch
                          checked={formData.isActive}
                          onCheckedChange={(checked) => setFormData({ ...formData, isActive: checked })}
                        />
                        <Label>{t('modules.features.appFeatures.isActive')}</Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Switch
                          checked={formData.isBannable}
                          onCheckedChange={(checked) => setFormData({ ...formData, isBannable: checked })}
                        />
                        <Label>{t('modules.features.appFeatures.isBannable')}</Label>
                      </div>
                    </div>
                  </div>
                  <DialogFooter>
                    <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)} disabled={isSubmitting}>
                      {t('common.cancel')}
                    </Button>
                    <Button onClick={handleCreate} disabled={isSubmitting}>
                      {isSubmitting ? (
                        <>
                          <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                          {t('common.creating')}
                        </>
                      ) : (
                        t('common.create')
                      )}
                    </Button>
                  </DialogFooter>
                </DialogContent>
              </Dialog>
            </div>

            {/* Stats Overview */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">{t('modules.features.appFeatures.totalFeatures')}</CardTitle>
                  <Settings className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.total}</div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">{t('modules.features.appFeatures.activeFeatures')}</CardTitle>
                  <Shield className="h-4 w-4 text-green-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-green-600">{stats.active}</div>
                  <p className="text-xs text-muted-foreground">
                    {Math.round((stats.active / stats.total) * 100)}% {t('modules.features.appFeatures.ofTotal')}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">{t('modules.features.appFeatures.bannableFeatures')}</CardTitle>
                  <Shield className="h-4 w-4 text-orange-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold text-orange-600">{stats.bannable}</div>
                  <p className="text-xs text-muted-foreground">
                    {t('modules.features.appFeatures.canBeBanned')}
                  </p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">{t('modules.features.appFeatures.categories')}</CardTitle>
                  <FileText className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{Object.keys(stats.categories).length}</div>
                  <p className="text-xs text-muted-foreground">
                    {t('modules.features.appFeatures.featureCategories')}
                  </p>
                </CardContent>
              </Card>
            </div>

            {/* Search */}
            <Card>
              <CardHeader>
                <CardTitle>{t('common.search')}</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-center space-x-2">
                  <Search className="h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder={t('modules.features.appFeatures.searchPlaceholder')}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="flex-1"
                  />
                </div>
              </CardContent>
            </Card>

            {/* Features Table */}
            <Card>
              <CardHeader>
                <CardTitle>{t('modules.features.appFeatures.list')}</CardTitle>
                <CardDescription>
                  {t('modules.features.appFeatures.listDescription')}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {featuresError && (
                  <div className="text-center py-8">
                    <div className="text-red-600 mb-4">
                      <p className="font-medium">{t('common.errors.loadingFailed')}</p>
                      <p className="text-sm text-muted-foreground">{featuresError.message}</p>
                    </div>
                    <Button onClick={() => window.location.reload()}>
                      {t('common.retry')}
                    </Button>
                  </div>
                )}

                {featuresLoading && !featuresError && (
                  <div className="text-center py-8">
                    <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4" />
                    <p className="text-muted-foreground">{t('common.loading')}</p>
                  </div>
                )}

                {!featuresLoading && !featuresError && (
                  <>
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>{t('modules.features.appFeatures.feature')}</TableHead>
                          <TableHead>{t('modules.features.appFeatures.category.label')}</TableHead>
                          <TableHead>{t('modules.features.appFeatures.bannable')}</TableHead>
                          <TableHead>{t('common.status')}</TableHead>
                          <TableHead>{t('modules.features.appFeatures.updated')}</TableHead>
                          <TableHead className="text-right">{t('common.actions')}</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {filteredFeatures.map((feature) => (
                          <TableRow key={feature.id}>
                            <TableCell>
                              <div className="space-y-1">
                                <p className="text-sm font-medium">
                                  {locale === 'ar' ? feature.nameAr : feature.nameEn}
                                </p>
                                <p className="text-xs text-muted-foreground line-clamp-2">
                                  {locale === 'ar' ? feature.descriptionAr : feature.descriptionEn}
                                </p>
                              </div>
                            </TableCell>
                            <TableCell>{getCategoryBadge(feature.category)}</TableCell>
                            <TableCell>
                              <Badge variant={feature.isBannable ? 'default' : 'secondary'}>
                                {feature.isBannable ? t('common.yes') : t('common.no')}
                              </Badge>
                            </TableCell>
                            <TableCell>
                              <div className="flex items-center space-x-2">
                                <Switch
                                  checked={feature.isActive}
                                  onCheckedChange={() => toggleFeatureStatus(feature)}
                                  disabled={isSubmitting}
                                />
                                <Badge variant={feature.isActive ? 'default' : 'secondary'}>
                                  {feature.isActive ? t('common.active') : t('common.inactive')}
                                </Badge>
                              </div>
                            </TableCell>
                            <TableCell>
                                                        {new Intl.DateTimeFormat(locale === 'ar' ? 'ar-SA' : 'en-US', {
                            year: 'numeric',
                            month: 'short',
                            day: 'numeric',
                            calendar: 'gregory',
                          }).format(convertTimestamp(feature.updatedAt))}
                            </TableCell>
                            <TableCell className="text-right">
                              <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                  <Button variant="ghost" className="h-8 w-8 p-0" disabled={isSubmitting}>
                                    <MoreHorizontal className="h-4 w-4" />
                                  </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent align="end">
                                  <DropdownMenuItem onClick={() => handleEdit(feature)} disabled={isSubmitting}>
                                    <Edit className="h-4 w-4 mr-2" />
                                    {t('common.edit')}
                                  </DropdownMenuItem>
                                  <DropdownMenuSeparator />
                                  <DropdownMenuItem 
                                    className="text-red-600"
                                    onClick={() => handleDelete(feature)}
                                    disabled={isSubmitting}
                                  >
                                    <Trash2 className="h-4 w-4 mr-2" />
                                    {t('common.delete')}
                                  </DropdownMenuItem>
                                </DropdownMenuContent>
                              </DropdownMenu>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>

                    {filteredFeatures.length === 0 && (
                      <div className="text-center py-8">
                        <Settings className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                        <p className="text-lg font-medium">{t('common.noData')}</p>
                        <p className="text-muted-foreground">
                          {searchQuery ? t('modules.features.appFeatures.noFeaturesMatch') : t('modules.features.appFeatures.noFeaturesConfigured')}
                        </p>
                      </div>
                    )}
                  </>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>

      {/* Edit Dialog */}
      <Dialog open={!!editingFeature} onOpenChange={() => setEditingFeature(null)}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{t('modules.features.appFeatures.edit')}</DialogTitle>
            <DialogDescription>
              {t('modules.features.appFeatures.editDescription')}
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="edit-nameEn">{t('modules.features.appFeatures.nameEn')}</Label>
                <Input
                  id="edit-nameEn"
                  value={formData.nameEn}
                  onChange={(e) => setFormData({ ...formData, nameEn: e.target.value })}
                  placeholder={t('modules.features.appFeatures.nameEnPlaceholder')}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-nameAr">{t('modules.features.appFeatures.nameAr')}</Label>
                <Input
                  id="edit-nameAr"
                  value={formData.nameAr}
                  onChange={(e) => setFormData({ ...formData, nameAr: e.target.value })}
                  placeholder={t('modules.features.appFeatures.nameArPlaceholder')}
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="edit-descriptionEn">{t('modules.features.appFeatures.descriptionEn')}</Label>
                <Textarea
                  id="edit-descriptionEn"
                  value={formData.descriptionEn}
                  onChange={(e) => setFormData({ ...formData, descriptionEn: e.target.value })}
                  placeholder={t('modules.features.appFeatures.descriptionEnPlaceholder')}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-descriptionAr">{t('modules.features.appFeatures.descriptionAr')}</Label>
                <Textarea
                  id="edit-descriptionAr"
                  value={formData.descriptionAr}
                  onChange={(e) => setFormData({ ...formData, descriptionAr: e.target.value })}
                  placeholder={t('modules.features.appFeatures.descriptionArPlaceholder')}
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="edit-category">{t('modules.features.appFeatures.category.label')}</Label>
                <select
                  id="edit-category"
                  value={formData.category}
                  onChange={(e) => setFormData({ ...formData, category: e.target.value as AppFeature['category'] })}
                  className="w-full px-3 py-2 border border-input bg-background rounded-md"
                >
                  <option value="core">{t('modules.features.appFeatures.category.core')}</option>
                  <option value="social">{t('modules.features.appFeatures.category.social')}</option>
                  <option value="content">{t('modules.features.appFeatures.category.content')}</option>
                  <option value="communication">{t('modules.features.appFeatures.category.communication')}</option>
                  <option value="settings">{t('modules.features.appFeatures.category.settings')}</option>
                </select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-iconName">{t('modules.features.appFeatures.iconName')}</Label>
                <Input
                  id="edit-iconName"
                  value={formData.iconName}
                  onChange={(e) => setFormData({ ...formData, iconName: e.target.value })}
                  placeholder={t('modules.features.appFeatures.iconNamePlaceholder')}
                />
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <Switch
                  checked={formData.isActive}
                  onCheckedChange={(checked) => setFormData({ ...formData, isActive: checked })}
                />
                <Label>{t('modules.features.appFeatures.isActive')}</Label>
              </div>
              <div className="flex items-center space-x-2">
                <Switch
                  checked={formData.isBannable}
                  onCheckedChange={(checked) => setFormData({ ...formData, isBannable: checked })}
                />
                <Label>{t('modules.features.appFeatures.isBannable')}</Label>
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingFeature(null)} disabled={isSubmitting}>
              {t('common.cancel')}
            </Button>
            <Button onClick={handleUpdate} disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  {t('common.updating')}
                </>
              ) : (
                t('common.update')
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
} 