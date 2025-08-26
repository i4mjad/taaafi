import {onRequest} from 'firebase-functions/v2/https';
import {onCall} from 'firebase-functions/v2/https';
import {onDocumentCreated, onDocumentUpdated} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Get Firebase Messaging instance
const messaging = admin.messaging();

// Translation system matching the app's localization
const translations = {
  en: {
    'high-risk-hour-alert': 'High-Risk Hour Alert',
    'streak-vulnerability-alert': 'Streak Vulnerability Alert',
    'high-risk-hour-description': 'Get notified 30 minutes before your statistically highest risk hour for relapse',
    'smart-alerts-check-completed': 'Smart alerts check completed successfully. {alertsSent} alerts sent.',
    'test-notification-sent': 'Test {alertType} notification sent successfully!',
    'high-risk-hour-message': '⚠️ High-risk hour detected! Stay strong and use your coping strategies.',
    'streak-vulnerability-message': '🔔 Streak vulnerability detected! Consider doing a recovery activity to strengthen your resolve.',
    'smart-alerts-title': 'Smart Alert Suite',
    'user-authenticated-error': 'User must be authenticated',
    'high-risk-hour-approaching': 'Your high-risk hour is approaching in 30 minutes. Prepare your coping strategies.',
    'streak-at-risk': 'Your streak may be vulnerable. Consider checking in with your support network.',
    'notification-sent-successfully': 'FCM notification sent successfully',
    'notification-failed': 'Failed to send FCM notification',
    
    // Community notification translations
    'new-comment-on-post': 'New Comment',
    'someone-commented-on-your-post': 'Someone commented on your post "{postTitle}"',
    'new-reply-to-comment': 'New Reply',
    'someone-replied-to-your-comment': 'Someone replied to your comment "{commentText}"',
    'liked-your-post': 'Post Liked',
    'disliked-your-post': 'Post Disliked',
    'liked-your-comment': 'Comment Liked',
    'disliked-your-comment': 'Comment Disliked',
    'someone-liked-your-post': 'Someone liked your post "{title}"',
    'someone-disliked-your-post': 'Someone disliked your post "{title}"',
    'someone-liked-your-comment': 'Someone liked your comment "{title}"',
    'someone-disliked-your-comment': 'Someone disliked your comment "{title}"',
  },
  ar: {
    'high-risk-hour-alert': 'تنبيه ساعة الخطر العالي',
    'streak-vulnerability-alert': 'تنبيه ضعف الإنجاز', 
    'high-risk-hour-description': 'احصل على تنبيه قبل 30 دقيقة من ساعة الخطر الأعلى إحصائياً للانتكاس',
    'smart-alerts-check-completed': 'تم فحص التنبيهات الذكية بنجاح. تم إرسال {alertsSent} تنبيهات.',
    'test-notification-sent': 'تم إرسال اختبار {alertType} بنجاح!',
    'high-risk-hour-message': '⚠️ تم اكتشاف ساعة خطر عالي! ابق قوياً واستخدم استراتيجيات التأقلم.',
    'streak-vulnerability-message': '🔔 تم اكتشاف ضعف في الإنجاز! فكر في القيام بنشاط للتعافي لتقوية عزيمتك.',
    'smart-alerts-title': 'مجموعة التنبيهات الذكية',
    'user-authenticated-error': 'يجب تسجيل الدخول أولاً',
    'high-risk-hour-approaching': 'ساعة الخطر العالي تقترب خلال 30 دقيقة. استعد لاستراتيجيات التأقلم.',
    'streak-at-risk': 'قد يكون إنجازك في خطر. فكر في التواصل مع شبكة الدعم الخاصة بك.',
    'notification-sent-successfully': 'تم إرسال الإشعار بنجاح',
    'notification-failed': 'فشل في إرسال الإشعار',
    
    // Community notification translations
    'new-comment-on-post': 'تعليق جديد',
    'someone-commented-on-your-post': 'علق أحدهم على منشورك "{postTitle}"',
    'new-reply-to-comment': 'رد جديد',
    'someone-replied-to-your-comment': 'رد أحدهم على تعليقك "{commentText}"',
    'liked-your-post': 'إعجاب بالمنشور',
    'disliked-your-post': 'عدم إعجاب بالمنشور',
    'liked-your-comment': 'إعجاب بالتعليق',
    'disliked-your-comment': 'عدم إعجاب بالتعليق',
    'someone-liked-your-post': 'أعجب أحدهم بمنشورك "{title}"',
    'someone-disliked-your-post': 'لم يعجب أحدهم بمنشورك "{title}"',
    'someone-liked-your-comment': 'أعجب أحدهم بتعليقك "{title}"',
    'someone-disliked-your-comment': 'لم يعجب أحدهم بتعليقك "{title}"',
  }
};

