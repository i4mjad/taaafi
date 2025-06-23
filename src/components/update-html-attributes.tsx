'use client'

import { useEffect } from "react"
import { Locale } from "../../i18n.config"

interface Props {
  lang: Locale
}

export default function UpdateHtmlAttributes({ lang }: Props) {
  useEffect(() => {
    document.documentElement.lang = lang
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr"
  }, [lang])
  return null
} 