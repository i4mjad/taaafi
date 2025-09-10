import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';

// Set global options for all functions
setGlobalOptions({
  region: 'us-central1',
  memory: '1GiB',
  timeoutSeconds: 30,
  maxInstances: 50
});

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Initialize OpenAI
const openai = new OpenAI({
  apiKey: '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', 
});

/**
 * TypeScript Interfaces
 */
interface MessageData {
  body: string;
  senderCpId: string;
  groupId: string;
  createdAt: admin.firestore.Timestamp;
  attachments?: any;
  [key: string]: any;
}

interface UserProfile {
  userUID: string;
  locale?: 'arabic' | 'english';
  [key: string]: any;
}

interface LocalizedMessages {
  arabic: {
    [key: string]: string;
  };
  english: {
    [key: string]: string;
  };
}

interface ModerationStatus {
  status: 'pending' | 'approved' | 'blocked' | 'manual_review';
  reason: string | null;
}

interface OpenAIModerationResult {
  shouldBlock: boolean;
  violationType: 'social_media_sharing' | 'sexual_content' | 'cuckoldry_content' | 'homosexuality_content' | 'none';
  severity: 'low' | 'medium' | 'high';
  confidence: number;
  reason: string;
  detectedContent: string[];
  culturalContext?: string;
  processingTime?: number;
}

interface CharMapping {
  originalIndex: number;
  normalizedIndex: number;
}

interface NormalizedText {
  original: string;
  normalized: string;
  charMap: CharMapping[];
}

interface CustomRuleResult {
  detected: boolean;
  type: 'social_media_sharing' | 'sexual_content' | 'cuckoldry_content' | 'homosexuality_content';
  severity: 'low' | 'medium' | 'high';
  confidence: number;
  reason: string;
  detectedSpans: Array<{start: number; end: number; content: string}>;
}

interface FinalModerationDecision {
  action: 'block' | 'review' | 'allow_with_redaction' | 'allow';
  reason: string;
  violationType?: string;
  confidence: number;
  redactionSpans?: Array<{start: number; end: number}>;
  processingDetails: {
    openaiUsed: boolean;
    customRulesUsed: boolean;
    processingTime: number;
  };
}


/**
 * Localized violation messages
 */
const LOCALIZED_MESSAGES: LocalizedMessages = {
  arabic: {
    social_media_sharing: 'مشاركة حسابات وسائل التواصل الاجتماعي غير مسموحة',
    sexual_content: 'المحتوى الجنسي غير مسموح',
    cuckoldry_content: 'المحتوى غير اللائق غير مسموح',
    homosexuality_content: 'المحتوى غير المناسب غير مسموح',
    harassment: 'المضايقة والتحرش غير مسموح',
    hate: 'خطاب الكراهية غير مسموح',
    illicit: 'المحتوى غير القانوني غير مسموح',
    system_error: 'خطأ في النظام - تحت المراجعة',
    manual_review: 'رسالتك تحت المراجعة من قبل الإدارة'
  },
  english: {
    social_media_sharing: 'Sharing social media accounts is not allowed',
    sexual_content: 'Sexual content is not allowed',
    cuckoldry_content: 'Inappropriate sexual content is not allowed',
    homosexuality_content: 'Inappropriate content is not allowed',
    harassment: 'Harassment content is not allowed',
    hate: 'Hate speech is not allowed',
    illicit: 'Illicit content is not allowed',
    system_error: 'System error - under review',
    manual_review: 'Your message is under review by moderators'
  }
};


/**
 * Normalize Arabic text with character index mapping
 * Step 1: Remove diacritics, zero-width chars, tatweel, unify letters, convert numbers, collapse spaces
 */
function normalizeArabicText(text: string): NormalizedText {
  console.log('🔧 Starting Arabic text normalization...');
  
  const original = text;
  const charMap: CharMapping[] = [];
  let normalized = '';
  let normalizedIndex = 0;

  for (let i = 0; i < original.length; i++) {
    const char = original[i];
    let processedChar = char;

    // Remove diacritics (Arabic diacritical marks)
    if (/[\u064B-\u065F\u0670\u0671]/.test(char)) {
      // Skip diacritics - don't add to normalized text
      continue;
    }

    // Remove zero-width characters
    if (/[\u200B-\u200F\u2060\u2061\u2062\u2063\u2064\u2065\u2066\u2067\u2068\u2069\u061C]/.test(char)) {
      // Skip zero-width chars
      continue;
    }

    // Remove Arabic tatweel (kashida)
    if (char === '\u0640') {
      continue;
    }

    // Unify Arabic letters
    // Alif variations: أإآ → ا
    if (/[أإآ]/.test(char)) {
      processedChar = 'ا';
    }
    // Ya variations: ى → ي
    else if (char === 'ى') {
      processedChar = 'ي';
    }
    // Ta marbuta: ة → ه (optional normalization)
    else if (char === 'ة') {
      processedChar = 'ه';
    }

    // Convert Arabic-Indic digits to Western digits
    const arabicToWestern: {[key: string]: string} = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9'
    };
    if (arabicToWestern[char]) {
      processedChar = arabicToWestern[char];
    }

    // Add character mapping
    charMap.push({
      originalIndex: i,
      normalizedIndex: normalizedIndex
    });

    normalized += processedChar;
    normalizedIndex++;
  }

  // Collapse extra spaces and punctuation
  normalized = normalized
    .replace(/\s+/g, ' ') // Multiple spaces to single space
    .replace(/[.]{2,}/g, '.') // Multiple dots to single dot
    .replace(/[!]{2,}/g, '!') // Multiple exclamations to single
    .replace(/[?]{2,}/g, '?') // Multiple questions to single
    .trim();

  console.log(`✅ Normalization complete: ${original.length} → ${normalized.length} chars`);
  
  return {
    original,
    normalized,
    charMap
  };
}

