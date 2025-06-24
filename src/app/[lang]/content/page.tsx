'use client';

import ContentPage from "@/modules/content/pages";
import { SidebarProvider, SidebarInset } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/app-sidebar';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from "@/contexts/TranslationContext";

export default function ContentRoute() {
  const { t, locale } = useTranslation();
  
  // Create sidebar dictionary
  const sidebarDictionary = {
    appName: t('appSidebar.appName') || 'Ta\'aafi Platform Admin Panel',
    taafiPlatform: t('appSidebar.taafiPlatform') || 'Ta\'aafi Platform',
    quickCreate: t('appSidebar.quickCreate') || 'Quick Create',
    inbox: t('appSidebar.inbox') || 'Inbox',
    dashboard: t('appSidebar.dashboard') || 'Dashboard',
    userManagement: t('appSidebar.userManagement') || 'User Management',
    users: t('appSidebar.users') || 'Users',
    roles: t('appSidebar.roles') || 'Roles',
    permissions: t('appSidebar.permissions') || 'Permissions',
    community: t('appSidebar.community') || 'Community',
    forum: t('appSidebar.forum') || 'Forum',
    groups: t('appSidebar.groups') || 'Groups',
    directMessages: t('appSidebar.directMessages') || 'Direct Messages',
    reports: t('appSidebar.reports') || 'Reports',
    content: t('appSidebar.content') || 'Content',
    contentTypes: t('appSidebar.contentTypes') || 'Content Types',
    contentOwners: t('appSidebar.contentOwners') || 'Content Owners',
    categories: t('appSidebar.categories') || 'Categories',
    contentLists: t('appSidebar.contentLists') || 'Content Lists',
    features: t('appSidebar.features') || 'Features',
    lifecycle: t('appSidebar.lifecycle') || 'Lifecycle',
    analytics: t('appSidebar.analytics') || 'Analytics',
    projects: t('appSidebar.projects') || 'Projects',
    team: t('appSidebar.team') || 'Team',
    documents: t('appSidebar.documents') || 'Documents',
    dataLibrary: t('appSidebar.dataLibrary') || 'Data Library',
    wordAssistant: t('appSidebar.wordAssistant') || 'Word Assistant',
    more: t('appSidebar.more') || 'More',
    settings: t('appSidebar.settings') || 'Settings',
    getHelp: t('appSidebar.getHelp') || 'Get Help',
    search: t('appSidebar.search') || 'Search',
    userMenu: {
      account: t('appSidebar.userMenu.account') || 'Account',
      billing: t('appSidebar.userMenu.billing') || 'Billing',
      notifications: t('appSidebar.userMenu.notifications') || 'Notifications',
      logOut: t('appSidebar.userMenu.logOut') || 'Log out',
    },
    localeSwitcher: {
      english: t('appSidebar.localeSwitcher.english') || 'English',
      arabic: t('appSidebar.localeSwitcher.arabic') || 'Arabic',
    },
  };

  const headerDictionary = {
    documents: t('siteHeader.documents') || 'Documents',
  };
  
  return (
    <SidebarProvider>
      <AppSidebar variant="inset" lang={locale} dictionary={sidebarDictionary} />
      <SidebarInset>
        <SiteHeader dictionary={headerDictionary} />
        <div className="p-6">
          <ContentPage t={t} locale={locale} />
        </div>
      </SidebarInset>
    </SidebarProvider>
  );
} 