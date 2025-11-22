'use client';

import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { ExternalLink } from 'lucide-react';
import { useTranslation } from '@/contexts/TranslationContext';

interface TopReferrer {
  userId: string;
  displayName: string;
  email: string;
  photoURL?: string | null;
  totalReferred: number;
  totalVerified: number;
  totalRewards: string;
}

interface TopReferrersTableProps {
  referrers: TopReferrer[];
  lang: string;
}

export function TopReferrersTable({ referrers, lang }: TopReferrersTableProps) {
  const { t } = useTranslation();

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t('modules.userManagement.referralDashboard.topReferrers.title')}</CardTitle>
        <CardDescription>
          {t('modules.userManagement.referralDashboard.topReferrers.description')}
        </CardDescription>
      </CardHeader>
      <CardContent className="px-3 sm:px-6">
        {/* Mobile: Card Layout */}
        <div className="block md:hidden space-y-3">
          {referrers.length === 0 ? (
            <p className="text-center text-muted-foreground py-8 text-sm">
              {t('modules.userManagement.referralDashboard.topReferrers.noReferrers')}
            </p>
          ) : (
            referrers.map((referrer) => (
              <div key={referrer.userId} className="border rounded-lg p-3 space-y-2">
                <div className="flex items-center gap-3">
                  <Avatar className="h-10 w-10">
                    <AvatarImage src={referrer.photoURL || undefined} alt={referrer.displayName} />
                    <AvatarFallback>
                      {referrer.displayName.substring(0, 2).toUpperCase()}
                    </AvatarFallback>
                  </Avatar>
                  <div className="flex-1 min-w-0">
                    <div className="font-medium truncate">{referrer.displayName}</div>
                    <div className="text-xs text-muted-foreground truncate">{referrer.email}</div>
                  </div>
                  <Link href={`/${lang}/user-management/users/${referrer.userId}`}>
                    <Button variant="ghost" size="sm">
                      <ExternalLink className="h-4 w-4" />
                    </Button>
                  </Link>
                </div>
                <div className="grid grid-cols-3 gap-2 text-center pt-2 border-t">
                  <div>
                    <div className="text-xs text-muted-foreground">{t('modules.userManagement.referralDashboard.topReferrers.referred')}</div>
                    <div className="text-lg font-semibold">{referrer.totalReferred}</div>
                  </div>
                  <div>
                    <div className="text-xs text-muted-foreground">{t('modules.userManagement.referralDashboard.topReferrers.verified')}</div>
                    <div className="text-lg font-semibold text-green-600">{referrer.totalVerified}</div>
                  </div>
                  <div>
                    <div className="text-xs text-muted-foreground">{t('modules.userManagement.referralDashboard.topReferrers.rewards')}</div>
                    <div className="text-sm font-medium">{referrer.totalRewards}</div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Desktop: Table Layout */}
        <div className="hidden md:block">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>{t('modules.userManagement.referralDashboard.topReferrers.user')}</TableHead>
                <TableHead className="text-center">{t('modules.userManagement.referralDashboard.topReferrers.referred')}</TableHead>
                <TableHead className="text-center">{t('modules.userManagement.referralDashboard.topReferrers.verified')}</TableHead>
                <TableHead>{t('modules.userManagement.referralDashboard.topReferrers.rewards')}</TableHead>
                <TableHead className="text-right">{t('modules.userManagement.referralDashboard.topReferrers.actions')}</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {referrers.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground py-8">
                    {t('modules.userManagement.referralDashboard.topReferrers.noReferrers')}
                  </TableCell>
                </TableRow>
              ) : (
                referrers.map((referrer) => (
                  <TableRow key={referrer.userId}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <Avatar className="h-8 w-8">
                          <AvatarImage src={referrer.photoURL || undefined} alt={referrer.displayName} />
                          <AvatarFallback>
                            {referrer.displayName.substring(0, 2).toUpperCase()}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <div className="font-medium">{referrer.displayName}</div>
                          <div className="text-sm text-muted-foreground">{referrer.email}</div>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-center font-medium">{referrer.totalReferred}</TableCell>
                    <TableCell className="text-center font-medium text-green-600">{referrer.totalVerified}</TableCell>
                    <TableCell>{referrer.totalRewards}</TableCell>
                    <TableCell className="text-right">
                      <Link href={`/${lang}/user-management/users/${referrer.userId}`}>
                        <Button variant="ghost" size="sm">
                          <ExternalLink className="h-4 w-4" />
                        </Button>
                      </Link>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}