/**
 * De-obfuscate common tokens (platform names, handles, etc.)
 * Step 2: Collapse spaced/dotted platform names and handles
 */
function deobfuscateTokens(text: string): string {
  console.log('🕵️ Starting token de-obfuscation...');
  
  let deobfuscated = text;

  // Platform names with spaces/dots
  const platformPatterns = [
    // English platforms with spaces/dots
    { pattern: /w\s*a\s*\.\s*m\s*e/gi, replacement: 'wa.me' },
    { pattern: /i\s*n\s*s\s*t\s*a\s*g\s*r\s*a\s*m/gi, replacement: 'instagram' },
    { pattern: /f\s*a\s*c\s*e\s*b\s*o\s*o\s*k/gi, replacement: 'facebook' },
    { pattern: /w\s*h\s*a\s*t\s*s\s*a\s*p\s*p/gi, replacement: 'whatsapp' },
    { pattern: /t\s*e\s*l\s*e\s*g\s*r\s*a\s*m/gi, replacement: 'telegram' },
    { pattern: /t\s*i\s*k\s*t\s*o\s*k/gi, replacement: 'tiktok' },
    { pattern: /s\s*n\s*a\s*p\s*c\s*h\s*a\s*t/gi, replacement: 'snapchat' },
    
    // Arabic platforms with spaces
    { pattern: /ت\s*ل\s*ي\s*ج\s*ر\s*ا\s*م/g, replacement: 'تليجرام' },
    { pattern: /ا\s*ن\s*س\s*ت\s*ق\s*ر\s*ا\s*م/g, replacement: 'انستقرام' },
    { pattern: /ا\s*ن\s*س\s*ت\s*ا/g, replacement: 'انستا' },
    { pattern: /ف\s*ي\s*س\s*ب\s*و\s*ك/g, replacement: 'فيسبوك' },
    { pattern: /و\s*ا\s*ت\s*س\s*ا\s*ب/g, replacement: 'واتساب' },
    { pattern: /س\s*ن\s*ا\s*ب\s*ش\s*ا\s*ت/g, replacement: 'سناب شات' },
    { pattern: /ت\s*ي\s*ك\s*ت\s*و\s*ك/g, replacement: 'تيك توك' },
  ];

  // Apply platform de-obfuscation
  for (const { pattern, replacement } of platformPatterns) {
    deobfuscated = deobfuscated.replace(pattern, replacement);
  }

  // Handle spaced @ mentions: @ a m j a d → @amjad
  deobfuscated = deobfuscated.replace(/@\s+([a-zA-Z0-9_]+(?:\s+[a-zA-Z0-9_]+)*)/g, (match, username) => {
    const cleanUsername = username.replace(/\s+/g, '');
    return `@${cleanUsername}`;
  });

  // Handle spaced usernames without @
  deobfuscated = deobfuscated.replace(/\b([a-zA-Z0-9_]+(?:\s+[a-zA-Z0-9_]+){2,})\b/g, (match) => {
    // Only if it looks like a username (3+ parts, alphanumeric)
    const parts = match.split(/\s+/);
    if (parts.length >= 3 && parts.every(part => /^[a-zA-Z0-9_]+$/.test(part))) {
      return parts.join('');
    }
    return match;
  });

  // Handle dotted domains: wa . me → wa.me
  deobfuscated = deobfuscated.replace(/\b([a-zA-Z0-9]+(?:\s*\.\s*[a-zA-Z0-9]+)+)\b/g, (match) => {
    return match.replace(/\s*\.\s*/g, '.');
  });

  console.log('✅ Token de-obfuscation complete');
  return deobfuscated;
}

/**
 * Custom rule patterns for Arabic content (applied to normalized text)
 */
const CUSTOM_RULE_PATTERNS = {
  socialMedia: {
    platforms: [
      'انستقرام', 'انستا', 'instagram', 'insta',
      'فيسبوك', 'فيس', 'facebook', 'fb',
      'تيك توك', 'tiktok',
      'سناب شات', 'سناب', 'snapchat', 'snap',
      'واتساب', 'whatsapp', 'واتس',
      'تليجرام', 'telegram',
      'wa.me', 'حساب', 'اكاونت', 'account'
    ],
    followPhrases: [
      'تابعوني على', 'ضيفوني على', 'اكاونتي على', 'حسابي في',
      'شوفوني على', 'لقوني على', 'follow me on', 'add me on',
      'ممكن نتواصل', 'نتواصل بطريقة أخرى', 'نتكلم في مكان آخر'
    ],
    usernamePatterns: [
      /@[a-zA-Z0-9_.]+/,
      /[a-zA-Z0-9_.]+\.(com|net|org|me)/,
      /\b[a-zA-Z0-9_.]{3,}\b/
    ]
  },
  sexual: {
    explicit: [
      'جنس', 'عري', 'إباحي', 'sex', 'porn', 'nude',
      'زب', 'كس', 'نيك', 'طيز', 'سالب', 'موجب'
    ]
  },
  cuckoldry: {
    terms: ['ديوث', 'قواد', 'يشارك زوجته', 'تبادل زوجات']
  },
  homosexuality: {
    terms: ['شاذ', 'شذوذ', 'مثلي', 'لوطي', 'خنيث', 'gay', 'lesbian']
  }
};

