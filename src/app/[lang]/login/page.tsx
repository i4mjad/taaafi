import { LoginForm } from "@/components/login-form"
import { getDictionary } from "@/app/[lang]/dashboard/dictionaries"
import { Locale } from "../../../../i18n.config"

export default async function LoginPage({ params }: { params: Promise<{ lang: Locale }> }) {
  const { lang } = await params
  const dict = await getDictionary(lang)
  
  return (
    <div className="bg-background flex min-h-svh flex-col items-center justify-center gap-6 p-6 md:p-10">
      <div className="w-full max-w-sm">
        <LoginForm dict={dict} />
      </div>
    </div>
  )
} 