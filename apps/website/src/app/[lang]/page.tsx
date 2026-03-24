import type { Metadata } from "next";
import { type Locale, fallbackLng, languages } from "../i18n/settings";
import { getDictionary } from "../dictionaries/get-dictonaries";
import { HeroScrollSection } from "@/components/hero-scroll";
import Header from "@/components/header";
import AboutSectionCompanyValues from "@/components/about-section";
import Footer from "@/components/footer";
import StatisticsSection from "@/components/statistics-section";
import ContactSection from "@/components/contact-section";
import { RecentPostsSection } from "@/components/blog/recent-posts-section";
import { blogPosts } from "@/data/blog-data";
import {
  JsonLd,
  organizationJsonLd,
  websiteJsonLd,
  mobileAppJsonLd,
} from "@/components/json-ld";

const BASE_URL = "https://ta3afi.app";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}): Promise<Metadata> {
  const { lang } = await params;

  const titles: Record<Locale, string> = {
    ar: "تعافي - تحرر من الإدمان | منصة التعافي الشاملة",
    en: "Ta'aafi - Break Free from Addiction | Recovery Platform",
  };

  const descriptions: Record<Locale, string> = {
    ar: "استعد السيطرة على حياتك وتغلب على إدمان المواد الإباحية مع منصة تعافي الشاملة للتعافي. انضم لآلاف الأشخاص الذين وجدوا الحرية.",
    en: "Take control of your life and overcome porn addiction with Ta'aafi, a comprehensive recovery platform. Join thousands who've found freedom and built healthier habits.",
  };

  return {
    title: titles[lang],
    description: descriptions[lang],
    alternates: {
      canonical: `${BASE_URL}/${lang}`,
      languages: Object.fromEntries(
        languages.map((l) => [l, `${BASE_URL}/${l}`])
      ),
    },
    openGraph: {
      title: titles[lang],
      description: descriptions[lang],
      url: `${BASE_URL}/${lang}`,
    },
  };
}

// Server-side function to get recent posts
const getServerRecentPosts = (count: number) => {
  return blogPosts
    .sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime())
    .slice(0, count);
};

export default async function ComingSoonPage({
  params,
}: {
  params: Promise<{ lang: Locale }>;
}) {
  const { lang } = await params;
  const dict = await getDictionary(lang || fallbackLng);

  return (
    <>
      <JsonLd data={organizationJsonLd()} />
      <JsonLd data={websiteJsonLd()} />
      <JsonLd data={mobileAppJsonLd()} />


      <Header dict={dict}/>
      
      <HeroScrollSection dict={dict} />
      
      <section id="features">
        <AboutSectionCompanyValues dict={dict} />
      </section>

      {/* Statistics Section */}
      <section id="statistics">
        <StatisticsSection dict={dict} />
      </section>

      {/* Contact Section */}
      <section id="blog">
       <RecentPostsSection posts={getServerRecentPosts(3)} dict={dict} />
      </section>
      
      {/* Contact Section */}
      <section id="contact">
       <ContactSection dict={dict} />
      </section>

      {/* Footer */}
      <Footer dict={dict} />
    </>
  );
}

