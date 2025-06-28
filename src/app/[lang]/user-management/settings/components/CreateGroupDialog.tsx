"use client";

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Loader2, Plus, Users, AlertCircle, CheckCircle } from 'lucide-react';
import { useTranslation } from "@/contexts/TranslationContext";
// Firebase imports
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface GroupData {
  name: string;
  nameAr: string;
  description: string;
  descriptionAr: string;
  topicId: string;
}

interface CreateGroupDialogProps {
  trigger?: React.ReactNode;
  onGroupCreated?: (group: any) => void;
}

export default function CreateGroupDialog({ trigger, onGroupCreated }: CreateGroupDialogProps) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [formData, setFormData] = useState<GroupData>({
    name: '',
    nameAr: '',
    description: '',
    descriptionAr: '',
    topicId: ''
  });

  const validateForm = () => {
    const errors: string[] = [];
    
    if (!formData.name.trim()) {
      errors.push(t('modules.userManagement.groups.errors.nameRequired') || 'English name is required');
    }
    
    if (!formData.nameAr.trim()) {
      errors.push(t('modules.userManagement.groups.errors.nameArRequired') || 'Arabic name is required');
    }
    
    if (!formData.topicId.trim()) {
      errors.push(t('modules.userManagement.groups.errors.topicIdRequired') || 'Topic ID is required');
    }
    
    // Validate topic ID format (letters, numbers, underscores, hyphens only)
    if (formData.topicId && !/^[a-zA-Z0-9_-]+$/.test(formData.topicId)) {
      errors.push(t('modules.userManagement.groups.errors.invalidTopicId') || 'Topic ID can only contain letters, numbers, underscores, and hyphens');
    }
    
    return errors;
  };

  const generateTopicId = () => {
    if (formData.name) {
      const topicId = formData.name
        .toLowerCase()
        .replace(/\s+/g, '_')
        .replace(/[^a-zA-Z0-9_-]/g, '')
        .slice(0, 50); // FCM topic names have limits
      
      setFormData({ ...formData, topicId });
    }
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
      // Add group to Firestore
      const groupData = {
        name: formData.name,
        nameAr: formData.nameAr,
        description: formData.description || '',
        descriptionAr: formData.descriptionAr || '',
        topicId: formData.topicId,
        memberCount: 0,
        isActive: true,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };

      const docRef = await addDoc(collection(db, 'usersMessagingGroups'), groupData);

      setAlert({ type: 'success', message: t('modules.userManagement.groups.createSuccess') || 'Group created successfully' });
      
      // Reset form
      setFormData({
        name: '',
        nameAr: '',
        description: '',
        descriptionAr: '',
        topicId: ''
      });
      
      // Call callback if provided
      if (onGroupCreated) {
        onGroupCreated({ id: docRef.id, ...groupData });
      }
      
      // Close dialog after a short delay
      setTimeout(() => {
        setOpen(false);
        setAlert(null);
      }, 1500);

    } catch (error: any) {
      console.error('Error creating group:', error);
      setAlert({ type: 'error', message: error.message || t('modules.userManagement.groups.createError') || 'Failed to create group' });
    } finally {
      setIsLoading(false);
    }
  };

  const defaultTrigger = (
    <Button>
      <Plus className="w-4 h-4 mr-2" />
      {t('modules.userManagement.groups.createGroup') || 'Create Group'}
    </Button>
  );

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {trigger || defaultTrigger}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            {t('modules.userManagement.groups.createGroup') || 'Create Messaging Group'}
          </DialogTitle>
          <DialogDescription>
            {t('modules.userManagement.groups.createDescription') || 'Create a new messaging group for targeted notifications and communications.'}
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

          <div className="space-y-2">
            <Label htmlFor="topicId" className="flex items-center gap-2">
              {t('modules.userManagement.groups.topicId') || 'Topic ID'}
              <Button 
                type="button" 
                variant="outline" 
                size="sm" 
                onClick={generateTopicId}
                disabled={isLoading || !formData.name}
              >
                {t('modules.userManagement.groups.generate') || 'Generate'}
              </Button>
            </Label>
            <Input
              id="topicId"
              value={formData.topicId}
              onChange={(e) => setFormData({ ...formData, topicId: e.target.value })}
              placeholder={t('modules.userManagement.groups.topicIdPlaceholder') || 'premium_users'}
              disabled={isLoading}
              required
            />
            <p className="text-sm text-muted-foreground">
              {t('modules.userManagement.groups.topicIdHelp') || 'Unique identifier for FCM topics (letters, numbers, underscores, and hyphens only)'}
            </p>
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

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setOpen(false)} disabled={isLoading}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  {t('modules.userManagement.groups.creating') || 'Creating...'}
                </>
              ) : (
                <>
                  <Plus className="w-4 h-4 mr-2" />
                  {t('modules.userManagement.groups.createGroup') || 'Create Group'}
                </>
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
} 