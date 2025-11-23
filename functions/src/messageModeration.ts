import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { defineString } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';

// Define environment parameters
const openaiApiKey = defineString('OPENAI_API_KEY');

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

// Initialize OpenAI (will be initialized when the function runs)
let openai: OpenAI;

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
      // VERY SELECTIVE - Only block direct solicitation, not recovery discussion
      // These terms are only flagged when used in solicitation context, not educational
      // Note: Most sexual terms are ALLOWED in recovery context and handled by AI
    ]
  },
  cuckoldry: {
    // Only direct solicitation terms - discussion about these topics in recovery context is allowed
    directSolicitation: ['تعال أديثك', 'بدي قواد', 'come cuckold me']
  },
  homosexuality: {
    // Only direct solicitation terms - discussion about these topics in recovery context is allowed  
    directSolicitation: ['بحث عن شاب مثلي', 'looking for gay partner']
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
  arabic: `أنت نظام مراقبة محتوى متخصص في مجموعات الدعم للتعافي من إدمان المواد الإباحية. هذه مساحة آمنة للمتعافين لمشاركة تجاربهم وطلب المساعدة.

**السياق المهم:**
هذه مجموعة دعم للأشخاص الذين يتعافون من إدمان الأفلام الإباحية. الأعضاء يشاركون:
- رحلات التعافي والتحديات
- الانتكاسات والنجاحات  
- طلب النصائح والدعم
- مشاعرهم وتجاربهم الشخصية

**المحتوى المسموح (لا تحجبه):**
✅ مشاركة رحلات التعافي: "بديت رحلة التعافي من ٨ أشهر"
✅ الحديث عن الانتكاسات: "دخلت في سلسلة انتكاسات" 
✅ طلب الدعم والنصائح: "محتاج مساعدتكم"
✅ مشاركة المشاعر والتقدم: "رجعت لي مشاعري"
✅ ذكر الألفاظ الجنسية في سياق تعليمي أو علاجي
✅ النقاش الأكاديمي أو الطبي حول الإدمان
✅ تشجيع الآخرين ودعمهم
✅ رسائل إدارية/تنظيمية: "هو مفيش مكان"، "قوانين المعسكر قالت ممنوع برا"، "ممكن تعمل زمالة جديدة" — لا تعتبر مخالفة

**المخالفات المطلوب رصدها فقط:**

1. **الطلبات الجنسية المباشرة**
   - طلبات فعلية مثل: "تعال أديثك"، "بدي أنيكك"
   - طلب لقاءات جنسية حقيقية
   - عروض جنسية مباشرة (ليس مجرد ذكر كلمات في سياق التعافي)

2. **مشاركة وسائل التواصل للأغراض غير العلاجية**
   - "تابعوني على انستقرام" (للترفيه أو التجارة)
   - محاولات نقل المحادثة خارج المجموعة لأغراض شخصية
   - طلب التواصل الخاص بدون مبرر علاجي واضح

3. **إساءة استخدام المنصة**
   - استخدام المجموعة للتجارة أو الإعلانات
   - نشر محتوى لا علاقة له بالتعافي
   - السب والشتائم المباشرة للأعضاء

**إرشادات حاسمة:**
- السياق هو الأهم: نفس الكلمة قد تكون مقبولة في سياق التعافي ومرفوضة في سياق الطلب
- عند الشك أو عند كون الرسالة إدارية/تنظيمية، لا تحجب المحتوى — اجعل shouldBlock = false
- ركز على النية وليس فقط الكلمات
- هذه مساحة آمنة للمتعافين - احترم رحلتهم
- الهدف حماية المجموعة من سوء الاستخدام وليس منع النقاش الصحي
- لا تعتبر الرسائل التي تذكر القوانين أو المنع (مثل: "ممنوع برا"، "لا يسمح") كمخالفة؛ هذه رسائل إدارية

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
}

مهم: اجعل shouldBlock = true فقط عند (1) وجود طلب جنسي مباشر صريح، أو (2) مشاركة وسيلة تواصل خارجية مع نية شخصية غير علاجية واضحة (مثل "تابعوني على انستقرام" + اسم حساب). عند عدم وضوح النية أو عندما تكون الرسالة إدارية/تنظيمية أو تشير إلى القوانين ("ممنوع برا")، اجعل shouldBlock = false.`,

  english: `You are a content moderation system specialized in SUPPORT GROUPS for people recovering from pornography addiction. This is a safe space for recovering individuals to share their experiences and seek help.

**Important Context:**
This is a support group for people recovering from pornography addiction. Members share:
- Recovery journeys and challenges
- Relapses and successes
- Requests for advice and support  
- Their feelings and personal experiences

**ALLOWED Content (DO NOT block):**
✅ Recovery journey sharing: "Started my recovery 8 months ago"
✅ Discussing relapses: "I've been struggling with relapses"
✅ Asking for support: "I need your help"
✅ Sharing emotions and progress: "My feelings are returning"
✅ Mentioning sexual terms in educational or therapeutic context
✅ Academic or medical discussion about addiction
✅ Encouraging and supporting others
✅ Administrative/organizational messages: "no space available", "rules say not allowed outside", "you can create a new fellowship" — do NOT treat as violations

**VIOLATIONS to Detect ONLY:**

1. **Direct Sexual Requests**
   - Actual requests like: "come cuckold me", "let's have sex"
   - Requests for real sexual encounters
   - Direct sexual propositions (not just mentioning words in recovery context)

2. **Social Media Sharing for Non-Therapeutic Purposes**
   - "Follow me on Instagram" (for entertainment or business)
   - Attempts to move conversation outside group for personal reasons
   - Requesting private contact without clear therapeutic justification

3. **Platform Misuse**
   - Using the group for commerce or advertisements
   - Posting content unrelated to recovery
   - Direct insults and profanity toward members

**Critical Guidelines:**
- Context is everything: same word might be acceptable in recovery context but inappropriate in solicitation context
- When in doubt or when the message is administrative/organizational, do NOT block — set shouldBlock = false
- Focus on intent, not just words
- This is a safe space for recovering individuals - respect their journey
- Goal is protecting group from misuse, not preventing healthy discussion
 - Do not treat messages mentioning rules or prohibitions (e.g., "not allowed outside", "rules say no") as violations; these are administrative

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
}

Important: Set shouldBlock = true only when (1) there is a direct, explicit sexual request, OR (2) explicit sharing of external contact (handles/links) with clear non-therapeutic intent to move the conversation outside the group. If intent is unclear or the message is administrative/organizational, set shouldBlock = false.`
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
  console.log('🔍 Evaluating custom rules on normalized text for SUPPORT GROUP context...');
  console.log('⚠️ Note: This is a recovery support group - being conservative with rule enforcement');
  
  const results: CustomRuleResult[] = [];
  const lowerText = normalizedText.toLowerCase();

  // Social Media Sharing Rules
  console.log('📱 Checking social media sharing rules...');
  const socialMediaSpans: Array<{start: number; end: number; content: string}> = [];
  const followSpans: Array<{start: number; end: number; content: string}> = [];
  const platformSpans: Array<{start: number; end: number; content: string}> = [];
  const handleSpans: Array<{start: number; end: number; content: string}> = [];

  // Administrative context keywords to avoid false positives
  const adminContextRegex = /(ممنوع|قوانين|غير مسموح|محظور|تعليمات|لوائح|not allowed|rules?)/i;
  const outsideContextRegex = /(برا|خارج|outside)/i;
  const isAdministrativeContext = adminContextRegex.test(normalizedText) && outsideContextRegex.test(normalizedText);

  // Check for follow/contact intent phrases
  for (const phrase of CUSTOM_RULE_PATTERNS.socialMedia.followPhrases) {
    const idx = lowerText.indexOf(phrase.toLowerCase());
    if (idx !== -1) {
      followSpans.push({ start: idx, end: idx + phrase.length, content: phrase });
    }
  }

  // Check for platform mentions
  for (const platform of CUSTOM_RULE_PATTERNS.socialMedia.platforms) {
    const idx = lowerText.indexOf(platform.toLowerCase());
    if (idx !== -1) {
      platformSpans.push({ start: idx, end: idx + platform.length, content: platform });
    }
  }

  // Check for usernames/links
  for (const pattern of CUSTOM_RULE_PATTERNS.socialMedia.usernamePatterns) {
    const matches = normalizedText.matchAll(new RegExp(pattern, 'gi'));
    for (const match of matches) {
      if (match.index !== undefined) {
        handleSpans.push({ start: match.index, end: match.index + match[0].length, content: match[0] });
      }
    }
  }

  const hasIntent = followSpans.length > 0;
  const hasContactToken = platformSpans.length > 0 || handleSpans.length > 0;

  if (!isAdministrativeContext && hasIntent && hasContactToken) {
    // Only consider as violation when intent + contact token are both present
    const combinedSpans = [...followSpans, ...platformSpans, ...handleSpans];
    socialMediaSpans.push(...combinedSpans);
    results.push({
      detected: true,
      type: 'social_media_sharing',
      severity: 'high',
      confidence: 0.9,
      reason: `Detected non-therapeutic contact intent with platform/handle: ${combinedSpans.map(s => s.content).join(', ')}`,
      detectedSpans: combinedSpans
    });
  }

  // Sexual Content Rules - SUPPORT GROUP CONTEXT: Only direct solicitation
  console.log('🔞 Checking for direct sexual solicitation (not recovery discussion)...');
  // NOTE: Most sexual terms are ALLOWED in recovery context - AI handles context
  // Custom rules only catch obvious solicitation patterns
  
  // Cuckoldry Content Rules - Only Direct Solicitation
  console.log('🚫 Checking for direct cuckoldry solicitation...');
  const cuckoldrySpans: Array<{start: number; end: number; content: string}> = [];
  let cuckoldryConfidence = 0;

  for (const term of CUSTOM_RULE_PATTERNS.cuckoldry.directSolicitation) {
    const termIndex = lowerText.indexOf(term.toLowerCase());
    if (termIndex !== -1) {
      cuckoldrySpans.push({
        start: termIndex,
        end: termIndex + term.length,
        content: term
      });
      cuckoldryConfidence = Math.max(cuckoldryConfidence, 0.95);
      console.log('🚨 DIRECT CUCKOLDRY SOLICITATION detected:', term);
    }
  }

  if (cuckoldrySpans.length > 0) {
    results.push({
      detected: true,
      type: 'cuckoldry_content',
      severity: 'high',
      confidence: cuckoldryConfidence,
      reason: `Direct cuckoldry solicitation detected: ${cuckoldrySpans.map(s => s.content).join(', ')}`,
      detectedSpans: cuckoldrySpans
    });
  }

  // Homosexuality Content Rules - Only Direct Solicitation
  console.log('🏳️‍🌈 Checking for direct homosexual solicitation...');
  const homosexualitySpans: Array<{start: number; end: number; content: string}> = [];
  let homosexualityConfidence = 0;

  for (const term of CUSTOM_RULE_PATTERNS.homosexuality.directSolicitation) {
    const termIndex = lowerText.indexOf(term.toLowerCase());
    if (termIndex !== -1) {
      homosexualitySpans.push({
        start: termIndex,
        end: termIndex + term.length,
        content: term
      });
      homosexualityConfidence = Math.max(homosexualityConfidence, 0.95);
      console.log('🚨 DIRECT HOMOSEXUAL SOLICITATION detected:', term);
    }
  }

  if (homosexualitySpans.length > 0) {
    results.push({
      detected: true,
      type: 'homosexuality_content',
      severity: 'high',
      confidence: homosexualityConfidence,
      reason: `Direct homosexual solicitation detected: ${homosexualitySpans.map(s => s.content).join(', ')}`,
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
  
  // New policy: never auto-block. If any detection occurs, route to manual review.
  const anyCustomDetection = customRuleResults.some(r => r.detected);
  if (openaiResult.shouldBlock || anyCustomDetection) {
    console.log('⚠️ REVIEW: Detection present (OpenAI or custom rules). Routing to manual review.');
    const reason = openaiResult.shouldBlock
      ? `Requires review: ${openaiResult.reason}`
      : customRuleResults.find(r => r.detected)?.reason || 'Requires review based on custom rules';
    const violationType = openaiResult.shouldBlock
      ? openaiResult.violationType
      : customRuleResults.find(r => r.detected)?.type;
    const confidence = Math.max(
      openaiResult.confidence || 0,
      ...customRuleResults.filter(r => r.detected).map(r => r.confidence || 0),
      0.6
    );
    return {
      action: 'review',
      reason,
      violationType,
      confidence,
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
    confidence: 1.0,
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
  
  // Initialize OpenAI client if not already initialized
  if (!openai) {
    const apiKey = openaiApiKey.value();
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY is not configured');
    }
    openai = new OpenAI({ apiKey });
    console.log('✅ OpenAI client initialized');
  }
  
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
      // SUPPORT GROUP MODERATION PIPELINE (8 Steps)
      // Specialized for porn addiction recovery support groups
      // Prioritizes allowing recovery discussions over blocking
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

        // Step 4: Review policy (no auto blocking/hiding)
        console.log('\n=== STEP 4: REVIEW POLICY (NO AUTO-BLOCK) ===');

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

        switch (finalDecision.action) {
          case 'review':
            finalStatus = 'manual_review';
            localizedReason = getLocalizedMessage('manual_review', userLocale);
            break;
          case 'allow_with_redaction':
            finalStatus = 'approved';
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

        // Never hide automatically

        // Attach AI analysis details for admin UI justification
        (updateData.moderation as any).ai = {
          reason: openaiResult.reason,
          violationType: openaiResult.violationType,
          severity: openaiResult.severity,
          confidence: openaiResult.confidence,
          detectedContent: openaiResult.detectedContent,
          culturalContext: openaiResult.culturalContext || null
        };

        (updateData.moderation as any).finalDecision = {
          action: finalDecision.action,
          reason: finalDecision.reason,
          violationType: finalDecision.violationType || null,
          confidence: finalDecision.confidence
        };

        (updateData.moderation as any).customRules = customRuleResults
          .filter(r => r.detected)
          .map(r => ({
            type: r.type,
            severity: r.severity,
            confidence: r.confidence,
            reason: r.reason
          }));

        (updateData.moderation as any).analysisAt = admin.firestore.FieldValue.serverTimestamp();

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
        openaiModel: 'gpt-4o-mini',
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
