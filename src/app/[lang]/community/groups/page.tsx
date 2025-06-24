'use client';

import { useTranslation } from "@/contexts/TranslationContext";

export default function GroupsPage() {
  const { t } = useTranslation();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">{t('sidebar.groups')}</h1>
        <p className="text-muted-foreground">
          {t('modules.community.groupsDescription') || 'Manage support groups and communities'}
        </p>
      </div>
      
      <div className="rounded-lg border p-8 text-center">
        <h2 className="text-xl font-semibold mb-2">Groups Management</h2>
        <p className="text-muted-foreground">
          Support groups management interface will be implemented here.
        </p>
      </div>
    </div>
  );
} 