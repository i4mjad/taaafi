import { ChartAreaInteractive } from "@/components/chart-area-interactive"
import { DataTable } from "@/components/data-table"
import { SectionCards } from "@/components/section-cards"
import { SiteHeader } from "@/components/site-header"
import { Locale } from "../../../../i18n.config"
import rawData from "./data.json" // Keep original data loading
import { getDictionary } from "./dictionaries"

// Define a type for the dictionary for better type safety
export type Dictionary = Awaited<ReturnType<typeof getDictionary>>

export default async function Page({ params }: { params: Promise<{ lang: string }> }) {
  const { lang: rawLang } = await params
  const lang = rawLang as Locale
  const dictionary = await getDictionary(lang)

  // For data.json, you might need a more complex solution for full i18n
  // For now, we'll pass the raw data and handle UI strings via dictionary
  const data = rawData.map((item) => ({
    ...item,
    // Example: If 'status' or 'type' were keys in dictionary
    // status: dictionary.dataTable.statusTypes[item.status.toLowerCase().replace(' ', '') as keyof typeof dictionary.dataTable.statusTypes] || item.status,
    // type: dictionary.dataTable.typeNames[item.type.toLowerCase().replace(/ /g, '') as keyof typeof dictionary.dataTable.typeNames] || item.type,
  }))

  return (
    <>
      <SiteHeader dictionary={dictionary.siteHeader} />
      <div className="flex flex-1 flex-col">
        <div className="@container/main flex flex-1 flex-col gap-2">
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6">
            <SectionCards dictionary={dictionary.sectionCards} />
            <div className="px-4 lg:px-6">
              <ChartAreaInteractive dictionary={dictionary.chartAreaInteractive} />
            </div>
            <DataTable data={data} dictionary={dictionary.dataTable} lang={lang} />
          </div>
        </div>
      </div>
    </>
  )
}