// Helper function to translate based on locale
function translate(key: string, locale: string = 'en', replacements?: Record<string, string | number>): string {
  // Map full language names to language codes
  let languageCode: string;
  const lowerLocale = locale.toLowerCase();
  
  if (lowerLocale === 'arabic' || lowerLocale === 'ar') {
    languageCode = 'ar';
  } else if (lowerLocale === 'english' || lowerLocale === 'en') {
    languageCode = 'en';
  } else {
    // Handle other formats like 'en-US' by taking first part
    languageCode = locale.split('-')[0].toLowerCase();
    // Final fallback mapping
    if (languageCode === 'arabic') languageCode = 'ar';
    else if (languageCode === 'english') languageCode = 'en';
    else if (!['en', 'ar'].includes(languageCode)) languageCode = 'en';
  }
  
  const supportedLocale = ['en', 'ar'].includes(languageCode) ? languageCode : 'en';
  
  let translation = translations[supportedLocale as keyof typeof translations]?.[key] ||
                   translations.en[key] || 
                   `Unknown key: ${key}`;
  
  // Handle replacements like {alertsSent}
  if (replacements) {
    Object.entries(replacements).forEach(([placeholder, value]) => {
      translation = translation.replace(`{${placeholder}}`, String(value));
    });
  }
  
  return translation;
}

