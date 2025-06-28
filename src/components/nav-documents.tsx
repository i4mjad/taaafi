"use client"

import { FolderIcon, MoreHorizontalIcon, ShareIcon, type LucideIcon } from "lucide-react"

import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import {
  SidebarGroup,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuAction,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar"
import type { Dictionary } from "@/app/[lang]/dashboard/page"

interface NavDocumentsProps {
  items: {
    name: string 
    url: string
    icon: LucideIcon
  }[]
  dictionary: Dictionary["appSidebar"] & { navDocs: Dictionary["navDocuments"] } // Combine for specific keys
}

export function NavDocuments({ items, dictionary }: NavDocumentsProps) {
  const { isMobile, state: sidebarState } = useSidebar()
  const isCollapsed = sidebarState === "collapsed"

  return (
    <SidebarGroup className={isCollapsed ? "group-data-[collapsible=icon]:hidden" : ""}>
      <SidebarGroupLabel>{dictionary.documents}</SidebarGroupLabel>
      <SidebarMenu>
        {items.map((item) => (
          <SidebarMenuItem key={item.name}>
            <SidebarMenuButton asChild tooltip={isCollapsed ? item.name : undefined}>
              <a href={item.url}>
                <item.icon />
                <span>{item.name}</span>
              </a>
            </SidebarMenuButton>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <SidebarMenuAction showOnHover className="rounded-sm data-[state=open]:bg-accent">
                  <MoreHorizontalIcon />
                  <span className="sr-only">{dictionary.more}</span>
                </SidebarMenuAction>
              </DropdownMenuTrigger>
              <DropdownMenuContent
                className="w-24 rounded-lg"
                side={isMobile ? "bottom" : "right"}
                align={isMobile ? "end" : "start"}
              >
                <DropdownMenuItem>
                  <FolderIcon className="ltr:mr-2 rtl:ml-2" />
                  <span>{dictionary.navDocs.open}</span>
                </DropdownMenuItem>
                <DropdownMenuItem>
                  <ShareIcon className="ltr:mr-2 rtl:ml-2" />
                  <span>{dictionary.navDocs.share}</span>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        ))}
        <SidebarMenuItem>
          <SidebarMenuButton className="text-sidebar-foreground/70" tooltip={isCollapsed ? dictionary.more : undefined}>
            <MoreHorizontalIcon className="text-sidebar-foreground/70" />
            <span>{dictionary.more}</span>
          </SidebarMenuButton>
        </SidebarMenuItem>
      </SidebarMenu>
    </SidebarGroup>
  )
}
