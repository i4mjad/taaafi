import type { MetadataRoute } from "next";
import { blogPosts } from "@/data/blog-data";
import { languages } from "./i18n/settings";

const BASE_URL = "https://ta3afi.app";

export default function sitemap(): MetadataRoute.Sitemap {
  const staticPages = ["", "/blog", "/privacy", "/terms"];

  // Generate entries for each static page in each language
  const staticEntries: MetadataRoute.Sitemap = staticPages.flatMap((page) =>
    languages.map((lang) => ({
      url: `${BASE_URL}/${lang}${page}`,
      lastModified: new Date(),
      changeFrequency: page === "" ? "weekly" : "monthly" as const,
      priority: page === "" ? 1.0 : 0.7,
      alternates: {
        languages: Object.fromEntries(
          languages.map((l) => [l, `${BASE_URL}/${l}${page}`])
        ),
      },
    }))
  );

  // Generate entries for each blog post in each language
  const blogEntries: MetadataRoute.Sitemap = blogPosts.flatMap((post) =>
    languages.map((lang) => ({
      url: `${BASE_URL}/${lang}/blog/${post.slug}`,
      lastModified: new Date(post.publishedAt),
      changeFrequency: "monthly" as const,
      priority: 0.6,
      alternates: {
        languages: Object.fromEntries(
          languages.map((l) => [l, `${BASE_URL}/${l}/blog/${post.slug}`])
        ),
      },
    }))
  );

  return [...staticEntries, ...blogEntries];
}
