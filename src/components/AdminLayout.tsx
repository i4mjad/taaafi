'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { useGroup } from '@/hooks/useGroupAdmin';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet';
import { 
  ArrowLeft, 
  Menu, 
  Users, 
  MessageSquare, 
  Trophy, 
  Settings, 
  LayoutDashboard,
  UserPlus,
  Shield
} from 'lucide-react';
import { cn } from '@/lib/utils';

interface AdminLayoutProps {
  groupId: string;
  children: React.ReactNode;
  currentPath?: string;
}

interface NavItem {
  title: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: number;
  condition?: boolean;
}

export const AdminLayout: React.FC<AdminLayoutProps> = ({ 
  groupId, 
  children, 
  currentPath 
}) => {
  const { t } = useTranslation();
  const router = useRouter();
  const { group, loading: groupLoading } = useGroup(groupId);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const navItems: NavItem[] = [
    {
      title: t('admin.navigation.overview'),
      href: `/community/groups/${groupId}/admin`,
      icon: LayoutDashboard,
    },
    {
      title: t('admin.navigation.members'),
      href: `/community/groups/${groupId}/admin/members`,
      icon: Users,
      // badge: pendingApprovals, // TODO: Add pending approvals count
    },
    {
      title: t('admin.navigation.content'),
      href: `/community/groups/${groupId}/admin/content`,
      icon: MessageSquare,
      // badge: reportedMessages, // TODO: Add reported messages count
    },
    {
      title: t('admin.navigation.reports'),
      href: `/community/groups/${groupId}/admin/reports`,
      icon: Shield,
      // badge: openReports, // TODO: Add open reports count
    },
    {
      title: t('admin.navigation.challenges'),
      href: `/community/groups/${groupId}/admin/challenges`,
      icon: Trophy,
    },
    {
      title: t('admin.navigation.invitations'),
      href: `/community/groups/${groupId}/admin/invitations`,
      icon: UserPlus,
      condition: group?.joinMethod === 'admin_only',
    },
    {
      title: t('admin.navigation.settings'),
      href: `/community/groups/${groupId}/admin/settings`,
      icon: Settings,
    },
  ];

  const filteredNavItems = navItems.filter(item => item.condition !== false);

  const NavContent = () => (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="p-4 border-b">
        <div className="flex items-center gap-3 mb-3">
          <Shield className="h-6 w-6 text-primary" />
          <div>
            <h2 className="font-semibold text-sm">{t('admin.title')}</h2>
            <p className="text-xs text-muted-foreground">{group?.name || groupId}</p>
          </div>
        </div>
        {group && (
          <div className="flex gap-2">
            <Badge variant={group.isActive ? 'default' : 'secondary'} className="text-xs">
              {group.isActive ? t('common.active') : t('common.inactive')}
            </Badge>
            <Badge variant="outline" className="text-xs">
              {group.memberCount || 0}/{group.capacity || 0}
            </Badge>
          </div>
        )}
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-2">
        {filteredNavItems.map((item) => {
          const isActive = currentPath === item.href;
          const Icon = item.icon;
          
          return (
            <Button
              key={item.href}
              variant={isActive ? 'default' : 'ghost'}
              className={cn(
                'w-full justify-start gap-3 h-auto py-3 px-3',
                isActive && 'bg-primary text-primary-foreground'
              )}
              onClick={() => {
                router.push(item.href);
                setSidebarOpen(false);
              }}
            >
              <Icon className="h-4 w-4 flex-shrink-0" />
              <span className="flex-1 text-left text-sm">{item.title}</span>
              {item.badge && item.badge > 0 && (
                <Badge variant="secondary" className="text-xs px-1.5 py-0.5">
                  {item.badge}
                </Badge>
              )}
            </Button>
          );
        })}
      </nav>

      {/* Back to Groups */}
      <div className="p-4 border-t">
        <Button
          variant="outline"
          className="w-full justify-start gap-3"
          onClick={() => router.push('/community/groups')}
        >
          <ArrowLeft className="h-4 w-4" />
          {t('admin.backToGroups')}
        </Button>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-background">
      {/* Mobile Header */}
      <div className="lg:hidden">
        <header className="sticky top-0 z-40 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="flex h-14 items-center justify-between px-4">
            <div className="flex items-center gap-3">
              <Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}>
                <SheetTrigger asChild>
                  <Button variant="ghost" size="sm" className="p-2">
                    <Menu className="h-5 w-5" />
                  </Button>
                </SheetTrigger>
                <SheetContent side="left" className="w-80 p-0">
                  <NavContent />
                </SheetContent>
              </Sheet>
              
              <div>
                <h1 className="font-semibold text-sm">{t('admin.title')}</h1>
                <p className="text-xs text-muted-foreground truncate max-w-40">
                  {group?.name || groupId}
                </p>
              </div>
            </div>

            <Button
              variant="ghost"
              size="sm"
              onClick={() => router.push('/community/groups')}
            >
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </div>
        </header>
      </div>

      <div className="flex">
        {/* Desktop Sidebar */}
        <aside className="hidden lg:block w-80 border-r bg-muted/10">
          <div className="sticky top-0 h-screen">
            <NavContent />
          </div>
        </aside>

        {/* Main Content */}
        <main className="flex-1">
          <div className="container max-w-none p-4 lg:p-6">
            {groupLoading ? (
              <div className="flex items-center justify-center py-12">
                <Card className="w-full max-w-md">
                  <CardContent className="flex flex-col items-center justify-center p-8">
                    <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent mb-4" />
                    <p className="text-center text-muted-foreground">
                      {t('admin.loadingGroup')}
                    </p>
                  </CardContent>
                </Card>
              </div>
            ) : (
              children
            )}
          </div>
        </main>
      </div>
    </div>
  );
};
