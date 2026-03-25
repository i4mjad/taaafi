import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import OpenAI from 'openai';
import { defineSecret } from 'firebase-functions/params';
import {
  ContentType,
  LLMClassification,
  ModerationConfig,
  ModerationStatusType,
  ModerationWriteData,
  ViolationType,
} from './types';
import { buildPromptWithText } from './prompts';

export const openaiApiKey = defineSecret('OPENAI_API_KEY');

let openaiClient: OpenAI | null = null;

const REVIEW_CONFIDENCE_THRESHOLD = 0.75;
const CLASSIFICATION_FAILED_REASON = 'classification_failed';

// ── Localized messages ──────────────────────────────────────────────

const LOCALIZED_MESSAGES: Record<string, Record<string, string>> = {
  arabic: {
    account_sharing: 'مشاركة معلومات التواصل الشخصية غير مسموحة',
    manual_review: 'محتواك تحت المراجعة من قبل الإدارة',
    system_error: 'خطأ في النظام - تحت المراجعة',
  },
  english: {
    account_sharing: 'Sharing personal contact information is not allowed',
    manual_review: 'Your content is under review by moderators',
    system_error: 'System error - under review',
  },
};

function getLocalizedMessage(
  violationType: ViolationType,
  locale: 'arabic' | 'english',
  reason?: string,
): string | null {
  if (reason === CLASSIFICATION_FAILED_REASON) {
    return LOCALIZED_MESSAGES[locale].system_error;
  }
  if (violationType === 'none') return null;
  return LOCALIZED_MESSAGES[locale][violationType] || LOCALIZED_MESSAGES[locale].manual_review;
}

// ── Digit normalization ─────────────────────────────────────────────

const EMOJI_DIGIT_MAP: Record<string, string> = {
  '0️⃣': '0', '1️⃣': '1', '2️⃣': '2', '3️⃣': '3', '4️⃣': '4',
  '5️⃣': '5', '6️⃣': '6', '7️⃣': '7', '8️⃣': '8', '9️⃣': '9',
};

export function normalizeDigits(text: string): string {
  let result = text;

  // Replace emoji digits (0️⃣-9️⃣) → 0-9
  for (const [emoji, digit] of Object.entries(EMOJI_DIGIT_MAP)) {
    result = result.split(emoji).join(digit);
  }

  // Replace Arabic-Indic digits (٠-٩) → 0-9
  result = result.replace(/[٠-٩]/g, (char) =>
    String.fromCharCode(char.charCodeAt(0) - 0x0660 + 48),
  );

  return result;
}

// ── Language detection ───────────────────────────────────────────────

export function detectLanguage(text: string): 'arabic' | 'english' {
  const arabicChars = text.match(/[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]/g);
  const englishChars = text.match(/[a-zA-Z]/g);
  const arabicCount = arabicChars ? arabicChars.length : 0;
  const englishCount = englishChars ? englishChars.length : 0;
  const total = arabicCount + englishCount;
  if (total === 0) return 'arabic'; // default
  return (arabicCount / total) * 100 >= 30 ? 'arabic' : 'english';
}

// ── User locale ─────────────────────────────────────────────────────

export async function getUserLocale(authorCpId: string): Promise<'arabic' | 'english'> {
  try {
    const profileDoc = await admin.firestore()
      .collection('communityProfiles')
      .doc(authorCpId)
      .get();

    if (!profileDoc.exists) return 'arabic';

    const userUID = profileDoc.data()?.userUID;
    if (!userUID) return 'arabic';

    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userUID)
      .get();

    if (!userDoc.exists) return 'arabic';

    const locale = userDoc.data()?.locale || 'arabic';
    return locale === 'english' ? 'english' : 'arabic';
  } catch (error) {
    console.error('Error getting user locale:', error);
    return 'arabic';
  }
}

// ── LLM classification ──────────────────────────────────────────────

function getOpenAIClient(): OpenAI {
  if (!openaiClient) {
    const apiKey = openaiApiKey.value();
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY is not configured');
    }
    openaiClient = new OpenAI({ apiKey });
  }
  return openaiClient;
}

async function callOpenAI(prompt: string): Promise<string> {
  const client = getOpenAIClient();
  const completion = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: 'You are a content classification expert. Always respond with valid JSON only.',
      },
      { role: 'user', content: prompt },
    ],
    temperature: 0.1,
    max_tokens: 300,
    response_format: { type: 'json_object' },
  });

  const content = completion.choices[0]?.message?.content;
  if (!content) throw new Error('Empty response from OpenAI');
  return content;
}

function parseClassification(raw: string): LLMClassification {
  const parsed = JSON.parse(raw);
  return {
    shouldFlag: parsed.shouldFlag === true,
    violationType: parsed.violationType === 'account_sharing' ? 'account_sharing' : 'none',
    confidence: Math.min(Math.max(Number(parsed.confidence) || 0, 0), 1),
    reason: String(parsed.reason || ''),
    detectedContent: Array.isArray(parsed.detectedContent) ? parsed.detectedContent : [],
  };
}