/**
 * Detect message language based on character analysis
 */
function detectMessageLanguage(text: string): 'arabic' | 'english' {
  console.log('🌐 Detecting message language...');
  
  // Count Arabic characters (including Arabic letters and Arabic-specific punctuation)
  const arabicCharsRegex = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]/g;
  const arabicMatches = text.match(arabicCharsRegex);
  const arabicCharCount = arabicMatches ? arabicMatches.length : 0;
  
  // Count English characters
  const englishCharsRegex = /[a-zA-Z]/g;
  const englishMatches = text.match(englishCharsRegex);
  const englishCharCount = englishMatches ? englishMatches.length : 0;
  
  // Calculate total meaningful characters
  const totalChars = arabicCharCount + englishCharCount;
  
  if (totalChars === 0) {
    console.log('⚠️ No meaningful characters detected, defaulting to Arabic');
    return 'arabic';
  }
  
  // Calculate Arabic percentage
  const arabicPercentage = (arabicCharCount / totalChars) * 100;
  
  console.log(`📊 Language detection: Arabic: ${arabicCharCount} chars (${arabicPercentage.toFixed(1)}%), English: ${englishCharCount} chars`);
  
  // If 30% or more Arabic characters, consider it Arabic
  const detectedLanguage = arabicPercentage >= 30 ? 'arabic' : 'english';
  console.log(`🌐 Detected language: ${detectedLanguage}`);
  
  return detectedLanguage;
}

/**
 * Moderation prompts for different languages
 */
const MODERATION_PROMPTS = {
  arabic: `أنت نظام مراقبة محتوى متخصص في تحليل الرسائل العربية. مهمتك تحليل النص المرفق والكشف عن المخالفات التالية فقط:

**المخالفات المطلوب رصدها:**

1. **مشاركة حسابات وسائل التواصل الاجتماعي** 
   - البحث عن عبارات مثل: "تابعوني على"، "ضيفوني على"، "حسابي في"، "اكاونتي على"
   - ذكر منصات مثل: انستقرام، فيسبوك، تيك توك، سناب شات، واتساب، تليجرام
   - محاولات التواصل الخارجي مثل: "ممكن نتواصل بطريقة أخرى"، "نتكلم في مكان آخر"
   - أسماء المستخدمين أو الروابط أو العبارات المشبوهة

2. **المحتوى الجنسي أو الإباحي**
   - الكلمات الصريحة والألفاظ الجنسية المباشرة
   - الإيحاءات الجنسية والعبارات المثيرة
   - طلب صور أو لقاءات خاصة
   - أي محتوى جنسي غير لائق

3. **محتوى الديوثة وتبادل الأزواج**
   - كلمات مثل: "ديوث"، "قواد"، "يشارك زوجته"، "تبادل زوجات"
   - أي محتوى يتعلق بالديوثة أو القيادة الجنسية
   - عبارات تدل على تبادل الشركاء

4. **المحتوى المثلي أو الشاذ جنسياً**
   - كلمات مثل: "شاذ"، "مثلي"، "لوطي"، "خنيث" 
   - البحث عن شركاء من نفس الجنس
   - أي محتوى يروج للشذوذ الجنسي

**إرشادات مهمة للتحليل:**
- انتبه للسياق الثقافي العربي والإسلامي
- فرق بين النقاش الأكاديمي المحترم (مسموح) والبحث الشخصي المخالف (ممنوع)
- راعي استخدام الحروف البديلة أو المتشابهة لتجنب الرقابة
- انتبه للكلمات المقسمة بمسافات أو رموز
- اعتبر شدة المخالفة (خفيفة، متوسطة، عالية)

**النص المطلوب تحليله:**
"{{MESSAGE_TEXT}}"

**المطلوب منك:**
أجب بصيغة JSON فقط دون أي نص إضافي:

{
  "shouldBlock": true/false,
  "violationType": "social_media_sharing" أو "sexual_content" أو "cuckoldry_content" أو "homosexuality_content" أو "none",
  "severity": "low" أو "medium" أو "high",
  "confidence": 0.0-1.0,
  "reason": "شرح مختصر بالعربية لسبب القرار",
  "detectedContent": ["قائمة بالعبارات أو الكلمات المخالفة المكتشفة"],
  "culturalContext": "ملاحظة عن السياق الثقافي إن وجد"
}`,

  english: `You are a content moderation system specialized in analyzing messages. Your task is to analyze the provided text and detect the following violations only:

**Required Violation Detection:**

1. **Social Media Account Sharing**
   - Look for phrases like: "follow me on", "add me on", "my account on", "find me on"
   - Platform mentions: Instagram, Facebook, TikTok, Snapchat, WhatsApp, Telegram
   - External communication attempts: "let's talk elsewhere", "contact me privately"
   - Usernames, links, or suspicious sharing patterns

2. **Sexual or Pornographic Content**
   - Explicit sexual words and direct sexual language
   - Sexual innuendos and suggestive phrases
   - Requests for photos or private meetings
   - Any inappropriate sexual content

3. **Cuckoldry and Partner Swapping Content**
   - Words like: "cuckold", "hotwife", "wife sharing", "partner swapping"
   - Any content related to cuckoldry or sexual pimping
   - Expressions indicating partner exchange

4. **Homosexual or LGBTQ+ Content**
   - Words like: "gay", "lesbian", "queer", seeking same-sex partners
   - Looking for same-gender partners
   - Any content promoting LGBTQ+ relationships

**Important Analysis Guidelines:**
- Consider cultural and religious context (Islamic/Arab culture)
- Distinguish between respectful academic discussion (allowed) vs. personal seeking (forbidden)
- Watch for character substitution to avoid detection
- Pay attention to words separated by spaces or symbols
- Consider violation severity (low, medium, high)

**Text to Analyze:**
"{{MESSAGE_TEXT}}"

**Required Response:**
Respond with JSON only, no additional text:

{
  "shouldBlock": true/false,
  "violationType": "social_media_sharing" or "sexual_content" or "cuckoldry_content" or "homosexuality_content" or "none",
  "severity": "low" or "medium" or "high",
  "confidence": 0.0-1.0,
  "reason": "Brief explanation in English for the decision",
  "detectedContent": ["List of detected violating phrases or words"],
  "culturalContext": "Note about cultural context if applicable"
}`
};

