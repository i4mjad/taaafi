"use client"

import { useState, useEffect } from "react"
import { useSearchParams, useRouter, useParams } from "next/navigation"
import { getPaginatedPosts, categories } from "@/data/blog-data"
import { BlogCard } from "@/components/blog/blog-card"
import { BlogSearch } from "@/components/blog/blog-search"
import { CategoryFilter } from "@/components/blog/category-filter"
import { BlogPagination } from "@/components/blog/blog-pagination"
import Header from "@/components/header"


export default function BlogPage() {
  const routeParams = useParams();
  const lang = Array.isArray(routeParams?.lang) ? routeParams.lang[0] : (routeParams as any).lang as string;

  const searchParams = useSearchParams()
  const router = useRouter()

  // Get query parameters
  const pageParam = searchParams.get("page")
  const categoryParam = searchParams.get("category")
  const searchParam = searchParams.get("search")

  const [currentPage, setCurrentPage] = useState(pageParam ? Number.parseInt(pageParam) : 1)
  const [selectedCategory, setSelectedCategory] = useState<string | undefined>(categoryParam || undefined)
  const [searchQuery, setSearchQuery] = useState(searchParam || "")

  // Get posts based on current filters
  const { posts, total } = getPaginatedPosts(currentPage, 6, selectedCategory, searchQuery)
  const totalPages = Math.ceil(total / 6)

  // Update URL when filters change
  useEffect(() => {
    const queryParams = new URLSearchParams()

    if (currentPage > 1) {
      queryParams.set("page", currentPage.toString())
    }

    if (selectedCategory) {
      queryParams.set("category", selectedCategory)
    }

    if (searchQuery) {
      queryParams.set("search", searchQuery)
    }

    const queryString = queryParams.toString()
    const url = queryString ? `/${lang}/blog?${queryString}` : `/${lang}/blog`

    router.push(url, { scroll: false })
  }, [currentPage, selectedCategory, searchQuery, router, lang])

  // Handle page change
  const handlePageChange = (page: number) => {
    setCurrentPage(page)
    window.scrollTo({ top: 0, behavior: "smooth" })
  }

  // Handle category selection
  const handleCategorySelect = (categorySlug: string | undefined) => {
    setSelectedCategory(categorySlug)
    setCurrentPage(1)
  }

  // Handle search
  const handleSearch = (query: string) => {
    setSearchQuery(query)
    setCurrentPage(1)
  }

  return (
    <>
      <Header />
      <div className="container mx-auto px-4 py-12">
        <div className="max-w-3xl mx-auto mb-12 text-center">
          <h1 className="text-4xl font-bold tracking-tight mb-4">Our Blog</h1>
          <p className="text-gray-600 text-lg">Insights, tutorials, and updates from our team</p>
        </div>

        <div className="max-w-5xl mx-auto">
          {/* Search and Filter */}
          <div className="flex flex-col md:flex-row gap-4 mb-8 items-start md:items-center justify-between">
            <div className="w-full md:w-auto">
              <BlogSearch onSearch={handleSearch} initialQuery={searchQuery} />
            </div>
            <div className="w-full md:w-auto overflow-x-auto pb-2">
              <CategoryFilter
                categories={categories}
                selectedCategory={selectedCategory}
                onSelectCategory={handleCategorySelect}
              />
            </div>
          </div>

          {/* Results info */}
          <div className="mb-6 text-sm text-gray-500">
            {total === 0 ? (
              <p>No articles found. Try adjusting your search or filters.</p>
            ) : (
              <p>
                Showing {posts.length} of {total} article{total !== 1 ? "s" : ""}
                {selectedCategory && ` in ${categories.find((c) => c.slug === selectedCategory)?.name}`}
                {searchQuery && ` matching "${searchQuery}"`}
              </p>
            )}
          </div>

          {/* Blog posts grid */}
          {posts.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
              {posts.map((post) => (
                <BlogCard key={post.id} post={post} />
              ))}
            </div>
          ) : (
            <div className="py-12 text-center">
              <p className="text-gray-500 mb-4">No articles found</p>
              <p className="text-gray-400">Try adjusting your search or filters</p>
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <BlogPagination currentPage={currentPage} totalPages={totalPages} onPageChange={handlePageChange} />
          )}
        </div>
      </div>
    </>
  )
}