// Helper function to send FCM notification
async function sendFCMNotification(
  userId: string, 
  title: string, 
  body: string, 
  locale: string,
  data?: Record<string, string>
): Promise<boolean> {
  try {
    console.log(`📱 Sending FCM notification to user: ${userId}`);
    
    // Get user's FCM token from Firestore
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (!userData || !userData.messagingToken) {
      console.log('⚠️ No FCM token found for user');
      return false;
    }
    
    const fcmToken = userData.messagingToken;
    
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: 'smart_alert',
        locale: locale,
        timestamp: new Date().toISOString(),
        ...data,
      },
      android: {
        notification: {
          channelId: 'high_importance_channel',
          icon: '@mipmap/ic_launcher',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    const response = await admin.messaging().send(message);
    console.log(`✅ FCM notification sent successfully: ${response}`);
    return true;
    
  } catch (error) {
    console.error(`❌ Error sending FCM notification: ${error}`);
    return false;
  }
}

// Helper function to analyze user data for smart alerts
async function analyzeUserDataForAlerts(userId: string): Promise<{
  alertsSent: number;
  alerts: Array<{type: string; reason: string; sent: boolean}>;
}> {
  try {
    console.log(`📊 Analyzing user data for smart alerts: ${userId}`);
    
    const alerts: Array<{type: string; reason: string; sent: boolean}> = [];
    let alertsSent = 0;
    
    // Get user data from Firestore
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    if (!userData) {
      console.log('⚠️ No user data found');
      return { alertsSent: 0, alerts: [] };
    }
    
    // Analyze high-risk hours
    await analyzeHighRiskHours(userId, userData, alerts);
    
    // Analyze streak vulnerability  
    await analyzeStreakVulnerability(userId, userData, alerts);
    
    // Count successful alerts
    alertsSent = alerts.filter(alert => alert.sent).length;
    
    console.log(`📈 Analysis complete. Alerts found: ${alerts.length}, sent: ${alertsSent}`);
    return { alertsSent, alerts };
    
  } catch (error) {
    console.error(`❌ Error analyzing user data: ${error}`);
    return { alertsSent: 0, alerts: [] };
  }
}

// Analyze high-risk hours based on user's historical data
async function analyzeHighRiskHours(
  userId: string, 
  userData: any, 
  alerts: Array<{type: string; reason: string; sent: boolean}>
): Promise<void> {
  try {
    // Get user's relapse history from the last 90 days
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
    
    const relapses = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('relapses')
      .where('date', '>=', ninetyDaysAgo)
      .get();
    
    if (relapses.empty) {
      console.log('📊 No recent relapse data for high-risk hour analysis');
      return;
    }
    
    // Analyze hour patterns
    const hourCounts: Record<number, number> = {};
    
    relapses.docs.forEach(doc => {
      const relapseData = doc.data();
      if (relapseData.date && relapseData.date.toDate) {
        const hour = relapseData.date.toDate().getHours();
        hourCounts[hour] = (hourCounts[hour] || 0) + 1;
      }
    });
    
    // Find the highest risk hour
    let highestRiskHour = -1;
    let maxCount = 0;
    
    Object.entries(hourCounts).forEach(([hour, count]) => {
      if (count > maxCount) {
        maxCount = count;
        highestRiskHour = parseInt(hour);
      }
    });
    
    if (highestRiskHour !== -1 && maxCount >= 2) {
      const currentHour = new Date().getHours();
      const targetHour = (highestRiskHour - 1 + 24) % 24; // 1 hour before risk hour
      
      // Check if it's currently the alert time (30 minutes before risk hour)
      if (currentHour === targetHour) {
        const minutes = new Date().getMinutes();
        if (minutes >= 30) { // 30 minutes before the risk hour
          alerts.push({
            type: 'highRiskHour',
            reason: `High-risk hour ${highestRiskHour} approaching (${maxCount} historical incidents)`,
            sent: false
          });
        }
      }
    }
    
  } catch (error) {
    console.error(`❌ Error analyzing high-risk hours: ${error}`);
  }
}

// Analyze streak vulnerability based on patterns
async function analyzeStreakVulnerability(
  userId: string, 
  userData: any, 
  alerts: Array<{type: string; reason: string; sent: boolean}>
): Promise<void> {
  try {
    // Get current streak info
    const currentStreak = userData.currentStreak || 0;
    
    // Get historical streak data
    const streaks = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('streaks')
      .orderBy('endDate', 'desc')
      .limit(5)
      .get();
    
    if (streaks.empty) {
      console.log('📊 No streak history for vulnerability analysis');
      return;
    }
    
    // Analyze streak patterns
    const streakLengths: number[] = [];
    
    streaks.docs.forEach(doc => {
      const streakData = doc.data();
      if (streakData.length) {
        streakLengths.push(streakData.length);
      }
    });
    
    if (streakLengths.length >= 2) {
      const averageStreak = streakLengths.reduce((a, b) => a + b, 0) / streakLengths.length;
      const vulnerabilityThreshold = Math.floor(averageStreak * 0.7); // 70% of average
      
      // Check if current streak is approaching vulnerability threshold
      if (currentStreak >= vulnerabilityThreshold && currentStreak < averageStreak) {
        // Check time patterns - weekends and evenings are typically higher risk
        const now = new Date();
        const isWeekend = now.getDay() === 0 || now.getDay() === 6;
        const isEvening = now.getHours() >= 18 && now.getHours() <= 23;
        
        if (isWeekend || isEvening) {
          alerts.push({
            type: 'streakVulnerability',
            reason: `Streak at ${currentStreak} days, approaching vulnerability threshold (${vulnerabilityThreshold}) during ${isWeekend ? 'weekend' : 'evening'}`,
            sent: false
          });
        }
      }
    }
    
  } catch (error) {
    console.error(`❌ Error analyzing streak vulnerability: ${error}`);
  }
}

// Helper function to get user gender from community profile
async function getUserGender(communityProfileId: string): Promise<string | null> {
  try {
    const cpDoc = await admin.firestore().collection('communityProfiles').doc(communityProfileId).get();
    if (!cpDoc.exists) {
      console.log(`⚠️ Community profile not found: ${communityProfileId}`);
      return null;
    }
    
    const cpData = cpDoc.data()!;
    return cpData.gender || null;
  } catch (error) {
    console.error(`❌ Error getting user gender for CP ${communityProfileId}:`, error);
    return null;
  }
}

// Helper function to check gender compatibility and mark comment as deleted if needed
async function checkGenderCompatibilityAndMarkDeleted(commentData: any, commentId: string): Promise<void> {
  try {
    const { authorCPId: commenterCPId, parentFor, parentId } = commentData;
    
    console.log(`🔍 Checking gender compatibility for comment ${commentId} by ${commenterCPId} (parentFor: ${parentFor}, parentId: ${parentId})`);
    
    // Get commenter's gender
    const commenterGender = await getUserGender(commenterCPId);
    if (!commenterGender) {
      console.log(`⚠️ Could not get commenter gender, skipping gender check`);
      return;
    }
    
    let parentAuthorGender: string | null = null;
    
    // Get parent author's gender based on parentFor type
    if (parentFor === 'post') {
      // Get post author's gender
      const postDoc = await admin.firestore().collection('forumPosts').doc(parentId).get();
      if (!postDoc.exists) {
        console.log(`⚠️ Post not found: ${parentId}, skipping gender check`);
        return;
      }
      
      const postData = postDoc.data()!;
      const postAuthorCPId = postData.authorCPId;
      parentAuthorGender = await getUserGender(postAuthorCPId);
      
    } else if (parentFor === 'comment') {
      // Get parent comment author's gender
      const parentCommentDoc = await admin.firestore().collection('comments').doc(parentId).get();
      if (!parentCommentDoc.exists) {
        console.log(`⚠️ Parent comment not found: ${parentId}, skipping gender check`);
        return;
      }
      
      const parentCommentData = parentCommentDoc.data()!;
      const parentCommentAuthorCPId = parentCommentData.authorCPId;
      parentAuthorGender = await getUserGender(parentCommentAuthorCPId);
    } else {
      console.log(`⚠️ Unknown parentFor type: ${parentFor}, skipping gender check`);
      return;
    }
    
    if (!parentAuthorGender) {
      console.log(`⚠️ Could not get parent author gender, skipping gender check`);
      return;
    }
    
    // Compare genders
    console.log(`👥 Gender comparison: commenter(${commenterGender}) vs parent(${parentAuthorGender})`);
    
    if (commenterGender !== parentAuthorGender) {
      // Genders don't match - mark comment as deleted
      console.log(`🚫 Gender mismatch detected! Marking comment ${commentId} as deleted`);
      
      await admin.firestore().collection('comments').doc(commentId).update({
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        deletedReason: 'gender_mismatch'
      });
      
      console.log(`✅ Comment ${commentId} marked as deleted due to gender mismatch`);
    } else {
      console.log(`✅ Gender match confirmed for comment ${commentId}`);
    }
    
  } catch (error) {
    console.error(`❌ Error checking gender compatibility for comment ${commentId}:`, error);
    // Don't throw - we don't want to break the entire flow if gender checking fails
  }
}

// Community notification handler functions
async function handleCommentNotification(commentData: any, commentId: string): Promise<void> {
  try {
    const { postId, authorCPId: commenterCPId, parentFor, parentId } = commentData;
    
    console.log(`💬 New comment notification: comment ${commentId} (parentFor: ${parentFor}, parentId: ${parentId}) by ${commenterCPId}`);
    
    // Handle different types of comments
    if (parentFor === 'post') {
      // This is a comment on a post
      await handlePostCommentNotification(commentData, commentId);
    } else if (parentFor === 'comment') {
      // This is a reply to a comment
      await handleCommentReplyNotification(commentData, commentId);
    } else {
      console.log(`⚠️ Unknown parentFor type: ${parentFor}, skipping notification`);
    }
    
  } catch (error) {
    console.error('❌ Error handling comment notification:', error);
    // Log but don't throw - notification failure shouldn't crash the function
  }
}

async function handlePostCommentNotification(commentData: any, commentId: string): Promise<void> {
  try {
    const { postId, authorCPId: commenterCPId } = commentData;
    
    console.log(`💬 Handling post comment notification: comment ${commentId} on post ${postId} by ${commenterCPId}`);
    
    // Get the post to find the post owner
    const postDoc = await admin.firestore().collection('forumPosts').doc(postId).get();
    if (!postDoc.exists) {
      console.log('⚠️ Post not found, skipping notification');
      return;
    }
    
    const postData = postDoc.data()!;
    const postOwnerCPId = postData.authorCPId;
    
    // Don't notify if commenting on own post
    if (postOwnerCPId === commenterCPId) {
      console.log('ℹ️ User commented on own post, skipping notification');
      return;
    }
    
    // Get post owner's community profile to get the userUID
    const postOwnerCPDoc = await admin.firestore().collection('communityProfiles').doc(postOwnerCPId).get();
    if (!postOwnerCPDoc.exists) {
      console.log('⚠️ Post owner community profile not found, skipping notification');
      return;
    }
    
    const postOwnerCPData = postOwnerCPDoc.data()!;
    const postOwnerUserUID = postOwnerCPData.userUID;
    
    if (!postOwnerUserUID) {
      console.log('⚠️ Post owner community profile missing userUID, skipping notification');
      return;
    }
    
    // Get post owner's user document to check if they exist and get locale
    const postOwnerUserDoc = await admin.firestore().collection('users').doc(postOwnerUserUID).get();
    if (!postOwnerUserDoc.exists) {
      console.log('⚠️ Post owner not found in users collection, skipping notification');
      return;
    }
    
    const postOwnerUserData = postOwnerUserDoc.data()!;
    const locale = postOwnerUserData.locale || 'en';
    
    // Prepare notification content
    const title = translate('new-comment-on-post', locale);
    const postTitle = postData.title && postData.title.length > 30 
      ? postData.title.substring(0, 30) + '...' 
      : postData.title || 'your post';
    const body = translate('someone-commented-on-your-post', locale, {
      postTitle: postTitle
    });
    
    console.log(`📱 Sending post comment notification to user ${postOwnerUserUID} (CP: ${postOwnerCPId}) in locale: ${locale}`);
    
    // Send FCM notification
    const success = await sendFCMNotification(postOwnerUserUID, title, body, locale, {
      type: 'community_notification',
      screen: 'postDetails',
      postId: postId,
      commentId: commentId,
      notificationType: 'comment'
    });
    
    if (success) {
      console.log('✅ Post comment notification sent successfully');
    } else {
      console.log('❌ Failed to send post comment notification');
    }
    
  } catch (error) {
    console.error('❌ Error handling post comment notification:', error);
  }
}

async function handleCommentReplyNotification(commentData: any, commentId: string): Promise<void> {
  try {
    const { postId, authorCPId: replierCPId, parentId: parentCommentId } = commentData;
    
    console.log(`💬 Handling comment reply notification: reply ${commentId} to comment ${parentCommentId} by ${replierCPId}`);
    
    // Get the parent comment to find the comment owner
    const parentCommentDoc = await admin.firestore().collection('comments').doc(parentCommentId).get();
    if (!parentCommentDoc.exists) {
      console.log('⚠️ Parent comment not found, skipping notification');
      return;
    }
    
    const parentCommentData = parentCommentDoc.data()!;
    const commentOwnerCPId = parentCommentData.authorCPId;
    
    // Don't notify if replying to own comment
    if (commentOwnerCPId === replierCPId) {
      console.log('ℹ️ User replied to own comment, skipping notification');
      return;
    }
    
    // Get comment owner's community profile to get the userUID
    const commentOwnerCPDoc = await admin.firestore().collection('communityProfiles').doc(commentOwnerCPId).get();
    if (!commentOwnerCPDoc.exists) {
      console.log('⚠️ Comment owner community profile not found, skipping notification');
      return;
    }
    
    const commentOwnerCPData = commentOwnerCPDoc.data()!;
    const commentOwnerUserUID = commentOwnerCPData.userUID;
    
    if (!commentOwnerUserUID) {
      console.log('⚠️ Comment owner community profile missing userUID, skipping notification');
      return;
    }
    
    // Get comment owner's user document to check if they exist and get locale
    const commentOwnerUserDoc = await admin.firestore().collection('users').doc(commentOwnerUserUID).get();
    if (!commentOwnerUserDoc.exists) {
      console.log('⚠️ Comment owner not found in users collection, skipping notification');
      return;
    }
    
    const commentOwnerUserData = commentOwnerUserDoc.data()!;
    const locale = commentOwnerUserData.locale || 'en';
    
    // Prepare notification content
    const title = translate('new-reply-to-comment', locale);
    const commentText = parentCommentData.body && parentCommentData.body.length > 30 
      ? parentCommentData.body.substring(0, 30) + '...' 
      : parentCommentData.body || 'your comment';
    const body = translate('someone-replied-to-your-comment', locale, {
      commentText: commentText
    });
    
    console.log(`📱 Sending comment reply notification to user ${commentOwnerUserUID} (CP: ${commentOwnerCPId}) in locale: ${locale}`);
    
    // Send FCM notification
    const success = await sendFCMNotification(commentOwnerUserUID, title, body, locale, {
      type: 'community_notification',
      screen: 'postDetails',
      postId: postId,
      commentId: commentId,
      parentCommentId: parentCommentId,
      notificationType: 'commentReply'
    });
    
    if (success) {
      console.log('✅ Comment reply notification sent successfully');
    } else {
      console.log('❌ Failed to send comment reply notification');
    }
    
  } catch (error) {
    console.error('❌ Error handling comment reply notification:', error);
  }
}

async function handleInteractionNotification(interactionData: any): Promise<void> {
  try {
    const { targetType, targetId, userCPId: interactorCPId, value } = interactionData;
    
    console.log(`👍 New interaction notification: ${targetType} ${targetId} by ${interactorCPId} value ${value}`);
    
    // Only notify for likes and dislikes, not neutral (0)
    if (value === 0) {
      console.log('ℹ️ Neutral interaction, skipping notification');
      return;
    }
    
    let targetOwnerCPId: string;
    let targetTitle: string;
    let postId: string;
    
    if (targetType === 'post') {
      const postDoc = await admin.firestore().collection('forumPosts').doc(targetId).get();
      if (!postDoc.exists) {
        console.log('⚠️ Post not found, skipping notification');
        return;
      }
      
      const postData = postDoc.data()!;
      targetOwnerCPId = postData.authorCPId;
      targetTitle = postData.title || 'your post';
      postId = targetId;
    } else if (targetType === 'comment') {
      const commentDoc = await admin.firestore().collection('comments').doc(targetId).get();
      if (!commentDoc.exists) {
        console.log('⚠️ Comment not found, skipping notification');
        return;
      }
      
      const commentData = commentDoc.data()!;
      targetOwnerCPId = commentData.authorCPId;
      targetTitle = commentData.body && commentData.body.length > 30 
        ? commentData.body.substring(0, 30) + '...' 
        : commentData.body || 'your comment';
      postId = commentData.postId; // Comments have postId field
    } else {
      console.log(`⚠️ Unknown target type: ${targetType}, skipping notification`);
      return;
    }
    
    // Don't notify if interacting with own content
    if (targetOwnerCPId === interactorCPId) {
      console.log('ℹ️ User interacted with own content, skipping notification');
      return;
    }
    
    // Get target owner's community profile to get the userUID
    const targetOwnerCPDoc = await admin.firestore().collection('communityProfiles').doc(targetOwnerCPId).get();
    if (!targetOwnerCPDoc.exists) {
      console.log('⚠️ Target owner community profile not found, skipping notification');
      return;
    }
    
    const targetOwnerCPData = targetOwnerCPDoc.data()!;
    const targetOwnerUserUID = targetOwnerCPData.userUID;
    
    if (!targetOwnerUserUID) {
      console.log('⚠️ Target owner community profile missing userUID, skipping notification');
      return;
    }
    
    // Get target owner's user document
    const targetOwnerUserDoc = await admin.firestore().collection('users').doc(targetOwnerUserUID).get();
    if (!targetOwnerUserDoc.exists) {
      console.log('⚠️ Target owner not found in users collection, skipping notification');
      return;
    }
    
    const targetOwnerUserData = targetOwnerUserDoc.data()!;
    const locale = targetOwnerUserData.locale || 'en';
    
    // Determine notification type
    const isLike = value === 1;
    const actionKey = isLike ? 'liked' : 'disliked';
    const titleKey = `${actionKey}-your-${targetType}`;
    
    const title = translate(titleKey, locale);
    const body = translate(`someone-${actionKey}-your-${targetType}`, locale, {
      title: targetTitle
    });
    
    console.log(`📱 Sending interaction notification to user ${targetOwnerUserUID} (CP: ${targetOwnerCPId}) in locale: ${locale}`);
    
    // Send FCM notification
    const success = await sendFCMNotification(targetOwnerUserUID, title, body, locale, {
      type: 'community_notification',
      screen: 'postDetails',
      postId: postId,
      targetId: targetId,
      notificationType: 'interaction',
      interactionType: actionKey
    });
    
    if (success) {
      console.log('✅ Interaction notification sent successfully');
    } else {
      console.log('❌ Failed to send interaction notification');
    }
    
  } catch (error) {
    console.error('❌ Error handling interaction notification:', error);
    // Log but don't throw
  }
}

// Simple test function to verify deployment works
export const helloWorld = onRequest(
  {
    region: 'us-east1',
  },
  (request, response) => {
    response.json({ message: 'Hello from Ta\'aafi Smart Alerts!' });
  }
);

// Simple test function to verify callable functions work
export const testCallable = onCall(
  {
    region: 'us-central1',
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new Error('User must be authenticated');
      }
      
      return {
        success: true,
        message: 'Callable function test successful!',
        userId: request.auth.uid
      };
      
    } catch (error) {
      console.error('❌ Error in test callable:', error);
      throw error;
    }
  }
);

