'use client';

import { useTranslation } from "@/contexts/TranslationContext";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import PostCategoriesManagement from "./components/PostCategoryForm";

export default function ForumPage() {
  const { t } = useTranslation();

  return (
    <div className="p-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">{t('appSidebar.forum')}</h1>
        <p className="text-muted-foreground">
          {t('modules.community.forumDescription')}
        </p>
      </div>
      
      <Tabs defaultValue="categories" className="w-full">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="categories">{t('modules.community.postCategories.title')}</TabsTrigger>
          <TabsTrigger value="management">{t('modules.community.forumManagement')}</TabsTrigger>
        </TabsList>
        
        <TabsContent value="categories" className="space-y-4">
          <PostCategoriesManagement />
        </TabsContent>
        
        <TabsContent value="management" className="space-y-4">
          <div className="rounded-lg border p-8 text-center">
            <h2 className="text-xl font-semibold mb-2">{t('modules.community.forumManagement')}</h2>
            <p className="text-muted-foreground">
              {t('modules.community.forumManagementDescription')}
            </p>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
} 