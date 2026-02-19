/**
 * Shared utility for locale/language detection and normalization
 * Used across all Cloud Functions for consistent behavior
 */

/**
 * Get user's locale from user document with proper fallbacks
 * 
 * @param userData - Firestore user document data
 * @returns Normalized locale string: 'english' or 'arabic'
 * 
 * @example
 * const locale = getUserLocale(userData);
 * // Returns: 'english' or 'arabic'
 */
export function getUserLocale(userData: any): 'english' | 'arabic' {
  // Check both possible fields (language has priority, then locale)
  const rawLocale = userData?.language || userData?.locale || 'en';
  
  // Normalize to 'english' or 'arabic'
  return normalizeLocale(rawLocale);
}

/**
 * Normalize any locale string to 'english' or 'arabic'
 * Handles various formats: 'en', 'ar', 'english', 'arabic', 'en-US', 'ar-SA', etc.
 * 
 * @param locale - Raw locale string
 * @returns Normalized locale: 'english' or 'arabic'
 * 
 * @example
 * normalizeLocale('ar')       // 'arabic'
 * normalizeLocale('arabic')   // 'arabic'
 * normalizeLocale('Arabic')   // 'arabic'
 * normalizeLocale('ar-SA')    // 'arabic'
 * normalizeLocale('en')       // 'english'
 * normalizeLocale('english')  // 'english'
 * normalizeLocale('en-US')    // 'english'
 * normalizeLocale(null)       // 'english' (default)
 */
export function normalizeLocale(locale: string | null | undefined): 'english' | 'arabic' {
  if (!locale) {
    return 'english';
  }
  
  // Convert to lowercase for case-insensitive comparison
  const lowerLocale = String(locale).toLowerCase();
  
  // Check if it contains 'ar' (catches: 'ar', 'arabic', 'ar-SA', 'Arabic', etc.)
  if (lowerLocale.includes('ar')) {
    return 'arabic';
  }
  
  // Everything else defaults to English
  return 'english';
}

/**
 * Get language code ('en' or 'ar') from any locale format
 * Useful for translation systems that use 2-letter codes
 * 
 * @param locale - Raw locale string or normalized locale
 * @returns Language code: 'en' or 'ar'
 * 
 * @example
 * getLanguageCode('english')  // 'en'
 * getLanguageCode('arabic')   // 'ar'
 * getLanguageCode('ar-SA')    // 'ar'
 * getLanguageCode('en-US')    // 'en'
 */
export function getLanguageCode(locale: string | null | undefined): 'en' | 'ar' {
  const normalized = normalizeLocale(locale);
  return normalized === 'arabic' ? 'ar' : 'en';
}

/**
 * Check if a locale represents Arabic
 * 
 * @param locale - Locale string to check
 * @returns true if locale is Arabic, false otherwise
 */
export function isArabicLocale(locale: string | null | undefined): boolean {
  return normalizeLocale(locale) === 'arabic';
}

/**
 * Check if a locale represents English
 * 
 * @param locale - Locale string to check
 * @returns true if locale is English, false otherwise
 */
export function isEnglishLocale(locale: string | null | undefined): boolean {
  return normalizeLocale(locale) === 'english';
}

