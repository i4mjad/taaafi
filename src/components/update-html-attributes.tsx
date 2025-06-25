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

  useEffect(() => {
    // Suppress browser extension listener errors that don't affect functionality
    const handleError = (event: ErrorEvent) => {
      const message = event.message || event.error?.message || ''
      
      // Suppress the specific browser extension error
      if (message.includes('A listener indicated an asynchronous response by returning true, but the message channel closed before a response was received')) {
        event.preventDefault()
        console.debug('Suppressed browser extension listener error (harmless)')
        return false
      }
    }

    const handleUnhandledRejection = (event: PromiseRejectionEvent) => {
      const message = event.reason?.message || String(event.reason)
      
      // Suppress the specific browser extension error in promises
      if (message.includes('A listener indicated an asynchronous response by returning true, but the message channel closed before a response was received')) {
        event.preventDefault()
        console.debug('Suppressed browser extension promise rejection error (harmless)')
        return false
      }
    }

    window.addEventListener('error', handleError)
    window.addEventListener('unhandledrejection', handleUnhandledRejection)

    return () => {
      window.removeEventListener('error', handleError)
      window.removeEventListener('unhandledrejection', handleUnhandledRejection)
    }
  }, [])

  return null
} 