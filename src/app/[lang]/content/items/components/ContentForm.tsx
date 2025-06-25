'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Loader2 } from 'lucide-react';
import { ContentFormProps, CreateContentRequest, UpdateContentRequest, ContentType, ContentOwner, Category } from '@/types/content';

interface ContentFormPropsExtended extends ContentFormProps {
  contentTypes: ContentType[];
  contentOwners: ContentOwner[];
  categories: Category[];
}

export default function ContentForm({
  content,
  onSubmit,
  onCancel,
  isLoading = false,
  t,
  locale,
  contentTypes,
  contentOwners,
  categories,
}: ContentFormPropsExtended) {
  const [formData, setFormData] = useState({
    contentName: '',
    contentNameAr: '',
    contentLanguage: 'en' as 'en' | 'ar' | 'both',
    contentLink: '',
    contentCategoryId: '',
    contentTypeId: '',
    contentOwnerId: '',
    isActive: true,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (content) {
      setFormData({
        contentName: content.contentName,
        contentNameAr: content.contentNameAr || '',
        contentLanguage: content.contentLanguage,
        contentLink: content.contentLink,
        contentCategoryId: content.contentCategoryId,
        contentTypeId: content.contentTypeId,
        contentOwnerId: content.contentOwnerId,
        isActive: content.isActive,
      });
    }
  }, [content]);

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.contentName.trim()) {
      newErrors.contentName = t('content.items.errors.nameRequired') || 'Name is required';
    }

    if (!formData.contentLink.trim()) {
      newErrors.contentLink = t('content.items.errors.linkRequired') || 'Content link is required';
    } else {
      // Basic URL validation
      try {
        new URL(formData.contentLink);
      } catch {
        newErrors.contentLink = t('content.items.errors.invalidLink') || 'Please enter a valid URL';
      }
    }

    if (!formData.contentCategoryId) {
      newErrors.contentCategoryId = t('content.items.errors.categoryRequired') || 'Category is required';
    }

    if (!formData.contentTypeId) {
      newErrors.contentTypeId = t('content.items.errors.typeRequired') || 'Content type is required';
    }

    if (!formData.contentOwnerId) {
      newErrors.contentOwnerId = t('content.items.errors.ownerRequired') || 'Content owner is required';
    }

    // If language is 'ar' or 'both', Arabic name is required
    if ((formData.contentLanguage === 'ar' || formData.contentLanguage === 'both') && !formData.contentNameAr.trim()) {
      newErrors.contentNameAr = t('content.items.errors.nameArRequired') || 'Arabic name is required for this language setting';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    const submitData: CreateContentRequest | UpdateContentRequest = {
      contentName: formData.contentName.trim(),
      contentNameAr: formData.contentNameAr.trim() || undefined,
      contentLanguage: formData.contentLanguage,
      contentLink: formData.contentLink.trim(),
      contentCategoryId: formData.contentCategoryId,
      contentTypeId: formData.contentTypeId,
      contentOwnerId: formData.contentOwnerId,
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
      {/* English Name */}
      <div className="space-y-2">
        <Label htmlFor="nameEn">
          {t('content.items.nameEn') || 'Name (English)'} *
        </Label>
        <Input
          id="nameEn"
          value={formData.contentName}
          onChange={(e) => handleInputChange('contentName', e.target.value)}
          placeholder={t('content.items.nameEnPlaceholder') || 'Enter content name in English'}
          className={errors.contentName ? 'border-red-500' : ''}
        />
        {errors.contentName && (
          <p className="text-sm text-red-600">{errors.contentName}</p>
        )}
      </div>

      {/* Arabic Name */}
      <div className="space-y-2">
        <Label htmlFor="nameAr">
          {t('content.items.nameAr') || 'Name (Arabic)'}
          {(formData.contentLanguage === 'ar' || formData.contentLanguage === 'both') && ' *'}
        </Label>
        <Input
          id="nameAr"
          value={formData.contentNameAr}
          onChange={(e) => handleInputChange('contentNameAr', e.target.value)}
          placeholder={t('content.items.nameArPlaceholder') || 'Enter content name in Arabic'}
          dir={locale === 'ar' ? 'rtl' : 'ltr'}
          className={errors.contentNameAr ? 'border-red-500' : ''}
        />
        {errors.contentNameAr && (
          <p className="text-sm text-red-600">{errors.contentNameAr}</p>
        )}
      </div>

      {/* Content Language */}
      <div className="space-y-2">
        <Label htmlFor="language">
          {t('content.items.language') || 'Content Language'} *
        </Label>
        <Select
          value={formData.contentLanguage}
          onValueChange={(value: 'en' | 'ar' | 'both') => handleInputChange('contentLanguage', value)}
        >
          <SelectTrigger className={errors.contentLanguage ? 'border-red-500' : ''}>
            <SelectValue placeholder={t('content.items.selectLanguage') || 'Select language'} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="en">{t('content.items.languageEn') || 'English'}</SelectItem>
            <SelectItem value="ar">{t('content.items.languageAr') || 'Arabic'}</SelectItem>
            <SelectItem value="both">{t('content.items.languageBoth') || 'Both'}</SelectItem>
          </SelectContent>
        </Select>
        {errors.contentLanguage && (
          <p className="text-sm text-red-600">{errors.contentLanguage}</p>
        )}
      </div>

      {/* Content Link */}
      <div className="space-y-2">
        <Label htmlFor="link">
          {t('content.items.link') || 'Content Link'} *
        </Label>
        <Input
          id="link"
          type="url"
          value={formData.contentLink}
          onChange={(e) => handleInputChange('contentLink', e.target.value)}
          placeholder={t('content.items.linkPlaceholder') || 'https://example.com/content'}
          className={errors.contentLink ? 'border-red-500' : ''}
        />
        {errors.contentLink && (
          <p className="text-sm text-red-600">{errors.contentLink}</p>
        )}
        <p className="text-xs text-muted-foreground">
          {t('content.items.linkHelp') || 'Enter the full URL to the content'}
        </p>
      </div>

      {/* Category */}
      <div className="space-y-2">
        <Label htmlFor="category">
          {t('content.items.category') || 'Category'} *
        </Label>
        <Select
          value={formData.contentCategoryId}
          onValueChange={(value) => handleInputChange('contentCategoryId', value)}
        >
          <SelectTrigger className={errors.contentCategoryId ? 'border-red-500' : ''}>
            <SelectValue placeholder={t('content.items.selectCategory') || 'Select category'} />
          </SelectTrigger>
          <SelectContent>
            {categories.map((category) => (
              <SelectItem key={category.id} value={category.id}>
                {locale === 'ar' && category.categoryNameAr ? category.categoryNameAr : category.categoryName}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        {errors.contentCategoryId && (
          <p className="text-sm text-red-600">{errors.contentCategoryId}</p>
        )}
      </div>

      {/* Content Type */}
      <div className="space-y-2">
        <Label htmlFor="type">
          {t('content.items.type') || 'Content Type'} *
        </Label>
        <Select
          value={formData.contentTypeId}
          onValueChange={(value) => handleInputChange('contentTypeId', value)}
        >
          <SelectTrigger className={errors.contentTypeId ? 'border-red-500' : ''}>
            <SelectValue placeholder={t('content.items.selectType') || 'Select content type'} />
          </SelectTrigger>
          <SelectContent>
            {contentTypes.map((type) => (
              <SelectItem key={type.id} value={type.id}>
                {locale === 'ar' && type.contentTypeNameAr ? type.contentTypeNameAr : type.contentTypeName}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        {errors.contentTypeId && (
          <p className="text-sm text-red-600">{errors.contentTypeId}</p>
        )}
      </div>

      {/* Content Owner */}
      <div className="space-y-2">
        <Label htmlFor="owner">
          {t('content.items.owner') || 'Content Owner'} *
        </Label>
        <Select
          value={formData.contentOwnerId}
          onValueChange={(value) => handleInputChange('contentOwnerId', value)}
        >
          <SelectTrigger className={errors.contentOwnerId ? 'border-red-500' : ''}>
            <SelectValue placeholder={t('content.items.selectOwner') || 'Select content owner'} />
          </SelectTrigger>
          <SelectContent>
            {contentOwners.map((owner) => (
              <SelectItem key={owner.id} value={owner.id}>
                {locale === 'ar' && owner.ownerNameAr ? owner.ownerNameAr : owner.ownerName}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        {errors.contentOwnerId && (
          <p className="text-sm text-red-600">{errors.contentOwnerId}</p>
        )}
      </div>

      {/* Active Status */}
      <div className="flex items-center justify-between">
        <div className="space-y-0.5">
          <Label htmlFor="isActive">
            {t('content.items.isActive') || 'Active'}
          </Label>
          <p className="text-sm text-muted-foreground">
            {t('content.items.isActiveHelp') || 'Active content is visible to users'}
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
          {content
            ? (t('common.update') || 'Update')
            : (t('common.create') || 'Create')
          }
        </Button>
      </div>
    </form>
  );
} 