"use client"
import Link from "next/link"
import { Clock, User, ArrowRight } from "lucide-react"
import type { BlogPost } from "@/types/blog"
import { formatDate } from "@/lib/utils"

interface BlogCardProps {
  post: BlogPost
}

export function BlogCard({ post }: BlogCardProps) {
  return (
    <div className="bg-white p-6 rounded-lg border border-gray-100 hover:border-gray-200 transition-colors group h-full flex flex-col">
      {/* Header with category and date */}
      <div className="flex items-center justify-between mb-4">
        <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-50 text-blue-700">
          {post.category.name}
        </span>
        <span className="text-sm text-gray-500">{formatDate(post.publishedAt)}</span>
      </div>

      {/* Title */}
      <h3 className="text-xl font-bold text-gray-900 mb-3 leading-tight">
        <Link href={`/blog/${post.slug}`} className="hover:text-blue-600 transition-colors">
          {post.title}
        </Link>
      </h3>

      {/* Excerpt - flex-grow to take available space */}
      <p className="text-gray-600 mb-6 leading-relaxed flex-grow">{post.excerpt}</p>

      {/* Footer with author and reading time - always at bottom */}
      <div className="mt-auto">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center">
            <User className="h-4 w-4 text-gray-400 mr-2" />
            <span className="text-sm text-gray-600">{post.author.name}</span>
          </div>
          <div className="flex items-center">
            <Clock className="h-4 w-4 text-gray-400 mr-2" />
            <span className="text-sm text-gray-600">{post.readingTime}</span>
          </div>
        </div>

        {/* Read More link */}
        <Link
          href={`/blog/${post.slug}`}
          className="inline-flex items-center text-blue-600 font-medium hover:text-blue-700 transition-colors group-hover:translate-x-1 transform duration-200"
        >
          Read More
          <ArrowRight className="ml-2 h-4 w-4" />
        </Link>
      </div>
    </div>
  )
}
