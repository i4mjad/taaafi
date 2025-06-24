'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { Locale } from '../../i18n.config';

type TranslationFunction = (key: string) => string;

interface TranslationContextType {
  t: TranslationFunction;
  locale: Locale;
  isLoading: boolean;
}

const TranslationContext = createContext<TranslationContextType | undefined>(undefined);

interface TranslationProviderProps {
  children: React.ReactNode;
  locale: Locale;
  initialDictionary: Record<string, any>;
}

export function TranslationProvider({ children, locale, initialDictionary }: TranslationProviderProps) {
  const [dictionary, setDictionary] = useState(initialDictionary);
  const [isLoading, setIsLoading] = useState(false);

  // Create translation function
  const t: TranslationFunction = (key: string) => {
    const keys = key.split('.');
    let value: any = dictionary;
    
    for (const k of keys) {
      value = value?.[k];
    }
    
    return typeof value === 'string' ? value : key;
  };

  // Update dictionary when locale changes
  useEffect(() => {
    if (!dictionary) {
      setIsLoading(true);
      // This would typically load the dictionary dynamically
      // For now, we'll use the initial dictionary
      setIsLoading(false);
    }
  }, [locale, dictionary]);

  const contextValue: TranslationContextType = {
    t,
    locale,
    isLoading,
  };

  return (
    <TranslationContext.Provider value={contextValue}>
      {children}
    </TranslationContext.Provider>
  );
}

export function useTranslation(): TranslationContextType {
  const context = useContext(TranslationContext);
  if (context === undefined) {
    throw new Error('useTranslation must be used within a TranslationProvider');
  }
  return context;
} 