'use client';

import { Badge } from '@/components/ui/badge';
import { useTranslation } from '@/contexts/TranslationContext';
import { FileText, Trophy, Flag, HeartHandshake } from 'lucide-react';

interface UpdateTypeBadgeProps {
  type: 'general' | 'achievement' | 'milestone' | 'support';
  className?: string;
}

export function UpdateTypeBadge({ type, className }: UpdateTypeBadgeProps) {
  const { t } = useTranslation();

  const config = {
    general: {
      icon: FileText,
      label: t('modules.community.groupUpdates.updateTypes.general'),
      className: 'bg-slate-100 text-slate-800 dark:bg-slate-800 dark:text-slate-300',
    },
    achievement: {
      icon: Trophy,
      label: t('modules.community.groupUpdates.updateTypes.achievement'),
      className: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
    },
    milestone: {
      icon: Flag,
      label: t('modules.community.groupUpdates.updateTypes.milestone'),
      className: 'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300',
    },
    support: {
      icon: HeartHandshake,
      label: t('modules.community.groupUpdates.updateTypes.support'),
      className: 'bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-300',
    },
  };

  const typeConfig = config[type] || config.general; // Fallback to general if type is invalid
  const Icon = typeConfig.icon;

  return (
    <Badge variant="outline" className={`${typeConfig.className} ${className || ''} flex items-center gap-1`}>
      <Icon className="h-3 w-3" />
      {typeConfig.label}
    </Badge>
  );
}

