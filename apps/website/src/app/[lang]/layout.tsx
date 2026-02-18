import { type Locale, languages } from "../i18n/settings";

export async function generateStaticParams() {
  return languages.map((lang) => ({ lang }));
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ lang: Locale }>;
}) {
  const { lang } = await params;
  // const dict = await getDictionary(lang || fallbackLng);
  const dir = lang === "ar" ? "rtl" : "ltr";

  return (
    <html lang={lang} dir={dir} suppressHydrationWarning>
      
      <body className="flex min-h-screen flex-col font-expo-arabic">
        
        <main className="flex-grow">{children}</main>
      </body>
    </html>
  );
}