// Smart Alerts function to trigger manual check
export const triggerSmartAlertsCheck = onCall(
  {
    region: 'us-central1',
  },
  async (request) => {
    try {
      console.log('🎯 Manual smart alerts check triggered');
      
      if (!request.auth) {
        const locale = request.data?.locale || 'en';
        throw new Error(translate('user-authenticated-error', locale));
      }
      
      const userId = request.auth.uid;
      const locale = request.data?.locale || 'en';
      
      console.log(`👤 Checking alerts for user: ${userId}`);
      console.log(`🌐 User locale: ${locale}`);
      
      // Perform actual smart alerts analysis
      const analysisResult = await analyzeUserDataForAlerts(userId);
      
      // Send FCM notifications for detected alerts
      for (const alert of analysisResult.alerts) {
        try {
          const title = translate(`${alert.type}-alert`, locale);
          const body = translate(`${alert.type}-message`, locale);
          
          const fcmSent = await sendFCMNotification(userId, title, body, locale, {
            alertType: alert.type,
            reason: alert.reason
          });
          
          alert.sent = fcmSent;
          
        } catch (error) {
          console.error(`❌ Error sending alert ${alert.type}:`, error);
          alert.sent = false;
        }
      }
      
      const actualAlertsSent = analysisResult.alerts.filter(a => a.sent).length;
      
      console.log(`✅ Smart alerts check completed. Alerts sent: ${actualAlertsSent}`);
      
      const localizedMessage = translate('smart-alerts-check-completed', locale, { alertsSent: actualAlertsSent });
      
      return {
        success: true,
        alertsSent: actualAlertsSent,
        message: localizedMessage,
        timestamp: new Date().toISOString(),
        userId: userId,
        locale: locale,
        alertsAnalyzed: analysisResult.alerts.length,
        alertDetails: analysisResult.alerts
      };
      
    } catch (error) {
      console.error('❌ Error in triggerSmartAlertsCheck:', error);
      throw error;
    }
  }
);

