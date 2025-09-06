"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.ARABIC_PATTERNS = exports.moderateMessage = void 0;
exports.performQuickCheck = performQuickCheck;
exports.checkWithFirebaseAI = checkWithFirebaseAI;
const firestore_1 = require("firebase-functions/v2/firestore");
const v2_1 = require("firebase-functions/v2");
const admin = __importStar(require("firebase-admin"));
const vertexai_1 = require("@google-cloud/vertexai");
// Set global options for all functions
(0, v2_1.setGlobalOptions)({
    region: 'us-central1',
    memory: '1GiB',
    timeoutSeconds: 30,
    maxInstances: 50
});
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
// Initialize Vertex AI
const vertexAI = new vertexai_1.VertexAI({
    project: process.env.GCLOUD_PROJECT || '',
    location: 'us-central1',
});
const model = vertexAI.preview.getGenerativeModel({
    model: 'gemini-1.5-flash', // Fast and cost-effective
    generationConfig: {
        maxOutputTokens: 512,
        temperature: 0.1,
        topP: 0.8,
    },
});
/**
 * Localized violation messages
 */
const LOCALIZED_MESSAGES = {
    arabic: {
        social_media_sharing: 'مشاركة حسابات وسائل التواصل الاجتماعي غير مسموحة',
        sexual_content: 'المحتوى الجنسي غير مسموح',
        cuckoldry_content: 'المحتوى غير اللائق غير مسموح',
        homosexuality_content: 'المحتوى غير المناسب غير مسموح',
        system_error: 'خطأ في النظام - تحت المراجعة',
        manual_review: 'رسالتك تحت المراجعة من قبل الإدارة'
    },
    english: {
        social_media_sharing: 'Sharing social media accounts is not allowed',
        sexual_content: 'Sexual content is not allowed',
        cuckoldry_content: 'Inappropriate sexual content is not allowed',
        homosexuality_content: 'Inappropriate content is not allowed',
        system_error: 'System error - under review',
        manual_review: 'Your message is under review by moderators'
    }
};
/**
 * Arabic Content Detection Patterns (Enhanced)
 */
