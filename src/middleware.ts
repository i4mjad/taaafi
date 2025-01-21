import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// List of supported languages
const supportedLocales = ["en", "ar"];
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

  // Check if the pathname starts with a supported locale
  const pathnameParts = pathname.split("/");
  const firstSegment = pathnameParts[1];

  // If URL already has a supported locale, don't redirect
  if (supportedLocales.includes(firstSegment)) {
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

  // Redirect to the same pathname with locale prefix
  return NextResponse.redirect(
    new URL(`/${browserLocale}${pathname === "/" ? "" : pathname}`, request.url)
  );
}

export const config = {
  matcher: ["/((?!_next|api|images).*)"],
};
