import "server-only";
import { Locale } from "../../i18n.config";

// Dictionary loading function
export async function getDictionary(locale: Locale) {
  try {
    const dictionary = await import(`@/locales/${locale}.json`);
    return dictionary.default;
  } catch (error) {
    console.warn(`Dictionary for locale ${locale} not found, falling back to Arabic`);
    const fallback = await import(`@/locales/ar.json`);
    return fallback.default;
  }
}

// Translation function factory
export function createTranslationFunction(dictionary: Record<string, any>) {
  return (key: string): string => {
    const keys = key.split('.');
    let value: any = dictionary;
    
    for (const k of keys) {
      value = value?.[k];
    }
    
    return typeof value === 'string' ? value : key;
  };
} 