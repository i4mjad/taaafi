'use client';

import { Progress } from '@/components/ui/progress';

interface ConfidenceIndicatorProps {
  confidence: number; // 0.0 - 1.0
  showPercentage?: boolean;
}

export function ConfidenceIndicator({ confidence, showPercentage = true }: ConfidenceIndicatorProps) {
  const percentage = Math.round(confidence * 100);
  
  const getColorClass = () => {
    if (confidence >= 0.8) return 'bg-red-500';
    if (confidence >= 0.5) return 'bg-yellow-500';
    return 'bg-green-500';
  };
  
  const getTextColorClass = () => {
    if (confidence >= 0.8) return 'text-red-700 dark:text-red-400';
    if (confidence >= 0.5) return 'text-yellow-700 dark:text-yellow-400';
    return 'text-green-700 dark:text-green-400';
  };
  
  return (
    <div className="flex items-center gap-2 min-w-[100px]">
      <Progress 
        value={percentage} 
        className="h-2 flex-1"
        indicatorClassName={getColorClass()}
      />
      {showPercentage && (
        <span className={`text-xs font-medium min-w-[35px] text-right ${getTextColorClass()}`}>
          {percentage}%
        </span>
      )}
    </div>
  );
}

