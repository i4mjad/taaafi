import {onRequest} from 'firebase-functions/v2/https';
import {onCall} from 'firebase-functions/v2/https';
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
  }
};

// Helper function to translate based on locale
function translate(key: string, locale: string = 'en', replacements?: Record<string, string | number>): string {
  const languageCode = locale.split('-')[0]; // Handle locales like 'en-US'
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
