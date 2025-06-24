"use client"

import type * as React from "react"
import {
  BarChartIcon,
  FolderIcon,
  HeartHandshakeIcon,
  LayoutDashboardIcon,
  ListIcon,
  UsersIcon,
  MessageSquareIcon,
  ShieldIcon,
  KeyIcon,
  SettingsIcon,
  FileTextIcon,
  UserIcon,
  TagIcon,
  FlagIcon,
  MessageCircleIcon,
  AlertTriangleIcon,
  CrownIcon,
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
      { 
        titleKey: "dashboard", 
        url: `/${lang}/dashboard`, 
        icon: LayoutDashboardIcon 
      },
      { 
        titleKey: "userManagement", 
        url: `/${lang}/user-management`, 
        icon: UsersIcon,
        items: [
          { titleKey: "users", url: `/${lang}/user-management/users`, icon: UserIcon },
          { titleKey: "roles", url: `/${lang}/user-management/roles`, icon: CrownIcon },
          { titleKey: "permissions", url: `/${lang}/user-management/permissions`, icon: KeyIcon },
          { titleKey: "settings", url: `/${lang}/user-management/settings`, icon: SettingsIcon },
        ]
      },
      { 
        titleKey: "community", 
        url: `/${lang}/community`, 
        icon: HeartHandshakeIcon,
        items: [
          { titleKey: "forum", url: `/${lang}/community/forum`, icon: MessageSquareIcon },
          { titleKey: "groups", url: `/${lang}/community/groups`, icon: UsersIcon },
          { titleKey: "directMessages", url: `/${lang}/community/direct-messages`, icon: MessageCircleIcon },
          { titleKey: "reports", url: `/${lang}/community/reports`, icon: AlertTriangleIcon },
          { titleKey: "settings", url: `/${lang}/community/settings`, icon: SettingsIcon },
        ]
      },
      { 
        titleKey: "content", 
        url: `/${lang}/content`, 
        icon: FileTextIcon,
        items: [
          { titleKey: "contentTypes", url: `/${lang}/content/types`, icon: ListIcon },
          { titleKey: "contentOwners", url: `/${lang}/content/owners`, icon: UserIcon },
          { titleKey: "categories", url: `/${lang}/content/categories`, icon: TagIcon },
          { titleKey: "content", url: `/${lang}/content/content`, icon: FileTextIcon },
          { titleKey: "contentLists", url: `/${lang}/content/lists`, icon: FolderIcon },
        ]
      },
      { 
        titleKey: "features", 
        url: `/${lang}/features`, 
        icon: FlagIcon 
      },
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
            items: item.items?.map((subItem) => ({
              ...subItem,
              title: String(dictionary[subItem.titleKey as keyof typeof dictionary] ?? subItem.titleKey),
            })),
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
