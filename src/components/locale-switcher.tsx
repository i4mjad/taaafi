"use client"

import { usePathname, useRouter } from "next/navigation"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Locale } from "../../i18n.config"
import { Dictionary } from "@/app/[lang]/dashboard/page"

interface LocaleSwitcherProps {
  currentLocale: Locale
  dictionary: Dictionary["appSidebar"]["localeSwitcher"]
}

export function LocaleSwitcher({ currentLocale, dictionary }: LocaleSwitcherProps) {
  const router = useRouter()
  const pathname = usePathname()

  const handleLocaleChange = (newLocale: Locale) => {
    if (currentLocale === newLocale) return

    const newPathname = pathname.replace(`/${currentLocale}`, `/${newLocale}`)
    router.push(newPathname)
    router.refresh() // Important to re-fetch server components with new locale
  }

  return (
    <Tabs
      defaultValue={currentLocale}
      onValueChange={(value) => handleLocaleChange(value as Locale)}
      className="w-full"
    >
      <TabsList className="grid w-full grid-cols-2">
        <TabsTrigger value="en">{dictionary.english}</TabsTrigger>
        <TabsTrigger value="ar">{dictionary.arabic}</TabsTrigger>
      </TabsList>
    </Tabs>
  )
}
