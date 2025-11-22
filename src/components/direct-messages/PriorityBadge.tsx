'use client';

import { Badge } from '@/components/ui/badge';
import { useTranslation } from '@/contexts/TranslationContext';
import { Priority } from '@/types/directMessages';
import { AlertCircle, AlertTriangle, Info } from 'lucide-react';

interface PriorityBadgeProps {
  priority: Priority;
}

export function PriorityBadge({ priority }: PriorityBadgeProps) {
  const { t } = useTranslation();
  
  const getIcon = () => {
    switch (priority) {
      case 'critical':
      case 'high':
        return <AlertCircle className="h-3 w-3 mr-1" />;
      case 'medium':
        return <AlertTriangle className="h-3 w-3 mr-1" />;
      case 'low':
        return <Info className="h-3 w-3 mr-1" />;
      default:
        return null;
    }
  };
  
  const getColorClass = () => {
    switch (priority) {
      case 'critical':
        return 'bg-red-600/10 text-red-700 dark:text-red-400 hover:bg-red-600/20 border-red-600/20';
      case 'high':
        return 'bg-orange-500/10 text-orange-700 dark:text-orange-400 hover:bg-orange-500/20 border-orange-500/20';
      case 'medium':
        return 'bg-yellow-500/10 text-yellow-700 dark:text-yellow-400 hover:bg-yellow-500/20 border-yellow-500/20';
      case 'low':
        return 'bg-blue-500/10 text-blue-700 dark:text-blue-400 hover:bg-blue-500/20 border-blue-500/20';
      default:
        return '';
    }
  };
  
  return (
    <Badge variant="outline" className={`flex items-center ${getColorClass()}`}>
      {getIcon()}
      {t(`modules.community.directMessages.priorities.${priority}`)}
    </Badge>
  );
}

