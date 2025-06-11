import Header from "@/components/header";
import { type Locale, languages, fallbackLng } from "../i18n/settings";
import { getDictionary } from "../dictionaries/get-dictonaries";
import Link from "next/link";

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
  const dict = await getDictionary(lang || fallbackLng);
  const dir = lang === "ar" ? "rtl" : "ltr";

  return (
    <html lang={lang} dir={dir}>
      <body className={"flex min-h-screen flex-col font-ibm"}>
        
        <main className="flex-grow">{children}</main>
      </body>
    </html>
  );
}
