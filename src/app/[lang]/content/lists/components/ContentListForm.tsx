'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Checkbox } from '@/components/ui/checkbox';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Loader2, Search } from 'lucide-react';
import { ContentListFormProps, CreateContentListRequest, UpdateContentListRequest, Content } from '@/types/content';

interface ContentListFormPropsExtended extends ContentListFormProps {
  contentItems: Content[];
}

export default function ContentListForm({
  contentList,
  onSubmit,
  onCancel,
  isLoading = false,
  t,
  locale,
  contentItems,
}: ContentListFormPropsExtended) {
  const [formData, setFormData] = useState({
    listName: '',
    listNameAr: '',
    listDescription: '',
    listDescriptionAr: '',
    contentListIconName: '',
    listContentIds: [] as string[],
    isFeatured: false,
    isActive: true,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [contentSearch, setContentSearch] = useState('');

  useEffect(() => {
    if (contentList) {
      setFormData({
        listName: contentList.listName,
        listNameAr: contentList.listNameAr || '',
        listDescription: contentList.listDescription,
        listDescriptionAr: contentList.listDescriptionAr || '',
        contentListIconName: contentList.contentListIconName,
        listContentIds: contentList.listContentIds || [],
        isFeatured: contentList.isFeatured,
        isActive: contentList.isActive,
      });
    }
  }, [contentList]);

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.listName.trim()) {
      newErrors.listName = t('content.lists.errors.nameRequired') || 'Name is required';
    }

    if (!formData.listDescription.trim()) {
      newErrors.listDescription = t('content.lists.errors.descriptionRequired') || 'Description is required';
    }

    if (!formData.contentListIconName.trim()) {
      newErrors.contentListIconName = t('content.lists.errors.iconRequired') || 'Icon name is required';
    }

    if (formData.listContentIds.length === 0) {
      newErrors.listContentIds = t('content.lists.errors.contentRequired') || 'At least one content item is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    const submitData: CreateContentListRequest | UpdateContentListRequest = {
      listName: formData.listName.trim(),
      listNameAr: formData.listNameAr.trim() || undefined,
      listDescription: formData.listDescription.trim(),
      listDescriptionAr: formData.listDescriptionAr.trim() || undefined,
      contentListIconName: formData.contentListIconName.trim(),
      listContentIds: formData.listContentIds,
      isFeatured: formData.isFeatured,
      isActive: formData.isActive,
    };

    await onSubmit(submitData);
  };

  const handleInputChange = (field: string, value: string | boolean | string[]) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const handleContentSelection = (contentId: string, checked: boolean) => {
    const updatedIds = checked
      ? [...formData.listContentIds, contentId]
      : formData.listContentIds.filter(id => id !== contentId);
    
    handleInputChange('listContentIds', updatedIds);
  };

  const filteredContentItems = contentItems.filter(item =>
    !item.isDeleted &&
    item.isActive &&
    (item.contentName.toLowerCase().includes(contentSearch.toLowerCase()) ||
     (item.contentNameAr && item.contentNameAr.toLowerCase().includes(contentSearch.toLowerCase())))
  );

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Basic Information */}
      <Card>
        <CardHeader>
          <CardTitle>{t('content.lists.basicInfo') || 'Basic Information'}</CardTitle>
          <CardDescription>
            {t('content.lists.basicInfoDescription') || 'Enter the basic details for your content list'}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* English Name */}
          <div className="space-y-2">
            <Label htmlFor="nameEn">
              {t('content.lists.nameEn') || 'Name (English)'} *
            </Label>
            <Input
              id="nameEn"
              value={formData.listName}
              onChange={(e) => handleInputChange('listName', e.target.value)}
              placeholder={t('content.lists.nameEnPlaceholder') || 'Enter list name in English'}
              className={errors.listName ? 'border-red-500' : ''}
            />
            {errors.listName && (
              <p className="text-sm text-red-600">{errors.listName}</p>
            )}
          </div>

          {/* Arabic Name */}
          <div className="space-y-2">
            <Label htmlFor="nameAr">
              {t('content.lists.nameAr') || 'Name (Arabic)'}
            </Label>
            <Input
              id="nameAr"
              value={formData.listNameAr}
              onChange={(e) => handleInputChange('listNameAr', e.target.value)}
              placeholder={t('content.lists.nameArPlaceholder') || 'Enter list name in Arabic'}
              dir={locale === 'ar' ? 'rtl' : 'ltr'}
            />
          </div>

          {/* English Description */}
          <div className="space-y-2">
            <Label htmlFor="descriptionEn">
              {t('content.lists.descriptionEn') || 'Description (English)'} *
            </Label>
            <textarea
              id="descriptionEn"
              value={formData.listDescription}
              onChange={(e) => handleInputChange('listDescription', e.target.value)}
              placeholder={t('content.lists.descriptionEnPlaceholder') || 'Enter list description in English'}
              className={`flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 ${errors.listDescription ? 'border-red-500' : ''}`}
              rows={3}
            />
            {errors.listDescription && (
              <p className="text-sm text-red-600">{errors.listDescription}</p>
            )}
          </div>

          {/* Arabic Description */}
          <div className="space-y-2">
            <Label htmlFor="descriptionAr">
              {t('content.lists.descriptionAr') || 'Description (Arabic)'}
            </Label>
            <textarea
              id="descriptionAr"
              value={formData.listDescriptionAr}
              onChange={(e) => handleInputChange('listDescriptionAr', e.target.value)}
              placeholder={t('content.lists.descriptionArPlaceholder') || 'Enter list description in Arabic'}
              className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
              dir={locale === 'ar' ? 'rtl' : 'ltr'}
              rows={3}
            />
          </div>

          {/* Icon Name */}
          <div className="space-y-2">
            <Label htmlFor="iconName">
              {t('content.lists.iconName') || 'Icon Name'} *
            </Label>
            <Input
              id="iconName"
              value={formData.contentListIconName}
              onChange={(e) => handleInputChange('contentListIconName', e.target.value)}
              placeholder={t('content.lists.iconNamePlaceholder') || 'e.g., List, Collection, Bookmark'}
              className={errors.contentListIconName ? 'border-red-500' : ''}
            />
            {errors.contentListIconName && (
              <p className="text-sm text-red-600">{errors.contentListIconName}</p>
            )}
            <p className="text-xs text-muted-foreground">
              {t('content.lists.iconNameHelp') || 'Use Lucide React icon names (e.g., List, Collection, Bookmark)'}
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Content Selection */}
      <Card>
        <CardHeader>
          <CardTitle>{t('content.lists.contentSelection') || 'Content Selection'}</CardTitle>
          <CardDescription>
            {t('content.lists.contentSelectionDescription') || 'Select the content items to include in this list'}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder={t('content.lists.searchContent') || 'Search content items...'}
              value={contentSearch}
              onChange={(e) => setContentSearch(e.target.value)}
              className="pl-10"
            />
          </div>

          {/* Content Items */}
          <div className="max-h-60 overflow-y-auto border rounded-md p-4 space-y-2">
            {filteredContentItems.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">
                {t('content.lists.noContentFound') || 'No content items found'}
              </p>
            ) : (
              filteredContentItems.map((content) => (
                <div key={content.id} className="flex items-center space-x-2">
                  <Checkbox
                    id={`content-${content.id}`}
                    checked={formData.listContentIds.includes(content.id)}
                    onCheckedChange={(checked) => handleContentSelection(content.id, checked as boolean)}
                  />
                  <Label
                    htmlFor={`content-${content.id}`}
                    className="text-sm font-normal cursor-pointer flex-1"
                  >
                    {locale === 'ar' && content.contentNameAr ? content.contentNameAr : content.contentName}
                  </Label>
                </div>
              ))
            )}
          </div>

          {errors.listContentIds && (
            <p className="text-sm text-red-600">{errors.listContentIds}</p>
          )}

          <p className="text-sm text-muted-foreground">
            {t('content.lists.selectedCount') || 'Selected:'} {formData.listContentIds.length} {t('content.lists.items') || 'items'}
          </p>
        </CardContent>
      </Card>

      {/* Settings */}
      <Card>
        <CardHeader>
          <CardTitle>{t('content.lists.settings') || 'Settings'}</CardTitle>
          <CardDescription>
            {t('content.lists.settingsDescription') || 'Configure list visibility and features'}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Featured Status */}
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label htmlFor="isFeatured">
                {t('content.lists.featured') || 'Featured'}
              </Label>
              <p className="text-sm text-muted-foreground">
                {t('content.lists.featuredHelp') || 'Featured lists are highlighted to users'}
              </p>
            </div>
            <Switch
              id="isFeatured"
              checked={formData.isFeatured}
              onCheckedChange={(checked) => handleInputChange('isFeatured', checked)}
            />
          </div>

          {/* Active Status */}
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label htmlFor="isActive">
                {t('content.lists.isActive') || 'Active'}
              </Label>
              <p className="text-sm text-muted-foreground">
                {t('content.lists.isActiveHelp') || 'Active lists are visible to users'}
              </p>
            </div>
            <Switch
              id="isActive"
              checked={formData.isActive}
              onCheckedChange={(checked) => handleInputChange('isActive', checked)}
            />
          </div>
        </CardContent>
      </Card>

      {/* Action Buttons */}
      <div className="flex justify-end space-x-2 pt-4">
        <Button type="button" variant="outline" onClick={onCancel} disabled={isLoading}>
          {t('common.cancel') || 'Cancel'}
        </Button>
        <Button type="submit" disabled={isLoading}>
          {isLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
          {contentList
            ? (t('common.update') || 'Update')
            : (t('common.create') || 'Create')
          }
        </Button>
      </div>
    </form>
  );
} 