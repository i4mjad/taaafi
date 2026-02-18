"use client"

import * as React from "react"
import { Area, AreaChart, CartesianGrid, XAxis } from "recharts"
import { format, subDays, startOfDay } from "date-fns"

import { useIsMobile } from "@/hooks/use-mobile"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { type ChartConfig, ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

const chartConfig = {
  content: {
    label: "Content Activity",
  },
  messages: {
    label: "Messages",
    color: "hsl(var(--chart-1))",
  },
  reports: {
    label: "Reports",
    color: "hsl(var(--chart-2))",
  },
} satisfies ChartConfig

interface ContentActivityChartProps {
  messages: any[]
  reports: any[]
  t: (key: string) => string
}

export function ContentActivityChart({ messages, reports, t }: ContentActivityChartProps) {
  const isMobile = useIsMobile()
  const [timeRange, setTimeRange] = React.useState("30d")

  React.useEffect(() => {
    if (isMobile) {
      setTimeRange("7d")
    }
  }, [isMobile])

  // Generate chart data by aggregating messages and reports by day
  const chartData = React.useMemo(() => {
    const days = timeRange === "90d" ? 90 : timeRange === "30d" ? 30 : 7
    const data = []
    
    for (let i = days - 1; i >= 0; i--) {
      const date = startOfDay(subDays(new Date(), i))
      const dateStr = format(date, "yyyy-MM-dd")
      
      // Count messages for this day
      const messagesCount = messages.filter(message => {
        const messageDate = message.createdAt
        return messageDate && format(startOfDay(messageDate), "yyyy-MM-dd") === dateStr
      }).length
      
      // Count reports for this day
      const reportsCount = reports.filter(report => {
        const reportDate = report.createdAt?.toDate?.() || report.createdAt
        return reportDate && format(startOfDay(reportDate), "yyyy-MM-dd") === dateStr
      }).length
      
      data.push({
        date: dateStr,
        messages: messagesCount,
        reports: reportsCount,
      })
    }
    
    return data
  }, [messages, reports, timeRange])

  return (
    <Card className="@container/card">
      <CardHeader className="relative">
        <CardTitle>{t('modules.admin.charts.contentActivity')}</CardTitle>
        <CardDescription>
          {t('modules.admin.charts.contentActivityDesc')}
        </CardDescription>
        <div className="absolute right-4 top-4 rtl:left-4 rtl:right-auto">
          <ToggleGroup
            type="single"
            value={timeRange}
            onValueChange={setTimeRange}
            variant="outline"
            className="@[767px]/card:flex hidden"
          >
            <ToggleGroupItem value="90d" className="h-8 px-2.5">
              {t('common.last90Days')}
            </ToggleGroupItem>
            <ToggleGroupItem value="30d" className="h-8 px-2.5">
              {t('common.last30Days')}
            </ToggleGroupItem>
            <ToggleGroupItem value="7d" className="h-8 px-2.5">
              {t('common.last7Days')}
            </ToggleGroupItem>
          </ToggleGroup>
          <Select value={timeRange} onValueChange={setTimeRange}>
            <SelectTrigger className="@[767px]/card:hidden flex w-40" aria-label="Select a value">
              <SelectValue placeholder={t('common.last30Days')} />
            </SelectTrigger>
            <SelectContent className="rounded-xl">
              <SelectItem value="90d" className="rounded-lg">
                {t('common.last90Days')}
              </SelectItem>
              <SelectItem value="30d" className="rounded-lg">
                {t('common.last30Days')}
              </SelectItem>
              <SelectItem value="7d" className="rounded-lg">
                {t('common.last7Days')}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>
      </CardHeader>
      <CardContent className="px-2 pt-4 sm:px-6 sm:pt-6">
        <ChartContainer config={chartConfig} className="aspect-auto h-[250px] w-full">
          <AreaChart data={chartData}>
            <defs>
              <linearGradient id="fillMessages" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="var(--color-messages)" stopOpacity={1.0} />
                <stop offset="95%" stopColor="var(--color-messages)" stopOpacity={0.1} />
              </linearGradient>
              <linearGradient id="fillReports" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="var(--color-reports)" stopOpacity={0.8} />
                <stop offset="95%" stopColor="var(--color-reports)" stopOpacity={0.1} />
              </linearGradient>
            </defs>
            <CartesianGrid vertical={false} />
            <XAxis
              dataKey="date"
              tickLine={false}
              axisLine={false}
              tickMargin={8}
              minTickGap={32}
              tickFormatter={(value) => {
                const date = new Date(value)
                return date.toLocaleDateString("en-US", {
                  month: "short",
                  day: "numeric",
                })
              }}
            />
            <ChartTooltip
              cursor={false}
              content={
                <ChartTooltipContent
                  labelFormatter={(value) => {
                    return new Date(value as string | number | Date).toLocaleDateString("en-US", {
                      month: "short",
                      day: "numeric",
                    })
                  }}
                  indicator="dot"
                />
              }
            />
            <Area dataKey="reports" type="natural" fill="url(#fillReports)" stroke="var(--color-reports)" stackId="a" />
            <Area dataKey="messages" type="natural" fill="url(#fillMessages)" stroke="var(--color-messages)" stackId="a" />
          </AreaChart>
        </ChartContainer>
      </CardContent>
    </Card>
  )
}
