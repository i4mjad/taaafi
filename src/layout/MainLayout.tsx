'use client';

import React from 'react';
import { usePathname } from 'next/navigation';
import { SidebarProvider, SidebarInset } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/app-sidebar';
import { useAuth } from '@/auth/AuthProvider';
import { useTranslation } from '@/contexts/TranslationContext';
import { Skeleton } from '@/components/ui/skeleton';

interface MainLayoutProps {
  children: React.ReactNode;
}

export function MainLayout({ children }: MainLayoutProps) {
  const { user, loading } = useAuth();
  const { t, locale } = useTranslation();
  const pathname = usePathname();

  // Check if we're on a public route (login page)
  const isLoginPage = pathname.includes('/login');

  // Don't show full loading layout, handle loading in content area instead

  // If user is not authenticated and NOT on login page, show access denied
  if (!user && !isLoginPage) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="text-center space-y-4">
          <h1 className="text-2xl font-bold">{t('auth.accessDenied')}</h1>
          <p className="text-muted-foreground">
            Please sign in with an administrator or moderator account.
          </p>
        </div>
      </div>
    );
  }

  // If we're on the login page, render without sidebar
  if (isLoginPage) {
    return (
      <div className={`font-sans min-h-screen ${locale === 'ar' ? 'rtl' : 'ltr'}`}>
        {children}
      </div>
    );
  }

  // Create dictionary object for the existing AppSidebar
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
    settings: t('appSidebar.settings') || 'Settings',
    getHelp: t('appSidebar.getHelp') || 'Get Help',
    search: t('appSidebar.search') || 'Search',
    // Legacy properties for compatibility
    lifecycle: t('appSidebar.userManagement') || 'User Management',
    analytics: t('appSidebar.features') || 'Features',
    projects: t('appSidebar.community') || 'Community',
    team: t('appSidebar.content') || 'Content',
    documents: t('appSidebar.documents') || 'Documents',
    dataLibrary: t('appSidebar.dataLibrary') || 'Data Library',
    wordAssistant: t('appSidebar.wordAssistant') || 'Word Assistant',
    more: t('appSidebar.more') || 'More',
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

  // Dynamic sidebar position based on locale
  const sidebarSide = locale === 'ar' ? 'right' : 'left';

  // Normal authenticated layout with single sidebar
  return (
    <SidebarProvider>
      <div className={`font-sans flex h-screen w-full ${locale === 'ar' ? 'rtl' : 'ltr'}`}>
        {/* Single sidebar that changes position based on locale */}
        <AppSidebar 
          lang={locale}
          dictionary={sidebarDictionary}
          side={sidebarSide}
        />
        
        {/* Main content area - takes remaining space */}
        <SidebarInset className="flex-1 min-w-0">
          <main className="h-full w-full overflow-auto">
            {loading ? (
              <div className="p-8">
                <div className="space-y-4">
                  <Skeleton className="h-8 w-1/3" />
                  <Skeleton className="h-4 w-2/3" />
                  <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                    {[...Array(4)].map((_, i) => (
                      <Skeleton key={i} className="h-32" />
                    ))}
                  </div>
                  <div className="space-y-3 mt-8">
                    {[...Array(5)].map((_, i) => (
                      <Skeleton key={i} className="h-16 w-full" />
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              children
            )}
          </main>
        </SidebarInset>
      </div>
    </SidebarProvider>
  );
} 