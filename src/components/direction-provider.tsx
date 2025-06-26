'use client';

import React from 'react';
import { DirectionProvider } from '@radix-ui/react-direction';
import { Locale } from '../../i18n.config';

interface DirectionWrapperProps {
  children: React.ReactNode;
  locale: Locale;
}

export function DirectionWrapper({ children, locale }: DirectionWrapperProps) {
  const dir = locale === 'ar' ? 'rtl' : 'ltr';
  
  return (
    <DirectionProvider dir={dir}>
      {children}
    </DirectionProvider>
  );
} 