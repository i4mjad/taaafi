'use client';

import FeatureFlagsPage from "@/modules/features/pages";
import { useTranslation } from "@/contexts/TranslationContext";

export default function FeaturesRoute() {
  const { t, locale } = useTranslation();
  
  return <FeatureFlagsPage t={t} locale={locale} />;
} 