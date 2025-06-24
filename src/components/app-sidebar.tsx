"use client"

import type * as React from "react"
import {
  BarChartIcon,
  FolderIcon,
  HeartHandshakeIcon,
  LayoutDashboardIcon,
  ListIcon,
  UsersIcon,
} from "lucide-react"

import { NavMain } from "@/components/nav-main"
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
}

export function AppSidebar({ lang, dictionary, ...props }: AppSidebarProps) {
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
    
    ],
    navSecondary: [
      
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
                <HeartHandshakeIcon className="h-5 w-5" />
                
                <span className="text-base font-semibold">{dictionary.appName}</span>
              </a>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
        <LocaleSwitcher currentLocale={lang} dictionary={dictionary.localeSwitcher} />
        <ThemeSwitcher />
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
    
   
      </SidebarContent>
      <SidebarFooter>
        <NavUser user={data.user} dictionary={dictionary.userMenu} />
      </SidebarFooter>
    </Sidebar>
  )
}
