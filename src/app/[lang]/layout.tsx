import { type Locale, languages, fallbackLng } from "../i18n/settings";
import Link from "next/link";

export async function generateStaticParams() {
  return languages.map((lang) => ({ lang }));
}

export default function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { lang: string };
}) {
  const dir = params.lang === "ar" ? "rtl" : "ltr";
  const fontClass = params.lang === "ar" ? "font-arabic" : "font-sans";

  return (
    <html lang={params.lang} dir={dir}>
      <body className={`flex min-h-screen flex-col antialiased ${fontClass}`}>
        <header className="p-4 flex justify-end">
          <nav>
            {languages.map((l) => (
              <Link
                key={l}
                href={`/${l}`}
                className={`mx-2 ${l === params.lang ? "font-bold" : ""}`}
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
