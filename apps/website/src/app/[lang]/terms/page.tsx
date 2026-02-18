import { Locale } from "../../i18n/settings";
import { getDictionary } from "../../dictionaries/get-dictonaries";
import { fallbackLng } from "../../i18n/settings";
import Header from "../../../components/header";
import Footer from "../../../components/footer";

export default async function TermsPage({
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
              {dict.termsAndConditions}
            </h1>

            {/* Last Updated Date */}
            <p className="text-gray-600 mb-8 text-center">
              {dict.lastUpdated}: {dict.termsLastUpdateDate}
            </p>

            {/* Terms Content */}
            <div className="prose prose-lg max-w-none">
              <div className="space-y-8">
                {dict.termsContent.map((section, index) => (
                  <section key={index} className="terms-section">
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

export const dynamic = "force-dynamic";
