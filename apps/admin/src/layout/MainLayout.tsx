'use client';

import React, { useEffect } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { SidebarProvider, SidebarInset } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/app-sidebar';
import { useAuth } from '@/auth/AuthProvider';
import { useTranslation } from '@/contexts/TranslationContext';
import { Skeleton } from '@/components/ui/skeleton';
import { Button } from '@/components/ui/button';
import { LoginForm } from '@/components/login-form';
import { HeartHandshakeIcon } from 'lucide-react';
import { LocaleSwitcher } from '@/components/locale-switcher';
import { ThemeSwitcher } from '@/components/theme-switcher';
import {
  Sidebar,
  SidebarContent,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from '@/components/ui/sidebar';

interface MainLayoutProps {
  children: React.ReactNode;
}

// Limited sidebar for non-authenticated users
function LimitedSidebar({ locale, side }: { locale: string; side: 'left' | 'right' }) {
  const { t } = useTranslation();
  
  return (
    <Sidebar collapsible="offcanvas" side={side}>
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
        <LocaleSwitcher currentLocale={locale as any} />
        <ThemeSwitcher />
      </SidebarHeader>
      <SidebarContent>
        {/* Empty content for non-authenticated users */}
      </SidebarContent>
    </Sidebar>
  );
}

export function MainLayout({ children }: MainLayoutProps) {
  const { user, loading, signOut } = useAuth();
  const { t, locale } = useTranslation();
  const pathname = usePathname();
  const router = useRouter();

  const isLoginPage = pathname.includes('/login');

  // Handle redirects for authenticated users on login page
  useEffect(() => {
    if (loading) return;

    // If authenticated and on login page, redirect to dashboard
    if (user && isLoginPage) {
      const [, locale] = pathname.split('/');
      router.replace(`/${locale || 'ar'}/dashboard`);
    }
  }, [user, loading, pathname, isLoginPage, router]);

  // Dynamic sidebar position based on locale
  const sidebarSide = locale === 'ar' ? 'right' : 'left';

  // If we're on the login page, render with limited sidebar
  if (isLoginPage) {
    // Show loading for login page during auth
    if (loading) {
      return (
        <SidebarProvider>
          <div className={`font-sans flex h-screen w-full ${locale === 'ar' ? 'rtl' : 'ltr'}`}>
            <LimitedSidebar locale={locale} side={sidebarSide} />
            <SidebarInset className="flex-1 min-w-0">
              <main className="h-full w-full overflow-auto flex items-center justify-center">
                <span>{t('auth.loading')}</span>
              </main>
            </SidebarInset>
          </div>
        </SidebarProvider>
      );
    }
    return (
      <SidebarProvider>
        <div className={`font-sans flex h-screen w-full ${locale === 'ar' ? 'rtl' : 'ltr'}`}>
          <LimitedSidebar locale={locale} side={sidebarSide} />
          <SidebarInset className="flex-1 min-w-0">
            <main className="h-full w-full overflow-auto">
              {children}
            </main>
          </SidebarInset>
        </div>
      </SidebarProvider>
    );
  }

  // For non-authenticated users: show limited sidebar + login form in content
  if (!user && !loading) {
    return (
      <SidebarProvider>
        <div className={`font-sans flex h-screen w-full ${locale === 'ar' ? 'rtl' : 'ltr'}`}>
          {/* Limited sidebar for non-authenticated users */}
          <LimitedSidebar locale={locale} side={sidebarSide} />
          
          {/* Main content area with login form */}
          <SidebarInset className="flex-1 min-w-0">
            <main className="h-full w-full overflow-auto flex items-center justify-center p-8">
              <div className="w-full max-w-md">
                <LoginForm 
                  dict={{
                    login: {
                      companyName: t('appSidebar.appName') || 'Ta\'aafi Platform',
                      welcome: t('login.welcome') || 'Welcome to Ta\'aafi Platform',
                      email: t('login.email') || 'Email',
                      emailPlaceholder: t('login.emailPlaceholder') || 'm@example.com',
                      password: t('login.password') || 'Password',
                      passwordPlaceholder: t('login.passwordPlaceholder') || '********',
                      loginButton: t('login.loginButton') || 'Login',
                      or: t('login.or') || 'Or',
                      continueWithApple: t('login.continueWithApple') || 'Continue with Apple',
                      continueWithGoogle: t('login.continueWithGoogle') || 'Continue with Google',
                      agreement: t('login.agreement') || 'By clicking continue, you agree to our',
                      termsOfService: t('login.termsOfService') || 'Terms of Service',
                      and: t('login.and') || 'and',
                      privacyPolicy: t('login.privacyPolicy') || 'Privacy Policy',
                    }
                  }}
                />
              </div>
            </main>
          </SidebarInset>
        </div>
      </SidebarProvider>
    );
  }

  // If user is unauthorised but still passed check (non-admin), show denied WITH sidebar
  if (!loading && user && user.role !== 'admin') {
    return (
      <SidebarProvider>
        <div className={`font-sans flex h-screen w-full ${locale === 'ar' ? 'rtl' : 'ltr'}`}>
          <AppSidebar lang={locale} side={sidebarSide} />
          <SidebarInset className="flex-1 min-w-0">
            <main className="h-full w-full overflow-auto flex items-center justify-center">
              <div className="flex flex-col gap-4 text-center">
                <p className="text-lg font-semibold text-destructive px-4">
                  {t('auth.insufficientPermissions')}
                </p>
                <Button
                  variant="outline"
                  onClick={async () => {
                    await signOut();
                    const [, locale] = pathname.split('/');
                    router.replace(`/${locale || 'ar'}/login`);
                  }}
                >
                  {t('auth.logOut')}
                </Button>
              </div>
            </main>
          </SidebarInset>
        </div>
      </SidebarProvider>
    );
  }

  // Normal authenticated layout - ALWAYS show sidebar, show loading only in content area
  return (
    <SidebarProvider>
      <div className={`font-sans flex h-screen w-full ${locale === 'ar' ? 'rtl' : 'ltr'}`}>
        {/* Sidebar is ALWAYS visible */}
        <AppSidebar 
          lang={locale}
          side={sidebarSide}
        />
        
        {/* Main content area */}
        <SidebarInset className="flex-1 min-w-0">
          <main className="h-full w-full overflow-auto">
            {loading ? (
              // Show loading skeleton in content area only, sidebar stays visible
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
              // Normal content
              children
            )}
          </main>
        </SidebarInset>
      </div>
    </SidebarProvider>
  );
} 