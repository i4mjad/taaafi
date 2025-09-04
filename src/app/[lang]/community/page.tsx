'use client';

import CommunityPage from "@/modules/community/pages";
import { useTranslation } from "@/contexts/TranslationContext";
import { SiteHeader } from '@/components/site-header';

export default function CommunityRoute() {
  const { t, locale } = useTranslation();
  
  const headerDictionary = {
    documents: t('appSidebar.community') || 'Community',
  };
  
  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <CommunityPage t={t} locale={locale} />
    </>
  );
} 