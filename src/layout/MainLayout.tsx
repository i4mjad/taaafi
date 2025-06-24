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

  if (loading) {
    return (
      <div className="flex h-screen">
        <div className="w-64 border-r">
          <Skeleton className="h-full w-full" />
        </div>
        <div className="flex-1 p-8">
          <div className="space-y-4">
            <Skeleton className="h-8 w-1/3" />
            <Skeleton className="h-4 w-2/3" />
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              {[...Array(4)].map((_, i) => (
                <Skeleton key={i} className="h-32" />
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

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
      <div className={`min-h-screen ${locale === 'ar' ? 'rtl' : 'ltr'}`}>
        {children}
      </div>
    );
  }

  // Create dictionary object for the existing AppSidebar
  const sidebarDictionary = {
    appName: t('sidebar.appName'),
    acmeInc: t('sidebar.taafiPlatform'),
    quickCreate: t('sidebar.quickCreate'),
    inbox: t('common.inbox') || 'Inbox',
    dashboard: t('sidebar.dashboard'),
    lifecycle: t('sidebar.userManagement'),
    analytics: t('modules.features.title'),
    projects: t('sidebar.community'),
    team: t('sidebar.content'),
    documents: t('sidebar.content'),
    dataLibrary: t('sidebar.contentTypes'),
    reports: t('sidebar.contentLists'),
    wordAssistant: t('sidebar.categories'),
    more: t('sidebar.features'),
    settings: t('sidebar.settings'),
    getHelp: t('common.help') || 'Help',
    search: t('common.search'),
    // Sub-navigation items
    forum: t('sidebar.forum'),
    groups: t('sidebar.groups'),
    messages: t('sidebar.directMessages'),
    types: t('sidebar.contentTypes'),
    owners: t('sidebar.contentOwners'),
    categories: t('sidebar.categories'),
    content: t('sidebar.contentItems'),
    lists: t('sidebar.contentLists'),
    userMenu: {
      account: t('common.account') || 'Account',
      billing: t('common.billing') || 'Billing',
      notifications: t('common.notifications') || 'Notifications',
      logOut: t('auth.signOut'),
    },
    localeSwitcher: {
      english: t('sidebar.localeSwitcher.english'),
      arabic: t('sidebar.localeSwitcher.arabic'),
    },
  };

  const navDocuments = {
    open: t('common.open') || 'Open',
    share: t('common.share') || 'Share',
  };

  // Dynamic sidebar position based on locale
  const sidebarSide = locale === 'ar' ? 'right' : 'left';

  // Normal authenticated layout with single sidebar
  return (
    <SidebarProvider>
      <div className={`flex h-screen w-full ${locale === 'ar' ? 'rtl' : 'ltr'}`}>
        {/* Single sidebar that changes position based on locale */}
        <AppSidebar 
          lang={locale}
          dictionary={sidebarDictionary}
          
          side={sidebarSide}
        />
        
        {/* Main content area - takes remaining space */}
        <SidebarInset className="flex-1 min-w-0">
          <main className="h-full w-full overflow-auto">
            {children}
          </main>
        </SidebarInset>
      </div>
    </SidebarProvider>
  );
} 