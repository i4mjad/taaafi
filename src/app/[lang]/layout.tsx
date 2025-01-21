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
  const dir = lang === "ar" ? "rtl" : "ltr";

  return (
    <html lang={lang} dir={dir}>
      <body className={"flex min-h-screen flex-col font-kufam"}>
        <nav className="p-4">
          <div className="flex justify-center">
            {["en", "ar"].map((l) => (
              <Link
                key={l}
                href={`/${l}`}
                className={`mx-2 ${l === lang ? "font-bold" : ""}`}
              >
                {l.toUpperCase()}
              </Link>
            ))}
          </div>
        </nav>
        <main className="flex-grow">{children}</main>
      </body>
    </html>
  );
}
