import type { BlogPost } from "@/types/blog";

const BASE_URL = "https://ta3afi.app";

interface JsonLdProps {
  data: Record<string, unknown>;
}

export function JsonLd({ data }: JsonLdProps) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}

export function organizationJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "Organization",
    name: "Ta'aafi",
    url: BASE_URL,
    logo: `${BASE_URL}/app-icon.png`,
    contactPoint: {
      "@type": "ContactPoint",
      email: "admin@ta3afi.app",
      contactType: "customer support",
    },
    sameAs: [
      "https://instagram.com/ta3afi",
      "https://twitter.com/ta3afi",
    ],
  };
}

export function websiteJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: "Ta'aafi",
    url: BASE_URL,
  };
}

export function mobileAppJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "MobileApplication",
    name: "Ta'aafi",
    operatingSystem: "iOS, Android",
    applicationCategory: "HealthApplication",
    aggregateRating: {
      "@type": "AggregateRating",
      ratingValue: "4.7",
      ratingCount: "17000",
      bestRating: "5",
    },
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
  };
}

export function blogPostJsonLd(post: BlogPost, lang: string) {
  return {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    headline: post.title,
    description: post.excerpt,
    author: {
      "@type": "Person",
      name: post.author.name,
    },
    datePublished: post.publishedAt,
    url: `${BASE_URL}/${lang}/blog/${post.slug}`,
    publisher: {
      "@type": "Organization",
      name: "Ta'aafi",
      logo: {
        "@type": "ImageObject",
        url: `${BASE_URL}/app-icon.png`,
      },
    },
  };
}

export function breadcrumbJsonLd(
  items: { name: string; url: string }[]
) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((item, index) => ({
      "@type": "ListItem",
      position: index + 1,
      name: item.name,
      item: item.url,
    })),
  };
}
