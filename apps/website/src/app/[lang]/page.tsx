import { type Locale, fallbackLng } from "../i18n/settings";
import { getDictionary } from "../dictionaries/get-dictonaries";
import { HeroScrollSection } from "@/components/hero-scroll";
import Header from "@/components/header";
import AboutSectionCompanyValues from "@/components/about-section";
import Footer from "@/components/footer";
import StatisticsSection from "@/components/statistics-section";
import ContactSection from "@/components/contact-section";
import { RecentPostsSection } from "@/components/blog/recent-posts-section";
import { blogPosts } from "@/data/blog-data";

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

export const dynamic = "force-dynamic";
