"use client"

import { usePathname, useRouter } from "next/navigation"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Locale } from "../../i18n.config"
import { useTranslation } from "@/contexts/TranslationContext"

interface LocaleSwitcherProps {
  currentLocale: Locale
}

export function LocaleSwitcher({ currentLocale }: LocaleSwitcherProps) {
  const { t } = useTranslation()
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
        <TabsTrigger value="en">{t('appSidebar.localeSwitcher.english')}</TabsTrigger>
        <TabsTrigger value="ar">{t('appSidebar.localeSwitcher.arabic')}</TabsTrigger>
      </TabsList>
    </Tabs>
  )
}
