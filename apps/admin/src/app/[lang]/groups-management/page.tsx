'use client';

import GroupsManagementPage from "@/modules/groups-management/pages";
import { useTranslation } from "@/contexts/TranslationContext";
import { SiteHeader } from '@/components/site-header';

export default function GroupsManagementRoute() {
  const { t, locale } = useTranslation();
  
  const headerDictionary = {
    documents: t('modules.groupsManagement.title') || 'Groups Management',
  };
  
  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <GroupsManagementPage t={t} locale={locale} />
    </>
  );
}
