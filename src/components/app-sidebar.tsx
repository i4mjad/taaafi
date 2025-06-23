"use client"

import type * as React from "react"
import {
  ArrowUpCircleIcon,
  BarChartIcon,
  ClipboardListIcon,
  DatabaseIcon,
  FileIcon,
  FolderIcon,
  HelpCircleIcon,
  LayoutDashboardIcon,
  ListIcon,
  SearchIcon,
  SettingsIcon,
  UsersIcon,
} from "lucide-react"

import { NavDocuments } from "@/components/nav-documents"
import { NavMain } from "@/components/nav-main"
import { NavSecondary } from "@/components/nav-secondary"
import { NavUser } from "@/components/nav-user"
import { LocaleSwitcher } from "@/components/locale-switcher"
import { ThemeSwitcher } from "@/components/theme-switcher"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarSeparator,
} from "@/components/ui/sidebar"

import type { Dictionary } from "@/app/[lang]/dashboard/page" // Assuming Dictionary type is exported from page
import { Locale } from "../../i18n.config"

interface AppSidebarProps extends React.ComponentProps<typeof Sidebar> {
  lang: Locale
  dictionary: Dictionary["appSidebar"]
  navDocs: Dictionary["navDocuments"]
}

export function AppSidebar({ lang, dictionary, navDocs, ...props }: AppSidebarProps) {
  const data = {
    user: {
      name: "shadcn", // This could also be from dictionary or user data
      email: "m@example.com",
      avatar: "/placeholder.svg?width=100&height=100",
    },
    navMain: [
      { titleKey: "dashboard", url: "#", icon: LayoutDashboardIcon },
      { titleKey: "lifecycle", url: "#", icon: ListIcon },
      { titleKey: "analytics", url: "#", icon: BarChartIcon },
      { titleKey: "projects", url: "#", icon: FolderIcon },
      { titleKey: "team", url: "#", icon: UsersIcon },
    ],
    documents: [
      { nameKey: "dataLibrary", url: "#", icon: DatabaseIcon },
      { nameKey: "reports", url: "#", icon: ClipboardListIcon },
      { nameKey: "wordAssistant", url: "#", icon: FileIcon },
    ],
    navSecondary: [
      { titleKey: "settings", url: "#", icon: SettingsIcon },
      { titleKey: "getHelp", url: "#", icon: HelpCircleIcon },
      { titleKey: "search", url: "#", icon: SearchIcon },
    ],
  }

  const sidebarSide = lang === "ar" ? "right" : "left"

  return (
    <Sidebar collapsible="offcanvas" side={sidebarSide} {...props}>
      <SidebarHeader className="flex flex-col gap-2">
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton asChild className="data-[slot=sidebar-menu-button]:!p-1.5">
              <a href="#">
                <ArrowUpCircleIcon className="h-5 w-5" />
                <span className="text-base font-semibold">{dictionary.acmeInc}</span>
              </a>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
        <LocaleSwitcher currentLocale={lang} dictionary={dictionary.localeSwitcher} />
      </SidebarHeader>
      <SidebarSeparator />
      <SidebarContent>
        <NavMain
          items={data.navMain.map((item) => ({
            ...item,
            title: String(dictionary[item.titleKey as keyof typeof dictionary] ?? item.titleKey),
          }))}
          dictionary={dictionary}
        />
        <NavDocuments
          items={data.documents.map((item) => ({
            ...item,
            name: String(dictionary[item.nameKey as keyof typeof dictionary] ?? item.nameKey),
          }))}
          dictionary={{ ...dictionary, navDocs }}
        />
        <NavSecondary
          items={data.navSecondary.map((item) => ({
            ...item,
            title: String(dictionary[item.titleKey as keyof typeof dictionary] ?? item.titleKey),
          }))}
          className="mt-auto"
        />
      </SidebarContent>
      <SidebarFooter>
        <ThemeSwitcher />
        <NavUser user={data.user} dictionary={dictionary.userMenu} />
      </SidebarFooter>
    </Sidebar>
  )
}
