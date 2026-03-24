'use client';

import { SiteHeader } from '@/components/site-header';
import { useTranslation } from '@/contexts/TranslationContext';
import { ForceUpdateSettings } from './components/ForceUpdateSettings';

export default function ForceUpdatePage() {
  const { t } = useTranslation();

  return (
    <>
      <SiteHeader title={t('modules.features.forceUpdate.title')} />
      <div className="flex flex-1 flex-col">
        <div className="@container/main flex flex-1 flex-col gap-2">
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
            <div>
              <h2 className="text-3xl font-bold tracking-tight">
                {t('modules.features.forceUpdate.title')}
              </h2>
              <p className="text-muted-foreground">
                {t('modules.features.forceUpdate.description')}
              </p>
            </div>
            <ForceUpdateSettings />
          </div>
        </div>
      </div>
    </>
  );
}
