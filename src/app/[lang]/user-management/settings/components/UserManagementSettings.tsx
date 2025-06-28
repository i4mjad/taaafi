"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Settings, Users, ArrowRight } from 'lucide-react';
import { useTranslation } from "@/contexts/TranslationContext";
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export default function UserManagementSettings() {
  const { t, locale } = useTranslation();

  return (
    <div className="space-y-6">
      {/* Actions Section */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            {t('modules.userManagement.actions.title') || 'Actions'}
          </CardTitle>
          <CardDescription>
            {t('modules.userManagement.actions.description') || 'Administrative actions for user management'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div className="flex items-center gap-3">
                <Users className="h-5 w-5 text-blue-600" />
                <div>
                  <h3 className="font-medium">{t('modules.userManagement.groups.title') || 'Messaging Groups'}</h3>
                  <p className="text-sm text-muted-foreground">
                    {t('modules.userManagement.groups.description') || 'Create and manage user groups for targeted messaging'}
                  </p>
                </div>
              </div>
              <Button asChild>
                <Link href={`/${locale}/user-management/settings/groups`}>
                  {t('modules.userManagement.groups.manageGroups') || 'Manage Groups'}
                  <ArrowRight className="w-4 h-4 ml-2" />
                </Link>
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>


    </div>
  );
} 