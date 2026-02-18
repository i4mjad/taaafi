'use client'

import type React from 'react'
import { useState } from 'react'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  BarChart2,
  CalendarDays,
  CheckSquare,
  UsersRound,
  Sparkles,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { usePathname } from 'next/navigation'

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

// Types
type Feature = {
  id: string
  name: string
  description: string
  icon: React.ElementType
  color: string
  status: 'now' | 'soon'
}

interface Dict {
  coreToolsLabel: string
  introHeading: string
  introDescription1: string
  introDescription2: string

  trackerName: string
  trackerDescription: string
  insightsName: string
  insightsDescription: string
  calendarName: string
  calendarDescription: string
  diariesName: string
  diariesDescription: string
  activitiesName: string
  activitiesDescription: string
  libraryName: string
  libraryDescription: string
  communityName: string
  communityDescription: string
  groupsName: string
  groupsDescription: string
  newToolsName: string
  newToolsDescription: string
  progressName: string
  progressDescription: string
  planningName: string
  planningDescription: string
  growthName: string
  growthDescription: string
  smartName: string
  smartDescription: string
}

const defaultDict: Dict = {
  coreToolsLabel: 'Core Tools',
  introHeading: 'Build Your Recovery',
  introDescription1:
    'Your recovery deserves more than willpower alone. Ta3afi equips you with science-backed digital tools that turn every urge resisted into a step forward.',
  introDescription2:
    'Start building the life you want—one healthy habit, one honest moment, one day at a time.',

  trackerName: 'Tracker',
  trackerDescription:
    'Log every victory—from a ten-second pause to a hundred-day streak—and watch your progress grow.',
  insightsName: 'Insights',
  insightsDescription:
    'Instant analytics reveal triggers, peak urge times, and patterns that keep you stuck—so you can break them.',
  calendarName: 'Calendar',
  calendarDescription:
    'Schedule milestones, therapy sessions, and self-care checkpoints; review wins at a glance.',
  diariesName: 'Diaries',
  diariesDescription:
    'A judgment-free space to record thoughts, emotions, and breakthroughs—encrypted and private.',
  activitiesName: 'Activities',
  activitiesDescription:
    'Curated tasks and habit-building exercises keep your hands busy and your mind focused on growth.',
  libraryName: 'Resource Library',
  libraryDescription:
    'Expert-reviewed articles and videos guide you through cravings, relapse prevention, and long-term healing.',
  communityName: 'Community Hub (Coming Soon)',
  communityDescription:
    "Join a worldwide network that celebrates victories, answers questions, and reminds you you're not alone.",
  groupsName: 'Support Groups (Coming Soon)',
  groupsDescription:
    'Real-time group chat, shared challenges, and peer accountability to keep motivation high.',
  newToolsName: 'New Tools (Coming Soon)',
  newToolsDescription:
    'Personalized AI coaching, relapse-prediction alerts, and mood-tracking integrations—stay tuned!',
  progressName: 'Progress & Insights',
  progressDescription:
    'See every victory and pattern in one place. Log streaks with the Tracker, then let Insights uncover triggers and peak-urge moments so you can stay one step ahead.',
  planningName: 'Planning & Reflection',
  planningDescription:
    'Map your recovery like a pro. Schedule milestones in the Calendar and process emotions privately in Diaries—because progress without reflection is just motion.',
  growthName: 'Guided Growth',
  growthDescription:
    'Keep hands busy and mind focused. Daily Activities and a curated Resource Library give you evidence-based help for every stage of recovery.',
  smartName: 'Smart Assistance (Coming Soon)',
  smartDescription:
    'Personalized AI coaching, relapse-prediction alerts, and mood-tracking integrations—everything you need to future-proof your progress.',
}

interface FeaturesSectionProps {
  dict?: Partial<Dict>
}

