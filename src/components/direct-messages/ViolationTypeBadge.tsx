'use client';

import { Badge } from '@/components/ui/badge';
import { useTranslation } from '@/contexts/TranslationContext';
import { ViolationType } from '@/types/directMessages';
import { AlertOctagon, Share2, Heart, Users, MessageSquareWarning } from 'lucide-react';

interface ViolationTypeBadgeProps {
  violationType: ViolationType;
  showIcon?: boolean;
}

export function ViolationTypeBadge({ violationType, showIcon = true }: ViolationTypeBadgeProps) {
  const { t } = useTranslation();
  
  const getIcon = () => {
    if (!showIcon) return null;
    
    switch (violationType) {
      case 'social_media_sharing':
        return <Share2 className="h-3 w-3 mr-1" />;
      case 'sexual_content':
      case 'cuckoldry_content':
      case 'homosexuality_content':
        return <Heart className="h-3 w-3 mr-1" />;
      case 'harassment':
        return <AlertOctagon className="h-3 w-3 mr-1" />;
      case 'spam':
        return <MessageSquareWarning className="h-3 w-3 mr-1" />;
      default:
        return <Users className="h-3 w-3 mr-1" />;
    }
  };
  
  const getColorClass = () => {
    switch (violationType) {
      case 'sexual_content':
      case 'cuckoldry_content':
      case 'homosexuality_content':
        return 'bg-purple-500/10 text-purple-700 dark:text-purple-400 hover:bg-purple-500/20 border-purple-500/20';
      case 'social_media_sharing':
        return 'bg-blue-500/10 text-blue-700 dark:text-blue-400 hover:bg-blue-500/20 border-blue-500/20';
      case 'harassment':
        return 'bg-red-500/10 text-red-700 dark:text-red-400 hover:bg-red-500/20 border-red-500/20';
      case 'spam':
        return 'bg-orange-500/10 text-orange-700 dark:text-orange-400 hover:bg-orange-500/20 border-orange-500/20';
      case 'none':
        return 'bg-gray-500/10 text-gray-700 dark:text-gray-400 hover:bg-gray-500/20 border-gray-500/20';
      default:
        return '';
    }
  };
  
  if (violationType === 'none') {
    return null;
  }
  
  return (
    <Badge variant="outline" className={`flex items-center ${getColorClass()}`}>
      {getIcon()}
      {t(`modules.community.directMessages.violationTypes.${violationType}`)}
    </Badge>
  );
}

