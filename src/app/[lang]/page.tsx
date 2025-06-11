import { type Locale, fallbackLng } from "../i18n/settings";
import { getDictionary } from "../dictionaries/get-dictonaries";
import { HeroScrollSection } from "@/components/hero-scroll";
import Header from "@/components/header";
import AboutSectionCompanyValues from "@/components/about-section";
import Footer from "@/components/footer";
import StatisticsSection from "@/components/statistics-section";

export default async function ComingSoonPage({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}) {
  const { lang } = await params;
  const dict = await getDictionary(lang || fallbackLng);

  return (
    <>
      <Header dict={dict} />
      
      <HeroScrollSection dict={dict} />
      
      <section id="features">
        <AboutSectionCompanyValues />
      </section>

      {/* Statistics Section */}
      <section id="statistics">
        <StatisticsSection />
      </section>

      {/* Contact Section */}
      <section id="contact">
        {/* Contact component would go here */}
        <div className="py-16">
          <div className="container mx-auto px-4 text-center">
            <h2 className="text-3xl font-bold mb-8">Contact Us</h2>
            <p className="text-gray-600">Get in touch with us for more information.</p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <Footer />
    </>
  );
}

export const dynamic = "force-dynamic";
