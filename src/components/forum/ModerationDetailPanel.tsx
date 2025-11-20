'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { useTranslation } from '@/contexts/TranslationContext';
import { ForumPostModeration, CommentModeration } from '@/types/community';
import { ConfidenceIndicator } from '@/components/direct-messages/ConfidenceIndicator';
import { AlertCircle, Brain, Shield, Clock, FileWarning } from 'lucide-react';
import { format } from 'date-fns';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';

interface ModerationDetailPanelProps {
  moderation?: ForumPostModeration | CommentModeration;
  isHidden?: boolean;
  contentType: 'post' | 'comment';
}

export function ModerationDetailPanel({ moderation, isHidden, contentType }: ModerationDetailPanelProps) {
  const { t } = useTranslation();
  
  if (!moderation) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <Shield className="h-4 w-4" />
            {t('modules.community.forum.moderation.noData')}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            {t('modules.community.forum.moderation.noDataDescription')}
          </p>
        </CardContent>
      </Card>
    );
  }
  
  const confidence = moderation.finalDecision?.confidence || moderation.ai?.confidence || 0;
  const shouldBeHidden = confidence >= 0.85;
  
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm flex items-center gap-2">
          <Shield className="h-4 w-4" />
          {t('modules.community.forum.moderation.details')}
        </CardTitle>
        <CardDescription>
          {t('modules.community.forum.moderation.detailsDescription')}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Status Overview */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">{t('modules.community.forum.moderation.status.label')}</span>
            <Badge variant={moderation.status === 'approved' ? 'default' : moderation.status === 'blocked' ? 'destructive' : 'secondary'}>
              {t(`modules.community.forum.moderation.status.${moderation.status}`)}
            </Badge>
          </div>
          
          {moderation.reason && (
            <div className="text-sm text-muted-foreground">
              <span className="font-medium">{t('modules.community.forum.moderation.reason')}: </span>
              {moderation.reason}
            </div>
          )}
          
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">{t('modules.community.forum.moderation.visibility')}</span>
            <Badge variant={isHidden ? 'destructive' : 'outline'}>
              {isHidden ? t('modules.community.forum.moderation.hidden') : t('modules.community.forum.moderation.visible')}
            </Badge>
          </div>
          
          {shouldBeHidden && isHidden && (
            <div className="flex items-center gap-2 text-xs text-yellow-600 dark:text-yellow-400 bg-yellow-500/10 p-2 rounded">
              <AlertCircle className="h-4 w-4" />
              {t('modules.community.forum.moderation.autoHiddenInfo')}
            </div>
          )}
        </div>
        
        <Separator />
        
        {/* Final Decision */}
        {moderation.finalDecision && (
          <>
            <div className="space-y-2">
              <h4 className="text-sm font-semibold flex items-center gap-2">
                <Brain className="h-4 w-4" />
                {t('modules.community.forum.moderation.finalDecision')}
              </h4>
              
              <div className="space-y-2 pl-6">
                <div className="flex items-center justify-between">
                  <span className="text-sm">{t('modules.community.forum.moderation.action')}</span>
                  <Badge variant="outline">{moderation.finalDecision.action}</Badge>
                </div>
                
                <div className="flex items-center justify-between">
                  <span className="text-sm">{t('modules.community.forum.moderation.confidence')}</span>
                  <ConfidenceIndicator confidence={moderation.finalDecision.confidence} />
                </div>
                
                {moderation.finalDecision.violationType && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm">{t('modules.community.forum.moderation.violationType')}</span>
                    <Badge variant="destructive" className="text-xs">
                      {moderation.finalDecision.violationType}
                    </Badge>
                  </div>
                )}
                
                {moderation.finalDecision.reason && (
                  <div className="text-sm text-muted-foreground">
                    {moderation.finalDecision.reason}
                  </div>
                )}
              </div>
            </div>
            
            <Separator />
          </>
        )}
        
        {/* AI Analysis */}
        {moderation.ai && (
          <Accordion type="single" collapsible className="w-full">
            <AccordionItem value="ai-analysis" className="border-none">
              <AccordionTrigger className="text-sm font-semibold hover:no-underline py-2">
                <div className="flex items-center gap-2">
                  <Brain className="h-4 w-4" />
                  {t('modules.community.forum.moderation.aiAnalysis')}
                </div>
              </AccordionTrigger>
              <AccordionContent className="space-y-2 pl-6">
                {moderation.ai.violationType && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm">{t('modules.community.forum.moderation.violationType')}</span>
                    <Badge variant="outline" className="text-xs">
                      {moderation.ai.violationType}
                    </Badge>
                  </div>
                )}
                
                {moderation.ai.severity && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm">{t('modules.community.forum.moderation.severity')}</span>
                    <Badge 
                      variant={moderation.ai.severity === 'high' ? 'destructive' : 'secondary'}
                      className="text-xs"
                    >
                      {t(`modules.community.forum.moderation.severityLevel.${moderation.ai.severity}`)}
                    </Badge>
                  </div>
                )}
                
                {moderation.ai.confidence !== undefined && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm">{t('modules.community.forum.moderation.confidence')}</span>
                    <ConfidenceIndicator confidence={moderation.ai.confidence} />
                  </div>
                )}
                
                {moderation.ai.reason && (
                  <div className="text-sm text-muted-foreground">
                    <span className="font-medium">{t('modules.community.forum.moderation.reason')}: </span>
                    {moderation.ai.reason}
                  </div>
                )}
                
                {moderation.ai.detectedContent && moderation.ai.detectedContent.length > 0 && (
                  <div className="space-y-1">
                    <span className="text-sm font-medium">{t('modules.community.forum.moderation.detectedContent')}</span>
                    <div className="flex flex-wrap gap-1">
                      {moderation.ai.detectedContent.map((content, idx) => (
                        <Badge key={idx} variant="outline" className="text-xs">
                          {content}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
                
                {moderation.ai.culturalContext && (
                  <div className="text-sm text-muted-foreground">
                    <span className="font-medium">{t('modules.community.forum.moderation.culturalContext')}: </span>
                    {moderation.ai.culturalContext}
                  </div>
                )}
              </AccordionContent>
            </AccordionItem>
          </Accordion>
        )}
        
        {/* Custom Rules */}
        {moderation.customRules && moderation.customRules.length > 0 && (
          <>
            <Separator />
            <Accordion type="single" collapsible className="w-full">
              <AccordionItem value="custom-rules" className="border-none">
                <AccordionTrigger className="text-sm font-semibold hover:no-underline py-2">
                  <div className="flex items-center gap-2">
                    <FileWarning className="h-4 w-4" />
                    {t('modules.community.forum.moderation.customRules')} ({moderation.customRules.length})
                  </div>
                </AccordionTrigger>
                <AccordionContent className="space-y-3 pl-6">
                  {moderation.customRules.map((rule, idx) => (
                    <Card key={idx} className="bg-muted/50">
                      <CardContent className="pt-4 space-y-2">
                        <div className="flex items-center justify-between">
                          <Badge variant="outline" className="text-xs">{rule.type}</Badge>
                          <Badge 
                            variant={rule.severity === 'high' ? 'destructive' : 'secondary'}
                            className="text-xs"
                          >
                            {t(`modules.community.forum.moderation.severityLevel.${rule.severity}`)}
                          </Badge>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-xs">{t('modules.community.forum.moderation.confidence')}</span>
                          <ConfidenceIndicator confidence={rule.confidence} showPercentage />
                        </div>
                        {rule.reason && (
                          <p className="text-xs text-muted-foreground">{rule.reason}</p>
                        )}
                      </CardContent>
                    </Card>
                  ))}
                </AccordionContent>
              </AccordionItem>
            </Accordion>
          </>
        )}
        
        {/* Analysis Time */}
        {moderation.analysisAt && (
          <>
            <Separator />
            <div className="flex items-center gap-2 text-xs text-muted-foreground">
              <Clock className="h-3 w-3" />
              {t('modules.community.forum.moderation.analyzedAt')}: {format(
                moderation.analysisAt instanceof Date 
                  ? moderation.analysisAt 
                  : (moderation.analysisAt as any).toDate?.() || new Date(moderation.analysisAt as any),
                'MMM dd, yyyy HH:mm:ss'
              )}
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}