const ARABIC_PATTERNS = {
    // Social Media Sharing Patterns
    socialMedia: {
        followPhrases: [
            'تابعوني على',
            'ضيفوني على',
            'اكاونتي على',
            'حسابي في',
            'شوفوني على',
            'لقوني على',
            'ابحثوا عني باسم',
            'يوزرنيمي',
            'اسمي في الانستا',
            'follow me on',
            'add me on',
            // Contact/communication phrases
            'ممكن نتواصل',
            'نتواصل بطريقة أخرى',
            'نتكلم في مكان آخر',
            'تواصلوا معي',
            'راسلوني على',
            'كلموني على',
            'بحثوا عني في',
            'ابحثوا عني في'
        ],
        platforms: [
            'انستقرام', 'انستا', 'instagram', 'insta',
            'فيسبوك', 'فيس', 'facebook', 'fb',
            'تيك توك', 'tiktok', 'tik tok',
            'سناب شات', 'سناب', 'snapchat', 'snap',
            'واتساب', 'whatsapp', 'واتس',
            'تليجرام', 'telegram',
            // Indirect platform references
            'المنصة الزرقاء', // Facebook (the blue platform)
            'التطبيق الأزرق', // Facebook (the blue app)
            'المنصة الزرقا', // Facebook variation
            'التطبيق اللي فيه الصور المربعة', // Instagram (app with square photos)
            'تطبيق الصور المربعة', // Instagram
            'المنصة اللي فيها الصور', // Instagram
            'التطبيق الصيني', // TikTok
            'تطبيق الرقص', // TikTok
            'المنصة الصفراء', // Snapchat
            'التطبيق الأصفر', // Snapchat
            'تطبيق الأشباح', // Snapchat
            'التطبيق الأخضر', // WhatsApp
            'المنصة الخضراء', // WhatsApp
            'حساب', 'اكاونت', 'account', 'profile'
        ],
        usernamePatterns: [
            /@[a-zA-Z0-9_.]+/,
            /[a-zA-Z0-9_.]+\.(com|net|org)/,
            /\b[a-zA-Z0-9_.]{3,}\b/
        ],
        // Standalone contact-seeking phrases (should be blocked immediately)
        contactPhrases: [
            'ممكن نتواصل بطريقة أخرى',
            'نتكلم في مكان آخر',
            'عندي حساب على',
            'عندي اكاونت على',
            'عندي بروفايل على',
            'ابحثوا عني باسم',
            'بحثوا عني في',
            'لقوني في',
            'شوفوني في',
            'ادوروا علي في',
            'دوروا علي في'
        ]
    },
    // Sexual Content Patterns (Enhanced)
    sexual: {
        explicit: [
            // Core explicit terms
            'جنس', 'عري', 'إباحي', 'sex', 'porn', 'nude', 'xxx',
            // زب (penis) variations
            'زب', 'زبك', 'زبي', 'زبه', 'زبها', 'زبكم', 'زبهم', 'يزب', 'مزبوب',
            'زب ابوك', 'زب أبوك',
            // كس (vagina) variations  
            'كس', 'كسك', 'كسي', 'كسها', 'كسكم', 'كسهم', 'كسمك', 'يكس', 'كساس',
            'كس اختك', 'كس أختك',
            // نيك (fuck) variations
            'نيك', 'ينيك', 'ناك', 'نيكني', 'انيكك', 'أنيكك', 'نيكها', 'نيكة',
            'منيوك', 'مناك', 'منيوك من',
            // طيز (ass) variations
            'طيز', 'طيزك', 'طيزي', 'طيزها', 'مطيز',
            // Sexual positions/roles
            'سالب', 'موجب', 'مبادل', 'يسلب', 'يوجب', 'يبادل', 'سالب لك'
        ],
        suggestive: [
            'عايز أتعرف على بنات',
            'بدي صور',
            'ممكن نتكلم خاص',
            'عندك واتساب',
            'بدي بنت',
            'صور خاصة',
            'لقاء خاص'
        ]
    },
    // Cuckoldry Content (Enhanced)
    cuckoldry: {
        direct: [
            // Core terms
            'ديوث', 'قواد', 'يشارك زوجته', 'تبادل زوجات',
            'زوج يشاهد', 'أشارك مراتي', 'قواد لمراته',
            // ديوث variations
            'يديث', 'اديثك', 'أديثك', 'مديوث', 'ديوثة',
            // قواد variations  
            'قاد', 'يقود', 'قيادة'
        ],
        context: [
            'خيانة زوجية', 'زوجي يحب يشاهد', 'مع رجل آخر',
            'تجربة مع', 'ألعاب غريبة مع الشريك'
        ]
    },
    // Homosexuality Content (Enhanced)
    homosexuality: {
        direct: [
            // Core derogatory terms
            'شاذ', 'شذوذ', 'مثلي', 'لوطي', 'خنيث', 'gay', 'lesbian',
            'رجال مع رجال', 'بنات مع بنات',
            // خنث variations (effeminacy)
            'خنث', 'مخنث', 'يتخنث', 'خناثة', 'تخنيث', 'مخانيث',
            // لوط variations (sodomy)
            'لوط', 'لاط', 'يلوط', 'لوطي', 'ملوط'
        ],
        seeking: [
            'أي شباب مثليين',
            'بحب الأولاد الحلوين',
            'بنات تحب بنات',
            'من نفس الميول',
            'بحث عن صديق خاص',
            'أصدقاء من نفس الميول'
        ]
    }
};
exports.ARABIC_PATTERNS = ARABIC_PATTERNS;
/**
 * Get user locale from community profile
 */
async function getUserLocale(senderCpId) {
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
        const profileData = profileDoc.data();
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
        const locale = (userData === null || userData === void 0 ? void 0 : userData.locale) || 'arabic';
        console.log('🌐 User locale determined:', locale);
        return locale === 'english' ? 'english' : 'arabic';
    }
    catch (error) {
        console.error('❌ Error getting user locale:', error);
        return 'arabic'; // Default to Arabic
    }
}
/**
 * Get localized violation message
 */
function getLocalizedMessage(violationType, locale) {
    const messages = LOCALIZED_MESSAGES[locale];
    return messages[violationType] || messages.system_error;
}
/**
 * Perform quick rule-based content check
 */
