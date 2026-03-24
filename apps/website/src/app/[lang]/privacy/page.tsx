import type { Metadata } from "next";
import { type Locale, languages } from "../../i18n/settings";
import { getDictionary } from "../../dictionaries/get-dictonaries";
import { fallbackLng } from "../../i18n/settings";
import Header from "../../../components/header";
import Footer from "../../../components/footer";

const BASE_URL = "https://ta3afi.app";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}): Promise<Metadata> {
  const { lang } = await params;

  const titles: Record<Locale, string> = {
    ar: "سياسة الخصوصية",
    en: "Privacy Policy",
  };

  const descriptions: Record<Locale, string> = {
    ar: "سياسة الخصوصية لمنصة تعافي - كيف نحمي بياناتك ونحترم خصوصيتك.",
    en: "Ta'aafi Privacy Policy - How we protect your data and respect your privacy.",
  };

  return {
    title: titles[lang],
    description: descriptions[lang],
    alternates: {
      canonical: `${BASE_URL}/${lang}/privacy`,
      languages: Object.fromEntries(
        languages.map((l) => [l, `${BASE_URL}/${l}/privacy`])
      ),
    },
  };
}

export default async function PrivacyPage({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}) {
  const { lang } = await params;
  const dict = await getDictionary(lang || fallbackLng);

  return (
    <>
      <Header dict={dict} />
      <div className="min-h-screen py-12">
        <div className="container mx-auto px-4">
          <div className="max-w-4xl mx-auto">
            {/* Header */}
            <h1 className="text-4xl font-bold mb-8 text-center">
              {dict.privacyPolicy}
            </h1>

            {/* Last Updated Date */}
            <p className="text-gray-600 mb-8 text-center">
              {dict.lastUpdated}: {dict.privacyLastUpdateDate}
            </p>

            {/* Privacy Policy Content */}
            <div className="prose prose-lg max-w-none">
              <div className="space-y-8">
                {dict.privacyContent.map((section, index) => (
                  <section key={index} className="privacy-section">
                    {section.title && (
                      <h2 className="text-2xl font-semibold mb-4">
                        {section.title}
                      </h2>
                    )}
                    {section.content && (
                      <div
                        className="text-gray-700 whitespace-pre-wrap"
                        style={{ lineHeight: "1.8" }}
                      >
                        {section.content}
                      </div>
                    )}
                  </section>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
      <Footer dict={dict} />
    </>
  );
}

 