/**
 * Get user locale from community profile
 */
async function getUserLocale(senderCpId: string): Promise<'arabic' | 'english'> {
  try {
    console.log('🌐 Getting user locale for:', senderCpId);
    
    const profileDoc = await admin.firestore()
      .collection('community_profiles')
      .doc(senderCpId)
      .get();
    
    if (!profileDoc.exists) {
      console.log('⚠️ Community profile not found, defaulting to Arabic');
      return 'arabic';
    }
    
    const profileData = profileDoc.data() as UserProfile;
    const userUID = profileData.userUID;
    
    if (!userUID) {
      console.log('⚠️ UserUID not found, defaulting to Arabic');
      return 'arabic';
    }
    
    // Get user document to check locale
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userUID)
      .get();
    
    if (!userDoc.exists) {
      console.log('⚠️ User document not found, defaulting to Arabic');
      return 'arabic';
    }
    
    const userData = userDoc.data();
    const locale = userData?.locale || 'arabic';
    
    console.log('🌐 User locale determined:', locale);
    return locale === 'english' ? 'english' : 'arabic';
    
  } catch (error) {
    console.error('❌ Error getting user locale:', error);
    return 'arabic'; // Default to Arabic
  }
}

/**
 * Get localized violation message
 */
function getLocalizedMessage(violationType: string, locale: 'arabic' | 'english'): string {
  const messages = LOCALIZED_MESSAGES[locale];
  return messages[violationType] || messages.system_error;
}

/**
 * Evaluate custom rules on normalized text
 * Step 5: For each rule, detect → check intent → assign severity/confidence
 */
