import { Star, DownloadCloud, UserCheck, User } from "lucide-react"

interface Dict {
  statsHeading: string
  statsDescription: string
  averageRatingLabel: string
  averageRatingValue: string
  downloadsLabel: string
  downloadsValue: string
  activeUsersLabel: string
  activeUsersValue: string
  usersLabel: string
  usersValue: string
}

const defaultDict: Dict = {
  statsHeading: "Our achievements speak for themselves",
  statsDescription:
    "Since launching Ta'aafi we've hit milestones we're proud of and we're still working non-stop to give you the best experience.",
  averageRatingLabel: "Average rating",
  averageRatingValue: "4.5/5",
  downloadsLabel: "Downloads",
  downloadsValue: "35k+",
  activeUsersLabel: "Active users",
  activeUsersValue: "1.5k",
  usersLabel: "Users",
  usersValue: "30k+",
}

interface StatisticsSectionProps {
  dict?: Dict
}

export default function StatisticsSection({ dict = defaultDict }: StatisticsSectionProps) {
  return (
    <section className="py-16 sm:py-20 lg:py-24 bg-gray-50">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left Content */}
          <div className="space-y-8">
            <div className="space-y-4">
              <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">{dict.statsHeading}</h2>
              <p className="text-lg text-gray-600 leading-relaxed">{dict.statsDescription}</p>
            </div>
          </div>

          {/* Right Statistics Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 lg:gap-4">
            {/* Statistic 1 */}
            <div className="bg-white p-6 sm:p-8 rounded-2xl shadow-sm border border-gray-100 text-center space-y-4">
              <Star className="h-8 w-8 mx-auto text-teal-700" />
              <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">{dict.averageRatingValue}</div>
              <p className="text-sm sm:text-base text-gray-600 leading-relaxed">{dict.averageRatingLabel}</p>
            </div>

            {/* Statistic 2 */}
            <div className="bg-white p-6 sm:p-8 rounded-2xl shadow-sm border border-gray-100 text-center space-y-4">
              <DownloadCloud className="h-8 w-8 mx-auto text-teal-700" />
              <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">{dict.downloadsValue}</div>
              <p className="text-sm sm:text-base text-gray-600 leading-relaxed">{dict.downloadsLabel}</p>
            </div>

            {/* Statistic 3 */}
            <div className="bg-white p-6 sm:p-8 rounded-2xl shadow-sm border border-gray-100 text-center space-y-4">
              <UserCheck className="h-8 w-8 mx-auto text-teal-700" />
              <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">{dict.activeUsersValue}</div>
              <p className="text-sm sm:text-base text-gray-600 leading-relaxed">{dict.activeUsersLabel}</p>
            </div>

            {/* Statistic 4 */}
            <div className="bg-white p-6 sm:p-8 rounded-2xl shadow-sm border border-gray-100 text-center space-y-4">
              <User className="h-8 w-8 mx-auto text-teal-700" />
              <div className="text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900">{dict.usersValue}</div>
              <p className="text-sm sm:text-base text-gray-600 leading-relaxed">{dict.usersLabel}</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
