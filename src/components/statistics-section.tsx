import Image from "next/image"
import { TrendingUp } from "lucide-react"

export default function StatisticsSection() {
  return (
    <section className="py-16 sm:py-20 lg:py-24 bg-gray-50">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left Content */}
          <div className="space-y-8">
            <div className="space-y-4">
              <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">It's all about speed</h2>
              <p className="text-lg text-gray-600 leading-relaxed">
                We provide you with a test account that can be set up in seconds. Our main focus is getting responses to
                you as soon as we can.
              </p>
            </div>

            {/* Testimonial */}
            <div className="space-y-6">
              <blockquote className="text-xl sm:text-2xl font-medium text-gray-900 italic leading-relaxed">
                "Amazing people to work with. Very fast and professional partner."
              </blockquote>

              <div className="flex items-center space-x-4">
                <div className="relative h-12 w-12 overflow-hidden rounded-full">
                  <Image src="/placeholder.svg?height=48&width=48" alt="Josh Grazioso" fill className="object-cover" />
                </div>
                <div>
                  <p className="font-semibold text-gray-900">Josh Grazioso</p>
                  <p className="text-sm text-gray-600">Director Payments & Risk | Airbnb</p>
                </div>
              </div>
            </div>
          </div>

          {/* Right Statistics Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 lg:gap-4">
            {/* Statistic 1 */}
            <div className="bg-white p-6 sm:p-8 rounded-2xl shadow-sm border border-gray-100">
              <div className="space-y-2">
                <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">45k+</div>
                <p className="text-sm sm:text-base text-gray-600 leading-relaxed">
                  users - from new startups to public companies
                </p>
              </div>
            </div>

            {/* Statistic 2 */}
            <div className="bg-white p-6 sm:p-8 rounded-2xl shadow-sm border border-gray-100">
              <div className="space-y-2">
                <div className="flex items-center space-x-2">
                  <TrendingUp className="h-6 w-6 text-blue-500" />
                  <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">23%</div>
                </div>
                <p className="text-sm sm:text-base text-gray-600 leading-relaxed">
                  increase in traffic on webpages with Looms
                </p>
              </div>
            </div>

            {/* Statistic 3 */}
            <div className="bg-white p-6 sm:p-8 rounded-2xl shadow-sm border border-gray-100">
              <div className="space-y-2">
                <div className="flex items-center space-x-2">
                  <TrendingUp className="h-6 w-6 text-green-500" />
                  <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">9.3%</div>
                </div>
                <p className="text-sm sm:text-base text-gray-600 leading-relaxed">
                  boost in reply rates across sales outreach
                </p>
              </div>
            </div>

            {/* Statistic 4 */}
            <div className="bg-white p-6 sm:p-8 rounded-2xl shadow-sm border border-gray-100">
              <div className="space-y-2">
                <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">2x</div>
                <p className="text-sm sm:text-base text-gray-600 leading-relaxed">faster than previous Acme versions</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
