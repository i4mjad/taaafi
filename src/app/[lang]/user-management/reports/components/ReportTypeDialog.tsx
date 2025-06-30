'use client';

import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { useTranslation } from '@/contexts/TranslationContext';
import { toast } from 'sonner';

// Firebase imports
import { collection, addDoc, updateDoc, doc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface ReportType {
  id?: string;
  nameEn: string;
  nameAr: string;
  descriptionEn: string;
  descriptionAr: string;
  isActive: boolean;
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
}

interface ReportTypeDialogProps {
  isOpen: boolean;
  onClose: () => void;
  reportType?: ReportType | null;
  onSuccess?: () => void;
}

export default function ReportTypeDialog({ isOpen, onClose, reportType, onSuccess }: ReportTypeDialogProps) {
  const { t } = useTranslation();
  
  const [formData, setFormData] = useState<ReportType>({
    nameEn: '',
    nameAr: '',
    descriptionEn: '',
    descriptionAr: '',
    isActive: true,
  });
  
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const isEditMode = !!reportType?.id;

  // Reset form when dialog opens/closes or reportType changes
  useEffect(() => {
    if (reportType) {
      setFormData({
        nameEn: reportType.nameEn || '',
        nameAr: reportType.nameAr || '',
        descriptionEn: reportType.descriptionEn || '',
        descriptionAr: reportType.descriptionAr || '',
        isActive: reportType.isActive ?? true,
      });
    } else {
      setFormData({
        nameEn: '',
        nameAr: '',
        descriptionEn: '',
        descriptionAr: '',
        isActive: true,
      });
    }
    setErrors({});
  }, [reportType, isOpen]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.nameEn.trim()) {
      newErrors.nameEn = t('modules.userManagement.reports.reportTypes.errors.nameEnRequired') || 'English name is required';
    }

    if (!formData.nameAr.trim()) {
      newErrors.nameAr = t('modules.userManagement.reports.reportTypes.errors.nameArRequired') || 'Arabic name is required';
    }

    if (!formData.descriptionEn.trim()) {
      newErrors.descriptionEn = t('modules.userManagement.reports.reportTypes.errors.descriptionEnRequired') || 'English description is required';
    }

    if (!formData.descriptionAr.trim()) {
      newErrors.descriptionAr = t('modules.userManagement.reports.reportTypes.errors.descriptionArRequired') || 'Arabic description is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setLoading(true);

    try {
      const now = Timestamp.now();
      
      if (isEditMode && reportType?.id) {
        // Update existing report type
        const reportTypeRef = doc(db, 'reportTypes', reportType.id);
        await updateDoc(reportTypeRef, {
          nameEn: formData.nameEn.trim(),
          nameAr: formData.nameAr.trim(),
          descriptionEn: formData.descriptionEn.trim(),
          descriptionAr: formData.descriptionAr.trim(),
          isActive: formData.isActive,
          updatedAt: now,
        });

        toast.success(t('modules.userManagement.reports.reportTypes.updateSuccess') || 'Report type updated successfully');
      } else {
        // Create new report type
        await addDoc(collection(db, 'reportTypes'), {
          nameEn: formData.nameEn.trim(),
          nameAr: formData.nameAr.trim(),
          descriptionEn: formData.descriptionEn.trim(),
          descriptionAr: formData.descriptionAr.trim(),
          isActive: formData.isActive,
          createdAt: now,
          updatedAt: now,
        });

        toast.success(t('modules.userManagement.reports.reportTypes.createSuccess') || 'Report type created successfully');
      }

      onSuccess?.();
      onClose();
    } catch (error) {
      console.error('Error saving report type:', error);
      toast.error(
        isEditMode 
          ? t('modules.userManagement.reports.reportTypes.updateError') || 'Failed to update report type'
          : t('modules.userManagement.reports.reportTypes.createError') || 'Failed to create report type'
      );
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: keyof ReportType, value: string | boolean) => {
    setFormData(prev => ({
      ...prev,
      [field]: value,
    }));
    
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({
        ...prev,
        [field]: '',
      }));
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>
            {isEditMode 
              ? t('modules.userManagement.reports.reportTypes.edit') || 'Edit Report Type'
              : t('modules.userManagement.reports.reportTypes.create') || 'Create Report Type'
            }
          </DialogTitle>
          <DialogDescription>
            {isEditMode 
              ? t('modules.userManagement.reports.reportTypes.editDescription') || 'Update report type information'
              : t('modules.userManagement.reports.reportTypes.createDescription') || 'Add a new report type for users to select'
            }
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* English Name */}
          <div className="space-y-2">
            <Label htmlFor="nameEn">
              {t('modules.userManagement.reports.reportTypes.nameEn') || 'Name (English)'}
            </Label>
            <Input
              id="nameEn"
              value={formData.nameEn}
              onChange={(e) => handleInputChange('nameEn', e.target.value)}
              placeholder={t('modules.userManagement.reports.reportTypes.nameEnPlaceholder') || 'Enter report type name in English'}
              className={errors.nameEn ? 'border-red-500' : ''}
            />
            {errors.nameEn && (
              <p className="text-sm text-red-500">{errors.nameEn}</p>
            )}
          </div>

          {/* Arabic Name */}
          <div className="space-y-2">
            <Label htmlFor="nameAr">
              {t('modules.userManagement.reports.reportTypes.nameAr') || 'Name (Arabic)'}
            </Label>
            <Input
              id="nameAr"
              value={formData.nameAr}
              onChange={(e) => handleInputChange('nameAr', e.target.value)}
              placeholder={t('modules.userManagement.reports.reportTypes.nameArPlaceholder') || 'Enter report type name in Arabic'}
              className={errors.nameAr ? 'border-red-500' : ''}
              dir="rtl"
            />
            {errors.nameAr && (
              <p className="text-sm text-red-500">{errors.nameAr}</p>
            )}
          </div>

          {/* English Description */}
          <div className="space-y-2">
            <Label htmlFor="descriptionEn">
              {t('modules.userManagement.reports.reportTypes.descriptionEn') || 'Description (English)'}
            </Label>
            <Textarea
              id="descriptionEn"
              value={formData.descriptionEn}
              onChange={(e) => handleInputChange('descriptionEn', e.target.value)}
              placeholder={t('modules.userManagement.reports.reportTypes.descriptionEnPlaceholder') || 'Describe this report type in English'}
              className={errors.descriptionEn ? 'border-red-500' : ''}
              rows={3}
            />
            {errors.descriptionEn && (
              <p className="text-sm text-red-500">{errors.descriptionEn}</p>
            )}
          </div>

          {/* Arabic Description */}
          <div className="space-y-2">
            <Label htmlFor="descriptionAr">
              {t('modules.userManagement.reports.reportTypes.descriptionAr') || 'Description (Arabic)'}
            </Label>
            <Textarea
              id="descriptionAr"
              value={formData.descriptionAr}
              onChange={(e) => handleInputChange('descriptionAr', e.target.value)}
              placeholder={t('modules.userManagement.reports.reportTypes.descriptionArPlaceholder') || 'Describe this report type in Arabic'}
              className={errors.descriptionAr ? 'border-red-500' : ''}
              rows={3}
              dir="rtl"
            />
            {errors.descriptionAr && (
              <p className="text-sm text-red-500">{errors.descriptionAr}</p>
            )}
          </div>

          {/* Active Status */}
          <div className="flex items-center justify-between">
            <div className="space-y-0.5">
              <Label htmlFor="isActive">
                {t('modules.userManagement.reports.reportTypes.isActive') || 'Active'}
              </Label>
              <p className="text-sm text-muted-foreground">
                {t('modules.userManagement.reports.reportTypes.isActiveHelp') || 'Active report types are available for users to select'}
              </p>
            </div>
            <Switch
              id="isActive"
              checked={formData.isActive}
              onCheckedChange={(checked) => handleInputChange('isActive', checked)}
            />
          </div>

          <DialogFooter className="flex gap-2">
            <Button 
              type="button" 
              variant="outline" 
              onClick={onClose}
              disabled={loading}
            >
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button 
              type="submit" 
              disabled={loading}
            >
              {loading 
                ? (isEditMode 
                    ? t('modules.userManagement.reports.reportTypes.updating') || 'Updating...'
                    : t('modules.userManagement.reports.reportTypes.creating') || 'Creating...'
                  )
                : (isEditMode 
                    ? t('common.update') || 'Update'
                    : t('common.create') || 'Create'
                  )
              }
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
} 