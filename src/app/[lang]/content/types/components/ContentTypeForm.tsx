'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { FileText, Loader2 } from 'lucide-react';
import { ContentTypeFormProps, CreateContentTypeRequest, UpdateContentTypeRequest } from '@/types/content';

export default function ContentTypeForm({
  contentType,
  onSubmit,
  onCancel,
  isLoading = false,
  t,
  locale,
}: ContentTypeFormProps) {
  const [formData, setFormData] = useState({
    contentTypeIconName: '',
    contentTypeName: '',
    contentTypeNameAr: '',
    isActive: true,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (contentType) {
      setFormData({
        contentTypeIconName: contentType.contentTypeIconName,
        contentTypeName: contentType.contentTypeName,
        contentTypeNameAr: contentType.contentTypeNameAr || '',
        isActive: contentType.isActive,
      });
    }
  }, [contentType]);

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.contentTypeName.trim()) {
      newErrors.contentTypeName = t('content.types.errors.nameRequired') || 'Name is required';
    }

    if (!formData.contentTypeIconName.trim()) {
      newErrors.contentTypeIconName = t('content.types.errors.iconRequired') || 'Icon name is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    const submitData: CreateContentTypeRequest | UpdateContentTypeRequest = {
      contentTypeIconName: formData.contentTypeIconName.trim(),
      contentTypeName: formData.contentTypeName.trim(),
      contentTypeNameAr: formData.contentTypeNameAr.trim() || undefined,
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
          {t('content.types.iconName') || 'Icon Name'} *
        </Label>
        <Input
          id="iconName"
          value={formData.contentTypeIconName}
          onChange={(e) => handleInputChange('contentTypeIconName', e.target.value)}
          placeholder={t('content.types.iconNamePlaceholder') || 'e.g., FileText, Video, Image'}
          className={errors.contentTypeIconName ? 'border-red-500' : ''}
        />
        {errors.contentTypeIconName && (
          <p className="text-sm text-red-600">{errors.contentTypeIconName}</p>
        )}
        <p className="text-xs text-muted-foreground">
          {t('content.types.iconNameHelp') || 'Use Lucide React icon names (e.g., FileText, Video, Image)'}
        </p>
      </div>

      {/* English Name */}
      <div className="space-y-2">
        <Label htmlFor="nameEn">
          {t('content.types.nameEn') || 'Name (English)'} *
        </Label>
        <Input
          id="nameEn"
          value={formData.contentTypeName}
          onChange={(e) => handleInputChange('contentTypeName', e.target.value)}
          placeholder={t('content.types.nameEnPlaceholder') || 'Enter content type name in English'}
          className={errors.contentTypeName ? 'border-red-500' : ''}
        />
        {errors.contentTypeName && (
          <p className="text-sm text-red-600">{errors.contentTypeName}</p>
        )}
      </div>

      {/* Arabic Name */}
      <div className="space-y-2">
        <Label htmlFor="nameAr">
          {t('content.types.nameAr') || 'Name (Arabic)'}
        </Label>
        <Input
          id="nameAr"
          value={formData.contentTypeNameAr}
          onChange={(e) => handleInputChange('contentTypeNameAr', e.target.value)}
          placeholder={t('content.types.nameArPlaceholder') || 'Enter content type name in Arabic'}
          dir={locale === 'ar' ? 'rtl' : 'ltr'}
        />
      </div>

      {/* Active Status */}
      <div className="flex items-center justify-between">
        <div className="space-y-0.5">
          <Label htmlFor="isActive">
            {t('content.types.isActive') || 'Active'}
          </Label>
          <p className="text-sm text-muted-foreground">
            {t('content.types.isActiveHelp') || 'Active content types are available for content creation'}
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
          {contentType
            ? (t('common.update') || 'Update')
            : (t('common.create') || 'Create')
          }
        </Button>
      </div>
    </form>
  );
} 