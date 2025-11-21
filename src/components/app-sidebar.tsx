"use client"

import type * as React from "react"
import {
  FolderIcon,
  HeartHandshakeIcon,
  LayoutDashboardIcon,
  ListIcon,
  UsersIcon,
  MessageSquareIcon,
  SettingsIcon,
  FileTextIcon,
  UserIcon,
  TagIcon,
  FlagIcon,
  MessageCircleIcon,
  AlertTriangleIcon,
  CrownIcon,
  BellIcon,
  ShieldIcon,
  TrophyIcon,
  UserPlusIcon,
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
import { useTranslation } from '@/contexts/TranslationContext'



interface AppSidebarProps extends React.ComponentProps<typeof Sidebar> {
  lang: Locale
  
}

export function AppSidebar({ lang, ...props }: AppSidebarProps) {
  const { user } = useAuth();
  const { t } = useTranslation();

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
          { titleKey: "referralProgram", url: `/${lang}/user-management/referrals/dashboard`, icon: UserPlusIcon },
          { titleKey: "reports", url: `/${lang}/user-management/reports`, icon: AlertTriangleIcon },
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
          { titleKey: "directMessages", url: `/${lang}/community/direct-messages`, icon: MessageCircleIcon },
          { titleKey: "reports", url: `/${lang}/community/reports`, icon: AlertTriangleIcon },
          { titleKey: "settings", url: `/${lang}/community/settings`, icon: SettingsIcon },
        ]
      },
      // Groups Management - Combined admin and management tools
      {
        titleKey: "groupAdministration", 
        url: "#", 
        icon: CrownIcon,
        items: [
          { titleKey: "adminDashboard", url: `/${lang}/community/groups/admin-overview`, icon: LayoutDashboardIcon },
          { titleKey: "allGroups", url: `/${lang}/groups-management`, icon: UsersIcon },
          { titleKey: "memberManagement", url: `/${lang}/community/groups/memberships`, icon: UsersIcon },
          { titleKey: "messagesModeration", url: `/${lang}/community/groups/messages-moderation`, icon: MessageSquareIcon },
          { titleKey: "updatesModeration", url: `/${lang}/community/groups/updates-moderation`, icon: FileTextIcon },
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
        icon: FlagIcon,
        items: [
          { titleKey: "featureFlags", url: `/${lang}/features`, icon: FlagIcon },
          { titleKey: "appFeatures", url: `/${lang}/features/app-features`, icon: SettingsIcon },
        ]
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
                
                <span className="text-base font-semibold">{t('appSidebar.appName')}</span>
              </a>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
        <LocaleSwitcher currentLocale={lang} />
        <ThemeSwitcher />
      </SidebarHeader>
      <SidebarSeparator />
      <SidebarContent>
        <NavMain
          items={data.navMain.map((item) => ({
            ...item,
            title: t(`appSidebar.${item.titleKey}`),
            items: item.items?.map((subItem) => ({
              ...subItem,
              title: t(`appSidebar.${subItem.titleKey}`),
            })),
          }))}
        />
    
   
      </SidebarContent>
      <SidebarFooter>
        <NavUser user={data.user} />
      </SidebarFooter>
    </Sidebar>
  )
}