function evaluateCustomRules(normalizedText: string): CustomRuleResult[] {
  console.log('🔍 Evaluating custom rules on normalized text...');
  
  const results: CustomRuleResult[] = [];
  const lowerText = normalizedText.toLowerCase();

  // Social Media Sharing Rules
  console.log('📱 Checking social media sharing rules...');
  const socialMediaSpans: Array<{start: number; end: number; content: string}> = [];
  let socialMediaSeverity: 'low' | 'medium' | 'high' = 'low';
  let socialMediaConfidence = 0;

  // Check for follow phrases
  for (const phrase of CUSTOM_RULE_PATTERNS.socialMedia.followPhrases) {
    const phraseIndex = lowerText.indexOf(phrase.toLowerCase());
    if (phraseIndex !== -1) {
      socialMediaSpans.push({
        start: phraseIndex,
        end: phraseIndex + phrase.length,
        content: phrase
      });
      socialMediaSeverity = 'high';
      socialMediaConfidence = Math.max(socialMediaConfidence, 0.9);
    }
  }

  // Check for platform mentions
  for (const platform of CUSTOM_RULE_PATTERNS.socialMedia.platforms) {
    const platformIndex = lowerText.indexOf(platform.toLowerCase());
    if (platformIndex !== -1) {
      socialMediaSpans.push({
        start: platformIndex,
        end: platformIndex + platform.length,
        content: platform
      });
      socialMediaSeverity = socialMediaSeverity === 'high' ? 'high' : 'medium';
      socialMediaConfidence = Math.max(socialMediaConfidence, 0.7);
    }
  }

  // Check for username patterns
  for (const pattern of CUSTOM_RULE_PATTERNS.socialMedia.usernamePatterns) {
    const matches = normalizedText.matchAll(new RegExp(pattern, 'gi'));
    for (const match of matches) {
      if (match.index !== undefined) {
        socialMediaSpans.push({
          start: match.index,
          end: match.index + match[0].length,
          content: match[0]
        });
        socialMediaSeverity = socialMediaSeverity === 'high' ? 'high' : 'medium';
        socialMediaConfidence = Math.max(socialMediaConfidence, 0.6);
      }
    }
  }

  if (socialMediaSpans.length > 0) {
    results.push({
      detected: true,
      type: 'social_media_sharing',
      severity: socialMediaSeverity,
      confidence: socialMediaConfidence,
      reason: `Detected social media sharing indicators: ${socialMediaSpans.map(s => s.content).join(', ')}`,
      detectedSpans: socialMediaSpans
    });
  }

  // Sexual Content Rules
  console.log('🔞 Checking sexual content rules...');
  const sexualSpans: Array<{start: number; end: number; content: string}> = [];
  let sexualConfidence = 0;

  for (const term of CUSTOM_RULE_PATTERNS.sexual.explicit) {
    const termIndex = lowerText.indexOf(term.toLowerCase());
    if (termIndex !== -1) {
      sexualSpans.push({
        start: termIndex,
        end: termIndex + term.length,
        content: term
      });
      sexualConfidence = Math.max(sexualConfidence, 0.95);
    }
  }

  if (sexualSpans.length > 0) {
    results.push({
      detected: true,
      type: 'sexual_content',
      severity: 'high',
      confidence: sexualConfidence,
      reason: `Detected explicit sexual content: ${sexualSpans.map(s => s.content).join(', ')}`,
      detectedSpans: sexualSpans
    });
  }

  // Cuckoldry Content Rules
  console.log('🚫 Checking cuckoldry content rules...');
  const cuckoldrySpans: Array<{start: number; end: number; content: string}> = [];
  let cuckoldryConfidence = 0;

  for (const term of CUSTOM_RULE_PATTERNS.cuckoldry.terms) {
    const termIndex = lowerText.indexOf(term.toLowerCase());
    if (termIndex !== -1) {
      cuckoldrySpans.push({
        start: termIndex,
        end: termIndex + term.length,
        content: term
      });
      cuckoldryConfidence = Math.max(cuckoldryConfidence, 0.9);
    }
  }

  if (cuckoldrySpans.length > 0) {
    results.push({
      detected: true,
      type: 'cuckoldry_content',
      severity: 'high',
      confidence: cuckoldryConfidence,
      reason: `Detected cuckoldry content: ${cuckoldrySpans.map(s => s.content).join(', ')}`,
      detectedSpans: cuckoldrySpans
    });
  }

  // Homosexuality Content Rules
  console.log('🏳️‍🌈 Checking homosexuality content rules...');
  const homosexualitySpans: Array<{start: number; end: number; content: string}> = [];
  let homosexualityConfidence = 0;

  for (const term of CUSTOM_RULE_PATTERNS.homosexuality.terms) {
    const termIndex = lowerText.indexOf(term.toLowerCase());
    if (termIndex !== -1) {
      homosexualitySpans.push({
        start: termIndex,
        end: termIndex + term.length,
        content: term
      });
      homosexualityConfidence = Math.max(homosexualityConfidence, 0.9);
    }
  }

  if (homosexualitySpans.length > 0) {
    results.push({
      detected: true,
      type: 'homosexuality_content',
      severity: 'high',
      confidence: homosexualityConfidence,
      reason: `Detected inappropriate content: ${homosexualitySpans.map(s => s.content).join(', ')}`,
      detectedSpans: homosexualitySpans
    });
  }

  console.log(`✅ Custom rule evaluation complete: ${results.length} violations detected`);
  return results;
}

/**
 * Map normalized text spans back to original text indices
 * Step 7: Map spans back to original indices using char-index map
 */
function mapSpansToOriginal(
  normalizedSpans: Array<{start: number; end: number}>, 
  charMap: CharMapping[]
): Array<{start: number; end: number}> {
  console.log('🗺️ Mapping normalized spans back to original indices...');
  
  const originalSpans: Array<{start: number; end: number}> = [];

  for (const span of normalizedSpans) {
    // Find the original indices for start and end positions
    const startMapping = charMap.find(m => m.normalizedIndex === span.start);
    const endMapping = charMap.find(m => m.normalizedIndex === span.end - 1);

    if (startMapping && endMapping) {
      originalSpans.push({
        start: startMapping.originalIndex,
        end: endMapping.originalIndex + 1 // +1 to make it exclusive end
      });
    }
  }

  console.log(`✅ Mapped ${normalizedSpans.length} spans to original indices`);
  return originalSpans;
}

/**
 * Synthesize final moderation decision with fixed precedence
 * Step 6: block > review > allow_with_redaction > allow
 */