function performQuickCheck(text) {
    console.log('🔍 Starting quick rule-based check for text:', text.substring(0, 50) + '...');
    const lowerText = text.toLowerCase();
    const originalText = text;
    // Check Social Media Sharing
    console.log('📱 Checking social media patterns...');
    // First check standalone contact phrases (immediate block)
    for (const phrase of ARABIC_PATTERNS.socialMedia.contactPhrases) {
        if (lowerText.includes(phrase.toLowerCase())) {
            console.log('🚨 VIOLATION DETECTED: Contact seeking phrase found:', phrase);
            return {
                definiteViolation: true,
                type: 'social_media_sharing',
                reason: 'Attempting to share contact information is not allowed',
                detectedPhrase: phrase,
                needsAICheck: false
            };
        }
    }
    // Then check follow phrases with platform/username confirmation
    for (const phrase of ARABIC_PATTERNS.socialMedia.followPhrases) {
        if (lowerText.includes(phrase.toLowerCase())) {
            console.log('🚨 VIOLATION DETECTED: Social media sharing phrase found:', phrase);
            // Check if accompanied by platform or username
            const hasPlatform = ARABIC_PATTERNS.socialMedia.platforms.some(platform => lowerText.includes(platform.toLowerCase()));
            const hasUsername = ARABIC_PATTERNS.socialMedia.usernamePatterns.some(pattern => pattern.test(originalText));
            if (hasPlatform || hasUsername) {
                console.log('✅ Confirmed social media sharing violation');
                return {
                    definiteViolation: true,
                    type: 'social_media_sharing',
                    reason: 'Sharing social media accounts is not allowed',
                    detectedPhrase: phrase,
                    needsAICheck: false
                };
            }
        }
    }
    // Check for platform mentions with account-related words
    for (const platform of ARABIC_PATTERNS.socialMedia.platforms) {
        if (lowerText.includes(platform.toLowerCase())) {
            // Check if it's accompanied by account-related words
            const accountWords = ['حساب', 'اكاونت', 'account', 'profile', 'عندي', 'لي'];
            const hasAccountContext = accountWords.some(word => lowerText.includes(word.toLowerCase()));
            if (hasAccountContext) {
                console.log('🚨 VIOLATION DETECTED: Platform mention with account context:', platform);
                return {
                    definiteViolation: true,
                    type: 'social_media_sharing',
                    reason: 'Sharing social media accounts is not allowed',
                    detectedPhrase: platform,
                    needsAICheck: false
                };
            }
        }
    }
    // Check Explicit Sexual Content
    console.log('🔞 Checking explicit sexual content...');
    for (const term of ARABIC_PATTERNS.sexual.explicit) {
        if (lowerText.includes(term.toLowerCase())) {
            console.log('🚨 VIOLATION DETECTED: Explicit sexual term found:', term);
            return {
                definiteViolation: true,
                type: 'sexual_content',
                reason: 'Sexual content is not allowed',
                detectedTerm: term,
                needsAICheck: false
            };
        }
    }
    // Check Cuckoldry Content
    console.log('🚫 Checking cuckoldry content...');
    for (const term of ARABIC_PATTERNS.cuckoldry.direct) {
        if (lowerText.includes(term.toLowerCase())) {
            console.log('🚨 VIOLATION DETECTED: Cuckoldry term found:', term);
            return {
                definiteViolation: true,
                type: 'cuckoldry_content',
                reason: 'Inappropriate sexual content is not allowed',
                detectedTerm: term,
                needsAICheck: false
            };
        }
    }
    // Check Homosexuality Content
    console.log('🏳️‍🌈 Checking homosexuality content...');
    for (const term of ARABIC_PATTERNS.homosexuality.direct) {
        if (lowerText.includes(term.toLowerCase())) {
            console.log('🚨 VIOLATION DETECTED: Homosexuality term found:', term);
            return {
                definiteViolation: true,
                type: 'homosexuality_content',
                reason: 'Inappropriate content is not allowed',
                detectedTerm: term,
                needsAICheck: false
            };
        }
    }
    // Check Suggestive Content (needs AI analysis)
    console.log('🤔 Checking suggestive content patterns...');
    const suggestivePatterns = [
        ...ARABIC_PATTERNS.sexual.suggestive,
        ...ARABIC_PATTERNS.cuckoldry.context,
        ...ARABIC_PATTERNS.homosexuality.seeking
    ];
    for (const pattern of suggestivePatterns) {
        if (lowerText.includes(pattern.toLowerCase())) {
            console.log('⚠️ SUSPICIOUS CONTENT: Suggestive pattern found, needs AI analysis:', pattern);
            return {
                definiteViolation: false,
                needsAICheck: true,
                suspiciousPattern: pattern,
                reason: 'Content needs AI analysis for context'
            };
        }
    }
    // Check for suspicious patterns that might bypass filters
    console.log('🕵️ Checking bypass attempts...');
    const suspiciousPatterns = [
        /[^\w\s\u0600-\u06FF]{3,}/, // Multiple special characters
        /\d{5,}/, // Long numbers (might be phone numbers)
        /\.com|\.net|\.org/i, // URLs
        /@\w+/i // @ mentions
    ];
    for (const pattern of suspiciousPatterns) {
        if (pattern.test(originalText)) {
            console.log('⚠️ SUSPICIOUS PATTERN: Potential bypass attempt detected');
            return {
                definiteViolation: false,
                needsAICheck: true,
                reason: 'Suspicious pattern detected, needs AI analysis'
            };
        }
    }
    console.log('✅ Content appears clean after rule-based check');
    return {
        definiteViolation: false,
        needsAICheck: false,
        reason: 'Content appears clean'
    };
}
/**
 * Analyze content using Firebase AI (Vertex AI)
 */
