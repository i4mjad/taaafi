import { redirect } from "next/navigation"
import { Locale } from "../../../i18n.config"


// Locale root page that redirects to dashboard
export default async function LocalePage({ params }: { params: Promise<{ lang: string }> }) {
  const { lang } = await params
  redirect(`/${lang}/login`)
}
