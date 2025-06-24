'use client';

import { useTranslation } from "@/contexts/TranslationContext";

export default function ContentCategoriesPage() {
  const { t } = useTranslation();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">{t('sidebar.categories')}</h1>
        <p className="text-muted-foreground">
          {t('modules.content.categoriesDescription') || 'Organize content into categories and topics'}
        </p>
      </div>
      
      <div className="rounded-lg border p-8 text-center">
        <h2 className="text-xl font-semibold mb-2">Categories Management</h2>
        <p className="text-muted-foreground">
          Content categories organization interface will be implemented here.
        </p>
      </div>
    </div>
  );
} 