function synthesizeDecision(
  openaiResult: OpenAIModerationResult,
  customRuleResults: CustomRuleResult[],
  processingTime: number
): FinalModerationDecision {
  console.log('⚖️ Synthesizing final moderation decision...');
  
  // Hard-stop policy: Check OpenAI high-confidence violations first
  if (openaiResult.shouldBlock && (openaiResult.confidence >= 0.8 || openaiResult.severity === 'high')) {
    console.log('🚫 HARD STOP: High-confidence/severity OpenAI violation');
    return {
      action: 'block',
      reason: `OpenAI detected: ${openaiResult.reason}`,
      violationType: openaiResult.violationType,
      confidence: openaiResult.confidence,
      processingDetails: {
        openaiUsed: true,
        customRulesUsed: true,
        processingTime
      }
    };
  }

  // Check custom rules for high-severity violations
  const highSeverityRules = customRuleResults.filter(r => r.detected && r.severity === 'high');
  if (highSeverityRules.length > 0) {
    const highestConfidenceRule = highSeverityRules.reduce((max, rule) => 
      rule.confidence > max.confidence ? rule : max
    );

    if (highestConfidenceRule.confidence >= 0.9) {
      console.log('🚫 BLOCK: High-severity custom rule violation');
      return {
        action: 'block',
        reason: highestConfidenceRule.reason,
        violationType: highestConfidenceRule.type,
        confidence: highestConfidenceRule.confidence,
        processingDetails: {
          openaiUsed: true,
          customRulesUsed: true,
          processingTime
        }
      };
    }
  }

  // Check for review-worthy violations
  if (openaiResult.shouldBlock && (openaiResult.confidence >= 0.5 || openaiResult.severity === 'medium')) {
    console.log('⚠️ REVIEW: Medium-confidence/severity OpenAI violation');
    return {
      action: 'review',
      reason: `Requires review: ${openaiResult.reason}`,
      violationType: openaiResult.violationType,
      confidence: openaiResult.confidence,
      processingDetails: {
        openaiUsed: true,
        customRulesUsed: true,
        processingTime
      }
    };
  }

  const mediumSeverityRules = customRuleResults.filter(r => r.detected && (r.severity === 'medium' || r.severity === 'high'));
  if (mediumSeverityRules.length > 0) {
    const highestConfidenceRule = mediumSeverityRules.reduce((max, rule) => 
      rule.confidence > max.confidence ? rule : max
    );

    if (highestConfidenceRule.confidence >= 0.6) {
      console.log('⚠️ REVIEW: Custom rule requires review');
      return {
        action: 'review',
        reason: highestConfidenceRule.reason,
        violationType: highestConfidenceRule.type,
        confidence: highestConfidenceRule.confidence,
        processingDetails: {
          openaiUsed: true,
          customRulesUsed: true,
          processingTime
        }
      };
    }
  }

  // Check for redaction-worthy violations
  const lowSeverityRules = customRuleResults.filter(r => r.detected && r.severity === 'low');
  if (lowSeverityRules.length > 0) {
    console.log('✏️ ALLOW WITH REDACTION: Low-severity violations detected');
    
    const allSpans = lowSeverityRules.flatMap(rule => rule.detectedSpans);
    const redactionSpans = allSpans.map(span => ({ start: span.start, end: span.end }));

    return {
      action: 'allow_with_redaction',
      reason: `Content allowed with redaction of: ${lowSeverityRules.map(r => r.type).join(', ')}`,
      confidence: 0.7,
      redactionSpans,
      processingDetails: {
        openaiUsed: true,
        customRulesUsed: true,
        processingTime
      }
    };
  }

  // Default: Allow
  console.log('✅ ALLOW: No significant violations detected');
  return {
    action: 'allow',
    reason: 'Content appears acceptable',
    confidence: 1.0 - Math.max(openaiResult.confidence || 0, 0.3),
    processingDetails: {
      openaiUsed: true,
      customRulesUsed: true,
      processingTime
    }
  };
}


/**
 * Analyze content using OpenAI Chat Completions with custom prompts
 */
async function checkWithOpenAI(text: string): Promise<OpenAIModerationResult> {
  console.log('🤖 Starting OpenAI analysis with custom prompts...');
  
  try {
    // Step 1: Detect message language
    const detectedLanguage = detectMessageLanguage(text);
    console.log(`📤 Using ${detectedLanguage} prompt for analysis`);
    
    // Step 2: Get appropriate prompt and prepare it
    const promptTemplate = MODERATION_PROMPTS[detectedLanguage];
    const prompt = promptTemplate.replace('{{MESSAGE_TEXT}}', text);
    
    const startTime = Date.now();
    
    // Step 3: Send request to Chat Completions API
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // Cost-effective model with good Arabic support
      messages: [
        {
          role: 'system',
          content: 'You are a content moderation expert. Always respond with valid JSON only, no additional text or formatting.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.1, // Low temperature for consistent results
      max_tokens: 500,   // Enough for JSON response
      response_format: { type: 'json_object' } // Ensure JSON response
    });
    
    const processingTime = Date.now() - startTime;
    console.log(`⏱️ OpenAI processing completed in ${processingTime}ms`);
    
    // Step 4: Parse the response
    const responseContent = completion.choices[0]?.message?.content;
    if (!responseContent) {
      throw new Error('Empty response from OpenAI');
    }
    
    console.log('🤖 Raw OpenAI Response:', responseContent);
    
    // Step 5: Parse JSON response
    let parsedResponse: any;
    try {
      parsedResponse = JSON.parse(responseContent);
    } catch (parseError) {
      console.error('❌ Failed to parse OpenAI JSON response:', parseError);
      console.error('Raw response:', responseContent);
      throw new Error('Invalid JSON response from OpenAI');
    }
    
    // Step 6: Validate and structure the response
    const result: OpenAIModerationResult = {
      shouldBlock: parsedResponse.shouldBlock || false,
      violationType: parsedResponse.violationType || 'none',
      severity: parsedResponse.severity || 'low',
      confidence: Math.min(Math.max(parsedResponse.confidence || 0, 0), 1), // Clamp between 0-1
      reason: parsedResponse.reason || 'No specific reason provided',
      detectedContent: Array.isArray(parsedResponse.detectedContent) ? parsedResponse.detectedContent : [],
      culturalContext: parsedResponse.culturalContext || undefined,
      processingTime
    };
    
    console.log('✅ Structured OpenAI Result:', result);
    return result;
    
  } catch (error) {
    console.error('❌ OpenAI analysis failed:', error);
    
    // Return safe fallback result that triggers manual review
    return {
      shouldBlock: false, // Don't auto-block on errors
      violationType: 'none',
      severity: 'low',
      confidence: 0,
      reason: 'Analysis failed - requires manual review',
      detectedContent: [],
      processingTime: 0
    };
  }
}

