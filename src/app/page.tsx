import { redirect } from "next/navigation"
import { i18n } from "../../i18n.config"


// Root page that redirects to the default locale
export default function RootPage() {
  redirect(`/${i18n.defaultLocale}/dashboard`)
}
