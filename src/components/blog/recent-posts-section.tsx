'use client'

import Link from 'next/link'
import { ArrowLeft, ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import type { BlogPost } from '@/types/blog'

import { useParams } from 'next/navigation'
import { BlogCard } from './blog-card'

interface RecentPostsSectionProps {
  posts: BlogPost[]
  dict: {
    blogLatestArticles: string
    blogStayUpdated: string
    blogViewAllArticles: string
    blogContentComingSoon: string
  }
}

export function RecentPostsSection({ posts, dict }: RecentPostsSectionProps) {
  const params = useParams()
  const lang = Array.isArray(params?.lang)
    ? params.lang[0]
    : ((params as any).lang as string)

  return (
    <section className="py-16 bg-gray-50">
      <div className="container mx-auto px-4">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-12">
          <div>
            <h2 className="text-3xl font-bold tracking-tight mb-2">
              {dict.blogLatestArticles}
            </h2>
            <p className="text-gray-500 max-w-2xl">
              {dict.blogStayUpdated}
            </p>
          </div>
          {/*
          <Button asChild className="mt-4 md:mt-0" variant="outline">
            <Link href={`/${lang}/blog`} className="flex items-center">
              {dict.blogViewAllArticles}
              {lang === 'ar' ? (
                <ArrowLeft className="mr-2 h-4 w-4" />
              ) : (
                <ArrowRight className="ml-2 h-4 w-4" />
              )}
            </Link>
          </Button>
          */}
        </div>

        <p className="text-center text-gray-500 w-full mt-8 text-xl font-semibold">
          {dict.blogContentComingSoon}
        </p>
        {/*
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {posts.map((post) => (
            <BlogCard key={post.id} post={post} />
          ))}
        </div>
        */}
      </div>
    </section>
  )
}