// Smart Alerts function to send test notification
export const sendTestSmartAlert = onCall(
  {
    region: 'us-central1',
  },
  async (request) => {
    try {
      console.log('🧪 Test smart alert requested');
      
      if (!request.auth) {
        const locale = request.data?.locale || 'en';
        throw new Error(translate('user-authenticated-error', locale));
      }
      
      const userId = request.auth.uid;
      const alertType = request.data?.alertType || 'highRiskHour';
      const locale = request.data?.locale || 'en';
      
      console.log(`👤 User: ${userId}`);
      console.log(`📱 Alert type: ${alertType}`);
      console.log(`🌐 User locale: ${locale}`);
      
      // Send actual FCM test notification
      const messageKey = alertType === 'highRiskHour' ? 'high-risk-hour-message' : 'streak-vulnerability-message';
      const alertTypeKey = alertType === 'highRiskHour' ? 'high-risk-hour-alert' : 'streak-vulnerability-alert';
      
      const localizedTitle = translate(alertTypeKey, locale);
      const localizedMessage = translate(messageKey, locale);
      const successMessage = translate('test-notification-sent', locale, { alertType: localizedTitle });
      
      // Send actual FCM notification
      const fcmSent = await sendFCMNotification(userId, localizedTitle, localizedMessage, locale, {
        alertType: alertType,
        isTest: 'true'
      });
      
      const fcmStatus = fcmSent ? 
        translate('notification-sent-successfully', locale) : 
        translate('notification-failed', locale);
      
      console.log(`✅ Test notification result: ${fcmSent ? 'sent' : 'failed'}`);
      
      return {
        success: fcmSent,
        message: successMessage,
        testMessage: localizedMessage,
        alertTypeName: localizedTitle,
        timestamp: new Date().toISOString(),
        userId: userId,
        alertType: alertType,
        locale: locale,
        fcmStatus: fcmStatus,
        fcmSent: fcmSent
      };
      
    } catch (error) {
      console.error('❌ Error in sendTestSmartAlert:', error);
      throw error;
    }
  }
);