async function checkWithFirebaseAI(text) {
    var _a, _b, _c, _d, _e;
    console.log('🤖 Starting Firebase AI analysis...');
    const prompt = `
    تحليل هذه الرسالة للكشف عن المخالفات التالية فقط:
    1. مشاركة حسابات وسائل التواصل الاجتماعي
    2. المحتوى الجنسي أو غير اللائق
    3. محتوى الديوثة أو تبادل الأزواج
    4. المحتوى المثلي أو الشاذ

    النص: "${text}"

    اعتبارات مهمة:
    - فرق بين النقاش الأكاديمي (مسموح) والبحث الشخصي (ممنوع)
    - انتبه للسياق الثقافي العربي
    - الكلمات المسيئة يجب حجبها فوراً

    الرد بصيغة JSON فقط:
    {
      "shouldBlock": true/false,
      "violationType": "social_media" أو "sexual_content" أو "cuckoldry" أو "homosexuality" أو "none",
      "confidence": 0.0-1.0,
      "reason": "شرح مختصر بالعربية",
      "detectedContent": "النص المخالف إن وجد"
    }
  `;
    try {
        console.log('📤 Sending request to Vertex AI...');
        const startTime = Date.now();
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const processingTime = Date.now() - startTime;
        console.log(`⏱️ AI processing completed in ${processingTime}ms`);
        const responseText = ((_e = (_d = (_c = (_b = (_a = response.candidates) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.content) === null || _c === void 0 ? void 0 : _c.parts) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.text) || '';
        const aiResponse = JSON.parse(responseText);
        console.log('🤖 AI Response:', aiResponse);
        return {
            ...aiResponse,
            processingTime
        };
    }
    catch (error) {
        console.error('❌ Firebase AI analysis failed:', error);
        throw error;
    }
}
/**
 * Main Cloud Function for Message Moderation (Firebase Functions v2)
 */
exports.moderateMessage = (0, firestore_1.onDocumentCreated)('group_messages/{messageId}', async (event) => {
    var _a, _b;
    const functionStartTime = Date.now();
    const messageId = (_a = event.params) === null || _a === void 0 ? void 0 : _a.messageId;
    const snap = event.data;
    if (!snap || !messageId) {
        console.error('❌ Invalid event data');
        return;
    }
    console.log('🚀 MODERATION STARTED for message:', messageId);
    console.log('📍 Function triggered at:', new Date().toISOString());
    try {
        const message = snap.data();
        console.log('📝 Message data retrieved:', {
            messageId,
            senderCpId: message.senderCpId,
            groupId: message.groupId,
            bodyLength: ((_b = message.body) === null || _b === void 0 ? void 0 : _b.length) || 0,
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
                }
            });
            return;
        }
        console.log('🔍 Message content preview:', message.body.substring(0, 100) + '...');
        // Step 1: Quick Rule-Based Check
        console.log('\n=== STEP 1: RULE-BASED ANALYSIS ===');
        const quickCheckStart = Date.now();
        const quickCheck = performQuickCheck(message.body);
        const quickCheckTime = Date.now() - quickCheckStart;
        console.log(`⏱️ Rule-based check completed in ${quickCheckTime}ms`);
        console.log('📊 Quick check result:', quickCheck);
        // Handle definite violations
        if (quickCheck.definiteViolation) {
            console.log('🚫 BLOCKING MESSAGE - Rule-based violation detected');
            const localizedReason = getLocalizedMessage(quickCheck.type || 'system_error', userLocale);
            const moderationData = {
                status: 'blocked',
                reason: localizedReason
            };
            // Block message and hide it from other users
            await snap.ref.update({
                moderation: moderationData,
                isHidden: true // Hide from other users, sender can still see it with blocked status
            });
            console.log('✅ Message blocked and hidden from other users');
            // TODO: Send notification to user about blocked message
            console.log('📧 TODO: Send notification to user about violation');
            return;
        }
        // Step 2: AI Analysis (if needed)
        if (quickCheck.needsAICheck) {
            console.log('\n=== STEP 2: AI ANALYSIS ===');
            console.log('🤖 Suspicious content detected, starting AI analysis...');
            try {
                const aiResult = await checkWithFirebaseAI(message.body);
                console.log('🤖 AI analysis completed:', aiResult);
                const shouldBlock = aiResult.shouldBlock;
                const confidence = aiResult.confidence || 0.5;
                // Determine final action based on AI confidence
                let finalStatus = 'approved';
                if (shouldBlock && confidence >= 0.8) {
                    finalStatus = 'blocked';
                    console.log('🚫 BLOCKING MESSAGE - High confidence AI violation');
                }
                else if (shouldBlock && confidence >= 0.5) {
                    finalStatus = 'manual_review';
                    console.log('⚠️ MANUAL REVIEW REQUIRED - Medium confidence violation');
                }
                else {
                    finalStatus = 'approved';
                    console.log('✅ APPROVING MESSAGE - AI found no significant violations');
                }
                // Get localized reason based on AI result
                let localizedReason;
                if (finalStatus === 'blocked') {
                    localizedReason = getLocalizedMessage(aiResult.violationType, userLocale);
                }
                else if (finalStatus === 'manual_review') {
                    localizedReason = getLocalizedMessage('manual_review', userLocale);
                }
                else {
                    localizedReason = aiResult.reason;
                }
                const moderationData = {
                    status: finalStatus,
                    reason: localizedReason
                };
                // Only hide message if it's blocked, otherwise keep it visible
                const updateData = { moderation: moderationData };
                if (finalStatus === 'blocked') {
                    updateData.isHidden = true; // Hide from other users
                }
                await snap.ref.update(updateData);
                console.log('✅ AI moderation completed and database updated');
                // Add to manual review queue if needed
                if (finalStatus === 'manual_review') {
                    console.log('📋 Adding to manual review queue...');
                    await admin.firestore().collection('moderation_queue').add({
                        messageId,
                        groupId: message.groupId,
                        senderCpId: message.senderCpId,
                        messageBody: message.body,
                        aiAnalysis: aiResult,
                        priority: confidence >= 0.7 ? 'high' : 'medium',
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    console.log('✅ Added to manual review queue');
                }
            }
            catch (aiError) {
                console.error('❌ AI analysis failed:', aiError);
                // Fallback to manual review
                console.log('🔄 Falling back to manual review due to AI failure');
                const fallbackReason = getLocalizedMessage('system_error', userLocale);
                await snap.ref.update({
                    moderation: {
                        status: 'manual_review',
                        reason: fallbackReason
                    }
                });
                // Add to high priority manual review
                await admin.firestore().collection('moderation_queue').add({
                    messageId,
                    groupId: message.groupId,
                    senderCpId: message.senderCpId,
                    messageBody: message.body,
                    error: aiError.message,
                    priority: 'high',
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
        }
        else {
            // Step 3: Auto-approve clean content
            console.log('\n=== STEP 3: AUTO-APPROVAL ===');
            console.log('✅ APPROVING MESSAGE - No violations detected');
            await snap.ref.update({
                moderation: {
                    status: 'approved',
                    reason: null // No reason needed for approved messages
                }
            });
        }
        const totalProcessingTime = Date.now() - functionStartTime;
        console.log(`\n🏁 MODERATION COMPLETED in ${totalProcessingTime}ms`);
        console.log('📊 Final processing stats:', {
            messageId,
            totalTime: totalProcessingTime,
            ruleCheckTime: quickCheckTime,
            usedAI: quickCheck.needsAICheck
        });
    }
    catch (error) {
        console.error('💥 CRITICAL ERROR in message moderation:', error);
        // Log error details
        console.error('Error details:', {
            messageId,
            error: error.message,
            stack: error.stack,
            timestamp: new Date().toISOString()
        });
        // Fallback to manual review for any unhandled errors
        try {
            // Get user locale for error message (fallback to arabic if failed)
            let errorLocale = 'arabic';
            try {
                const message = snap.data();
                if (message === null || message === void 0 ? void 0 : message.senderCpId) {
                    errorLocale = await getUserLocale(message.senderCpId);
                }
            }
            catch (localeError) {
                console.log('⚠️ Could not get user locale for error message, using Arabic');
            }
            const errorReason = getLocalizedMessage('system_error', errorLocale);
            await snap.ref.update({
                moderation: {
                    status: 'manual_review',
                    reason: errorReason
                }
            });
            // Add to high priority queue
            await admin.firestore().collection('moderation_queue').add({
                messageId,
                error: error.message,
                priority: 'critical',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log('🔄 Error handled: Message sent to manual review');
        }
        catch (fallbackError) {
            console.error('💀 CATASTROPHIC FAILURE: Could not even save error state:', fallbackError);
        }
    }
});
//# sourceMappingURL=messageModeration.js.map