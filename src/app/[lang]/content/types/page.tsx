'use client';

import { useTranslation } from "@/contexts/TranslationContext";

export default function ContentTypesPage() {
  const { t } = useTranslation();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">{t('sidebar.contentTypes')}</h1>
        <p className="text-muted-foreground">
          {t('modules.content.typesDescription') || 'Manage different types of content (articles, videos, resources)'}
        </p>
      </div>
      
      <div className="rounded-lg border p-8 text-center">
        <h2 className="text-xl font-semibold mb-2">Content Types Management</h2>
        <p className="text-muted-foreground">
          Content types configuration interface will be implemented here.
        </p>
      </div>
    </div>
  );
} 