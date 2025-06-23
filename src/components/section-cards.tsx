import { TrendingDownIcon, TrendingUpIcon } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Card, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import type { Dictionary } from "@/app/[lang]/dashboard/page"

interface SectionCardsProps {
  dictionary: Dictionary["sectionCards"]
}

export function SectionCards({ dictionary }: SectionCardsProps) {
  return (
    <div className="*:data-[slot=card]:shadow-xs @xl/main:grid-cols-2 @5xl/main:grid-cols-4 grid grid-cols-1 gap-4 px-4 *:data-[slot=card]:bg-gradient-to-t *:data-[slot=card]:from-primary/5 *:data-[slot=card]:to-card dark:*:data-[slot=card]:bg-card lg:px-6">
      <Card className="@container/card">
        <CardHeader className="relative">
          <CardDescription>{dictionary.totalRevenue}</CardDescription>
          <CardTitle className="@[250px]/card:text-3xl text-2xl font-semibold tabular-nums">$1,250.00</CardTitle>
          <div className="absolute right-4 top-4 rtl:left-4 rtl:right-auto">
            <Badge variant="outline" className="flex gap-1 rounded-lg text-xs">
              <TrendingUpIcon className="size-3" />
              +12.5%
            </Badge>
          </div>
        </CardHeader>
        <CardFooter className="flex-col items-start gap-1 text-sm">
          <div className="line-clamp-1 flex gap-2 font-medium">
            {dictionary.trendingUp} {dictionary.thisMonth} <TrendingUpIcon className="size-4" />
          </div>
          <div className="text-muted-foreground">{dictionary.visitorsLast6Months}</div>
        </CardFooter>
      </Card>
      <Card className="@container/card">
        <CardHeader className="relative">
          <CardDescription>{dictionary.newCustomers}</CardDescription>
          <CardTitle className="@[250px]/card:text-3xl text-2xl font-semibold tabular-nums">1,234</CardTitle>
          <div className="absolute right-4 top-4 rtl:left-4 rtl:right-auto">
            <Badge variant="outline" className="flex gap-1 rounded-lg text-xs">
              <TrendingDownIcon className="size-3" />
              -20%
            </Badge>
          </div>
        </CardHeader>
        <CardFooter className="flex-col items-start gap-1 text-sm">
          <div className="line-clamp-1 flex gap-2 font-medium">
            {dictionary.trendingDown} 20% {dictionary.thisPeriod} <TrendingDownIcon className="size-4" />
          </div>
          <div className="text-muted-foreground">{dictionary.acquisitionNeedsAttention}</div>
        </CardFooter>
      </Card>
      <Card className="@container/card">
        <CardHeader className="relative">
          <CardDescription>{dictionary.activeAccounts}</CardDescription>
          <CardTitle className="@[250px]/card:text-3xl text-2xl font-semibold tabular-nums">45,678</CardTitle>
          <div className="absolute right-4 top-4 rtl:left-4 rtl:right-auto">
            <Badge variant="outline" className="flex gap-1 rounded-lg text-xs">
              <TrendingUpIcon className="size-3" />
              +12.5%
            </Badge>
          </div>
        </CardHeader>
        <CardFooter className="flex-col items-start gap-1 text-sm">
          <div className="line-clamp-1 flex gap-2 font-medium">
            {dictionary.strongUserRetention} <TrendingUpIcon className="size-4" />
          </div>
          <div className="text-muted-foreground">{dictionary.engagementExceedTargets}</div>
        </CardFooter>
      </Card>
      <Card className="@container/card">
        <CardHeader className="relative">
          <CardDescription>{dictionary.growthRate}</CardDescription>
          <CardTitle className="@[250px]/card:text-3xl text-2xl font-semibold tabular-nums">4.5%</CardTitle>
          <div className="absolute right-4 top-4 rtl:left-4 rtl:right-auto">
            <Badge variant="outline" className="flex gap-1 rounded-lg text-xs">
              <TrendingUpIcon className="size-3" />
              +4.5%
            </Badge>
          </div>
        </CardHeader>
        <CardFooter className="flex-col items-start gap-1 text-sm">
          <div className="line-clamp-1 flex gap-2 font-medium">
            {dictionary.steadyPerformance} <TrendingUpIcon className="size-4" />
          </div>
          <div className="text-muted-foreground">{dictionary.meetsGrowthProjections}</div>
        </CardFooter>
      </Card>
    </div>
  )
}
