import type React from "react"
import type { Metadata } from "next"
import "../globals.css"
import { Toaster } from "../../components/ui/sonner"
import { i18n, Locale } from "../../../i18n.config"
import { ThemeProvider } from "next-themes"

export async function generateStaticParams() {
  return i18n.locales.map((locale) => ({ lang: locale }))
}

export const metadata: Metadata = {
  title: "Dashboard App",
  description: "A modern dashboard application",
}

export default async function RootLayout({
  children,
  params,
}: Readonly<{
  children: React.ReactNode
  params: Promise<{ lang: Locale }>
}>) {
  // In Next.js 15, `params` is asynchronous. Await it before using its properties.
  const { lang } = await params;

  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
      <div className="font-sans" dir={lang === "ar" ? "rtl" : "ltr"}>
        {children}
        <Toaster />
      </div>
    </ThemeProvider>
  )
}
