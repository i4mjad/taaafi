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
  health: {
    label: "System Health",
  },
  activeGroups: {
    label: "Active Groups",
    color: "hsl(var(--chart-3))",
  },
  moderationActions: {
    label: "Moderation Actions",
    color: "hsl(var(--chart-4))",
  },
} satisfies ChartConfig

interface SystemHealthChartProps {
  groups: any[]
  messages: any[]
  t: (key: string) => string
}

export function SystemHealthChart({ groups, messages, t }: SystemHealthChartProps) {
  const isMobile = useIsMobile()
  const [timeRange, setTimeRange] = React.useState("30d")

  React.useEffect(() => {
    if (isMobile) {
      setTimeRange("7d")
    }
  }, [isMobile])

  // Generate chart data by calculating active groups and moderation actions by day
  const chartData = React.useMemo(() => {
    const days = timeRange === "90d" ? 90 : timeRange === "30d" ? 30 : 7
    const data = []
    
    for (let i = days - 1; i >= 0; i--) {
      const date = startOfDay(subDays(new Date(), i))
      const dateStr = format(date, "yyyy-MM-dd")
      
      // Count groups that had activity (messages) on this day
      const activeGroupsSet = new Set()
      messages.forEach(message => {
        const messageDate = message.createdAt
        if (messageDate && format(startOfDay(messageDate), "yyyy-MM-dd") === dateStr) {
          activeGroupsSet.add(message.groupId)
        }
      })
      
      // Count moderation actions (messages with moderation status change) on this day
      const moderationActions = messages.filter(message => {
        const messageDate = message.createdAt
        const hasModeration = message.moderation?.status && message.moderation?.status !== 'pending'
        return messageDate && hasModeration && format(startOfDay(messageDate), "yyyy-MM-dd") === dateStr
      }).length
      
      data.push({
        date: dateStr,
        activeGroups: activeGroupsSet.size,
        moderationActions: moderationActions,
      })
    }
    
    return data
  }, [groups, messages, timeRange])

  return (
    <Card className="@container/card">
      <CardHeader className="relative">
        <CardTitle>{t('modules.admin.charts.systemHealth')}</CardTitle>
        <CardDescription>
          {t('modules.admin.charts.systemHealthDesc')}
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
              <linearGradient id="fillActiveGroups" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="var(--color-activeGroups)" stopOpacity={1.0} />
                <stop offset="95%" stopColor="var(--color-activeGroups)" stopOpacity={0.1} />
              </linearGradient>
              <linearGradient id="fillModerationActions" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="var(--color-moderationActions)" stopOpacity={0.8} />
                <stop offset="95%" stopColor="var(--color-moderationActions)" stopOpacity={0.1} />
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
            <Area dataKey="moderationActions" type="natural" fill="url(#fillModerationActions)" stroke="var(--color-moderationActions)" stackId="a" />
            <Area dataKey="activeGroups" type="natural" fill="url(#fillActiveGroups)" stroke="var(--color-activeGroups)" stackId="a" />
          </AreaChart>
        </ChartContainer>
      </CardContent>
    </Card>
  )
}
