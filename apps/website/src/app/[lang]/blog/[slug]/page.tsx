import Link from "next/link"
import { notFound } from "next/navigation"
import { ArrowLeft } from "lucide-react"
import { getPostBySlug, getRecentPosts } from "@/data/blog-data"
import { formatDate } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { BlogCard } from "@/components/blog/blog-card"
import Header from "@/components/header"

export default async function BlogPostPage({
  params,
}: {
  params: Promise<{ lang: string; slug: string }>
}) {
  const { lang, slug } = await params;
  const post = getPostBySlug(slug)

  if (!post) {
    notFound()
  }

  // Get related posts (excluding current post)
  const relatedPosts = getRecentPosts(4)
    .filter((p) => p.id !== post.id)
    .slice(0, 3)

  return (
    <>
    <Header />
    <article className="container mx-auto px-4 py-12">
    
      <div className="max-w-3xl mx-auto">
        {/* Back button */}
        <div className="mb-8">
          <Button variant="ghost" asChild className="pl-0 hover:pl-0">
            <Link href="/blog" className="flex items-center text-gray-500 hover:text-gray-900">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back to all articles
            </Link>
          </Button>
        </div>

        {/* Article header */}
        <header className="mb-8">
          <div className="flex items-center mb-4">
            <span className="text-sm font-medium text-blue-600">{post.category.name}</span>
            <span className="mx-2 text-gray-300">•</span>
            <span className="text-sm text-gray-500">{formatDate(post.publishedAt)}</span>
            <span className="mx-2 text-gray-300">•</span>
            <span className="text-sm text-gray-500">{post.readingTime}</span>
          </div>

          <h1 className="text-3xl md:text-4xl font-bold tracking-tight mb-4">{post.title}</h1>

          <p className="text-xl text-gray-600">{post.excerpt}</p>

          <div className="flex items-center mt-6">
            <div className="flex-shrink-0 mr-3">
              <img
                src={post.author.avatar || "/placeholder.svg"}
                alt={post.author.name}
                className="h-10 w-10 rounded-full"
              />
            </div>
            <div>
              <p className="text-sm font-medium">{post.author.name}</p>
            </div>
          </div>
        </header>

        {/* Article content */}
        <div className="prose prose-blue max-w-none">
          {/* This is a simplified rendering of the content */}
          {/* In a real app, you'd use a markdown renderer like react-markdown */}
          <div dangerouslySetInnerHTML={{ __html: post.content.replace(/\n/g, "<br>") }} />
        </div>

        {/* Article footer */}
        <div className="mt-12 pt-8 border-t border-gray-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="flex-shrink-0 mr-3">
                <img
                  src={post.author.avatar || "/placeholder.svg"}
                  alt={post.author.name}
                  className="h-10 w-10 rounded-full"
                />
              </div>
              <div>
                <p className="text-sm font-medium">{post.author.name}</p>
              </div>
            </div>

            <div className="flex space-x-2">
              <Button variant="outline" size="sm">
                Share
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* Related articles */}
      {relatedPosts.length > 0 && (
        <div className="max-w-5xl mx-auto mt-16">
          <h2 className="text-2xl font-bold mb-6">Related Articles</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {relatedPosts.map((relatedPost) => (
              <BlogCard key={relatedPost.id} post={relatedPost} />
            ))}
          </div>
        </div>
      )}
    </article>
    </>
  )
}
