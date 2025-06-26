import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

import { match as matchLocale } from "@formatjs/intl-localematcher"
import Negotiator from "negotiator"
import { i18n, Locale } from "./i18n.config"

function getLocale(request: NextRequest): Locale {
  const negotiatorHeaders: Record<string, string> = {}
  request.headers.forEach((value, key) => (negotiatorHeaders[key] = value))

  const locales: string[] = [...i18n.locales]
  const languages = new Negotiator({ headers: negotiatorHeaders }).languages(locales)

  const locale = matchLocale(languages, locales, i18n.defaultLocale)
  return locale as Locale
}

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname

  console.log('Middleware: pathname =', pathname)

  // Check if there is any supported locale in the pathname
  const pathnameIsMissingLocale = i18n.locales.every(
    (locale) => !pathname.startsWith(`/${locale}/`) && pathname !== `/${locale}`,
  )

  console.log('Middleware: pathnameIsMissingLocale =', pathnameIsMissingLocale)

  // Redirect if there is no locale
  if (pathnameIsMissingLocale) {
    const locale = getLocale(request)
    console.log('Middleware: locale =', locale)

    // Handle root path
    if (pathname === "/") {
      const redirectUrl = `/${locale}/dashboard`
      console.log('Middleware: root redirect to =', redirectUrl)
      return NextResponse.redirect(new URL(redirectUrl, request.url))
    }

    // Handle other paths
    const redirectUrl = `/${locale}${pathname}`
    console.log('Middleware: other paths redirect to =', redirectUrl)
    return NextResponse.redirect(new URL(redirectUrl, request.url))
  }
}

export const config = {
  // Matcher ignoring `/_next/`, `/api/`, and static files
  matcher: [
    // Skip all internal paths (_next)
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
    // Optional: only run on root (/) URL
    // '/'
  ],
}
