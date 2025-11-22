'use client';

import { Badge } from '@/components/ui/badge';
import { useTranslation } from '@/contexts/TranslationContext';
import { AlertTriangle, AlertCircle, Info } from 'lucide-react';

interface SeverityBadgeProps {
  severity: 'low' | 'medium' | 'high';
  className?: string;
}

export function SeverityBadge({ severity, className }: SeverityBadgeProps) {
  const { t } = useTranslation();

  const config = {
    low: {
      icon: Info,
      label: t('modules.community.groupUpdates.severities.low'),
      className: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
    },
    medium: {
      icon: AlertCircle,
      label: t('modules.community.groupUpdates.severities.medium'),
      className: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300',
    },
    high: {
      icon: AlertTriangle,
      label: t('modules.community.groupUpdates.severities.high'),
      className: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
    },
  };

  const severityConfig = config[severity] || config.low; // Fallback to low if severity is invalid
  const Icon = severityConfig.icon;

  return (
    <Badge className={`${severityConfig.className} ${className || ''} flex items-center gap-1`}>
      <Icon className="h-3 w-3" />
      {severityConfig.label}
    </Badge>
  );
}

