'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Loader2 } from 'lucide-react';
import { ContentOwnerFormProps, CreateContentOwnerRequest, UpdateContentOwnerRequest } from '@/types/content';

export default function ContentOwnerForm({
  contentOwner,
  onSubmit,
  onCancel,
  isLoading = false,
  t,
  locale,
}: ContentOwnerFormProps) {
  const [formData, setFormData] = useState({
    ownerName: '',
    ownerNameAr: '',
    ownerSource: '',
    isActive: true,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (contentOwner) {
      setFormData({
        ownerName: contentOwner.ownerName,
        ownerNameAr: contentOwner.ownerNameAr || '',
        ownerSource: contentOwner.ownerSource,
        isActive: contentOwner.isActive,
      });
    }
  }, [contentOwner]);

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.ownerName.trim()) {
      newErrors.ownerName = t('content.owners.errors.nameRequired') || 'Name is required';
    }

    if (!formData.ownerSource.trim()) {
      newErrors.ownerSource = t('content.owners.errors.sourceRequired') || 'Source is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    const submitData: CreateContentOwnerRequest | UpdateContentOwnerRequest = {
      ownerName: formData.ownerName.trim(),
      ownerNameAr: formData.ownerNameAr.trim() || undefined,
      ownerSource: formData.ownerSource.trim(),
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
          {t('content.owners.nameEn') || 'Name (English)'} *
        </Label>
        <Input
          id="nameEn"
          value={formData.ownerName}
          onChange={(e) => handleInputChange('ownerName', e.target.value)}
          placeholder={t('content.owners.nameEnPlaceholder') || 'Enter owner name in English'}
          className={errors.ownerName ? 'border-red-500' : ''}
        />
        {errors.ownerName && (
          <p className="text-sm text-red-600">{errors.ownerName}</p>
        )}
      </div>

      {/* Arabic Name */}
      <div className="space-y-2">
        <Label htmlFor="nameAr">
          {t('content.owners.nameAr') || 'Name (Arabic)'}
        </Label>
        <Input
          id="nameAr"
          value={formData.ownerNameAr}
          onChange={(e) => handleInputChange('ownerNameAr', e.target.value)}
          placeholder={t('content.owners.nameArPlaceholder') || 'Enter owner name in Arabic'}
          dir={locale === 'ar' ? 'rtl' : 'ltr'}
        />
      </div>

      {/* Source */}
      <div className="space-y-2">
        <Label htmlFor="source">
          {t('content.owners.source') || 'Source'} *
        </Label>
        <Input
          id="source"
          value={formData.ownerSource}
          onChange={(e) => handleInputChange('ownerSource', e.target.value)}
          placeholder={t('content.owners.sourcePlaceholder') || 'e.g., Internal, External Partner, Freelancer'}
          className={errors.ownerSource ? 'border-red-500' : ''}
        />
        {errors.ownerSource && (
          <p className="text-sm text-red-600">{errors.ownerSource}</p>
        )}
        <p className="text-xs text-muted-foreground">
          {t('content.owners.sourceHelp') || 'Specify the source or type of content owner'}
        </p>
      </div>

      {/* Active Status */}
      <div className="flex items-center justify-between">
        <div className="space-y-0.5">
          <Label htmlFor="isActive">
            {t('content.owners.isActive') || 'Active'}
          </Label>
          <p className="text-sm text-muted-foreground">
            {t('content.owners.isActiveHelp') || 'Active owners can create and manage content'}
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
          {contentOwner
            ? (t('common.update') || 'Update')
            : (t('common.create') || 'Create')
          }
        </Button>
      </div>
    </form>
  );
} 