// User Account Deletion function - handles all user data deletion
export const deleteUserAccount = onCall(
  {
    region: 'us-central1',
    timeoutSeconds: 540, // 9 minutes timeout for comprehensive deletion
  },
  async (request) => {
    try {
      console.log('🗑️ User account deletion requested');
      
      if (!request.auth) {
        throw new Error('User must be authenticated');
      }
      
      const userId = request.auth.uid;
      const startTime = Date.now();
      
      console.log(`👤 Starting comprehensive deletion for user: ${userId}`);
      
      const deletionSummary = {
        userId: userId,
        timestamp: new Date().toISOString(),
        startTime: startTime,
        collections: {} as Record<string, number>,
        totalDocuments: 0,
        errors: [] as string[],
        success: false
      };

      // Initialize Firestore batch operations
      const db = admin.firestore();
      const batchSize = 500; // Firestore batch limit
      
      try {
        // 1. Delete Community Data
        console.log('🏘️ Deleting community data...');
        await deleteCommunityData(db, userId, deletionSummary);
        
        // 2. Delete Vault Data  
        console.log('🏦 Deleting vault data...');
        await deleteVaultData(db, userId, deletionSummary);
        
        // 3. Delete User Profile and Main Document
        console.log('👤 Deleting user profile...');
        await deleteUserProfile(db, userId, deletionSummary);
        
        // 4. Delete Authentication Records
        console.log('🔐 Deleting authentication records...');
        await deleteAuthenticationData(db, userId, deletionSummary);
        
        // 5. Add deletion record for audit purposes
        console.log('📝 Creating deletion audit record...');
        await createDeletionAuditRecord(db, deletionSummary);
        
        const endTime = Date.now();
        const duration = endTime - startTime;
        
        deletionSummary.success = true;
        
        console.log(`✅ User deletion completed successfully in ${duration}ms`);
        console.log(`📊 Deletion summary:`, deletionSummary);
        
        return {
          success: true,
          message: 'User account and all associated data deleted successfully',
          userId: userId,
          duration: duration,
          collectionsProcessed: Object.keys(deletionSummary.collections).length,
          totalDocuments: deletionSummary.totalDocuments,
          timestamp: deletionSummary.timestamp
        };
        
      } catch (error) {
        console.error(`❌ Error during user deletion for ${userId}:`, error);
        deletionSummary.errors.push(error.message);
        
        // Even if some deletions fail, we should still create an audit record
        try {
          await createDeletionAuditRecord(db, deletionSummary);
        } catch (auditError) {
          console.error('❌ Failed to create deletion audit record:', auditError);
        }
        
        throw error;
      }
      
    } catch (error) {
      console.error('❌ Error in deleteUserAccount:', error);
      throw error;
    }
  }
);

