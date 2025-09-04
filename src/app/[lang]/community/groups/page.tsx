'use client';

import GroupsPage from "@/modules/groups/pages";
import { useTranslation } from "@/contexts/TranslationContext";
import { SiteHeader } from '@/components/site-header';

export default function GroupsRoute() {
  const { t, locale } = useTranslation();
  
  const headerDictionary = {
    documents: t('appSidebar.groups') || 'Groups',
  };
  
  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <GroupsPage t={t} locale={locale} />
    </>
  );
}
