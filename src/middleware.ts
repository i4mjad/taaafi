import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// List of supported languages
const supportedLocales = ["en", "es", "fr", "de"];
const defaultLocale = "en";

export function middleware(request: NextRequest) {
  // Get pathname
  const pathname = request.nextUrl.pathname;

  // Skip if request is for static files or API routes
  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/api") ||
    pathname.includes(".")
  ) {
    return;
  }

  // Get the preferred language from browser
  const acceptLanguage = request.headers.get("accept-language");
  let browserLocale = defaultLocale;

  if (acceptLanguage) {
    // Parse the Accept-Language header and get the first supported locale
    browserLocale =
      acceptLanguage
        .split(",")
        .map((lang) => lang.split(";")[0].substring(0, 2))
        .find((lang) => supportedLocales.includes(lang)) || defaultLocale;
  }

  // Check if pathname already starts with locale
  const pathnameHasLocale = supportedLocales.some(
    (locale) => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  );

  if (pathnameHasLocale) return;

  // Redirect to the same pathname with locale prefix
  return NextResponse.redirect(
    new URL(`/${browserLocale}${pathname === "/" ? "" : pathname}`, request.url)
  );
}

export const config = {
  matcher: [
    // Skip all internal paths (_next)
    "/((?!_next|api|images).*)",
    // Optional: Skip static files
    // '/((?!_next|api|images|favicon.ico).*)',
  ],
};
