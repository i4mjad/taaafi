'use client'
import { ContainerScroll } from '@/components/ui/container-scroll-animation'
import Image from 'next/image'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { Star } from 'lucide-react'

interface HeroScrollSectionProps {
  dict: {
    heroTitle: string
    heroSubtitle: string
    heroDescription: string
    downloadOnAppStore: string
    getItOn: string
    appStore: string
    googlePlay: string
    googleReviewsRating: string
    appleReviewsRating: string
    google: string
    apple: string
    appScreenAlt: string
  }
}

export function HeroScrollSection({ dict }: HeroScrollSectionProps) {
  return (
    <div className="flex flex-col overflow-hidden mb-[16px]">
      <ContainerScroll
        useSimpleCard={true}
        titleComponent={
          <div className="space-y-6">
            <h1 className="text-3xl md:text-4xl font-semibold text-black dark:text-white">
              {dict.heroTitle} <br />
              <span className="text-3xl md:text-[6rem] font-bold mt-1 leading-none text-blue-600">
                {dict.heroSubtitle}
              </span>
            </h1>
            <p className="text-base md:text-xl text-gray-600 max-w-3xl mx-auto px-4">
              {dict.heroDescription}
            </p>

            {/* App Store Buttons
            <div className="flex flex-row gap-4 justify-center mt-6 px-4">
              <Link
                href="https://apps.apple.com/eg/app/taaafi-platfrom-better-life/id1531562469"
                className="flex items-center"
              >
                <Image
                  src="/download-from-app-store.svg"
                  alt="Download from App Store"
                  width={160}
                  height={48}
                  className="h-12 w-auto"
                  priority
                />
              </Link>
              <Link
                href="https://play.google.com/store/apps/details?id=com.amjadkhalfan.reboot_app_3&hl=ar&pli=1"
                className="flex items-center"
              >
                <Image
                  src="/download-from-google-play.png"
                  alt="Get it on Google Play"
                  width={160}
                  height={48}
                  className="h-12 w-auto"
                  priority
                />
              </Link>
            </div> */}

            {/* Reviews Section */}
            <div className="grid grid-cols-2 gap-4 max-w-md mx-auto mt-6 px-4">
              <div className="flex flex-col items-start bg-white/80 backdrop-blur-sm p-2 sm:p-4 rounded-lg">
                <div className="flex flex-col items-start gap-5 ">
                  <Link
                    href="https://play.google.com/store/apps/details?id=com.amjadkhalfan.reboot_app_3&hl=ar&pli=1"
                    className="flex items-center"
                  >
                    <Image
                      src="/download-from-google-play.png"
                      alt="Get it on Google Play"
                      width={160}
                      height={48}
                      className="h-12 w-auto"
                      priority
                    />
                  </Link>
                  <div className="flex flex-col items-start ">
                    <div className="flex items-center space-x-1 mb-1 sm:mb-2">
                      {[...Array(5)].map((_, i) => (
                        <Star
                          key={i}
                          className="w-3 h-3 sm:w-4 sm:h-4 fill-yellow-400 text-yellow-400"
                        />
                      ))}
                    </div>
                    <p className="text-xs sm:text-sm text-gray-600 mb-1">
                      {dict.googleReviewsRating}
                    </p>
                    <p className="text-sm sm:text-lg font-semibold text-gray-900">
                      {dict.google}
                    </p>
                  </div>
                </div>
              </div>
              {/* Apple Reviews */}
              <div className="flex bg-white/80 flex-col  items-start backdrop-blur-sm p-2 sm:p-4 rounded-lg">
                <div className="flex flex-col items-start gap-5 ">
                  <Link
                    href="https://apps.apple.com/eg/app/taaafi-platfrom-better-life/id1531562469"
                    className="flex items-center"
                  >
                    <Image
                      src="/download-from-app-store.svg"
                      alt="Download from App Store"
                      width={160}
                      height={48}
                      className="h-12 w-auto"
                      priority
                    />
                  </Link>
                  <div className="flex flex-col items-start ">
                    <div className="flex items-center space-x-1 mb-1 sm:mb-2">
                      {[...Array(4)].map((_, i) => (
                        <Star
                          key={i}
                          className="w-3 h-3 sm:w-4 sm:h-4 fill-yellow-400 text-yellow-400"
                        />
                      ))}
                      <Star className="w-3 h-3 sm:w-4 sm:h-4 fill-yellow-400/50 text-yellow-400" />
                    </div>
                    <p className="text-xs sm:text-sm text-gray-600 mb-1">
                      {dict.appleReviewsRating}
                    </p>
                    <p className="text-sm sm:text-lg font-semibold text-gray-900">
                      {dict.apple}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        }
      >
        <div className="relative w-full h-auto flex justify-center mt-4">
          <Image
            src="/images/app-screen-center.png"
            alt={dict.appScreenAlt}
            width={180}
            height={360}
            className="w-1/2 sm:w-2/3 md:w-3/4 h-auto object-contain rounded-[2rem]"
            priority
            style={{ backgroundColor: 'transparent' }}
          />
        </div>
      </ContainerScroll>
    </div>
  )
}
