'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Loader2 } from 'lucide-react';
import { CategoryFormProps, CreateCategoryRequest, UpdateCategoryRequest } from '@/types/content';

export default function CategoryForm({
  category,
  onSubmit,
  onCancel,
  isLoading = false,
  t,
  locale,
}: CategoryFormProps) {
  const [formData, setFormData] = useState({
    contentCategoryIconName: '',
    categoryName: '',
    categoryNameAr: '',
    isActive: true,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (category) {
      setFormData({
        contentCategoryIconName: category.contentCategoryIconName,
        categoryName: category.categoryName,
        categoryNameAr: category.categoryNameAr || '',
        isActive: category.isActive,
      });
    }
  }, [category]);

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.categoryName.trim()) {
      newErrors.categoryName = t('content.categories.errors.nameRequired') || 'Name is required';
    }

    if (!formData.contentCategoryIconName.trim()) {
      newErrors.contentCategoryIconName = t('content.categories.errors.iconRequired') || 'Icon name is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    const submitData: CreateCategoryRequest | UpdateCategoryRequest = {
      contentCategoryIconName: formData.contentCategoryIconName.trim(),
      categoryName: formData.categoryName.trim(),
      categoryNameAr: formData.categoryNameAr.trim() || undefined,
      isActive: formData.isActive,
    };

    await onSubmit(submitData);
  };

  const handleInputChange = (field: string, value: string | boolean) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {/* Icon Name */}
      <div className="space-y-2">
        <Label htmlFor="iconName">
          {t('content.categories.iconName') || 'Icon Name'} *
        </Label>
        <Input
          id="iconName"
          value={formData.contentCategoryIconName}
          onChange={(e) => handleInputChange('contentCategoryIconName', e.target.value)}
          placeholder={t('content.categories.iconNamePlaceholder') || 'e.g., Tag, Folder, BookOpen'}
          className={errors.contentCategoryIconName ? 'border-red-500' : ''}
        />
        {errors.contentCategoryIconName && (
          <p className="text-sm text-red-600">{errors.contentCategoryIconName}</p>
        )}
        <p className="text-xs text-muted-foreground">
          {t('content.categories.iconNameHelp') || 'Use Lucide React icon names (e.g., Tag, Folder, BookOpen)'}
        </p>
      </div>

      {/* Name */}
      <div className="space-y-2">
        <Label htmlFor="nameEn">
          {t('content.categories.name') || 'Name'} *
        </Label>
        <Input
          id="nameEn"
          value={formData.categoryName}
          onChange={(e) => handleInputChange('categoryName', e.target.value)}
          placeholder={t('content.categories.namePlaceholder') || 'Enter category name'}
          className={errors.categoryName ? 'border-red-500' : ''}
        />
        {errors.categoryName && (
          <p className="text-sm text-red-600">{errors.categoryName}</p>
        )}
      </div>

      {/* Arabic Name */}
      <div className="space-y-2">
        <Label htmlFor="nameAr">
          {t('content.categories.nameAr') || 'Name (Arabic)'}
        </Label>
        <Input
          id="nameAr"
          value={formData.categoryNameAr}
          onChange={(e) => handleInputChange('categoryNameAr', e.target.value)}
          placeholder={t('content.categories.nameArPlaceholder') || 'Enter category name in Arabic'}
          dir={locale === 'ar' ? 'rtl' : 'ltr'}
        />
      </div>

      {/* Active Status */}
      <div className="flex items-center justify-between">
        <div className="space-y-0.5">
          <Label htmlFor="isActive">
            {t('content.categories.isActive') || 'Active'}
          </Label>
          <p className="text-sm text-muted-foreground">
            {t('content.categories.isActiveHelp') || 'Active categories are available for content organization'}
          </p>
        </div>
        <Switch
          id="isActive"
          checked={formData.isActive}
          onCheckedChange={(checked) => handleInputChange('isActive', checked)}
        />
      </div>

      {/* Action Buttons */}
      <div className="flex justify-end space-x-2 pt-4">
        <Button type="button" variant="outline" onClick={onCancel} disabled={isLoading}>
          {t('common.cancel') || 'Cancel'}
        </Button>
        <Button type="submit" disabled={isLoading}>
          {isLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
          {category
            ? (t('common.update') || 'Update')
            : (t('common.create') || 'Create')
          }
        </Button>
      </div>
    </form>
  );
} 