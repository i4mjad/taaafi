"use client"

import type React from "react"

import { useState } from "react"
import { Search } from "lucide-react"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"

interface BlogSearchProps {
  onSearch: (query: string) => void
  initialQuery?: string
}

export function BlogSearch({ onSearch, initialQuery = "" }: BlogSearchProps) {
  const [searchQuery, setSearchQuery] = useState(initialQuery)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSearch(searchQuery)
  }

  return (
    <form onSubmit={handleSubmit} className="relative">
      <Input
        type="search"
        placeholder="Search articles..."
        className="pr-10"
        value={searchQuery}
        onChange={(e) => setSearchQuery(e.target.value)}
      />
      <Button
        type="submit"
        size="sm"
        variant="ghost"
        className="absolute right-0 top-0 h-full px-3"
        aria-label="Search"
      >
        <Search className="h-4 w-4" />
      </Button>
    </form>
  )
}
