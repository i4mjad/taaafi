'use client';

import { Badge } from '@/components/ui/badge';
import { useTranslation } from '@/contexts/TranslationContext';

interface StatusBadgeProps {
  status: 'pending' | 'manual_review' | 'approved' | 'blocked';
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const { t } = useTranslation();

  const variants: Record<typeof status, { variant: any; label: string }> = {
    pending: {
      variant: 'secondary',
      label: t('modules.community.groupUpdates.statuses.pending'),
    },
    manual_review: {
      variant: 'outline',
      label: t('modules.community.groupUpdates.statuses.manual_review'),
    },
    approved: {
      variant: 'default',
      label: t('modules.community.groupUpdates.statuses.approved'),
    },
    blocked: {
      variant: 'destructive',
      label: t('modules.community.groupUpdates.statuses.blocked'),
    },
  };

  const config = variants[status] || variants.pending;

  const colorClasses = {
    pending: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
    manual_review: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
    approved: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
    blocked: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
  };

  const statusColor = colorClasses[status] || colorClasses.pending;

  return (
    <Badge className={`${statusColor} ${className || ''}`}>
      {config.label}
    </Badge>
  );
}

