"use client"

import type { Category } from "@/types/blog"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"

interface CategoryFilterProps {
  categories: Category[]
  selectedCategory?: string
  onSelectCategory: (categorySlug: string | undefined) => void
}

export function CategoryFilter({ categories, selectedCategory, onSelectCategory }: CategoryFilterProps) {
  return (
    <div className="flex flex-wrap gap-2">
      <Button
        variant="outline"
        size="sm"
        className={cn(
          "rounded-full",
          !selectedCategory && "bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100 hover:text-blue-800",
        )}
        onClick={() => onSelectCategory(undefined)}
      >
        All
      </Button>

      {categories.map((category) => (
        <Button
          key={category.id}
          variant="outline"
          size="sm"
          className={cn(
            "rounded-full",
            selectedCategory === category.slug &&
              "bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100 hover:text-blue-800",
          )}
          onClick={() => onSelectCategory(category.slug)}
        >
          {category.name}
        </Button>
      ))}
    </div>
  )
}
