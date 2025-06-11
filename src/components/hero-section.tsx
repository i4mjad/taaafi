"use client"

import { Button } from "@/components/ui/button"
import { Star } from "lucide-react"
import Image from "next/image"
import Link from "next/link"

export default function HeroSection() {
  return (
    <section className="py-8 sm:py-12 lg:py-16">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12 items-center">
          {/* Left Content */}
          <div className="order-2 lg:order-1">
            <h1 className="text-3xl sm:text-4xl lg:text-5xl xl:text-6xl font-bold text-gray-900 leading-tight">
              CloudMaster: Elevate Your Projects
            </h1>
            <p className="mt-4 sm:mt-6 text-lg sm:text-xl text-gray-600 leading-relaxed">
              Simplify team collaboration with CloudMaster, the ultimate tool for efficient project management.
            </p>

            {/* App Store Buttons */}
            <div className="mt-8 flex flex-col sm:flex-row gap-4">
              <Button
                className="bg-black hover:bg-gray-800 text-white px-6 py-3 h-auto rounded-lg flex items-center justify-center space-x-3"
                asChild
              >
                <Link href="#" className="flex items-center space-x-3">
                  <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
                  </svg>
                  <div className="text-left">
                    <div className="text-xs">Download on the</div>
                    <div className="text-sm font-semibold">App Store</div>
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
                    <div className="text-xs">Get it on</div>
                    <div className="text-sm font-semibold">Google Play</div>
                  </div>
                </Link>
              </Button>
            </div>

            {/* Reviews Section */}
            <div className="mt-8 sm:mt-12 grid grid-cols-1 sm:grid-cols-2 gap-6">
              {/* Google Reviews */}
              <div>
                <div className="flex items-center space-x-1 mb-2">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                  ))}
                </div>
                <p className="text-sm text-gray-600 mb-1">4.6 /5 - from 12k reviews</p>
                <p className="text-lg font-semibold text-gray-900">Google</p>
              </div>

              {/* Apple Reviews */}
              <div>
                <div className="flex items-center space-x-1 mb-2">
                  {[...Array(4)].map((_, i) => (
                    <Star key={i} className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                  ))}
                  <Star className="w-4 h-4 fill-yellow-400/50 text-yellow-400" />
                </div>
                <p className="text-sm text-gray-600 mb-1">4.8 /5 - from 5k reviews</p>
                <p className="text-lg font-semibold text-gray-900">Apple</p>
              </div>
            </div>
          </div>

          {/* Right Image */}
          <div className="order-1 lg:order-2">
            <div className="relative flex justify-center items-center min-h-[300px] overflow-visible px-8">
              {/* Three Phone Screenshots */}
              <div className="relative max-w-4xl bg-transparent w-full">
                {/* Left Phone (Library) - 3.png */}
                <div className="absolute -left-20 lg:-left-24 top-0 z-10 transform -rotate-[20deg] scale-[0.5] lg:scale-[0.55]">
                  <div className="relative">
                    <Image
                      src="/images/app-screen-left.png"
                      alt="CloudMaster Library"
                      width={160}
                      height={320}
                      className="w-full h-auto rounded-[1.5rem]  bg-transparent"
                      style={{ backgroundColor: "transparent" }}
                    />
                  </div>
                </div>

                {/* Center Phone (Dashboard) - 1.png */}
                <div className="relative z-20 mx-auto transform scale-[0.6] lg:scale-[0.65]">
                  <div className="relative">
                    <Image
                      src="/images/app-screen-center.png"
                      alt="CloudMaster Dashboard"
                      width={180}
                      height={360}
                      className="w-full h-auto rounded-[1.5rem] "
                      style={{ backgroundColor: "transparent" }}
                      priority
                    />
                  </div>
                </div>

                {/* Right Phone (Tasks) - 2.png */}
                <div className="absolute -right-20 lg:-right-24 top-0 z-10 transform rotate-[20deg] scale-[0.5] lg:scale-[0.55]">
                  <div className="relative">
                    <Image
                      src="/images/app-screen-right.png"
                      alt="CloudMaster Tasks"
                      width={160}
                      height={320}
                      className="w-full h-auto rounded-[1.5rem]  bg-transparent"
                      style={{ backgroundColor: "transparent" }}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
