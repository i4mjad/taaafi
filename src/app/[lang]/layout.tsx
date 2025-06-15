import { type Locale, languages } from "../i18n/settings";
import { IBM_Plex_Sans_Arabic } from "next/font/google";

export async function generateStaticParams() {
  return languages.map((lang) => ({ lang }));
}

const ibm = IBM_Plex_Sans_Arabic({
  subsets: ["arabic", "latin"],
  weight: [
    "100",
    "200",
    "300",
    "400",
    "500",
    "600",
    "700",
  ],
  display: "swap",
  variable: "--font-ibm",
});

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
      
      <body className={`${ibm.variable} flex min-h-screen flex-col font-ibm`}>
        
        <main className="flex-grow">{children}</main>
      </body>
    </html>
  );
}
