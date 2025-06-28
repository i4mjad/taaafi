'use client';

import React from 'react';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from "@/contexts/TranslationContext";
import NotificationsPage from './components/NotificationsPage';

export default function UserManagementNotificationsPage() {
  const { t } = useTranslation();

  const headerDictionary = {
    documents: t('modules.userManagement.notifications.title') || 'Notifications',
  };

  return (
    <>
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex flex-1 flex-col">
        <div className="@container/main flex flex-1 flex-col gap-2">
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
            <div className="space-y-6">
              <div>
                <h1 className="text-3xl font-bold tracking-tight">
                  {t('modules.userManagement.notifications.title') || 'Notifications'}
                </h1>
                <p className="text-muted-foreground">
                  {t('modules.userManagement.notifications.description') || 'Send notifications to selected user groups'}
                </p>
              </div>
              
              <NotificationsPage />
            </div>
          </div>
        </div>
      </div>
    </>
  );
} 