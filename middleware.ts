import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const locales = ["en", "ar"];
const defaultLocale = "ar";

function getPreferredLocale(request: NextRequest): string {
  // Get the Accept-Language header from the request
  const acceptLanguage = request.headers.get("accept-language");

  if (!acceptLanguage) return defaultLocale;

  // Parse the Accept-Language header
  const preferredLocales = acceptLanguage.split(",").map((lang) => {
    const [locale] = lang.trim().split(";");
    return locale;
  });

  // Check if any of our supported locales match the browser's preferences
  for (const locale of preferredLocales) {
    const shortLocale = locale.slice(0, 2).toLowerCase();
    if (locales.includes(shortLocale)) {
      return shortLocale;
    }
  }

  return defaultLocale;
}

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  // Special case for root path
  if (pathname === "/") {
    const preferredLocale = getPreferredLocale(request);
    return NextResponse.redirect(new URL(`/${preferredLocale}`, request.url));
  }

  // Check if the pathname is missing a locale
  const pathnameIsMissingLocale = locales.every(
    (locale) => !pathname.startsWith(`/${locale}/`) && pathname !== `/${locale}`
  );

  if (pathnameIsMissingLocale) {
    const preferredLocale = getPreferredLocale(request);
    return NextResponse.redirect(
      new URL(`/${preferredLocale}${pathname}`, request.url)
    );
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    // Skip all internal paths (_next)
    "/((?!_next|api|favicon.ico).*)",
  ],
};
