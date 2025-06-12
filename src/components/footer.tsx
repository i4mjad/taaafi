"use client"

import Link from "next/link"
import { Twitter, Instagram, Github, ArrowUp } from "lucide-react"
import { Button } from "@/components/ui/button"
import { usePathname } from "next/navigation"

interface Dict {
  appName: string
  features: string
  statistics: string
  blog: string
  contact: string
  footerTagline: string
  footerProduct: string
  footerPricing: string
  footerCompany: string
  footerAbout: string
  footerBlog: string
  footerCareers: string
  footerResources: string
  footerSupport: string
  footerLegal: string
  footerPrivacyPolicy: string
  footerTermsAndConditions: string
  footerCopyright: string
  footerBackToTop: string
  followUsOnTwitter: string
  followUsOnInstagram: string
  followUsOnGithub: string
}

const defaultDict: Dict = {
  appName: "Ta'aafi Platform",
  features: "Features",
  statistics: "Statistics",
  blog: "Blog",
  contact: "Contact",
  footerTagline: "For a better life.",
  footerProduct: "Product",
  footerPricing: "Pricing",
  footerCompany: "Company",
  footerAbout: "About",
  footerBlog: "Blog",
  footerCareers: "Careers",
  footerResources: "Resources",
  footerSupport: "Support",
  footerLegal: "Legal",
  footerPrivacyPolicy: "Privacy Policy",
  footerTermsAndConditions: "Terms and Conditions",
  footerCopyright: "© 2025 Ta'aafi Platform. All rights reserved.",
  footerBackToTop: "Back to top",
  followUsOnTwitter: "Follow us on Twitter",
  followUsOnInstagram: "Follow us on Instagram",
  followUsOnGithub: "Follow us on GitHub",
}

interface FooterProps {
  dict?: Dict
}

export default function Footer({ dict = defaultDict }: FooterProps) {
  const pathname = usePathname()
  const lang = pathname.split('/')[1] || 'en'
  const isHome = pathname === `/${lang}` || pathname === `/${lang}/`

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: "smooth" })
  }

  return (
    <footer className="bg-white border-t border-gray-200">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-12 lg:py-16">
        {/* Main Footer Content */}
        <div className="grid grid-cols-1 lg:grid-cols-6 gap-8 lg:gap-12">
          {/* Company Info */}
          <div className="lg:col-span-2">
            <h3 className="text-xl font-bold text-gray-900 mb-4">{dict.appName}</h3>
            <p className="text-gray-600 mb-6 max-w-sm">{dict.footerTagline}</p>

            {/* Social Media Icons */}
            <div className="flex space-x-4">
              <Link
                href="#"
                className="text-gray-400 hover:text-gray-600 transition-colors"
                aria-label={dict.followUsOnTwitter}
              >
                <Twitter className="h-5 w-5" />
              </Link>
              <Link
                href="#"
                className="text-gray-400 hover:text-gray-600 transition-colors"
                aria-label={dict.followUsOnInstagram}
              >
                <Instagram className="h-5 w-5" />
              </Link>
              <Link
                href="#"
                className="text-gray-400 hover:text-gray-600 transition-colors"
                aria-label={dict.followUsOnGithub}
              >
                <Github className="h-5 w-5" />
              </Link>
            </div>
          </div>

          {/* Product Links */}
          <div>
            <h4 className="text-sm font-semibold text-gray-900 mb-4">{dict.footerProduct}</h4>
            <ul className="space-y-3">
              <li>
                <Link href={isHome ? "#features" : `/${lang}#features`} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">
                  {dict.features}
                </Link>
              </li>
              <li>
                <Link href={isHome ? "#pricing" : `/${lang}#pricing`} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">
                  {dict.footerPricing}
                </Link>
              </li>
            </ul>
          </div>

          {/* Company Links */}
          <div>
            <h4 className="text-sm font-semibold text-gray-900 mb-4">{dict.footerCompany}</h4>
            <ul className="space-y-3">
              <li>
                <Link href={isHome ? "#about" : `/${lang}#about`} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">
                  {dict.footerAbout}
                </Link>
              </li>
              <li>
                <Link href={isHome ? "#blog" : `/${lang}#blog`} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">
                  {dict.footerBlog}
                </Link>
              </li>
              <li>
                <Link href={isHome ? "#careers" : `/${lang}#careers`} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">
                  {dict.footerCareers}
                </Link>
              </li>
            </ul>
          </div>

          {/* Resources Links */}
          <div>
            <h4 className="text-sm font-semibold text-gray-900 mb-4">{dict.footerResources}</h4>
            <ul className="space-y-3">
              <li>
                <Link href={isHome ? "#support" : `/${lang}#support`} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">
                  {dict.footerSupport}
                </Link>
              </li>
              <li>
                <Link href={isHome ? "#contact" : `/${lang}#contact`} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">
                  {dict.contact}
                </Link>
              </li>
            </ul>
          </div>

          {/* Legal Links */}
          <div>
            <h4 className="text-sm font-semibold text-gray-900 mb-4">{dict.footerLegal}</h4>
            <ul className="space-y-3">
              <li>
                <Link href={`/${lang}/privacy`} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">
                  {dict.footerPrivacyPolicy}
                </Link>
              </li>
              <li>
                <Link href={`/${lang}/terms`} className="text-sm text-gray-600 hover:text-gray-900 transition-colors">
                  {dict.footerTermsAndConditions}
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Footer Bottom */}
        <div className="mt-12 pt-8 border-t border-gray-200 flex flex-col sm:flex-row justify-between items-center">
          <p className="text-sm text-gray-600 mb-4 sm:mb-0">{dict.footerCopyright}</p>

          <Button
            variant="ghost"
            size="sm"
            onClick={scrollToTop}
            className="text-sm text-gray-600 hover:text-gray-900 transition-colors flex items-center space-x-1"
          >
            <span>{dict.footerBackToTop}</span>
            <ArrowUp className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </footer>
  )
}
