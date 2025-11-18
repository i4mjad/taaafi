'use client';

import { Badge } from '@/components/ui/badge';
import { useTranslation } from '@/contexts/TranslationContext';
import { Severity } from '@/types/directMessages';

interface SeverityBadgeProps {
  severity: Severity;
}

export function SeverityBadge({ severity }: SeverityBadgeProps) {
  const { t } = useTranslation();
  
  const getColorClass = () => {
    switch (severity) {
      case 'high':
        return 'bg-red-500/10 text-red-700 dark:text-red-400 hover:bg-red-500/20';
      case 'medium':
        return 'bg-orange-500/10 text-orange-700 dark:text-orange-400 hover:bg-orange-500/20';
      case 'low':
        return 'bg-yellow-500/10 text-yellow-700 dark:text-yellow-400 hover:bg-yellow-500/20';
      default:
        return '';
    }
  };
  
  return (
    <Badge variant="outline" className={getColorClass()}>
      {t(`modules.community.directMessages.severities.${severity}`)}
    </Badge>
  );
}

