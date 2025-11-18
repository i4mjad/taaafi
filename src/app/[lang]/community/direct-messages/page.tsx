'use client';

import { useTranslation } from "@/contexts/TranslationContext";
import { SiteHeader } from '@/components/site-header';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DashboardOverview } from '@/components/direct-messages/DashboardOverview';
import { ModerationQueue } from '@/components/direct-messages/ModerationQueue';
import { AllConversations } from '@/components/direct-messages/AllConversations';
import { AllMessages } from '@/components/direct-messages/AllMessages';
import { UserReports } from '@/components/direct-messages/UserReports';

export default function DirectMessagesPage() {
  const { t } = useTranslation();

  const headerDictionary = {
    documents: t('appSidebar.directMessages') || 'Direct Messages',
  };

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="p-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold tracking-tight">
            {t('modules.community.directMessages.title')}
          </h1>
          <p className="text-muted-foreground">
            {t('modules.community.directMessages.description')}
          </p>
        </div>
        
        <Tabs defaultValue="dashboard" className="w-full">
          <TabsList className="grid w-full grid-cols-5 mb-6">
            <TabsTrigger value="dashboard">
              {t('modules.community.directMessages.tabs.dashboard')}
            </TabsTrigger>
            <TabsTrigger value="queue">
              {t('modules.community.directMessages.tabs.moderationQueue')}
            </TabsTrigger>
            <TabsTrigger value="conversations">
              {t('modules.community.directMessages.tabs.allConversations')}
            </TabsTrigger>
            <TabsTrigger value="messages">
              {t('modules.community.directMessages.tabs.allMessages')}
            </TabsTrigger>
            <TabsTrigger value="reports">
              {t('modules.community.directMessages.tabs.userReports')}
            </TabsTrigger>
          </TabsList>
          
          <TabsContent value="dashboard" className="space-y-4">
            <DashboardOverview />
          </TabsContent>
          
          <TabsContent value="queue" className="space-y-4">
            <ModerationQueue />
          </TabsContent>
          
          <TabsContent value="conversations" className="space-y-4">
            <AllConversations />
          </TabsContent>
          
          <TabsContent value="messages" className="space-y-4">
            <AllMessages />
          </TabsContent>
          
          <TabsContent value="reports" className="space-y-4">
            <UserReports />
          </TabsContent>
        </Tabs>
      </div>
    </>
  );
}

