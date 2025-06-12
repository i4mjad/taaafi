"use client"
import { ContainerScroll } from "@/components/ui/container-scroll-animation"
import Image from "next/image"
import { Button } from "@/components/ui/button"
import Link from "next/link"
import { Star } from "lucide-react"

interface HeroScrollSectionProps {
  dict: {
    heroTitle: string;
    heroSubtitle: string;
    heroDescription: string;
    downloadOnAppStore: string;
    getItOn: string;
    appStore: string;
    googlePlay: string;
    googleReviewsRating: string;
    appleReviewsRating: string;
    google: string;
    apple: string;
    appScreenAlt: string;
  };
}

export function HeroScrollSection({ dict }: HeroScrollSectionProps) {
  return (
    <div className="flex flex-col overflow-hidden mb-[16px]">
      <ContainerScroll
        useSimpleCard={true}
        titleComponent={
          <div className="space-y-6">
            <h1 className="text-4xl font-semibold text-black dark:text-white">
              {dict.heroTitle} <br />
              <span className="text-4xl md:text-[6rem] font-bold mt-1 leading-none text-blue-600">
                {dict.heroSubtitle}
              </span>
            </h1>
            <p className="text-lg md:text-xl text-gray-600 max-w-3xl mx-auto">
              {dict.heroDescription}
            </p>

            {/* App Store Buttons */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center mt-8">
              <Button
                className="bg-black hover:bg-gray-800 text-white px-6 py-3 h-auto rounded-lg flex items-center justify-center space-x-3"
                asChild
              >
                <Link href="#" className="flex items-center space-x-3">
                  <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
                  </svg>
                  <div className="text-left">
                    <div className="text-xs">{dict.downloadOnAppStore}</div>
                    <div className="text-sm font-semibold">{dict.appStore}</div>
                  </div>
                </Link>
              </Button>

              <Button
                className="bg-black hover:bg-gray-800 text-white px-6 py-3 h-auto rounded-lg flex items-center justify-center space-x-3"
                asChild
              >
                <Link href="#" className="flex items-center space-x-3">
                  <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.53,12.9 20.18,13.18L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z" />
                  </svg>
                  <div className="text-left">
                    <div className="text-xs">{dict.getItOn}</div>
                    <div className="text-sm font-semibold">{dict.googlePlay}</div>
                  </div>
                </Link>
              </Button>
            </div>

            {/* Reviews Section */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 max-w-2xl mx-auto mt-8">
              {/* Google Reviews */}
              <div className="bg-white/80 backdrop-blur-sm p-4 rounded-lg">
                <div className="flex items-center space-x-1 mb-2">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                  ))}
                </div>
                <p className="text-sm text-gray-600 mb-1">{dict.googleReviewsRating}</p>
                <p className="text-lg font-semibold text-gray-900">{dict.google}</p>
              </div>

              {/* Apple Reviews */}
              <div className="bg-white/80 backdrop-blur-sm p-4 rounded-lg">
                <div className="flex items-center space-x-1 mb-2">
                  {[...Array(4)].map((_, i) => (
                    <Star key={i} className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                  ))}
                  <Star className="w-4 h-4 fill-yellow-400/50 text-yellow-400" />
                </div>
                <p className="text-sm text-gray-600 mb-1">{dict.appleReviewsRating}</p>
                <p className="text-lg font-semibold text-gray-900">{dict.apple}</p>
              </div>
            </div>
          </div>
        }
      >
        <div className="relative w-full h-auto flex justify-center">
          <Image
            src="/images/app-screen-center.png"
            alt={dict.appScreenAlt}
            width={180}
                      height={360}
            className="w-2/3 md:w-3/4 h-auto object-contain rounded-[2rem]"
            priority
            style={{ backgroundColor: "transparent" }}
          />
        </div>
      </ContainerScroll>
    </div>
  )
}
