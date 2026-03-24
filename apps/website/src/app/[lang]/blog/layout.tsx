import type { Metadata } from "next";
import type { Locale } from "../../i18n/settings";
import { languages } from "../../i18n/settings";

const BASE_URL = "https://ta3afi.app";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}): Promise<Metadata> {
  const { lang } = await params;

  const titles: Record<Locale, string> = {
    ar: "المدونة - مقالات ونصائح للتعافي",
    en: "Blog - Recovery Articles & Insights",
  };

  const descriptions: Record<Locale, string> = {
    ar: "اقرأ أحدث المقالات والنصائح حول التعافي من الإدمان، التكنولوجيا، والتطوير الذاتي من فريق تعافي.",
    en: "Read the latest articles and insights on addiction recovery, technology, and self-improvement from the Ta'aafi team.",
  };

  return {
    title: titles[lang],
    description: descriptions[lang],
    alternates: {
      canonical: `${BASE_URL}/${lang}/blog`,
      languages: Object.fromEntries(
        languages.map((l) => [l, `${BASE_URL}/${l}/blog`])
      ),
    },
    openGraph: {
      title: titles[lang],
      description: descriptions[lang],
      url: `${BASE_URL}/${lang}/blog`,
    },
  };
}

export default function BlogLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
