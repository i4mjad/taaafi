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
  BellIcon,
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

import { Locale } from "../../i18n.config"
import { useAuth } from '@/auth/AuthProvider'

interface SidebarDictionary {
  appName: string;
  taafiPlatform: string;
  quickCreate: string;
  inbox: string;
  dashboard: string;
  userManagement: string;
  users: string;
  roles: string;
  permissions: string;
  community: string;
  forum: string;
  groups: string;
  directMessages: string;
  reports: string;
  content: string;
  contentTypes: string;
  contentOwners: string;
  categories: string;
  contentLists: string;
  features: string;
  settings: string;
  getHelp: string;
  search: string;
  lifecycle: string;
  analytics: string;
  projects: string;
  team: string;
  documents: string;
  dataLibrary: string;
  wordAssistant: string;
  more: string;
  userMenu: {
    account: string;
    billing: string;
    notifications: string;
    logOut: string;
  };
  localeSwitcher: {
    english: string;
    arabic: string;
  };
}

interface AppSidebarProps extends React.ComponentProps<typeof Sidebar> {
  lang: Locale
  dictionary: SidebarDictionary
}

export function AppSidebar({ lang, dictionary, ...props }: AppSidebarProps) {
  const { user } = useAuth();

  const data = {
    user: {
      name: user?.displayName ?? user?.email ?? '—',
      email: user?.email ?? '-',
      avatar: user?.photoURL ?? '/placeholder.svg?width=100&height=100',
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
          { titleKey: "notifications", url: `/${lang}/user-management/notifications`, icon: BellIcon },
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
          { titleKey: "content", url: `/${lang}/content/items`, icon: FileTextIcon },
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
