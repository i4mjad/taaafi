'use client';

import ContentPage from "@/modules/content/pages";
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from "@/contexts/TranslationContext";

export default function ContentRoute() {
  const { t, locale } = useTranslation();

  const headerDictionary = {
    documents: t('siteHeader.documents') || 'Documents',
  };
  
  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="p-6">
        <ContentPage t={t} locale={locale} />
      </div>
    </>
  );
} 