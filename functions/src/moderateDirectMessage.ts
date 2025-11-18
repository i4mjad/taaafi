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
  conversationId: string;
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
      continue;
    }

    // Remove zero-width characters
    if (/[\u200B-\u200F\u2060\u2061\u2062\u2063\u2064\u2065\u2066\u2067\u2068\u2069\u061C]/.test(char)) {
      continue;
    }

    // Remove Arabic tatweel (kashida)
    if (char === '\u0640') {
      continue;
    }

    // Unify Arabic letters
    if (/[أإآ]/.test(char)) {
      processedChar = 'ا';
    }
    else if (char === 'ى') {
      processedChar = 'ي';
    }
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

    charMap.push({
      originalIndex: i,
      normalizedIndex: normalizedIndex
    });

    normalized += processedChar;
    normalizedIndex++;
  }

  normalized = normalized
    .replace(/\s+/g, ' ')
    .replace(/[.]{2,}/g, '.')
    .replace(/[!]{2,}/g, '!')
    .replace(/[?]{2,}/g, '?')
    .trim();

  console.log(`✅ Normalization complete: ${original.length} → ${normalized.length} chars`);
  
  return {
    original,
    normalized,
    charMap
  };
}

/**
 * De-obfuscate common tokens
 */
function deobfuscateTokens(text: string): string {
  console.log('🕵️ Starting token de-obfuscation...');
  
  let deobfuscated = text;

  const platformPatterns = [
    { pattern: /w\s*a\s*\.\s*m\s*e/gi, replacement: 'wa.me' },
    { pattern: /i\s*n\s*s\s*t\s*a\s*g\s*r\s*a\s*m/gi, replacement: 'instagram' },
    { pattern: /f\s*a\s*c\s*e\s*b\s*o\s*o\s*k/gi, replacement: 'facebook' },
    { pattern: /w\s*h\s*a\s*t\s*s\s*a\s*p\s*p/gi, replacement: 'whatsapp' },
    { pattern: /t\s*e\s*l\s*e\s*g\s*r\s*a\s*m/gi, replacement: 'telegram' },
    { pattern: /t\s*i\s*k\s*t\s*o\s*k/gi, replacement: 'tiktok' },
    { pattern: /s\s*n\s*a\s*p\s*c\s*h\s*a\s*t/gi, replacement: 'snapchat' },
    { pattern: /ت\s*ل\s*ي\s*ج\s*ر\s*ا\s*م/g, replacement: 'تليجرام' },
    { pattern: /ا\s*ن\s*س\s*ت\s*ق\s*ر\s*ا\s*م/g, replacement: 'انستقرام' },
    { pattern: /ا\s*ن\s*س\s*ت\s*ا/g, replacement: 'انستا' },
    { pattern: /ف\s*ي\s*س\s*ب\s*و\s*ك/g, replacement: 'فيسبوك' },
    { pattern: /و\s*ا\s*ت\s*س\s*ا\s*ب/g, replacement: 'واتساب' },
    { pattern: /س\s*ن\s*ا\s*ب\s*ش\s*ا\s*ت/g, replacement: 'سناب شات' },
    { pattern: /ت\s*ي\s*ك\s*ت\s*و\s*ك/g, replacement: 'تيك توك' },
  ];

  for (const { pattern, replacement } of platformPatterns) {
    deobfuscated = deobfuscated.replace(pattern, replacement);
  }

  deobfuscated = deobfuscated.replace(/@\s+([a-zA-Z0-9_]+(?:\s+[a-zA-Z0-9_]+)*)/g, (match, username) => {
    const cleanUsername = username.replace(/\s+/g, '');
    return `@${cleanUsername}`;
  });

  console.log('✅ Token de-obfuscation complete');
  return deobfuscated;
}

/**
 * Custom rule patterns
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
    explicit: []
  },
  cuckoldry: {
    directSolicitation: ['تعال أديثك', 'بدي قواد', 'come cuckold me']
  },
  homosexuality: {
    directSolicitation: ['بحث عن شاب مثلي', 'looking for gay partner']
  }
};

/**
 * Detect message language
 */
function detectMessageLanguage(text: string): 'arabic' | 'english' {
  console.log('🌐 Detecting message language...');
  
  const arabicCharsRegex = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]/g;
  const arabicMatches = text.match(arabicCharsRegex);
  const arabicCharCount = arabicMatches ? arabicMatches.length : 0;
  
  const englishCharsRegex = /[a-zA-Z]/g;
  const englishMatches = text.match(englishCharsRegex);
  const englishCharCount = englishMatches ? englishMatches.length : 0;
  
  const totalChars = arabicCharCount + englishCharCount;
  
  if (totalChars === 0) {
    console.log('⚠️ No meaningful characters detected, defaulting to Arabic');
    return 'arabic';
  }
  
  const arabicPercentage = (arabicCharCount / totalChars) * 100;
  
  console.log(`📊 Language detection: Arabic: ${arabicCharCount} chars (${arabicPercentage.toFixed(1)}%), English: ${englishCharCount} chars`);
  
  const detectedLanguage = arabicPercentage >= 30 ? 'arabic' : 'english';
  console.log(`🌐 Detected language: ${detectedLanguage}`);
  
  return detectedLanguage;
}

