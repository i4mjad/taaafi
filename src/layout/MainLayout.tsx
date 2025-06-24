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
    appName: t('sidebar.taafiPlatform') || 'Ta\'aafi Platform Admin Panel',
    taafiPlatform: t('sidebar.taafiPlatform') || 'Ta\'aafi Platform',
    quickCreate: t('sidebar.quickCreate') || 'Quick Create',
    inbox: t('common.inbox') || 'Inbox',
    dashboard: t('sidebar.dashboard') || 'Dashboard',
    userManagement: t('sidebar.userManagement') || 'User Management',
    users: t('modules.userManagement.users') || 'Users',
    roles: t('common.roles') || 'Roles',
    permissions: t('common.permissions') || 'Permissions',
    community: t('sidebar.community') || 'Community',
    forum: t('sidebar.forum') || 'Forum',
    groups: t('sidebar.groups') || 'Groups',
    directMessages: t('sidebar.directMessages') || 'Direct Messages',
    reports: t('common.reports') || 'Reports',
    content: t('sidebar.content') || 'Content',
    contentTypes: t('sidebar.contentTypes') || 'Content Types',
    contentOwners: t('sidebar.contentOwners') || 'Content Owners',
    categories: t('sidebar.categories') || 'Categories',
    contentLists: t('sidebar.contentLists') || 'Content Lists',
    features: t('sidebar.features') || 'Features',
    settings: t('sidebar.settings') || 'Settings',
    getHelp: t('common.help') || 'Get Help',
    search: t('common.search') || 'Search',
    // Legacy properties for compatibility
    lifecycle: t('sidebar.userManagement') || 'User Management',
    analytics: t('sidebar.features') || 'Features',
    projects: t('sidebar.community') || 'Community',
    team: t('sidebar.content') || 'Content',
    documents: t('sidebar.content') || 'Documents',
    dataLibrary: t('sidebar.contentTypes') || 'Data Library',
    wordAssistant: t('sidebar.categories') || 'Word Assistant',
    more: t('sidebar.features') || 'More',
    userMenu: {
      account: t('common.account') || 'Account',
      billing: t('common.billing') || 'Billing',
      notifications: t('common.notifications') || 'Notifications',
      logOut: t('auth.signOut') || 'Log out',
    },
    localeSwitcher: {
      english: t('sidebar.localeSwitcher.english') || 'English',
      arabic: t('sidebar.localeSwitcher.arabic') || 'Arabic',
    },
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