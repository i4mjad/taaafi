import type { Metadata } from "next";
import { type Locale, languages } from "../i18n/settings";

const BASE_URL = "https://ta3afi.app";

export async function generateStaticParams() {
  return languages.map((lang) => ({ lang }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}): Promise<Metadata> {
  const { lang } = await params;
  const otherLang = lang === "ar" ? "en" : "ar";

  return {
    alternates: {
      canonical: `${BASE_URL}/${lang}`,
      languages: {
        [lang]: `${BASE_URL}/${lang}`,
        [otherLang]: `${BASE_URL}/${otherLang}`,
        "x-default": `${BASE_URL}/ar`,
      },
    },
  };
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ lang: Locale }>;
}) {
  const { lang } = await params;
  const dir = lang === "ar" ? "rtl" : "ltr";

  return (
    <html lang={lang} dir={dir} suppressHydrationWarning>

      <body className="flex min-h-screen flex-col font-expo-arabic">

        <main className="flex-grow">{children}</main>
      </body>
    </html>
  );
}