/**
 * Moderation prompts for DMs - More lenient for 1-on-1 context
 */
const MODERATION_PROMPTS = {
  arabic: `أنت نظام مراقبة محتوى متخصص في الرسائل المباشرة بين المستخدمين في تطبيق التعافي من الإدمان.

**السياق المهم:**
هذه رسالة خاصة بين مستخدمين (1-على-1)، وليست في مجموعة عامة. يجب أن تكون أكثر تساهلاً.

**المحتوى المسموح (لا تحجبه):**
✅ المحادثات الشخصية والدعم المتبادل
✅ مشاركة التجارب الشخصية
✅ النقاش الخاص حول التعافي
✅ الرسائل التنظيمية أو الإدارية

**المخالفات المطلوب رصدها فقط:**

1. **الطلبات الجنسية المباشرة والصريحة**
   - طلبات لقاءات جنسية حقيقية
   - عروض جنسية مباشرة صريحة

2. **مشاركة وسائل التواصل لأغراض غير علاجية واضحة**
   - "تابعوني على انستقرام" + اسم حساب (للترويج)
   - محاولات واضحة لنقل المحادثة خارج التطبيق لأغراض تجارية

**النص المطلوب تحليله:**
"{{MESSAGE_TEXT}}"

**المطلوب منك:**
أجب بصيغة JSON فقط:

{
  "shouldBlock": true/false,
  "violationType": "social_media_sharing" أو "sexual_content" أو "cuckoldry_content" أو "homosexuality_content" أو "none",
  "severity": "low" أو "medium" أو "high",
  "confidence": 0.0-1.0,
  "reason": "شرح مختصر",
  "detectedContent": ["قائمة"],
  "culturalContext": "ملاحظة"
}

مهم: كن متساهلاً في سياق الرسائل الخاصة. فقط احجب المحتوى الخطير أو الترويجي الواضح.`,

  english: `You are a content moderation system for DIRECT MESSAGES (1-on-1) between users in a recovery app.

**Important Context:**
This is a private message between two users, not a public group. Be MORE LENIENT than group moderation.

**ALLOWED Content (DO NOT block):**
✅ Personal conversations and mutual support
✅ Sharing personal experiences
✅ Private discussion about recovery
✅ Administrative/organizational messages

**VIOLATIONS to Detect:**

1. **Direct and Explicit Sexual Requests**
   - Actual requests for real sexual encounters
   - Explicit direct sexual propositions

2. **Social Media Account Requests or Sharing**
   - ANY request for social media accounts (Instagram, Snapchat, WhatsApp, Facebook, TikTok, Telegram, etc.)
   - Examples: "your snapchat?", "what's your insta?", "send me your WhatsApp", "add me on telegram"
   - Sharing personal social media handles or usernames
   - ANY attempt to move conversation outside the app to social media platforms
   - This includes BOTH explicit sharing and asking for others' accounts

**Text to Analyze:**
"{{MESSAGE_TEXT}}"

**Required Response:**
Respond with JSON only:

{
  "shouldBlock": true/false,
  "violationType": "social_media_sharing" or "sexual_content" or "cuckoldry_content" or "homosexuality_content" or "none",
  "severity": "low" or "medium" or "high",
  "confidence": 0.0-1.0,
  "reason": "Brief explanation",
  "detectedContent": ["List"],
  "culturalContext": "Note"
}

Important: Be lenient in private message context. Only block clearly dangerous or promotional content.`
};

/**
 * Get user locale from community profile
 */
