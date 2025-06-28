'use client';

import React from 'react';
import { SiteHeader } from '@/components/site-header';
import { useTranslation } from "@/contexts/TranslationContext";
import UserManagementSettings from './components/UserManagementSettings';

export default function UserManagementSettingsPage() {
  const { t } = useTranslation();

  const headerDictionary = {
    documents: t('modules.userManagement.settings') || 'Settings',
  };

  return (
    <>
    <div className="p-4">
      <SiteHeader dictionary={headerDictionary} />
      <div className="flex flex-1 flex-col">
        <div className="@container/main flex flex-1 flex-col gap-2">
          <div className="flex flex-col gap-4 py-4 md:gap-6 md:py-6 px-4 lg:px-6">
            <div className="space-y-6">
              <div>
                <h1 className="text-3xl font-bold tracking-tight">
                  {t('modules.userManagement.settings') || 'Settings'}
                </h1>
                <p className="text-muted-foreground">
                  {t('modules.userManagement.settingsDescription') || 'Configure user management and notification settings'}
                </p>
              </div>
              
              <UserManagementSettings />
            </div>
          </div>
        </div>
      </div>
      </div>
    </>
  );
} 