// Helper function to delete community data
async function deleteCommunityData(
  db: FirebaseFirestore.Firestore, 
  userId: string, 
  summary: any
): Promise<void> {
  const batch = db.batch();
  let operationCount = 0;
  
  try {
    // Soft delete community profile
    const communityProfileRef = db.collection('communityProfiles').doc(userId);
    const profileSnapshot = await communityProfileRef.get();
    
    if (profileSnapshot.exists) {
      batch.update(communityProfileRef, {
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        displayName: '[Deleted User]',
        avatarUrl: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      operationCount++;
      summary.collections.communityProfiles = 1;
    }
    
    // Soft delete user posts
    const postsQuery = await db.collection('forumPosts')
      .where('authorCPId', '==', userId)
      .get();
    
    postsQuery.docs.forEach(doc => {
      batch.update(doc.ref, {
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        title: '[Post by deleted user]',
        body: '[This post was created by a user who has deleted their account]',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      operationCount++;
    });
    summary.collections.forumPosts = postsQuery.docs.length;
    
    // Soft delete user comments
    const commentsQuery = await db.collection('comments')
      .where('authorCPId', '==', userId)
      .get();
    
    commentsQuery.docs.forEach(doc => {
      batch.update(doc.ref, {
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        body: '[Comment by deleted user]',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      operationCount++;
    });
    summary.collections.comments = commentsQuery.docs.length;
    
    // Soft delete user interactions
    const interactionsQuery = await db.collection('interactions')
      .where('userCPId', '==', userId)
      .get();
    
    interactionsQuery.docs.forEach(doc => {
      batch.update(doc.ref, {
        isDeleted: true,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      operationCount++;
    });
    summary.collections.interactions = interactionsQuery.docs.length;
    
    // Hard delete community interest tracking
    const interestRef = db.collection('communityInterest').doc(userId);
    const interestSnapshot = await interestRef.get();
    
    if (interestSnapshot.exists) {
      batch.delete(interestRef);
      operationCount++;
      summary.collections.communityInterest = 1;
    }
    
    // Execute batch if there are operations
    if (operationCount > 0) {
      await batch.commit();
      console.log(`✅ Community data deletion completed: ${operationCount} operations`);
    } else {
      console.log('ℹ️ No community data found for user');
    }
    
  } catch (error) {
    console.error('❌ Error deleting community data:', error);
    summary.errors.push(`Community deletion failed: ${error.message}`);
    throw error;
  }
}

// Helper function to delete vault data
async function deleteVaultData(
  db: FirebaseFirestore.Firestore, 
  userId: string, 
  summary: any
): Promise<void> {
  try {
    const userRef = db.collection('users').doc(userId);
    
    // Delete user subcollections (activities, emotions, streaks, etc.)
    const subcollections = [
      'activities',
      'emotions', 
      'followups',
      'diaries',
    ];
    
    for (const subcollection of subcollections) {
      const collectionRef = userRef.collection(subcollection);
      const snapshot = await collectionRef.get();
      
      if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        
        await batch.commit();
        summary.collections[subcollection] = snapshot.docs.length;
        console.log(`✅ Deleted ${snapshot.docs.length} documents from ${subcollection}`);
      } else {
        summary.collections[subcollection] = 0;
      }
    }
    
  } catch (error) {
    console.error('❌ Error deleting vault data:', error);
    summary.errors.push(`Vault deletion failed: ${error.message}`);
    throw error;
  }
}

// Helper function to delete user profile
async function deleteUserProfile(
  db: FirebaseFirestore.Firestore, 
  userId: string, 
  summary: any
): Promise<void> {
  try {
    const userRef = db.collection('users').doc(userId);
    const userSnapshot = await userRef.get();
    
    if (userSnapshot.exists) {
      await userRef.delete();
      summary.collections.users = 1;
      console.log('✅ User profile document deleted');
    } else {
      summary.collections.users = 0;
      console.log('ℹ️ No user profile document found');
    }
    
  } catch (error) {
    console.error('❌ Error deleting user profile:', error);
    summary.errors.push(`User profile deletion failed: ${error.message}`);
    throw error;
  }
}

// Helper function to delete authentication data
async function deleteAuthenticationData(
  db: FirebaseFirestore.Firestore, 
  userId: string, 
  summary: any
): Promise<void> {
  try {
    // Delete any authentication-related documents
    const authCollections = [
      'userSessions',
      'refreshTokens', 
      'deviceTokens',
      'loginHistory'
    ];
    
    for (const collection of authCollections) {
      try {
        const collectionRef = db.collection(collection);
        const userDocsQuery = await collectionRef.where('userId', '==', userId).get();
        
        if (!userDocsQuery.empty) {
          const batch = db.batch();
          userDocsQuery.docs.forEach(doc => {
            batch.delete(doc.ref);
          });
          
          await batch.commit();
          summary.collections[collection] = userDocsQuery.docs.length;
          console.log(`✅ Deleted ${userDocsQuery.docs.length} documents from ${collection}`);
        } else {
          summary.collections[collection] = 0;
        }
      } catch (error) {
        console.log(`ℹ️ Collection ${collection} may not exist or is empty`);
        summary.collections[collection] = 0;
      }
    }
    
  } catch (error) {
    console.error('❌ Error deleting authentication data:', error);
    summary.errors.push(`Authentication data deletion failed: ${error.message}`);
    // Don't throw here as this is not critical
  }
}

// Helper function to create deletion audit record
async function createDeletionAuditRecord(
  db: FirebaseFirestore.Firestore, 
  summary: any
): Promise<void> {
  try {
    // Calculate total documents
    summary.totalDocuments = Object.values(summary.collections).reduce((total: number, count: number) => total + count, 0);
    
    await db.collection('deletedUsers').doc(summary.userId).set({
      ...summary,
      auditCreatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Deletion audit record created');
    
  } catch (error) {
    console.error('❌ Error creating deletion audit record:', error);
    throw error;
  }
}

// Import group message notification functions
import { 
  sendGroupMessageNotification, 
  updateNotificationSubscriptions 
} from './groupMessageNotifications';

// Import group member management notification functions
import { 
  sendMemberManagementNotification
} from './groupMemberManagementNotifications';

// Export group message notification functions
export { 
  sendGroupMessageNotification,
  updateNotificationSubscriptions
};

// Export group member management notification functions
export {
  sendMemberManagementNotification
};

// Community Notification Triggers

// Trigger when a new comment is created
export const onCommentCreate = onDocumentCreated(
  {
    document: 'comments/{commentId}',
    region: 'us-central1',
  },
  async (event) => {
    const commentData = event.data?.data();
    const commentId = event.params.commentId;
    
    if (!commentData) {
      console.log('❌ No comment data found in trigger');
      return;
    }
    
    console.log(`🔥 Comment created trigger fired for: ${commentId}`);
    
    // Check gender compatibility and mark as deleted if needed
    await checkGenderCompatibilityAndMarkDeleted(commentData, commentId);
    
    // Handle notifications
    await handleCommentNotification(commentData, commentId);
  }
);

// Trigger when a new interaction is created
export const onInteractionCreate = onDocumentCreated(
  {
    document: 'interactions/{interactionId}',
    region: 'us-central1',
  },
  async (event) => {
    const interactionData = event.data?.data();
    const interactionId = event.params.interactionId;
    
    if (!interactionData) {
      console.log('❌ No interaction data found in trigger');
      return;
    }
    
    console.log(`🔥 Interaction created trigger fired for: ${interactionId}`);
    await handleInteractionNotification(interactionData);
  }
);

// Trigger when an interaction is updated (like/dislike changes)
export const onInteractionUpdate = onDocumentUpdated(
  {
    document: 'interactions/{interactionId}',
    region: 'us-central1',
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const interactionId = event.params.interactionId;
    
    if (!before || !after) {
      console.log('❌ No before/after data found in interaction update trigger');
      return;
    }
    
    // Only trigger if value changed (like/dislike changed)
    if (before.value !== after.value) {
      console.log(`🔥 Interaction updated trigger fired for: ${interactionId} (${before.value} -> ${after.value})`);
      await handleInteractionNotification(after);
    } else {
      console.log(`ℹ️ Interaction updated but value unchanged for: ${interactionId}`);
    }
  }
);
