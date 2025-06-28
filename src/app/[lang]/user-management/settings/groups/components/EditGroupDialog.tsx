"use client";

import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Loader2, Save, Users, AlertCircle, CheckCircle } from 'lucide-react';
import { useTranslation } from "@/contexts/TranslationContext";
// Firebase imports
import { doc, updateDoc, serverTimestamp } from 'firebase/firestore';
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
  createdAt: Date;
  updatedAt: Date;
}

interface GroupFormData {
  name: string;
  nameAr: string;
  description: string;
  descriptionAr: string;
  isActive: boolean;
}

interface EditGroupDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  group: Group;
  onGroupUpdated?: (group: Group) => void;
}

export default function EditGroupDialog({ open, onOpenChange, group, onGroupUpdated }: EditGroupDialogProps) {
  const { t } = useTranslation();
  const [isLoading, setIsLoading] = useState(false);
  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [formData, setFormData] = useState<GroupFormData>({
    name: '',
    nameAr: '',
    description: '',
    descriptionAr: '',
    isActive: true
  });

  // Initialize form data when group changes
  useEffect(() => {
    if (group) {
      setFormData({
        name: group.name,
        nameAr: group.nameAr,
        description: group.description || '',
        descriptionAr: group.descriptionAr || '',
        isActive: group.isActive
      });
    }
  }, [group]);

  const validateForm = () => {
    const errors: string[] = [];
    
    if (!formData.name.trim()) {
      errors.push(t('modules.userManagement.groups.errors.nameRequired') || 'English name is required');
    }
    
    if (!formData.nameAr.trim()) {
      errors.push(t('modules.userManagement.groups.errors.nameArRequired') || 'Arabic name is required');
    }
    
    return errors;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const validationErrors = validateForm();
    if (validationErrors.length > 0) {
      setAlert({ type: 'error', message: validationErrors[0] });
      return;
    }

    setIsLoading(true);
    setAlert(null);

    try {
      // Update group in Firestore
      const groupRef = doc(db, 'usersMessagingGroups', group.id);
      const updateData = {
        name: formData.name,
        nameAr: formData.nameAr,
        description: formData.description,
        descriptionAr: formData.descriptionAr,
        isActive: formData.isActive,
        updatedAt: serverTimestamp(),
      };

      await updateDoc(groupRef, updateData);

      setAlert({ type: 'success', message: t('modules.userManagement.groups.updateSuccess') || 'Group updated successfully' });
      
      // Call callback if provided
      if (onGroupUpdated) {
        onGroupUpdated({
          ...group,
          ...updateData,
          updatedAt: new Date(), // Use current date for immediate UI update
        } as Group);
      }
      
      // Close dialog after a short delay
      setTimeout(() => {
        onOpenChange(false);
        setAlert(null);
      }, 1500);

    } catch (error: any) {
      console.error('Error updating group:', error);
      setAlert({ type: 'error', message: error.message || t('modules.userManagement.groups.updateError') || 'Failed to update group' });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            {t('modules.userManagement.groups.editGroup') || 'Edit Messaging Group'}
          </DialogTitle>
          <DialogDescription>
            {t('modules.userManagement.groups.editDescription') || 'Update the messaging group information and settings.'}
          </DialogDescription>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          {alert && (
            <div className={`flex items-center gap-2 p-3 rounded-lg border ${
              alert.type === 'error' 
                ? 'bg-destructive/10 border-destructive text-destructive' 
                : 'bg-green-50 border-green-200 text-green-800'
            }`}>
              {alert.type === 'error' ? (
                <AlertCircle className="h-4 w-4" />
              ) : (
                <CheckCircle className="h-4 w-4" />
              )}
              <span className="text-sm">{alert.message}</span>
            </div>
          )}

          {/* Topic ID Display (Read-only) */}
          <div className="space-y-2 p-3 bg-muted rounded-lg">
            <Label className="text-sm font-medium">{t('modules.userManagement.groups.topicId') || 'Topic ID'}</Label>
            <code className="block text-sm bg-background px-3 py-2 rounded border">
              {group.topicId}
            </code>
            <p className="text-xs text-muted-foreground">
              {t('modules.userManagement.groups.topicIdReadOnly') || 'Topic ID cannot be changed after group creation'}
            </p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="name">{t('modules.userManagement.groups.nameEn') || 'Name (English)'}</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder={t('modules.userManagement.groups.nameEnPlaceholder') || 'Enter group name in English'}
                disabled={isLoading}
                required
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="nameAr">{t('modules.userManagement.groups.nameAr') || 'Name (Arabic)'}</Label>
              <Input
                id="nameAr"
                value={formData.nameAr}
                onChange={(e) => setFormData({ ...formData, nameAr: e.target.value })}
                placeholder={t('modules.userManagement.groups.nameArPlaceholder') || 'أدخل اسم المجموعة بالعربية'}
                disabled={isLoading}
                required
                dir="rtl"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="description">{t('modules.userManagement.groups.descriptionEn') || 'Description (English)'}</Label>
              <Textarea
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder={t('modules.userManagement.groups.descriptionEnPlaceholder') || 'Describe the purpose of this group'}
                disabled={isLoading}
                rows={3}
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="descriptionAr">{t('modules.userManagement.groups.descriptionAr') || 'Description (Arabic)'}</Label>
              <Textarea
                id="descriptionAr"
                value={formData.descriptionAr}
                onChange={(e) => setFormData({ ...formData, descriptionAr: e.target.value })}
                placeholder={t('modules.userManagement.groups.descriptionArPlaceholder') || 'اوصف الغرض من هذه المجموعة'}
                disabled={isLoading}
                rows={3}
                dir="rtl"
              />
            </div>
          </div>

          {/* Group Status */}
          <div className="flex items-center space-x-2">
            <Switch
              id="isActive"
              checked={formData.isActive}
              onCheckedChange={(checked) => setFormData({ ...formData, isActive: checked })}
              disabled={isLoading}
            />
            <div className="space-y-1">
              <Label htmlFor="isActive">{t('modules.userManagement.groups.activeGroup') || 'Active Group'}</Label>
              <p className="text-sm text-muted-foreground">
                {t('modules.userManagement.groups.activeGroupHelp') || 'Inactive groups cannot receive new subscriptions'}
              </p>
            </div>
          </div>

          {/* Group Stats */}
          <div className="p-3 bg-muted rounded-lg">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="font-medium">{t('modules.userManagement.groups.members') || 'Members'}:</span>
                <span className="ml-2">{group.memberCount}</span>
              </div>
              <div>
                <span className="font-medium">{t('modules.userManagement.groups.created') || 'Created'}:</span>
                <span className="ml-2">{new Date(group.createdAt).toLocaleDateString()}</span>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={isLoading}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  {t('modules.userManagement.groups.updating') || 'Updating...'}
                </>
              ) : (
                <>
                  <Save className="w-4 h-4 mr-2" />
                  {t('modules.userManagement.groups.updateGroup') || 'Update Group'}
                </>
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
} 