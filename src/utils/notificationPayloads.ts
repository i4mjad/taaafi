/**
 * Simple notification payload structure for Flutter navigation
 * Using GoRouter named routes approach
 */
export interface NotificationPayload {
  notification: {
    title: string;
    body: string;
    image?: string;
  };
  data: {
    [key: string]: string;     // All data fields must be strings for FCM
  };
  android?: {
    priority: 'high' | 'normal';
    ttl?: number;
    notification?: {
      priority?: 'high' | 'normal';
      default_sound?: boolean;
      default_vibrate_timings?: boolean;
      click_action?: string;
    };
  };
  apns?: {
    headers?: {
      'apns-priority'?: string;
      'apns-push-type'?: string;
    };
    payload?: {
      aps: {
        alert: {
          title: string;
          body: string;
        };
        badge?: number;
        sound?: string;
        'content-available'?: number;
        'mutable-content'?: number;
      };
    };
  };
}

/**
 * Creates a simple payload for report updates
 * Following the Medium article approach with GoRouter
 */
export function createReportUpdatePayload(
  title: string,
  body: string,
  reportId: string,
  status: string,
  locale: string = 'en'
): NotificationPayload {
  return {
    notification: {
      title,
      body,
    },
    data: {
      // Simple key-value pairs for GoRouter navigation
      screen: 'reportConversation',      // GoRouter named route
      reportId: reportId,
      status: status,
      type: 'report_update',
      locale: locale,
    },
    android: {
      priority: 'high',
      ttl: 3600000, // 1 hour
      notification: {
        priority: 'high',
        default_sound: true,
        default_vibrate_timings: true,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'alert',
      },
      payload: {
        aps: {
          alert: {
            title,
            body,
          },
          badge: 1,
          sound: 'default',
          'content-available': 1,
          'mutable-content': 1,
        },
      },
    },
  };
}

/**
 * Creates a simple payload for new messages
 */
export function createNewMessagePayload(
  title: string,
  body: string,
  reportId: string,
  messageFrom: string,
  locale: string = 'en'
): NotificationPayload {
  return {
    notification: {
      title,
      body,
    },
    data: {
      // Simple key-value pairs for GoRouter navigation
      screen: 'reportDetails',      // GoRouter named route
      reportId: reportId,
      messageFrom: messageFrom,
      type: 'new_message',
      openConversation: 'true',     // String boolean
      locale: locale,
    },
    android: {
      priority: 'high',
      ttl: 3600000,
      notification: {
        priority: 'high',
        default_sound: true,
        default_vibrate_timings: true,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'alert',
      },
      payload: {
        aps: {
          alert: {
            title,
            body,
          },
          badge: 1,
          sound: 'default',
          'content-available': 1,
          'mutable-content': 1,
        },
      },
    },
  };
}

/**
 * Creates a generic payload for custom notifications
 * You can extend this pattern for other notification types
 */
export function createGenericNavigationPayload(
  title: string,
  body: string,
  screen: string,              // GoRouter named route
  additionalData?: Record<string, string>
): NotificationPayload {
  return {
    notification: {
      title,
      body,
    },
    data: {
      screen,
      ...additionalData,
    },
    android: {
      priority: 'high',
      notification: {
        priority: 'high',
        default_sound: true,
        default_vibrate_timings: true,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'alert',
      },
      payload: {
        aps: {
          alert: {
            title,
            body,
          },
          sound: 'default',
          'content-available': 1,
        },
      },
    },
  };
}

/**
 * Creates a payload for ban notifications
 * Navigates user to their profile screen where they can see ban details
 */
export function createBanNotificationPayload(
  title: string,
  body: string,
  userId: string,
  banType: string,
  severity: string,
  locale: string = 'en'
): NotificationPayload {
  return {
    notification: {
      title,
      body,
    },
    data: {
      screen: 'userProfile',      // GoRouter named route to user profile
      userId: userId,
      type: 'ban_notification',
      banType: banType,
      severity: severity,
      locale: locale,
    },
    android: {
      priority: 'high',
      ttl: 86400000, // 24 hours
      notification: {
        priority: 'high',
        default_sound: true,
        default_vibrate_timings: true,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'alert',
      },
      payload: {
        aps: {
          alert: {
            title,
            body,
          },
          badge: 1,
          sound: 'default',
          'content-available': 1,
          'mutable-content': 1,
        },
      },
    },
  };
}

/**
 * Creates a payload for warning notifications
 * Navigates user to their profile screen where they can see warning details
 */
export function createWarningNotificationPayload(
  title: string,
  body: string,
  userId: string,
  warningType: string,
  severity: string,
  locale: string = 'en'
): NotificationPayload {
  return {
    notification: {
      title,
      body,
    },
    data: {
      screen: 'userProfile',      // GoRouter named route to user profile
      userId: userId,
      type: 'warning_notification',
      warningType: warningType,
      severity: severity,
      locale: locale,
    },
    android: {
      priority: 'high',
      ttl: 86400000, // 24 hours
      notification: {
        priority: 'high',
        default_sound: true,
        default_vibrate_timings: true,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'alert',
      },
      payload: {
        aps: {
          alert: {
            title,
            body,
          },
          badge: 1,
          sound: 'default',
          'content-available': 1,
          'mutable-content': 1,
        },
      },
    },
  };
} 