'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, where, addDoc, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuthState } from 'react-firebase-hooks/auth';
import { auth } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { CreateForumPostRequest, PostCategory, CommunityProfile } from '@/types/community';
import { toast } from 'sonner';

interface ForumPostFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}

export default function ForumPostForm({ isOpen, onClose, onSuccess }: ForumPostFormProps) {
  const { t } = useTranslation();
  const [user] = useAuthState(auth);
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState<CreateForumPostRequest>({
    authorCPId: '',
    title: '',
    body: '',
    category: '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Fetch post categories - only active categories for admin
  const [categoriesValue] = useCollection(
    query(
      collection(db, 'postCategories'), 
      where('isActive', '==', true),
      orderBy('sortOrder')
    )
  );

  // Fetch current user's community profile
  const [userProfileValue, profileLoading, profileError] = useCollection(
    user ? query(
      collection(db, 'communityProfiles'),
      where('userUID', '==', user.uid),
      orderBy('createdAt', 'desc'),
      limit(1)
    ) : null
  );

  const categories = useMemo(() => {
    if (!categoriesValue) return [];
    
    return categoriesValue.docs.map(doc => ({
      id: doc.id,
      name: doc.data().name || 'Unknown',
      nameAr: doc.data().nameAr || 'غير معروف',
      isForAdminOnly: doc.data().isForAdminOnly || false,
      ...doc.data(),
    })) as PostCategory[];
  }, [categoriesValue]);

  const userProfile = useMemo(() => {
    if (!userProfileValue || userProfileValue.docs.length === 0) {
      return null;
    }
    
    const doc = userProfileValue.docs[0];
    const data = doc.data();
    
    // Check if profile is deleted and not restored
    if (data.isDeleted && !data.restoredAt) {
      return null;
    }
    
    return {
      id: doc.id,
      displayName: data.displayName || 'Unknown User',
      ...data,
    } as CommunityProfile;
  }, [userProfileValue]);

  // Reset form when dialog opens and set author from user profile
  useEffect(() => {
    if (isOpen) {
      setFormData({
        authorCPId: userProfile?.id || '',
        title: '',
        body: '',
        category: '',
      });
      setErrors({});
    }
  }, [isOpen, userProfile]);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.title.trim()) {
      newErrors.title = t('modules.community.posts.errors.titleRequired');
    }

    if (!formData.body.trim()) {
      newErrors.body = t('modules.community.posts.errors.bodyRequired');
    }

    if (!formData.category) {
      newErrors.category = t('modules.community.posts.errors.categoryRequired');
    }

    if (!userProfile) {
      newErrors.profile = t('modules.community.posts.errors.profileRequired');
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleInputChange = (field: keyof CreateForumPostRequest, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setIsLoading(true);

    try {
      // Create the forum post
      const postData = {
        authorCPId: userProfile?.id || formData.authorCPId,
        title: formData.title,
        body: formData.body,
        category: formData.category,
        score: 0,
        likeCount: 0,
        dislikeCount: 0,
        isDeleted: false,
        isCommentingAllowed: true,
        isPinned: false,
        createdAt: new Date(),
        updatedAt: null,
      };

      await addDoc(collection(db, 'forumPosts'), postData);

      toast.success(t('modules.community.posts.createSuccess'));
      onClose();
      onSuccess?.();
    } catch (error) {
      console.error('Error creating forum post:', error);
      toast.error(t('modules.community.posts.createError'));
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{t('modules.community.posts.createPost')}</DialogTitle>
          <DialogDescription>
            {t('modules.community.posts.createDescription')}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Title */}
          <div className="space-y-2">
            <Label htmlFor="title">{t('modules.community.posts.title')}</Label>
            <Input
              id="title"
              placeholder={t('modules.community.posts.titlePlaceholder')}
              value={formData.title}
              onChange={(e) => handleInputChange('title', e.target.value)}
              className={errors.title ? 'border-destructive' : ''}
            />
            {errors.title && (
              <p className="text-sm text-destructive">{errors.title}</p>
            )}
          </div>

          {/* Author Information Display */}
          <div className="space-y-2">
            <Label>{t('modules.community.posts.author')}</Label>
            <div className="p-3 bg-muted rounded-md">
              {profileLoading ? (
                <p className="text-sm text-muted-foreground">
                  {t('modules.community.posts.loadingProfile')}
                </p>
              ) : userProfile ? (
                <div className="flex items-center space-x-2">
                  <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center">
                    <span className="text-sm font-medium text-primary">
                      {userProfile.displayName.charAt(0).toUpperCase()}
                    </span>
                  </div>
                  <div>
                    <p className="text-sm font-medium">{userProfile.displayName}</p>
                    <p className="text-xs text-muted-foreground">
                      {t('modules.community.posts.authorProfile')}
                    </p>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-muted-foreground">
                  {t('modules.community.posts.noProfileMessage')}
                </p>
              )}
            </div>
            {errors.profile && (
              <p className="text-sm text-destructive">{errors.profile}</p>
            )}
          </div>

          {/* Category */}
          <div className="space-y-2">
            <Label htmlFor="category">{t('modules.community.posts.category')}</Label>
            <Select
              value={formData.category}
              onValueChange={(value) => handleInputChange('category', value)}
            >
              <SelectTrigger className={errors.category ? 'border-destructive' : ''}>
                <SelectValue placeholder={t('modules.community.posts.selectCategory')} />
              </SelectTrigger>
              <SelectContent>
                {categories.map((category) => (
                  <SelectItem key={category.id} value={category.id}>
                    {category.name}
                    {category.isForAdminOnly && (
                      <span className="ml-2 text-xs text-muted-foreground">
                        ({t('modules.community.postCategories.adminOnly')})
                      </span>
                    )}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {errors.category && (
              <p className="text-sm text-destructive">{errors.category}</p>
            )}
          </div>

          {/* Body Content */}
          <div className="space-y-2">
            <Label htmlFor="body">{t('modules.community.posts.body')}</Label>
            <Textarea
              id="body"
              placeholder={t('modules.community.posts.bodyPlaceholder')}
              value={formData.body}
              onChange={(e) => handleInputChange('body', e.target.value)}
              className={`min-h-[120px] ${errors.body ? 'border-destructive' : ''}`}
            />
            {errors.body && (
              <p className="text-sm text-destructive">{errors.body}</p>
            )}
          </div>


        </form>

        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose}>
            {t('common.cancel')}
          </Button>
          <Button 
            type="submit" 
            disabled={isLoading || !userProfile}
            onClick={handleSubmit}
          >
            {isLoading ? t('common.creating') : t('common.create')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}