async function getUserLocale(senderCpId: string): Promise<'arabic' | 'english'> {
  try {
    console.log('🌐 Getting user locale for:', senderCpId);
    
    const profileDoc = await admin.firestore()
      .collection('communityProfiles')
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
    return 'arabic';
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
 * Evaluate custom rules
 */
function evaluateCustomRules(normalizedText: string): CustomRuleResult[] {
  console.log('🔍 Evaluating custom rules for DM context...');
  
  const results: CustomRuleResult[] = [];
  const lowerText = normalizedText.toLowerCase();

  // Check for administrative context
  const adminContextRegex = /(ممنوع|قوانين|غير مسموح|محظور|not allowed|rules?)/i;
  const outsideContextRegex = /(برا|خارج|outside)/i;
  const isAdministrativeContext = adminContextRegex.test(normalizedText) && outsideContextRegex.test(normalizedText);

  // Social Media checks - more lenient for DMs
  const socialMediaSpans: Array<{start: number; end: number; content: string}> = [];
  const followSpans: Array<{start: number; end: number; content: string}> = [];
  const platformSpans: Array<{start: number; end: number; content: string}> = [];

  for (const phrase of CUSTOM_RULE_PATTERNS.socialMedia.followPhrases) {
    const idx = lowerText.indexOf(phrase.toLowerCase());
    if (idx !== -1) {
      followSpans.push({ start: idx, end: idx + phrase.length, content: phrase });
    }
  }

  for (const platform of CUSTOM_RULE_PATTERNS.socialMedia.platforms) {
    const idx = lowerText.indexOf(platform.toLowerCase());
    if (idx !== -1) {
      platformSpans.push({ start: idx, end: idx + platform.length, content: platform });
    }
  }

  const hasIntent = followSpans.length > 0;
  const hasContactToken = platformSpans.length > 0;

  if (!isAdministrativeContext && hasIntent && hasContactToken) {
    const combinedSpans = [...followSpans, ...platformSpans];
    socialMediaSpans.push(...combinedSpans);
    results.push({
      detected: true,
      type: 'social_media_sharing',
      severity: 'medium', // Lower severity for DMs
      confidence: 0.8,
      reason: `Detected potential social media promotion in DM: ${combinedSpans.map(s => s.content).join(', ')}`,
      detectedSpans: combinedSpans
    });
  }

  console.log(`✅ Custom rule evaluation complete: ${results.length} violations detected`);
  return results;
}

/**
 * Check with OpenAI
 */
async function checkWithOpenAI(text: string): Promise<OpenAIModerationResult> {
  console.log('🤖 Starting OpenAI analysis for DM...');
  
  try {
    const detectedLanguage = detectMessageLanguage(text);
    console.log(`📤 Using ${detectedLanguage} prompt for DM analysis`);
    
    const promptTemplate = MODERATION_PROMPTS[detectedLanguage];
    const prompt = promptTemplate.replace('{{MESSAGE_TEXT}}', text);
    
    const startTime = Date.now();
    
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a content moderation expert for private messages. Always respond with valid JSON only. Be more lenient than group moderation.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.1,
      max_tokens: 500,
      response_format: { type: 'json_object' }
    });
    
    const processingTime = Date.now() - startTime;
    console.log(`⏱️ OpenAI processing completed in ${processingTime}ms`);
    
    const responseContent = completion.choices[0]?.message?.content;
    if (!responseContent) {
      throw new Error('Empty response from OpenAI');
    }
    
    console.log('🤖 Raw OpenAI Response:', responseContent);
    
    let parsedResponse: any;
    try {
      parsedResponse = JSON.parse(responseContent);
    } catch (parseError) {
      console.error('❌ Failed to parse OpenAI JSON response:', parseError);
      throw new Error('Invalid JSON response from OpenAI');
    }
    
    const result: OpenAIModerationResult = {
      shouldBlock: parsedResponse.shouldBlock || false,
      violationType: parsedResponse.violationType || 'none',
      severity: parsedResponse.severity || 'low',
      confidence: Math.min(Math.max(parsedResponse.confidence || 0, 0), 1),
      reason: parsedResponse.reason || 'No specific reason provided',
      detectedContent: Array.isArray(parsedResponse.detectedContent) ? parsedResponse.detectedContent : [],
      culturalContext: parsedResponse.culturalContext || undefined,
      processingTime
    };
    
    console.log('✅ Structured OpenAI Result:', result);
    return result;
    
  } catch (error) {
    console.error('❌ OpenAI analysis failed:', error);
    
    return {
      shouldBlock: false,
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
 * Synthesize final moderation decision
 */
function synthesizeDecision(
  openaiResult: OpenAIModerationResult,
  customRuleResults: CustomRuleResult[],
  processingTime: number
): FinalModerationDecision {
  console.log('⚖️ Synthesizing final moderation decision for DM...');
  
  // For DMs: Route to manual review if any detection occurs
  const anyCustomDetection = customRuleResults.some(r => r.detected);
  if (openaiResult.shouldBlock || anyCustomDetection) {
    console.log('⚠️ REVIEW: Detection present. Routing to manual review.');
    const reason = openaiResult.shouldBlock
      ? `Requires review: ${openaiResult.reason}`
      : customRuleResults.find(r => r.detected)?.reason || 'Requires review';
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

  console.log('✅ ALLOW: No significant violations detected in DM');
  return {
    action: 'allow',
    reason: 'Content appears acceptable for private message',
    confidence: 1.0,
    processingDetails: {
      openaiUsed: true,
      customRulesUsed: true,
      processingTime
    }
  };
}

/**
 * Main Cloud Function for Direct Message Moderation
 */
export const moderateDirectMessage = onDocumentCreated(
  'direct_messages/{messageId}',
  async (event) => {
    const functionStartTime = Date.now();
    const messageId = event.params?.messageId;
    const snap = event.data;
    
    if (!snap || !messageId) {
      console.error('❌ Invalid event data');
      return;
    }
    
    console.log('🚀 DM MODERATION STARTED for message:', messageId);
    console.log('📍 Function triggered at:', new Date().toISOString());
    
    try {
      const message = snap.data() as MessageData;
      console.log('📝 DM data retrieved:', {
        messageId,
        senderCpId: message.senderCpId,
        conversationId: message.conversationId,
        bodyLength: message.body?.length || 0,
      });

      const userLocale = await getUserLocale(message.senderCpId);
      console.log('🌐 User locale:', userLocale);

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

      try {
        const pipelineStartTime = Date.now();

        // Step 1: Normalize Arabic text
        console.log('\n=== STEP 1: TEXT NORMALIZATION ===');
        const normalizedResult = normalizeArabicText(message.body);
        console.log('📝 Normalized length:', normalizedResult.normalized.length);

        // Step 2: De-obfuscate tokens
        console.log('\n=== STEP 2: TOKEN DE-OBFUSCATION ===');
        const deobfuscatedText = deobfuscateTokens(normalizedResult.normalized);

        // Step 3: Run OpenAI moderation
        console.log('\n=== STEP 3: OPENAI ANALYSIS ===');
        const openaiResult = await checkWithOpenAI(message.body);
        console.log('🤖 OpenAI result:', {
          shouldBlock: openaiResult.shouldBlock,
          violationType: openaiResult.violationType,
          confidence: openaiResult.confidence
        });

        // Step 4: Evaluate custom rules
        console.log('\n=== STEP 4: CUSTOM RULE EVALUATION ===');
        const customRuleResults = evaluateCustomRules(deobfuscatedText);
        console.log('📊 Custom rules detected:', customRuleResults.length, 'violations');

        // Step 5: Synthesize decision
        console.log('\n=== STEP 5: DECISION SYNTHESIS ===');
        const finalDecision = synthesizeDecision(
          openaiResult,
          customRuleResults,
          Date.now() - pipelineStartTime
        );
        console.log('⚖️ Final decision:', finalDecision.action, 'confidence:', finalDecision.confidence);

        // Step 6: Update message with moderation result
        console.log('\n=== STEP 6: RESPONSE EMISSION ===');
        
        let finalStatus: ModerationStatus['status'] = 'approved';
        let localizedReason: string;

        switch (finalDecision.action) {
          case 'review':
            finalStatus = 'manual_review';
            localizedReason = getLocalizedMessage('manual_review', userLocale);
            break;
          case 'allow':
          default:
            finalStatus = 'approved';
            localizedReason = finalDecision.reason;
            break;
        }

        const updateData: any = {
          moderation: {
            status: finalStatus,
            reason: localizedReason
          } as ModerationStatus
        };

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

        await snap.ref.update(updateData);
        console.log('✅ Database updated with final decision');

      } catch (pipelineError) {
        console.error('❌ Moderation pipeline failed:', pipelineError);
        
        const fallbackReason = getLocalizedMessage('system_error', userLocale);
        
        await snap.ref.update({
          moderation: {
            status: 'manual_review',
            reason: fallbackReason
          } as ModerationStatus
        });
      }

      const totalProcessingTime = Date.now() - functionStartTime;
      console.log(`\n🏁 DM MODERATION COMPLETED in ${totalProcessingTime}ms`);

    } catch (error) {
      console.error('💥 CRITICAL ERROR in DM moderation:', error);
      
      try {
        let errorLocale: 'arabic' | 'english' = 'arabic';
        try {
          const message = snap.data() as MessageData;
          if (message?.senderCpId) {
            errorLocale = await getUserLocale(message.senderCpId);
          }
        } catch (localeError) {
          console.log('⚠️ Could not get user locale, using Arabic');
        }
        
        const errorReason = getLocalizedMessage('system_error', errorLocale);
        
        await snap.ref.update({
          moderation: {
            status: 'manual_review',
            reason: errorReason
          } as ModerationStatus
        });

        console.log('🔄 Error handled: DM sent to manual review');
      } catch (fallbackError) {
        console.error('💀 CATASTROPHIC FAILURE:', fallbackError);
      }
    }
  });

