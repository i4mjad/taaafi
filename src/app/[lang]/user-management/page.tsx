'use client';

import UserManagementPage from "@/modules/user_management/pages";
import { useTranslation } from "@/contexts/TranslationContext";

export default function UserManagementRoute() {
  const { t, locale } = useTranslation();
  
  return <UserManagementPage t={t} locale={locale} />;
} 