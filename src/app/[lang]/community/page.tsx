'use client';

import CommunityPage from "@/modules/community/pages";
import { useTranslation } from "@/contexts/TranslationContext";

export default function CommunityRoute() {
  const { t, locale } = useTranslation();
  
  return <CommunityPage t={t} locale={locale} />;
} 