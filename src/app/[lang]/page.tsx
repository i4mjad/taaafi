import { type Locale, fallbackLng } from "../i18n/settings";
import { getDictionary } from "../dictionaries/get-dictonaries";
import { HeroScrollSection } from "@/components/hero-scroll";
import Header from "@/components/header";
import AboutSectionCompanyValues from "@/components/about-section";
import Footer from "@/components/footer";
import StatisticsSection from "@/components/statistics-section";
import { Contact } from "lucide-react";

export default async function ComingSoonPage({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}) {
  const { lang } = await params;
  const dict = await getDictionary(lang || fallbackLng);

  return (
    <>
      <HeroScrollSection dict={dict} />
      
      <AboutSectionCompanyValues />

      {/* Statistics Section */}
      <StatisticsSection />

      {/* Contact Section */}
      <Contact />

      {/* Footer */}
      <Footer />
    </>
  );
}

export const dynamic = "force-dynamic";
