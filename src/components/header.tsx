'use client'

import { Button } from '@/components/ui/button'
import { Menu } from 'lucide-react'
import Link from 'next/link'
import Image from 'next/image'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import { usePathname, useRouter } from 'next/navigation'
import { Toaster } from '@/components/ui/toaster'
import { toast } from '@/hooks/use-toast'
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from '@/components/ui/dropdown-menu'
import { Download } from 'lucide-react'

interface Dict {
  appName: string
  features: string
  statistics: string
  blog: string
  contact?: string
  download: string
  toggleMenu: string
  english: string
  arabic: string
  toastDesktopTitle?: string
  toastDesktopDescription?: string
}

const defaultDict: Dict = {
  appName: "Ta'aafi",
  features: 'Features',
  statistics: 'Statistics',
  blog: 'Blog',
  download: 'Download',
  toggleMenu: 'Toggle menu',
  english: 'English',
  arabic: 'Arabic',
  toastDesktopTitle: 'Not available on desktop',
  toastDesktopDescription: "Ta'aafi is only available for iOS and Android.",
}

interface HeaderProps {
  dict?: Dict
}

export default function Header({ dict = defaultDict }: HeaderProps) {
  const pathname = usePathname()
  const router = useRouter()
  const lang = pathname.split('/')[1] || 'en'

  const isHome = pathname === `/${lang}` || pathname === `/${lang}/`

  const handleLanguageChange = (value: string) => {
    if (value && value !== lang) {
      const segments = pathname.split('/')
      segments[1] = value // Replace the old language with the new one
      const newPath = segments.join('/')
      router.push(newPath)
    }
  }

  const handleDownloadClick = () => {
    if (typeof window === 'undefined') return
    const userAgent = navigator.userAgent || navigator.vendor || (window as any).opera

    const isAndroid = /android/i.test(userAgent)
    const isIOS = /iPad|iPhone|iPod/.test(userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)

    if (isAndroid) {
      window.location.href = 'https://play.google.com/store/apps/details?id=com.amjadkhalfan.reboot_app_3&hl=ar&pli=1'
      return
    }

    if (isIOS) {
      window.location.href = 'https://apps.apple.com/om/app/taaafi-platfrom-better-life/id1531562469'
      return
    }

    toast({
      title: dict.toastDesktopTitle ?? 'Not available on desktop',
      description: dict.toastDesktopDescription ?? "Ta'aafi is only available for iOS and Android.",
    })
  }

  return (
    <>
      <Toaster />
      <header className="sticky top-0 z-50 w-full border-b bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/60">
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            {/* Logo and App Name */}
            <Link href={`/${lang}`} className="flex items-center space-x-2 group">
              <Image
                src="/images/ta3afi-icon.svg"
                alt="Ta3afi App Icon"
                width={32}
                height={32}
                className="h-8 w-8 transition-transform group-hover:scale-105"
              />
              <span className="text-xl font-bold text-gray-900">
                {dict.appName}
              </span>
            </Link>

            {/* Desktop Navigation */}
            <nav className="hidden  md:flex items-center gap-6">
              <Link
                href={isHome ? '#features' : `/${lang}#features`}
                className="text-sm font-medium text-gray-700 hover:text-gray-900 transition-colors"
              >
                {dict.features}
              </Link>
              <Link
                href={isHome ? '#statistics' : `/${lang}#statistics`}
                className="text-sm font-medium text-gray-700 hover:text-gray-900 transition-colors"
              >
                {dict.statistics}
              </Link>
              <Link
                href={isHome ? '#blog' : `/${lang}#blog`}
                className="text-sm font-medium text-gray-700 hover:text-gray-900 transition-colors"
              >
                {dict.blog}
              </Link>
              <Link
                href={isHome ? '#contact' : `/${lang}#contact`}
                className="text-sm font-medium text-gray-700 hover:text-gray-900 transition-colors"
              >
                {dict.contact}
              </Link>

              {/* Language Switcher */}
              <ToggleGroup
                type="single"
                value={lang}
                onValueChange={handleLanguageChange}
              >
                <ToggleGroupItem value="en" aria-label={dict.english}>
                  EN
                </ToggleGroupItem>
                <ToggleGroupItem value="ar" aria-label={dict.arabic}>
                  AR
                </ToggleGroupItem>
              </ToggleGroup>

              <Button className="bg-blue-600 hover:bg-blue-700 text-white" onClick={handleDownloadClick}>
                {dict.download}
              </Button>
            </nav>

            {/* Mobile Icons */}
            <div className="flex items-center gap-1 md:hidden">
              {/* Download Icon */}
              <Button size="icon" className="bg-blue-100 hover:bg-blue-200 text-blue-600" onClick={handleDownloadClick}>
                <Download className="h-6 w-6" />
                <span className="sr-only">{dict.download}</span>
              </Button>

              {/* Dropdown Menu for navigation */}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="icon">
                    <Menu className="h-6 w-6" />
                    <span className="sr-only">{dict.toggleMenu}</span>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-56">
                  <DropdownMenuItem asChild>
                    <Link href={isHome ? '#features' : `/${lang}#features`}>
                      {dict.features}
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuItem asChild>
                    <Link href={isHome ? '#statistics' : `/${lang}#statistics`}>
                      {dict.statistics}
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuItem asChild>
                    <Link href={isHome ? '#blog' : `/${lang}#blog`}>
                      {dict.blog}
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuItem asChild>
                    <Link href={isHome ? '#contact' : `/${lang}#contact`}>
                      {dict.contact}
                    </Link>
                  </DropdownMenuItem>

                  {/* Language Switcher within dropdown */}
                  <div className="flex justify-center py-2">
                    <ToggleGroup
                      type="single"
                      value={lang}
                      onValueChange={handleLanguageChange}
                    >
                      <ToggleGroupItem value="en" aria-label={dict.english}>
                        EN
                      </ToggleGroupItem>
                      <ToggleGroupItem value="ar" aria-label={dict.arabic}>
                        AR
                      </ToggleGroupItem>
                    </ToggleGroup>
                  </div>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </div>
      </header>
    </>
  )
}
