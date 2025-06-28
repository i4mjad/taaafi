import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// List of supported languages
const supportedLocales = ["ar", "en"];
const defaultLocale = "ar";

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

  // Always use Arabic as the locale (no browser language detection)
  const locale = "ar";

  // Redirect to the same pathname with Arabic locale prefix
  return NextResponse.redirect(
    new URL(`/${locale}${pathname === "/" ? "" : pathname}`, request.url)
  );
}

export const config = {
  matcher: ["/((?!_next|api|images).*)"],
};
