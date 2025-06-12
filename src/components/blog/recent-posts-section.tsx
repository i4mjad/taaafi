"use client"

import Link from "next/link"
import { ArrowRight } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import type { BlogPost } from "@/types/blog"
import { formatDate } from "@/lib/utils"
import { useParams } from "next/navigation"

interface RecentPostsSectionProps {
  posts: BlogPost[]
}

export function RecentPostsSection({ posts }: RecentPostsSectionProps) {
  const params = useParams();
  const lang = Array.isArray(params?.lang) ? params.lang[0] : (params as any).lang as string;

  return (
    <section className="py-16 bg-gray-50">
      <div className="container mx-auto px-4">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-12">
          <div>
            <h2 className="text-3xl font-bold tracking-tight mb-2">Latest Articles</h2>
            <p className="text-gray-500 max-w-2xl">
              Stay updated with our latest insights, tutorials, and industry news
            </p>
          </div>
          <Button asChild className="mt-4 md:mt-0" variant="outline">
            <Link href={`/${lang}/blog`} className="flex items-center">
              View all articles
              <ArrowRight className="ml-2 h-4 w-4" />
            </Link>
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {posts.map((post) => (
            <Card
              key={post.id}
              className="flex flex-col h-full border-none shadow-sm hover:shadow-md transition-shadow"
            >
              <CardHeader className="pb-0">
                <div className="text-sm font-medium text-blue-600 mb-2">{post.category.name}</div>
                <CardTitle className="text-xl mb-2">
                  <Link href={`/${lang}/blog/${post.slug}`} className="hover:text-blue-600 transition-colors">
                    {post.title}
                  </Link>
                </CardTitle>
              </CardHeader>
              <CardContent className="py-4 flex-grow">
                <p className="text-gray-600 line-clamp-3">{post.excerpt}</p>
              </CardContent>
              <CardFooter className="pt-0 flex items-center justify-between">
                <div className="flex items-center">
                  <span className="text-sm text-gray-500">{formatDate(post.publishedAt)}</span>
                  <span className="mx-2 text-gray-300">•</span>
                  <span className="text-sm text-gray-500">{post.readingTime}</span>
                </div>
              </CardFooter>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
