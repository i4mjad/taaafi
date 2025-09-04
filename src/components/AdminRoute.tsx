'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useGroupAdmin } from '@/hooks/useGroupAdmin';
import { useTranslation } from '@/contexts/TranslationContext';
import { Card, CardContent } from '@/components/ui/card';
import { Shield, AlertTriangle } from 'lucide-react';

interface AdminRouteProps {
  groupId: string;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export const AdminRoute: React.FC<AdminRouteProps> = ({ 
  groupId, 
  children, 
  fallback 
}) => {
  const { isAdmin, loading, error } = useGroupAdmin(groupId);
  const { t } = useTranslation();
  const router = useRouter();

  useEffect(() => {
    // If not admin and not loading, redirect to group page
    if (!loading && !isAdmin && !error) {
      router.push(`/community/groups`);
    }
  }, [isAdmin, loading, error, router]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen p-4">
        <Card className="w-full max-w-md">
          <CardContent className="flex flex-col items-center justify-center p-8">
            <Shield className="h-12 w-12 text-muted-foreground animate-pulse mb-4" />
            <p className="text-center text-muted-foreground">
              {t('admin.checkingPermissions')}
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen p-4">
        <Card className="w-full max-w-md">
          <CardContent className="flex flex-col items-center justify-center p-8">
            <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
            <p className="text-center text-destructive font-medium mb-2">
              {t('admin.permissionError')}
            </p>
            <p className="text-center text-muted-foreground text-sm">
              {t('admin.tryAgainLater')}
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!isAdmin) {
    if (fallback) {
      return <>{fallback}</>;
    }

    return (
      <div className="flex items-center justify-center min-h-screen p-4">
        <Card className="w-full max-w-md">
          <CardContent className="flex flex-col items-center justify-center p-8">
            <Shield className="h-12 w-12 text-muted-foreground mb-4" />
            <p className="text-center font-medium mb-2">
              {t('admin.accessDenied')}
            </p>
            <p className="text-center text-muted-foreground text-sm">
              {t('admin.adminOnlyAccess')}
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return <>{children}</>;
};
