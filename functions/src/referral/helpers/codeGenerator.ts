/**
 * Referral Code Generator Helpers
 * Generates unique, user-friendly referral codes
 */

import * as admin from "firebase-admin";

// Characters to use (excluding confusing ones: 0, O, 1, I, l)
const SAFE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

/**
 * Generate a referral code from user name/email
 * @param name - User's display name
 * @param email - User's email
 * @returns A formatted referral code (e.g., "ABC123" or "AHMAD7")
 */
export function generateUniqueCode(name: string, email: string): string {
  let prefix = "";

  // Try to extract prefix from name first
  if (name && name.trim().length > 0) {
    // Remove special characters and get first 3-4 letters
    const cleanName = name
      .trim()
      .toUpperCase()
      .replace(/[^A-Z]/g, "");

    if (cleanName.length >= 3) {
      prefix = cleanName.substring(0, Math.min(4, cleanName.length));
    }
  }

  // Fallback to email if name didn't work
  if (prefix.length < 3 && email) {
    const emailPrefix = email.split("@")[0].toUpperCase().replace(/[^A-Z]/g, "");
    if (emailPrefix.length >= 3) {
      prefix = emailPrefix.substring(0, Math.min(4, emailPrefix.length));
    }
  }

  // If still no good prefix, use random letters
  if (prefix.length < 3) {
    prefix = "";
    for (let i = 0; i < 3; i++) {
      const letterIndex = Math.floor(Math.random() * 26);
      prefix += String.fromCharCode(65 + letterIndex); // A-Z
    }
  }

  // Ensure prefix uses only safe characters
  prefix = prefix
    .split("")
    .map((char) => (SAFE_CHARS.includes(char) ? char : SAFE_CHARS[Math.floor(Math.random() * 26)]))
    .join("");

  // Add random numeric/alphanumeric suffix
  const suffixLength = 8 - prefix.length; // Total length should be 6-8
  let suffix = "";
  for (let i = 0; i < suffixLength; i++) {
    suffix += SAFE_CHARS.charAt(Math.floor(Math.random() * SAFE_CHARS.length));
  }

  return (prefix + suffix).substring(0, 8); // Max 8 characters
}

/**
 * Check if a code is unique in Firestore
 * @param code - The code to check
 * @returns True if code doesn't exist, false otherwise
 */
export async function isCodeUnique(code: string): Promise<boolean> {
  const db = admin.firestore();

  const querySnapshot = await db
    .collection("referralCodes")
    .where("code", "==", code)
    .where("isActive", "==", true)
    .limit(1)
    .get();

  return querySnapshot.empty;
}

/**
 * Generate a unique code with retries
 * @param name - User's display name
 * @param email - User's email
 * @param maxAttempts - Maximum number of attempts (default: 10)
 * @returns A unique referral code
 * @throws Error if unable to generate unique code after max attempts
 */
export async function generateAndEnsureUniqueCode(
  name: string,
  email: string,
  maxAttempts: number = 10
): Promise<string> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const code = generateUniqueCode(name, email);

    if (await isCodeUnique(code)) {
      console.log(`✅ Generated unique code: ${code} (attempt ${attempt})`);
      return code;
    }

    console.log(`⚠️ Code collision on attempt ${attempt}: ${code}`);

    // On later attempts, add more randomness
    if (attempt > 5) {
      // Generate fully random code
      let randomCode = "";
      for (let i = 0; i < 8; i++) {
        randomCode += SAFE_CHARS.charAt(
          Math.floor(Math.random() * SAFE_CHARS.length)
        );
      }

      if (await isCodeUnique(randomCode)) {
        console.log(`✅ Generated random unique code: ${randomCode} (attempt ${attempt})`);
        return randomCode;
      }
    }
  }

  throw new Error(
    `Failed to generate unique code after ${maxAttempts} attempts`
  );
}
