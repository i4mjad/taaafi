'use client';

import { useTranslation } from "@/contexts/TranslationContext";

export default function ForumPage() {
  const { t } = useTranslation();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">{t('sidebar.forum')}</h1>
        <p className="text-muted-foreground">
          {t('modules.community.forumDescription')}
        </p>
      </div>
      
      <div className="rounded-lg border p-8 text-center">
        <h2 className="text-xl font-semibold mb-2">{t('modules.community.forumManagement')}</h2>
        <p className="text-muted-foreground">
          {t('modules.community.forumManagementDescription')}
        </p>
      </div>
    </div>
  );
} 