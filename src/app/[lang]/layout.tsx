import type React from "react"
import type { Metadata } from "next"
import "../globals.css"
import { Toaster } from "../../components/ui/sonner"
import { i18n, Locale } from "../../../i18n.config"
import { ThemeProvider } from "next-themes"
import { DirectionWrapper } from "@/components/direction-provider"
import UpdateHtmlAttributes from "@/components/update-html-attributes"
import { AuthProvider } from '@/auth/AuthProvider';
import { TranslationProvider } from '@/contexts/TranslationContext';
import { getDictionary } from '@/lib/dictionary';
import { MainLayout } from '@/layout/MainLayout';

export async function generateStaticParams() {
  return i18n.locales.map((locale) => ({ lang: locale }))
}

const metadataByLocale: Record<Locale, Metadata> = {
  en: {
    title: "Ta'aafi Platform Admin Portal",
    description: "Ta'aafi Platform Admin Portal",
  },
  ar: {
    title: "منصة تعافي - بوابة الإدارة",
    description: "بوابة إدارة منصة تعافي",
  },
}

export async function generateMetadata(
  { params }: { params: Promise<{ lang: Locale }> }
): Promise<Metadata> {
  const { lang } = await params
  return metadataByLocale[lang] ?? metadataByLocale.ar
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
  
  // Load dictionary for translation context
  const dictionary = await getDictionary(lang);

  return (
    <DirectionWrapper locale={lang}>
      <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
        <AuthProvider>
          <TranslationProvider locale={lang} initialDictionary={dictionary}>
            <UpdateHtmlAttributes lang={lang} />
            <MainLayout>
              {children}
            </MainLayout>
            <Toaster />
          </TranslationProvider>
        </AuthProvider>
      </ThemeProvider>
    </DirectionWrapper>
  )
}
