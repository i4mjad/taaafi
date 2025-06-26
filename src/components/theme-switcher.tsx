"use client"

import { useEffect, useState } from "react"
import { MoonIcon, SunIcon } from "lucide-react"

import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"

/**
 * A small toggle inside the sidebar footer that lets the user switch
 * between light and dark themes. The choice is persisted in
 * `localStorage` under the key `theme` and reflected by adding / removing
 * the `dark` class on the `<html>` element.
 */
export function ThemeSwitcher() {
  const [theme, setTheme] = useState<"light" | "dark">("light")
  const [mounted, setMounted] = useState(false)

  // Set initial theme (on mount) based on localStorage or system preference
  useEffect(() => {
    if (typeof window === "undefined") return

    const stored = localStorage.getItem("theme") as "light" | "dark" | null
    const prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches
    const initial = stored ?? (prefersDark ? "dark" : "light")

    setTheme(initial)
    document.documentElement.classList.toggle("dark", initial === "dark")
    setMounted(true)
  }, [])

  const setAndApplyTheme = (value: "light" | "dark") => {
    if (typeof window !== "undefined") {
      document.documentElement.classList.toggle("dark", value === "dark")
      localStorage.setItem("theme", value)
    }
    setTheme(value)
  }

  // Avoid rendering until mounted to prevent hydration mismatch
  if (!mounted) return null

  return (
    <Tabs
      value={theme}
      onValueChange={(val) => setAndApplyTheme(val as "light" | "dark")}
      orientation="horizontal"
      className="w-full"
    >
      <TabsList className="grid w-full grid-cols-2">
        <TabsTrigger value="light">
          <SunIcon />
          <span className="sr-only">Light</span>
        </TabsTrigger>
        <TabsTrigger value="dark">
          <MoonIcon />
          <span className="sr-only">Dark</span>
        </TabsTrigger>
      </TabsList>
    </Tabs>
  )
} 