'use client';

import React, { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/auth/AuthProvider';
import { useTranslation } from '@/contexts/TranslationContext';
import { Button } from '@/components/ui/button';

interface AuthGuardProps {
  children: React.ReactNode;
}

export default function AuthGuard({ children }: AuthGuardProps) {
  const { user, loading, signOut } = useAuth();
  const { t } = useTranslation();
  const pathname = usePathname();
  const router = useRouter();
  
  // Track if we've completed initial authentication check
  const [initialAuthComplete, setInitialAuthComplete] = useState(false);

  const isLoginPage = pathname?.includes('/login');

  useEffect(() => {
    if (loading) return;

    // Mark initial auth as complete once we get the first non-loading state
    if (!initialAuthComplete) {
      setInitialAuthComplete(true);
    }

    // If unauthenticated trying to access protected route
    if (!user && !isLoginPage) {
      // Extract locale from path, default to 'ar'
      const [, locale] = pathname.split('/');
      router.replace(`/${locale || 'ar'}/login`);
    }

    // If authenticated and on login page, redirect to dashboard
    if (user && isLoginPage) {
      const [, locale] = pathname.split('/');
      router.replace(`/${locale || 'ar'}/dashboard`);
    }
  }, [user, loading, pathname, isLoginPage, router, initialAuthComplete]);

  // Only show loading screen during initial app load (before any auth state is determined)
  if (!initialAuthComplete && loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <span>{t('auth.loading')}</span>
      </div>
    );
  }

  // If user is unauthorised but still passed check (non-admin), show denied
  if (!isLoginPage && (!user || user.role !== 'admin')) {
    return (
      <div className="flex h-screen items-center justify-center flex-col gap-4">
        <p className="text-lg font-semibold text-destructive text-center px-4">
          {t('auth.insufficientPermissions')}
        </p>
        {user && (
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
        )}
      </div>
    );
  }

  return <>{children}</>;
} 