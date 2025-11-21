/**
 * TypeScript interfaces for RevenueCat API
 */

export interface RevenueCatSubscriber {
  subscriber: {
    original_app_user_id: string;
    subscriptions: {
      [key: string]: {
        expires_date: string | null;
        purchase_date: string;
        period_type: string;
        store: string;
      };
    };
    entitlements: {
      [key: string]: {
        expires_date: string | null;
        product_identifier: string;
        purchase_date: string;
      };
    };
  };
}

export interface GrantEntitlementRequest {
  duration: string; // ISO 8601 duration (e.g., "P30D", "P1M", "P2W")
  start_time_ms?: number; // Optional start time in milliseconds
}

export interface GrantEntitlementResponse {
  success: boolean;
  expiresAt: Date;
  error?: string;
}

export interface RevenueCatError {
  message: string;
  code?: number;
  backend_error_code?: string;
}

