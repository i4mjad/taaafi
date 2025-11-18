'use client';

import { Badge } from '@/components/ui/badge';
import { useTranslation } from '@/contexts/TranslationContext';
import { ModerationStatus, QueueStatus, ReportStatus } from '@/types/directMessages';

interface StatusBadgeProps {
  status: ModerationStatus | QueueStatus | ReportStatus;
  type?: 'moderation' | 'queue' | 'report';
}

export function StatusBadge({ status, type = 'moderation' }: StatusBadgeProps) {
  const { t } = useTranslation();
  
  const getVariant = (): 'default' | 'secondary' | 'destructive' | 'outline' => {
    switch (status) {
      case 'pending':
        return 'outline';
      case 'approved':
        return 'default';
      case 'blocked':
        return 'destructive';
      case 'manual_review':
        return 'secondary';
      case 'active':
        return 'default';
      case 'resolved':
        return 'secondary';
      case 'dismissed':
        return 'outline';
      case 'reviewed':
        return 'secondary';
      default:
        return 'outline';
    }
  };
  
  const getColorClass = () => {
    switch (status) {
      case 'pending':
        return 'bg-yellow-500/10 text-yellow-700 dark:text-yellow-400 hover:bg-yellow-500/20';
      case 'approved':
        return 'bg-green-500/10 text-green-700 dark:text-green-400 hover:bg-green-500/20';
      case 'blocked':
        return 'bg-red-500/10 text-red-700 dark:text-red-400 hover:bg-red-500/20';
      case 'manual_review':
        return 'bg-blue-500/10 text-blue-700 dark:text-blue-400 hover:bg-blue-500/20';
      case 'active':
        return 'bg-green-500/10 text-green-700 dark:text-green-400 hover:bg-green-500/20';
      case 'resolved':
        return 'bg-gray-500/10 text-gray-700 dark:text-gray-400 hover:bg-gray-500/20';
      case 'dismissed':
        return 'bg-gray-500/10 text-gray-700 dark:text-gray-400 hover:bg-gray-500/20';
      case 'reviewed':
        return 'bg-blue-500/10 text-blue-700 dark:text-blue-400 hover:bg-blue-500/20';
      default:
        return '';
    }
  };
  
  return (
    <Badge variant={getVariant()} className={getColorClass()}>
      {t(`modules.community.directMessages.statuses.${status}`)}
    </Badge>
  );
}

