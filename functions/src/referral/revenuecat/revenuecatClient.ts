/**
 * RevenueCat API Client
 * Handles low-level HTTP requests to RevenueCat REST API v1
 */

import axios, { AxiosInstance, AxiosError } from "axios";
import * as functions from "firebase-functions";
import {
  GrantEntitlementRequest,
  RevenueCatSubscriber,
  RevenueCatError,
} from "./types";

const REVENUECAT_API_BASE_URL = "https://api.revenuecat.com/v1";

export class RevenueCatClient {
  private client: AxiosInstance;
  private secretKey: string;

  constructor(secretKey?: string) {
    // Get API key from Firebase config or constructor parameter
    this.secretKey =
      secretKey || functions.config().revenuecat?.secret_key || "";

    if (!this.secretKey) {
      console.error(
        "RevenueCat: Secret key not configured. Set with: firebase functions:config:set revenuecat.secret_key=sk_XXXXX"
      );
    }

    this.client = axios.create({
      baseURL: REVENUECAT_API_BASE_URL,
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
      const response = await this.client.get<RevenueCatSubscriber>(
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
        `RevenueCat API: Granting ${entitlementId} to ${userId} for ${request.duration}`
      );

      const response = await this.client.post<RevenueCatSubscriber>(
        `/subscribers/${userId}/entitlements/${entitlementId}/promotional`,
        request
      );

      console.log(
        `RevenueCat API: Successfully granted ${entitlementId} to ${userId}`
      );
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const axiosError = error as AxiosError<RevenueCatError>;
        console.error(
          `RevenueCat API Error: ${axiosError.response?.status} - ${JSON.stringify(axiosError.response?.data)}`
        );
        throw new Error(
          axiosError.response?.data?.message ||
            "Failed to grant promotional entitlement"
        );
      } else {
        console.error(`RevenueCat API Error:`, error);
        throw new Error("Failed to grant promotional entitlement");
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
   * Calculate ISO 8601 duration from days
   */
  static daysToISO8601Duration(days: number): string {
    if (days < 1) {
      throw new Error("Duration must be at least 1 day");
    }

    // For simplicity, we'll use days primarily
    // But could optimize for months/weeks for cleaner durations
    if (days % 30 === 0 && days >= 30) {
      const months = Math.floor(days / 30);
      const remainingDays = days % 30;
      if (remainingDays === 0) {
        return `P${months}M`;
      }
      return `P${months}M${remainingDays}D`;
    } else if (days % 7 === 0 && days >= 7) {
      const weeks = Math.floor(days / 7);
      const remainingDays = days % 7;
      if (remainingDays === 0) {
        return `P${weeks}W`;
      }
      return `P${weeks}W${remainingDays}D`;
    }

    return `P${days}D`;
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

