'use client'

import { Button } from '@/components/ui/button'
import { Menu } from 'lucide-react'
import Link from 'next/link'
import Image from 'next/image'
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import { usePathname, useRouter } from 'next/navigation'

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

  return (
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

            <Button className="bg-blue-600 hover:bg-blue-700 text-white">
              {dict.download}
            </Button>
          </nav>

          {/* Mobile Menu */}
          <Sheet>
            <SheetTrigger asChild className="md:hidden">
              <Button variant="ghost" size="icon">
                <Menu className="h-6 w-6" />
                <span className="sr-only">{dict.toggleMenu}</span>
              </Button>
            </SheetTrigger>
            <SheetContent side="right" className="w-[300px] sm:w-[400px]">
              <nav className="flex flex-col space-y-4 mt-8">
                <Link
                  href={isHome ? '#features' : `/${lang}#features`}
                  className="text-lg font-medium text-gray-700 hover:text-gray-900 transition-colors"
                >
                  {dict.features}
                </Link>
                <Link
                  href={isHome ? '#statistics' : `/${lang}#statistics`}
                  className="text-lg font-medium text-gray-700 hover:text-gray-900 transition-colors"
                >
                  {dict.statistics}
                </Link>
                <Link
                  href={isHome ? '#blog' : `/${lang}#blog`}
                  className="text-lg font-medium text-gray-700 hover:text-gray-900 transition-colors"
                >
                  {dict.blog}
                </Link>
                <Link
                  href={isHome ? '#contact' : `/${lang}#contact`}
                  className="text-lg font-medium text-gray-700 hover:text-gray-900 transition-colors"
                >
                  {dict.contact}
                </Link>

                {/* Language Switcher */}
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

                <Button className="bg-blue-600 hover:bg-blue-700 text-white w-full mt-4">
                  {dict.download}
                </Button>
              </nav>
            </SheetContent>
          </Sheet>
        </div>
      </div>
    </header>
  )
}
