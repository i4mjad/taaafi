'use client';

import FeatureFlagsPage from "@/modules/features/pages";
import { useTranslation } from "@/contexts/TranslationContext";
import { SiteHeader } from '@/components/site-header';

export default function FeaturesRoute() {
  const { t, locale } = useTranslation();
  
  const headerDictionary = {
    documents: t('appSidebar.features') || 'Features',
  };
  
  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <FeatureFlagsPage t={t} locale={locale} />
    </>
  );
} 