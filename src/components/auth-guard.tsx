'use client';

import React, { useEffect } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/auth/AuthProvider';
import { Button } from '@/components/ui/button';

interface AuthGuardProps {
  children: React.ReactNode;
}

export default function AuthGuard({ children }: AuthGuardProps) {
  const { user, loading, signOut } = useAuth();
  const pathname = usePathname();
  const router = useRouter();

  const isLoginPage = pathname?.includes('/login');

  useEffect(() => {
    if (loading) return;

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
  }, [user, loading, pathname, isLoginPage, router]);

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <span>Loading...</span>
      </div>
    );
  }

  // If user is unauthorised but still passed check (non-admin), show denied
  if (!isLoginPage && (!user || user.role !== 'admin')) {
    return (
      <div className="flex h-screen items-center justify-center flex-col gap-4">
        <p className="text-lg font-semibold text-destructive text-center px-4">
          Access denied: you do not have sufficient permissions.
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
            Log out
          </Button>
        )}
      </div>
    );
  }

  return <>{children}</>;
} 