export default function FeaturesSection({ dict }: FeaturesSectionProps) {
  const mergedDict: Dict = { ...defaultDict, ...(dict || {}) }
  const pathname = usePathname()
  const lang = pathname.split('/')[1] || 'en'
  const isRTL = lang === 'ar'

  const features: Feature[] = [
    {
      id: 'progress',
      name: mergedDict.progressName,
      description: mergedDict.progressDescription,
      icon: BarChart2,
      color: 'text-amber-500',
      status: 'now',
    },
    {
      id: 'planning',
      name: mergedDict.planningName,
      description: mergedDict.planningDescription,
      icon: CalendarDays,
      color: 'text-teal-500',
      status: 'now',
    },
    {
      id: 'growth',
      name: mergedDict.growthName,
      description: mergedDict.growthDescription,
      icon: CheckSquare,
      color: 'text-indigo-500',
      status: 'now',
    },
    {
      id: 'community-support',
      name: mergedDict.communityName,
      description: mergedDict.communityDescription,
      icon: UsersRound,
      color: 'text-pink-500',
      status: 'soon',
    },
    {
      id: 'smart',
      name: mergedDict.smartName,
      description: mergedDict.smartDescription,
      icon: Sparkles,
      color: 'text-yellow-500',
      status: 'soon',
    },
  ]

  const [activeFeature, setActiveFeature] = useState<string>('progress')

  const currentFeature =
    features.find((f) => f.id === activeFeature) || features[0]

  return (
    <section dir={isRTL ? 'rtl' : 'ltr'} className={cn(isRTL && 'text-right')}>
      <div className="container mx-auto px-4 md:px-6 2xl:max-w-[1400px]">
        <div className="mx-auto mb-16 max-w-3xl space-y-4 text-center">
          <div className="bg-primary/10 text-primary inline-block rounded-lg px-3 py-1 text-sm">
            {mergedDict.coreToolsLabel}
          </div>
          <h2 className="text-3xl font-bold tracking-tight md:text-4xl">
            {mergedDict.introHeading}
          </h2>
          <p className="text-muted-foreground">
            {mergedDict.introDescription1}
          </p>
          <p className="text-muted-foreground">
            {mergedDict.introDescription2}
          </p>
        </div>

        <Tabs
          value={activeFeature}
          onValueChange={setActiveFeature}
          className="space-y-8"
        >
          {/* Value selection - Tabs for md+ screens, Dropdown for smaller screens */}
          <div className="mb-8 flex justify-center">
            {/* Dropdown for small screens */}
            <div className="w-full md:hidden">
              <Select value={activeFeature} onValueChange={setActiveFeature}>
                <SelectTrigger
                  className={cn(
                    'w-full text-right',
                    isRTL ? 'flex-row-reverse' : ''
                  )}
                >
                  <SelectValue placeholder="اختر القسم" />
                </SelectTrigger>
                <SelectContent className={cn(isRTL && 'text-right ')}>
                  {features.map((feature) => (
                    <SelectItem
                      key={feature.id}
                      value={feature.id}
                      className={cn(isRTL ? 'flex-row-reverse' : '')}
                    >
                      <div
                        className={cn(
                          'flex items-center gap-2',
                          isRTL ? 'flex-row-reverse' : ''
                        )}
                      >
                        <feature.icon
                          className={cn(
                            'h-4 w-4',
                            feature.color,
                            isRTL ? 'ml-2' : 'mr-2'
                          )}
                        />
                        <span className={cn(isRTL && 'text-right')}>
                          {feature.name}
                        </span>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Tabs for medium screens and above */}
            <TabsList className="hidden h-auto bg-transparent p-1 md:flex">
              {features.map((feature) => (
                <TabsTrigger
                  key={feature.id}
                  value={feature.id}
                  className={cn(
                    'data-[state=active]:bg-muted gap-2',
                    'data-[state=active]:border-border border border-transparent'
                  )}
                >
                  <feature.icon
                    className={cn(
                      'h-4 w-4',
                      feature.color,
                      isRTL && 'order-2 ml-0 mr-2'
                    )}
                  />
                  <span>{feature.name}</span>
                </TabsTrigger>
              ))}
            </TabsList>
          </div>

          {/* Value content */}
          <div className="grid items-center gap-8 md:grid-cols-12">
            {/* Left column: Feature details */}
            <div className="space-y-6 md:col-span-6">
              <div
                className={cn(
                  'mb-4 flex items-center gap-4',
                  isRTL && 'flex-row-reverse'
                )}
              >
                <div className={cn('rounded-xl p-2.5', 'bg-muted')}>
                  <currentFeature.icon
                    className={cn('h-7 w-7', currentFeature.color)}
                  />
                </div>
                <h3 className="text-2xl font-bold">{currentFeature.name}</h3>
              </div>

              <p className="text-muted-foreground text-lg">
                {currentFeature.description}
              </p>
            </div>

            {/* Right column: Icon placeholder */}
            <div className="md:col-span-6">
              <div className="bg-muted flex aspect-[4/3] items-center justify-center rounded-xl">
                <currentFeature.icon
                  className={cn(
                    'h-24 w-24',
                    currentFeature.color,
                    'opacity-25'
                  )}
                />
              </div>
            </div>
          </div>
        </Tabs>
      </div>
    </section>
  )
}
