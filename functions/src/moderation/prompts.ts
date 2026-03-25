import { ContentType } from './types';

const CONTENT_TYPE_PREAMBLES = {
  arabic: {
    group_message: 'هذه رسالة في مجموعة دعم للتعافي.',
    forum_post: 'هذا منشور عام في منتدى دعم التعافي.',
    comment: 'هذا تعليق على منشور في منتدى دعم التعافي.',
    group_update: 'هذا تحديث/إعلان في مجموعة دعم التعافي.',
  },
  english: {
    group_message: 'This is a message in a recovery support group chat.',
    forum_post: 'This is a public post in a recovery support forum.',
    comment: 'This is a comment on a recovery support forum post.',
    group_update: 'This is an update/announcement in a recovery support group.',
  },
} as const;

const ARABIC_PROMPT = `أنت نظام تصنيف محتوى. مهمتك الوحيدة هي كشف محاولات مشاركة معلومات التواصل الشخصية.

**السياق:**
{{CONTENT_PREAMBLE}}
هذه منصة دعم للتعافي من إدمان المواد الإباحية. الأعضاء يتحدثون بحرية عن تجاربهم ومشاكلهم. المحتوى الجنسي في سياق التعافي مسموح تماماً.

**المهمة الوحيدة — كشف مشاركة معلومات التواصل:**

اكتشف فقط:
- حسابات التواصل الاجتماعي (انستقرام، فيسبوك، تيك توك، سناب شات، تويتر/إكس، يوتيوب)
- أرقام الهواتف (أرقام عادية، أرقام عربية ٠-٩، أرقام إيموجي مثل 1️⃣2️⃣3️⃣)
- روابط واتساب (wa.me)، تليجرام (t.me)، أو أي رابط تواصل خارجي
- أسماء مستخدمين — سواء مع @ أو بدون @. مثال: "akalsulimani" أو "@akalsulimani" أو "ahmed_123" كلها أسماء حسابات. لا تحتاج لوجود @ لتصنيف كلمة كاسم مستخدم
- كلمة واحدة بالإنجليزية تبدو كاسم حساب (بدون مسافات، حروف وأرقام ونقاط وشرطات سفلية) حتى لو كانت رسالة مستقلة — في مجموعة دعم عربية، كلمة إنجليزية وحيدة مثل "akalsulimani" هي حساب وليست محادثة عادية
- نية لنقل المحادثة خارج المنصة ("راسلني واتساب"، "تابعوني على"، "ضيفوني"، "ضيفني انستا"، "نتواصل بره"، "نتكلم في مكان آخر"، "أرسلي رسالة خاصة على")
- عبارة تطلب الإضافة على منصة + أي نص بعدها = مشاركة حساب (مثل "ضيفني انستا" حتى بدون ذكر اسم الحساب)

**ليست مخالفات (لا تحجبها أبداً):**
❌ مناقشة التعافي بأي لغة أو أي ألفاظ — هذه مساحة آمنة
❌ ذكر المنصات بشكل عام ("حذفت الانستقرام"، "السوشال ميديا تأثر علي")
❌ الرسائل الإدارية عن القوانين ("ممنوع التواصل برا"، "القوانين تمنع")
❌ الأرقام العادية (أعمار، أيام تعافي، تواريخ، آيات)
❌ أي محتوى جنسي في سياق التعافي والنقاش العلاجي
❌ طلبات الدعم أو المساعدة
❌ دعوات لمجموعات داخل التطبيق

**النص:**
"{{MESSAGE_TEXT}}"

أجب بـ JSON فقط:
{
  "shouldFlag": true/false,
  "violationType": "account_sharing" أو "none",
  "confidence": 0.0-1.0,
  "reason": "شرح مختصر",
  "detectedContent": ["العناصر المكتشفة"]
}

مهم: shouldFlag = true فقط عند وجود محاولة فعلية لمشاركة معلومات تواصل شخصية أو نقل المحادثة لمنصة خارجية. عند الشك، اختر false.`;

const ENGLISH_PROMPT = `You are a content classification system. Your ONLY task is detecting attempts to share personal contact information.

**Context:**
{{CONTENT_PREAMBLE}}
This is a support platform for pornography addiction recovery. Members speak freely about their experiences and struggles. Sexual content in a recovery context is completely allowed.

**Your ONLY task — detect contact info sharing:**

Detect only:
- Social media accounts (Instagram, Facebook, TikTok, Snapchat, Twitter/X, YouTube)
- Phone numbers (regular digits, Arabic-Indic digits ٠-٩, emoji digits like 1️⃣2️⃣3️⃣)
- WhatsApp links (wa.me), Telegram links (t.me), or any external contact links
- Usernames — with OR without the @ symbol. Examples: "akalsulimani", "@akalsulimani", "ahmed_123" are ALL account handles. The @ symbol is NOT required to classify something as a username
- A single English word that looks like an account handle (no spaces, alphanumeric with dots/underscores) even as a standalone message — in an Arabic recovery group, a lone English word like "akalsulimani" is almost certainly a social media handle, not normal conversation
- Intent to move conversation off-platform ("message me on WhatsApp", "follow me on", "add me on", "let's talk somewhere else", "DM me on", "add me on insta")
- A phrase requesting to be added on a platform + any text after it = account sharing (e.g. "add me on insta" even without a specific handle)

**NOT violations (NEVER flag these):**
❌ Recovery discussion in any language or any terms — this is a safe space
❌ Mentioning platforms generally ("I deleted Instagram", "social media triggers me")
❌ Administrative messages about rules ("not allowed outside", "rules say no external contact")
❌ Regular numbers (ages, recovery day counts, dates, verse references)
❌ Any sexual content in a recovery/therapeutic discussion context
❌ Requests for support or help
❌ Invitations to in-app groups

**Text:**
"{{MESSAGE_TEXT}}"

Respond with JSON only:
{
  "shouldFlag": true/false,
  "violationType": "account_sharing" or "none",
  "confidence": 0.0-1.0,
  "reason": "brief explanation",
  "detectedContent": ["detected items"]
}

Important: shouldFlag = true ONLY when there is an actual attempt to share personal contact information or move the conversation to an external platform. When in doubt, choose false.`;

export function getPrompt(contentType: ContentType, language: 'arabic' | 'english'): string {
  const preamble = CONTENT_TYPE_PREAMBLES[language][contentType];
  const template = language === 'arabic' ? ARABIC_PROMPT : ENGLISH_PROMPT;
  return template.replace('{{CONTENT_PREAMBLE}}', preamble);
}

export function buildPromptWithText(contentType: ContentType, language: 'arabic' | 'english', text: string): string {
  const prompt = getPrompt(contentType, language);
  return prompt.replace('{{MESSAGE_TEXT}}', text);
}
