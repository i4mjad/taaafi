'use client';

import UserManagementPage from "@/modules/user_management/pages";
import { useTranslation } from "@/contexts/TranslationContext";
import { SiteHeader } from '@/components/site-header';

export default function UserManagementRoute() {
  const { t, locale } = useTranslation();
  
  const headerDictionary = {
    documents: t('appSidebar.userManagement') || 'User Management',
  };
  
  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <UserManagementPage t={t} locale={locale} />
    </>
  );
} 