"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { BellIcon, SmartphoneIcon } from 'lucide-react';
import { useTranslation } from "@/contexts/TranslationContext";
import PushNotificationForm from './PushNotificationForm';
import InAppNotificationForm from './InAppNotificationForm';

export default function NotificationsPage() {
  const { t } = useTranslation();

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BellIcon className="h-5 w-5" />
          {t('modules.userManagement.notifications.title') || 'Notifications'}
        </CardTitle>
        <CardDescription>
          {t('modules.userManagement.notifications.description') || 'Send notifications to selected user groups'}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Tabs defaultValue="push" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="push" className="flex items-center gap-2">
              <SmartphoneIcon className="h-4 w-4" />
              {t('modules.userManagement.notifications.pushNotifications.title') || 'Push Notifications'}
            </TabsTrigger>
            <TabsTrigger value="inapp" className="flex items-center gap-2">
              <BellIcon className="h-4 w-4" />
              {t('modules.userManagement.notifications.inAppNotifications.title') || 'In-App Notifications'}
            </TabsTrigger>
          </TabsList>
          
          <TabsContent value="push" className="mt-6">
            <PushNotificationForm />
          </TabsContent>
          
          <TabsContent value="inapp" className="mt-6">
            <InAppNotificationForm />
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
} 