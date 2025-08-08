'use client';

import { useTranslation } from "@/contexts/TranslationContext";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import PostCategoriesManagement from "./components/PostCategoryForm";
import CommunityProfilesManagement from "./components/CommunityProfilesManagement";
import ForumPostsManagement from "./components/ForumPostsManagement";
import ForumCommentsManagement from "./components/ForumCommentsManagement";
import CommunityAnalytics from "./components/CommunityAnalytics";

export default function ForumPage() {
  const { t } = useTranslation();

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold tracking-tight">{t('appSidebar.forum')}</h1>
        <p className="text-muted-foreground">
          {t('modules.community.forumDescription')}
        </p>
      </div>
      
      <Tabs defaultValue="posts" className="w-full">
        <TabsList className="grid w-full grid-cols-5 mb-6">
          <TabsTrigger value="posts">{t('modules.community.posts.title')}</TabsTrigger>
          <TabsTrigger value="comments">{t('modules.community.comments.title')}</TabsTrigger>
          <TabsTrigger value="profiles">{t('modules.community.profiles.title')}</TabsTrigger>
          <TabsTrigger value="categories">{t('modules.community.postCategories.title')}</TabsTrigger>
          <TabsTrigger value="analytics">{t('modules.community.analytics.title')}</TabsTrigger>
        </TabsList>
        
        <TabsContent value="posts" className="space-y-4">
          <ForumPostsManagement />
        </TabsContent>
        <TabsContent value="comments" className="space-y-4">
          <ForumCommentsManagement />
        </TabsContent>
        
        <TabsContent value="profiles" className="space-y-4">
          <CommunityProfilesManagement />
        </TabsContent>
        
        <TabsContent value="categories" className="space-y-4">
          <PostCategoriesManagement />
        </TabsContent>
        
        <TabsContent value="analytics" className="space-y-4">
          <CommunityAnalytics />
        </TabsContent>
      </Tabs>
    </div>
  );
} 