/**
 * Main Cloud Function for Message Moderation (Firebase Functions v2)
 */
export const moderateMessage = onDocumentCreated(
  'group_messages/{messageId}',
  async (event) => {
    const functionStartTime = Date.now();
    const messageId = event.params?.messageId;
    const snap = event.data;
    
    if (!snap || !messageId) {
      console.error('❌ Invalid event data');
      return;
    }
    
    console.log('🚀 MODERATION STARTED for message:', messageId);
    console.log('📍 Function triggered at:', new Date().toISOString());
    
    try {
      const message = snap.data() as MessageData;
      console.log('📝 Message data retrieved:', {
        messageId,
        senderCpId: message.senderCpId,
        groupId: message.groupId,
        bodyLength: message.body?.length || 0,
        hasAttachments: !!message.attachments
      });

      // Get user locale for localized responses
      const userLocale = await getUserLocale(message.senderCpId);
      console.log('🌐 User locale:', userLocale);

      // Skip if message has no body
      if (!message.body || message.body.trim().length === 0) {
        console.log('⏭️ Skipping moderation - empty message body');
        await snap.ref.update({
          moderation: {
            status: 'approved',
            reason: null
          } as ModerationStatus
        });
        return;
      }

      console.log('🔍 Message content preview:', message.body.substring(0, 100) + '...');

      // ============================================
      // ENHANCED MODERATION PIPELINE (8 Steps)
      // ============================================
      
      try {
        const pipelineStartTime = Date.now();

        // Step 1: Normalize Arabic text; keep a char-index map
        console.log('\n=== STEP 1: TEXT NORMALIZATION ===');
        const normalizedResult = normalizeArabicText(message.body);
        console.log('📝 Original length:', normalizedResult.original.length);
        console.log('📝 Normalized length:', normalizedResult.normalized.length);

        // Step 2: De-obfuscate common tokens  
        console.log('\n=== STEP 2: TOKEN DE-OBFUSCATION ===');
        const deobfuscatedText = deobfuscateTokens(normalizedResult.normalized);
        console.log('🔍 De-obfuscated text preview:', deobfuscatedText.substring(0, 100) + '...');

        // Step 3: Run OpenAI moderation on RAW text
        console.log('\n=== STEP 3: OPENAI ANALYSIS (RAW TEXT) ===');
        const openaiResult = await checkWithOpenAI(message.body); // Use original raw text
        console.log('🤖 OpenAI result:', {
          shouldBlock: openaiResult.shouldBlock,
          violationType: openaiResult.violationType,
          confidence: openaiResult.confidence
        });

        // Step 4: Apply hard-stop policy using OpenAI scores
        console.log('\n=== STEP 4: HARD-STOP POLICY CHECK ===');
        if (openaiResult.shouldBlock && openaiResult.confidence >= 0.8) {
          console.log('🚫 HARD STOP TRIGGERED - Blocking immediately');
          
          const localizedReason = getLocalizedMessage(openaiResult.violationType, userLocale);
          await snap.ref.update({ 
            moderation: {
              status: 'blocked',
              reason: localizedReason
            } as ModerationStatus,
            isHidden: true
          });

          const processingTime = Date.now() - functionStartTime;
          console.log(`🏁 MODERATION COMPLETED (Hard Stop) in ${processingTime}ms`);
          return;
        }

        // Step 5: Evaluate custom rules on NORMALIZED text
        console.log('\n=== STEP 5: CUSTOM RULE EVALUATION ===');
        const customRuleResults = evaluateCustomRules(deobfuscatedText);
        console.log('📊 Custom rules detected:', customRuleResults.length, 'violations');

        // Step 6: Synthesize final decision with precedence
        console.log('\n=== STEP 6: DECISION SYNTHESIS ===');
        const finalDecision = synthesizeDecision(
          openaiResult,
          customRuleResults,
          Date.now() - pipelineStartTime
        );
        console.log('⚖️ Final decision:', finalDecision.action, 'confidence:', finalDecision.confidence);

        // Step 7: Handle redaction spans (if applicable)
        console.log('\n=== STEP 7: REDACTION PROCESSING ===');
        let originalRedactionSpans: Array<{start: number; end: number}> = [];
        
        if (finalDecision.action === 'allow_with_redaction' && finalDecision.redactionSpans) {
          originalRedactionSpans = mapSpansToOriginal(
            finalDecision.redactionSpans,
            normalizedResult.charMap
          );
          console.log('✏️ Mapped', finalDecision.redactionSpans.length, 'redaction spans to original text');
        }

        // Step 8: Emit final response with proper status alignment
        console.log('\n=== STEP 8: RESPONSE EMISSION ===');
        
        // Map decision actions to existing status system
        let finalStatus: ModerationStatus['status'] = 'approved';
        let localizedReason: string;
        let shouldHide = false;

        switch (finalDecision.action) {
          case 'block':
            finalStatus = 'blocked';
            shouldHide = true;
            localizedReason = getLocalizedMessage(finalDecision.violationType || 'system_error', userLocale);
            break;
          
          case 'review':
            finalStatus = 'manual_review';
            localizedReason = getLocalizedMessage('manual_review', userLocale);
            break;
          
          case 'allow_with_redaction':
            finalStatus = 'approved'; // Allow but with redaction info
            localizedReason = 'Content approved with redaction';
            break;
          
          case 'allow':
          default:
            finalStatus = 'approved';
            localizedReason = finalDecision.reason;
            break;
        }

        // Update message in database
        const updateData: any = {
          moderation: {
            status: finalStatus,
            reason: localizedReason
          } as ModerationStatus
        };

        if (shouldHide) {
          updateData.isHidden = true;
        }

        // Add redaction data if available (for future use)
        if (originalRedactionSpans.length > 0) {
          updateData.redactionSpans = originalRedactionSpans;
        }

        await snap.ref.update(updateData);
        console.log('✅ Database updated with final decision');

        // Add to manual review queue if needed
        if (finalStatus === 'manual_review') {
          console.log('📋 Adding to manual review queue...');
          await admin.firestore().collection('moderation_queue').add({
            messageId,
            groupId: message.groupId,
            senderCpId: message.senderCpId,
            messageBody: message.body,
            openaiAnalysis: openaiResult,
            customRuleResults: customRuleResults,
            finalDecision: finalDecision,
            priority: finalDecision.confidence >= 0.7 ? 'high' : 'medium',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
          console.log('✅ Added to manual review queue');
        }

      } catch (pipelineError) {
        console.error('❌ Moderation pipeline failed:', pipelineError);
        
        // Fallback to manual review on any pipeline error
        console.log('🔄 Falling back to manual review due to pipeline failure');
        const fallbackReason = getLocalizedMessage('system_error', userLocale);
        
        await snap.ref.update({
          moderation: {
            status: 'manual_review',
            reason: fallbackReason
          } as ModerationStatus
        });

        // Add to high priority manual review
        await admin.firestore().collection('moderation_queue').add({
          messageId,
          groupId: message.groupId,
          senderCpId: message.senderCpId,
          messageBody: message.body,
          error: (pipelineError as Error).message,
          priority: 'critical',
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      const totalProcessingTime = Date.now() - functionStartTime;
      console.log(`\n🏁 MODERATION COMPLETED in ${totalProcessingTime}ms`);
      console.log('📊 Final processing stats:', {
        messageId,
        totalTime: totalProcessingTime,
        pipelineUsed: 'enhanced-8-step',
        openaiModel: 'omni-moderation-2024-09-26',
        stepsCompleted: ['normalization', 'deobfuscation', 'openai_analysis', 'custom_rules', 'decision_synthesis']
      });

    } catch (error) {
      console.error('💥 CRITICAL ERROR in message moderation:', error);
      
      // Log error details
      console.error('Error details:', {
        messageId,
        error: (error as Error).message,
        stack: (error as Error).stack,
        timestamp: new Date().toISOString()
      });

      // Fallback to manual review for any unhandled errors
      try {
        // Get user locale for error message (fallback to arabic if failed)
        let errorLocale: 'arabic' | 'english' = 'arabic';
        try {
          const message = snap.data() as MessageData;
          if (message?.senderCpId) {
            errorLocale = await getUserLocale(message.senderCpId);
          }
        } catch (localeError) {
          console.log('⚠️ Could not get user locale for error message, using Arabic');
        }
        
        const errorReason = getLocalizedMessage('system_error', errorLocale);
        
        await snap.ref.update({
          moderation: {
            status: 'manual_review',
            reason: errorReason
          } as ModerationStatus
        });

        // Add to high priority queue
        await admin.firestore().collection('moderation_queue').add({
          messageId,
          error: (error as Error).message,
          priority: 'critical',
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log('🔄 Error handled: Message sent to manual review');
      } catch (fallbackError) {
        console.error('💀 CATASTROPHIC FAILURE: Could not even save error state:', fallbackError);
      }
    }
  });

// Export helper functions for testing
export { 
  checkWithOpenAI,
  detectMessageLanguage,
  normalizeArabicText,
  deobfuscateTokens,
  evaluateCustomRules,
  synthesizeDecision,
  mapSpansToOriginal
};
