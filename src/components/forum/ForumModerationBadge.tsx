'use client';

import { Badge } from '@/components/ui/badge';
import { useTranslation } from '@/contexts/TranslationContext';
import { AlertCircle, CheckCircle, XCircle } from 'lucide-react';

type ModerationStatus = 'approved' | 'manual_review' | 'blocked';

interface ForumModerationBadgeProps {
  status?: ModerationStatus;
  showIcon?: boolean;
  className?: string;
}

export function ForumModerationBadge({ status, showIcon = true, className = '' }: ForumModerationBadgeProps) {
  const { t } = useTranslation();
  
  if (!status) {
    return null;
  }
  
  const getIcon = () => {
    if (!showIcon) return null;
    
    switch (status) {
      case 'approved':
        return <CheckCircle className="h-3 w-3 mr-1" />;
      case 'blocked':
        return <XCircle className="h-3 w-3 mr-1" />;
      case 'manual_review':
        return <AlertCircle className="h-3 w-3 mr-1" />;
      default:
        return null;
    }
  };
  
  const getColorClass = () => {
    switch (status) {
      case 'approved':
        return 'bg-green-500/10 text-green-700 dark:text-green-400 hover:bg-green-500/20 border-green-500/20';
      case 'blocked':
        return 'bg-red-500/10 text-red-700 dark:text-red-400 hover:bg-red-500/20 border-red-500/20';
      case 'manual_review':
        return 'bg-yellow-500/10 text-yellow-700 dark:text-yellow-400 hover:bg-yellow-500/20 border-yellow-500/20';
      default:
        return '';
    }
  };
  
  return (
    <Badge variant="outline" className={`flex items-center ${getColorClass()} ${className}`}>
      {getIcon()}
      {t(`modules.community.forum.moderation.status.${status}`)}
    </Badge>
  );
}

