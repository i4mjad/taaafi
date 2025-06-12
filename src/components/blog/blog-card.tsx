"use client"

import Link from "next/link"
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import type { BlogPost } from "@/types/blog"
import { formatDate } from "@/lib/utils"
import { useParams } from "next/navigation"

interface BlogCardProps {
  post: BlogPost
}

export function BlogCard({ post }: BlogCardProps) {
  const params = useParams();
  const lang = Array.isArray(params?.lang) ? params.lang[0] : (params as any).lang as string;
  const href = `/${lang}/blog/${post.slug}`;

  return (
    <Card className="flex flex-col h-full border-none shadow-sm hover:shadow-md transition-shadow">
      <CardHeader className="pb-0">
        <div className="text-sm font-medium text-blue-600 mb-2">{post.category.name}</div>
        <CardTitle className="text-xl mb-2">
          <Link href={href} className="hover:text-blue-600 transition-colors">
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
  )
}
