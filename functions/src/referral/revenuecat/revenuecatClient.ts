/**
 * RevenueCat API Client
 * Handles low-level HTTP requests to RevenueCat REST API
 * 
 * IMPORTANT: Uses v1 API for promotional entitlements (v2 doesn't support this feature)
 * Secret API keys (sk_*) work with both v1 and v2 endpoints
 */

import axios, { AxiosInstance, AxiosError } from "axios";
import * as functions from "firebase-functions";
import {
  GrantEntitlementRequest,
  RevenueCatSubscriber,
  RevenueCatError,
} from "./types";

const REVENUECAT_API_V1_BASE_URL = "https://api.revenuecat.com/v1";
const REVENUECAT_API_V2_BASE_URL = "https://api.revenuecat.com/v2";

export class RevenueCatClient {
  private clientV1: AxiosInstance;
  private clientV2: AxiosInstance;
  private secretKey: string;

  constructor(secretKey?: string) {
    // Get API key from .env file OR Firebase config (for backward compatibility)
    // Priority: 1. Constructor param, 2. .env (REVENUECAT_SECRET_KEY_V1), 3. Firebase config (deprecated)
    this.secretKey =
      secretKey ||
      process.env.REVENUECAT_SECRET_KEY_V1 ||
      functions.config().revenuecat?.secret_key ||
      "";

    if (!this.secretKey) {
      console.error(
        "❌ RevenueCat: Secret key not configured. Add REVENUECAT_SECRET_KEY_V1 to functions/.env file or set via Firebase config"
      );
      throw new Error("RevenueCat secret key is not configured");
    }

    console.log(
      `✅ RevenueCat client initialized with key: ${this.secretKey.substring(0, 8)}...`
    );

    // Create v1 client for promotional entitlements (required!)
    this.clientV1 = axios.create({
      baseURL: REVENUECAT_API_V1_BASE_URL,
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        "Content-Type": "application/json",
      },
      timeout: 10000, // 10 second timeout
    });

    // Create v2 client for other operations (future use)
    this.clientV2 = axios.create({
      baseURL: REVENUECAT_API_V2_BASE_URL,
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        "Content-Type": "application/json",
      },
      timeout: 10000, // 10 second timeout
    });
  }

  /**
   * Get subscriber information from RevenueCat
   */
  async getSubscriber(userId: string): Promise<RevenueCatSubscriber | null> {
    try {
      console.log(`RevenueCat API: Fetching subscriber info for ${userId}`);
      // Use v2 API for getting subscriber info (better, newer API)
      const response = await this.clientV2.get<RevenueCatSubscriber>(
        `/subscribers/${userId}`
      );
      console.log(`RevenueCat API: Successfully fetched subscriber ${userId}`);
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const axiosError = error as AxiosError<RevenueCatError>;
        if (axiosError.response?.status === 404) {
          console.log(`RevenueCat API: Subscriber ${userId} not found`);
          return null;
        }
        console.error(
          `RevenueCat API Error: ${axiosError.response?.status} - ${axiosError.response?.data?.message}`
        );
      } else {
        console.error(`RevenueCat API Error:`, error);
      }
      return null;
    }
  }

  /**
   * Grant promotional entitlement to a user
   * IMPORTANT: Must use v1 API - this endpoint doesn't exist in v2!
   * @param userId - Firebase UID
   * @param entitlementId - Entitlement identifier (e.g., "taaafi_plus")
   * @param request - Grant request with duration
   */
  async grantPromotionalEntitlement(
    userId: string,
    entitlementId: string,
    request: GrantEntitlementRequest
  ): Promise<RevenueCatSubscriber | null> {
    try {
      console.log(
        `🎁 RevenueCat API v1: Granting ${entitlementId} to ${userId} for ${request.duration}`
      );
      console.log(`📍 API URL: ${REVENUECAT_API_V1_BASE_URL}/subscribers/${userId}/entitlements/${entitlementId}/promotional`);
      console.log(`📦 Request body:`, JSON.stringify(request));

      // MUST use v1 client - promotional entitlements don't exist in v2!
      const response = await this.clientV1.post<RevenueCatSubscriber>(
        `/subscribers/${userId}/entitlements/${entitlementId}/promotional`,
        request
      );

      console.log(
        `✅ RevenueCat API: Successfully granted ${entitlementId} to ${userId}`
      );
      console.log(`📊 Response:`, JSON.stringify(response.data).substring(0, 200));
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const axiosError = error as AxiosError<RevenueCatError>;
        console.error(
          `❌ RevenueCat API Error: ${axiosError.response?.status} - ${JSON.stringify(axiosError.response?.data)}`
        );
        console.error(`🔍 Request URL: ${axiosError.config?.url}`);
        console.error(`🔍 Request method: ${axiosError.config?.method}`);
        console.error(`🔍 Request headers: ${JSON.stringify(axiosError.config?.headers)}`);
        
        throw new Error(
          axiosError.response?.data?.message ||
            `RevenueCat API error: ${axiosError.message}` ||
            "Failed to grant promotional entitlement"
        );
      } else {
        console.error(`❌ RevenueCat Non-Axios Error:`, error);
        throw new Error(
          error instanceof Error ? error.message : "Failed to grant promotional entitlement"
        );
      }
    }
  }

  /**
   * Check if user has active entitlement
   */
  async hasActiveEntitlement(
    userId: string,
    entitlementId: string
  ): Promise<boolean> {
    try {
      const subscriber = await this.getSubscriber(userId);
      if (!subscriber) {
        return false;
      }

      const entitlement =
        subscriber.subscriber.entitlements[entitlementId];
      if (!entitlement) {
        return false;
      }

      // Check if entitlement is active (not expired)
      if (!entitlement.expires_date) {
        return true; // Lifetime entitlement
      }

      const expiresAt = new Date(entitlement.expires_date);
      const now = new Date();
      return expiresAt > now;
    } catch (error) {
      console.error(
        `Error checking entitlement for ${userId}:`,
        error
      );
      return false;
    }
  }

  /**
   * Convert days to RevenueCat v1 API duration format
   * v1 API only accepts specific predefined values:
   * - daily, three_day, weekly, monthly, two_month, three_month, six_month, yearly, lifetime
   */
  static daysToISO8601Duration(days: number): string {
    if (days < 1) {
      throw new Error("Duration must be at least 1 day");
    }

    // Map to RevenueCat's predefined duration values
    if (days === 1) return "daily";
    if (days === 3) return "three_day";
    if (days === 7) return "weekly";
    if (days === 30) return "monthly";
    if (days === 60) return "two_month";
    if (days === 90) return "three_month";
    if (days === 180) return "six_month";
    if (days === 365) return "yearly";
    
    // For custom durations, use the closest predefined value
    if (days <= 2) return "daily";
    if (days <= 5) return "three_day";
    if (days <= 20) return "weekly";
    if (days <= 45) return "monthly";
    if (days <= 75) return "two_month";
    if (days <= 135) return "three_month";
    if (days <= 270) return "six_month";
    
    return "yearly";
  }
}

// Singleton instance
let clientInstance: RevenueCatClient | null = null;

export function getRevenueCatClient(): RevenueCatClient {
  if (!clientInstance) {
    clientInstance = new RevenueCatClient();
  }
  return clientInstance;
}

