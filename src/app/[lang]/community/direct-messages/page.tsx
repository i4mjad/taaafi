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
    <div className="min-h-screen flex flex-col">
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">
              {t('modules.community.directMessages.title')}
            </h1>
            <p className="text-muted-foreground">
              {t('modules.community.directMessages.description')}
            </p>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto">
          <div className="p-6 space-y-6 max-w-none">
            {/* Stats Cards */}
            <DashboardOverview />
            
            <Tabs defaultValue="messages" className="w-full">
              <TabsList className="grid w-full grid-cols-4 mb-6">
                <TabsTrigger value="messages">
                  {t('modules.community.directMessages.tabs.allMessages')}
                </TabsTrigger>
                <TabsTrigger value="queue">
                  {t('modules.community.directMessages.tabs.moderationQueue')}
                </TabsTrigger>
                <TabsTrigger value="conversations">
                  {t('modules.community.directMessages.tabs.allConversations')}
                </TabsTrigger>
                <TabsTrigger value="reports">
                  {t('modules.community.directMessages.tabs.userReports')}
                </TabsTrigger>
              </TabsList>
              
              <TabsContent value="messages" className="space-y-4">
                <AllMessages />
              </TabsContent>
              
              <TabsContent value="queue" className="space-y-4">
                <ModerationQueue />
              </TabsContent>
              
              <TabsContent value="conversations" className="space-y-4">
                <AllConversations />
              </TabsContent>
              
              <TabsContent value="reports" className="space-y-4">
                <UserReports />
              </TabsContent>
            </Tabs>
          </div>
        </div>
      </div>
    </div>
  );
}

