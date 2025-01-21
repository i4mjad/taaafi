import { type Locale, languages, fallbackLng } from "../i18n/settings";
import Link from "next/link";

export async function generateStaticParams() {
  return languages.map((lang) => ({ lang }));
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { lang: Locale };
}) {
  const { lang } = await params;

  return (
    <html lang={lang} dir={lang === "ar" ? "rtl" : "ltr"}>
      <body
        className={`flex min-h-screen flex-col ${
          lang === "ar" ? "font-arabic" : "font-sans"
        }`}
      >
        <header className="p-4 flex justify-end">
          <nav>
            {languages.map((l) => (
              <Link
                key={l}
                href={`/${l}`}
                className={`mx-2 ${l === lang ? "font-bold" : ""}`}
              >
                {l.toUpperCase()}
              </Link>
            ))}
          </nav>
        </header>
        <main className="flex-grow">{children}</main>
      </body>
    </html>
  );
}
