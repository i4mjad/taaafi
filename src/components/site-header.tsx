import { Separator } from "@/components/ui/separator"
import { SidebarTrigger } from "@/components/ui/sidebar"
import type { Dictionary } from "@/app/[lang]/dashboard/page"

interface SiteHeaderProps {
  dictionary: Dictionary["siteHeader"]
}

export function SiteHeader({ dictionary }: SiteHeaderProps) {
  return (
    <header className="group-has-data-[collapsible=icon]/sidebar-wrapper:h-12 flex h-12 shrink-0 items-center gap-2 border-b transition-[width,height] ease-linear">
      <div className="flex w-full items-center gap-1 px-4 lg:gap-2 lg:px-6">
        <SidebarTrigger className="-ml-1 rtl:-mr-1 rtl:ml-0" />
        <Separator orientation="vertical" className="mx-2 data-[orientation=vertical]:h-4 rtl:mx-2" />
        <h1 className="text-base font-medium">{dictionary.documents}</h1>
      </div>
    </header>
  )
}
