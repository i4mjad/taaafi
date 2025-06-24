'use client';

import ContentPage from "@/modules/content/pages";
import { useTranslation } from "@/contexts/TranslationContext";

export default function ContentRoute() {
  const { t, locale } = useTranslation();
  
  return <ContentPage t={t} locale={locale} />;
} 