export async function classifyContent(
  text: string,
  contentType: ContentType,
  language: 'arabic' | 'english',
): Promise<LLMClassification> {
  const prompt = buildPromptWithText(contentType, language, text);
  const startTime = Date.now();

  // First attempt
  try {
    const raw = await callOpenAI(prompt);
    const result = parseClassification(raw);
    console.log(`OpenAI classification completed in ${Date.now() - startTime}ms:`, result);
    return result;
  } catch (firstError) {
    console.warn('First classification attempt failed, retrying in 2s:', firstError);
  }

  // Retry after 2s
  await new Promise((resolve) => setTimeout(resolve, 2000));

  try {
    const raw = await callOpenAI(prompt);
    const result = parseClassification(raw);
    console.log(`OpenAI classification (retry) completed in ${Date.now() - startTime}ms:`, result);
    return result;
  } catch (retryError) {
    console.error('Both classification attempts failed:', retryError);
    return {
      shouldFlag: false,
      violationType: 'none',
      confidence: 0,
      reason: CLASSIFICATION_FAILED_REASON,
      detectedContent: [],
    };
  }
}

// ── Status decision ─────────────────────────────────────────────────

function determineStatus(classification: LLMClassification): ModerationStatusType {
  // classification_failed always quarantines to manual_review
  if (classification.reason === CLASSIFICATION_FAILED_REASON) {
    return 'manual_review';
  }
  // High-confidence flag → manual review
  if (classification.shouldFlag && classification.confidence >= REVIEW_CONFIDENCE_THRESHOLD) {
    return 'manual_review';
  }
  return 'approved';
}

// ── Main pipeline ───────────────────────────────────────────────────

/**
 * Reusable document-level moderation helper.
 * Called by both Firestore triggers and the retry scheduler.
 */
export async function moderateSnapshot(
  docRef: FirebaseFirestore.DocumentReference,
  data: Record<string, any>,
  config: ModerationConfig,
): Promise<void> {
  const startTime = Date.now();
  const docId = docRef.id;

  console.log(`[MODERATION] Starting for ${config.contentType} ${docId}`);

  // Idempotency: skip if already moderated
  if (data.moderation?.completedAt) {
    console.log(`[MODERATION] Already moderated, skipping ${docId}`);
    return;
  }

  // Extract text
  const text = config.textExtractor(data).trim();
  if (!text) {
    console.log(`[MODERATION] Empty text, auto-approving ${docId}`);
    await docRef.update({
      'moderation.status': 'approved',
      'moderation.completedAt': FieldValue.serverTimestamp(),
      'moderation.reason': null,
      'moderation.violationType': 'none',
      'moderation.confidence': 1,
      'moderation.detectedContent': [],
      'moderation.ai': { reason: 'empty_content' },
    });
    return;
  }

  // Get author locale for localized messages
  const authorId = data[config.authorIdField];
  const locale = authorId ? await getUserLocale(authorId) : 'arabic';

  // Normalize digits (emoji + Arabic-Indic → regular)
  const normalizedText = normalizeDigits(text);

  // Detect language for prompt selection
  const language = detectLanguage(normalizedText);

  // Classify content via LLM
  const classification = await classifyContent(normalizedText, config.contentType, language);

  // Determine status
  const status = determineStatus(classification);

  // Build localized reason
  const reason = status === 'manual_review'
    ? getLocalizedMessage(classification.violationType, locale, classification.reason)
    : null;

  // Write moderation result
  const updateData: Record<string, any> = {
    'moderation.status': status,
    'moderation.reason': reason,
    'moderation.violationType': classification.violationType,
    'moderation.confidence': classification.confidence,
    'moderation.detectedContent': classification.detectedContent,
    'moderation.completedAt': FieldValue.serverTimestamp(),
    'moderation.ai': { reason: classification.reason },
  };

  // Auto-hide only high-confidence flags (≥0.85)
  // Lower confidence (0.75-0.85) stays visible but marked manual_review
  if (status === 'manual_review' && config.autoHideOnFlag && classification.confidence >= 0.85) {
    updateData.isHidden = true;
  }

  await docRef.update(updateData);

  const elapsed = Date.now() - startTime;
  console.log(`[MODERATION] Completed ${config.contentType} ${docId} → ${status} (${elapsed}ms)`);
}

/**
 * Thin event wrapper for Firestore onDocumentCreated triggers.
 * Extracts ref + data from the event and delegates to moderateSnapshot.
 */
export async function moderateDocument(
  event: { data?: { ref: FirebaseFirestore.DocumentReference; data: () => Record<string, any> | undefined } | null },
  config: ModerationConfig,
): Promise<void> {
  const ref = event.data?.ref;
  const data = event.data?.data();
  if (!ref || !data) {
    console.warn('[MODERATION] No document data in event, skipping');
    return;
  }
  await moderateSnapshot(ref, data, config);
}
