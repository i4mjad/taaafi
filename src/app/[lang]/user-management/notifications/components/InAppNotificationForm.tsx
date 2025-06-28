"use client";

import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Loader2, Send, AlertCircle, CheckCircle, Info, Users, Bell } from 'lucide-react';
import { useTranslation } from "@/contexts/TranslationContext";

interface InAppNotificationData {
  title: string;
  body: string;
  type: 'info' | 'warning' | 'success' | 'error';
  actionText?: string;
  actionUrl?: string;
  persistent: boolean;
  topic: string;
}

interface Group {
  id: string;
  name: string;
  nameAr: string;
  description?: string;
  descriptionAr?: string;
  topicId: string;
  memberCount: number;
  isActive: boolean;
}

export default function InAppNotificationForm() {
  const { t, locale } = useTranslation();
  const [isLoading, setIsLoading] = useState(false);
  const [groupsLoading, setGroupsLoading] = useState(true);
  const [groups, setGroups] = useState<Group[]>([]);
  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [formData, setFormData] = useState<InAppNotificationData>({
    title: '',
    body: '',
    type: 'info',
    actionText: '',
    actionUrl: '',
    persistent: false,
    topic: ''
  });

  // Load groups from database
  useEffect(() => {
    loadGroups();
  }, []);

  const loadGroups = async () => {
    try {
      setGroupsLoading(true);
      const response = await fetch('/api/admin/groups');
      
      if (response.ok) {
        const data = await response.json();
        const activeGroups = data.groups.filter((group: Group) => group.isActive);
        setGroups(activeGroups);
        
        // Set default topic to first available group if form topic is empty
        if (activeGroups.length > 0 && !formData.topic) {
          setFormData(prev => ({ ...prev, topic: activeGroups[0].topicId }));
        }
      }
    } catch (error) {
      console.error('Error loading groups:', error);
    } finally {
      setGroupsLoading(false);
    }
  };

  // Get available topics from database groups only
  const getAvailableTopics = () => {
    return groups.map(group => ({
      value: group.topicId,
      label: locale === 'ar' && group.nameAr ? group.nameAr : group.name,
      description: locale === 'ar' && group.descriptionAr ? group.descriptionAr : group.description || '',
      icon: '👥',
      memberCount: group.memberCount
    }));
  };

  const validateForm = () => {
    const errors: string[] = [];
    
    if (groups.length === 0) {
      errors.push(t('modules.userManagement.notifications.inAppNotifications.errors.noGroupsAvailable') || 'No groups available. Please create a group first.');
    }
    
    if (!formData.title.trim()) {
      errors.push(t('modules.userManagement.notifications.inAppNotifications.errors.titleRequired') || 'Title is required');
    }
    
    if (!formData.body.trim()) {
      errors.push(t('modules.userManagement.notifications.inAppNotifications.errors.messageRequired') || 'Message is required');
    }
    
    if (!formData.topic) {
      errors.push(t('modules.userManagement.notifications.inAppNotifications.errors.targetGroupRequired') || 'Please select a target group');
    }
    
    if (formData.actionUrl && !isValidUrl(formData.actionUrl)) {
      errors.push(t('modules.userManagement.notifications.inAppNotifications.errors.invalidActionUrl') || 'Please enter a valid action URL');
    }
    
    return errors;
  };

  const isValidUrl = (string: string) => {
    try {
      new URL(string);
      return true;
    } catch (_) {
      return false;
    }
  };

  const getSelectedTopicInfo = () => {
    const availableTopics = getAvailableTopics();
    return availableTopics.find(topic => topic.value === formData.topic);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const validationErrors = validateForm();
    if (validationErrors.length > 0) {
      setAlert({ type: 'error', message: validationErrors[0] });
      return;
    }

    setIsLoading(true);
    setAlert(null);

    try {
      const response = await fetch('/api/admin/notifications/in-app', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          topic: formData.topic,
          title: formData.title,
          body: formData.body,
          type: formData.type,
          ...(formData.actionText && { actionText: formData.actionText }),
          ...(formData.actionUrl && { actionUrl: formData.actionUrl }),
          persistent: formData.persistent
        }),
      });

      const result = await response.json();

      if (response.ok) {
        const selectedTopic = getSelectedTopicInfo();
        setAlert({ 
          type: 'success', 
          message: `${t('modules.userManagement.notifications.inAppNotifications.success') || 'In-app notification sent successfully'} to ${selectedTopic?.label || formData.topic}!`
        });
        // Reset form
        setFormData({
          title: '',
          body: '',
          type: 'info',
          actionText: '',
          actionUrl: '',
          persistent: false,
          topic: ''
        });
      } else {
        setAlert({ type: 'error', message: result.error || t('modules.userManagement.notifications.inAppNotifications.error') || 'Failed to send in-app notification' });
      }
    } catch (error) {
      setAlert({ type: 'error', message: t('modules.userManagement.notifications.inAppNotifications.error') || 'Failed to send in-app notification' });
    } finally {
      setIsLoading(false);
    }
  };

  const selectedTopicInfo = getSelectedTopicInfo();
  const availableTopics = getAvailableTopics();

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'warning':
        return <AlertCircle className="h-4 w-4 text-orange-500" />;
      case 'success':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'error':
        return <AlertCircle className="h-4 w-4 text-red-500" />;
      default:
        return <Info className="h-4 w-4 text-blue-500" />;
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Bell className="h-5 w-5" />
          {t('modules.userManagement.notifications.inAppNotifications.title') || 'In-App Notifications'}
        </CardTitle>
        <CardDescription>
          {t('modules.userManagement.notifications.inAppNotifications.description') || 'Send in-app notifications to selected user groups'}
        </CardDescription>
      </CardHeader>
      <CardContent>
        {!groupsLoading && groups.length === 0 ? (
          <div className="text-center py-8">
            <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-medium mb-2">
              {t('modules.userManagement.notifications.inAppNotifications.noGroupsTitle') || 'No Groups Available'}
            </h3>
            <p className="text-muted-foreground mb-4">
              {t('modules.userManagement.notifications.inAppNotifications.noGroupsDescription') || 'You need to create messaging groups before sending notifications. Groups allow you to target specific user segments.'}
            </p>
            <Button asChild>
              <a href={`/${locale}/user-management/settings/groups`}>
                {t('modules.userManagement.groups.createFirstGroup') || 'Create First Group'}
              </a>
            </Button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            {alert && (
              <div className={`flex items-center gap-2 p-3 rounded-lg border ${
                alert.type === 'error' 
                  ? 'bg-destructive/10 border-destructive text-destructive' 
                  : 'bg-blue-50 border-blue-200 text-blue-800'
              }`}>
                {alert.type === 'error' ? (
                  <AlertCircle className="h-4 w-4" />
                ) : (
                  <Info className="h-4 w-4" />
                )}
                <span className="text-sm">{alert.message}</span>
              </div>
            )}

          {/* Target Group Selection */}
          <div className="space-y-2">
            <Label htmlFor="topic">{t('modules.userManagement.notifications.inAppNotifications.targetGroup') || 'Target Group'}</Label>
            {groupsLoading ? (
              <Skeleton className="h-10 w-full" />
            ) : (
              <Select
                value={formData.topic}
                onValueChange={(value) => setFormData({ ...formData, topic: value })}
                disabled={isLoading}
              >
                <SelectTrigger>
                  <SelectValue placeholder={t('modules.userManagement.notifications.inAppNotifications.selectTargetGroup') || 'Select target group'} />
                </SelectTrigger>
                <SelectContent>
                  {availableTopics.map((topic) => (
                    <SelectItem key={topic.value} value={topic.value}>
                      <div className="flex items-center gap-2">
                        <span className="text-lg">{topic.icon}</span>
                        <div className="flex flex-col">
                          <span className="font-medium">{topic.label}</span>
                          <span className="text-xs text-muted-foreground">
                            {topic.description}
                            {topic.memberCount !== null && (
                              <> • {topic.memberCount} {t('modules.userManagement.groups.members') || 'members'}</>
                            )}
                          </span>
                        </div>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            )}
            {selectedTopicInfo && (
              <div className="flex items-center gap-2">
                <Badge variant="secondary" className="flex items-center gap-1">
                  <Users className="h-3 w-3" />
                  {t('modules.userManagement.notifications.inAppNotifications.sendingTo') || 'Sending to:'} {selectedTopicInfo.label}
                  {selectedTopicInfo.memberCount !== null && (
                    <span className="ml-1">({selectedTopicInfo.memberCount})</span>
                  )}
                </Badge>
              </div>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="type">{t('modules.userManagement.notifications.inAppNotifications.notificationType') || 'Notification Type'}</Label>
            <Select
              value={formData.type}
              onValueChange={(value: 'info' | 'warning' | 'success' | 'error') => 
                setFormData({ ...formData, type: value })
              }
              disabled={isLoading}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="info">
                  <div className="flex items-center gap-2">
                    {getTypeIcon('info')}
                    {t('modules.userManagement.notifications.inAppNotifications.typeInfo') || 'Information'}
                  </div>
                </SelectItem>
                <SelectItem value="warning">
                  <div className="flex items-center gap-2">
                    {getTypeIcon('warning')}
                    {t('modules.userManagement.notifications.inAppNotifications.typeWarning') || 'Warning'}
                  </div>
                </SelectItem>
                <SelectItem value="success">
                  <div className="flex items-center gap-2">
                    {getTypeIcon('success')}
                    {t('modules.userManagement.notifications.inAppNotifications.typeSuccess') || 'Success'}
                  </div>
                </SelectItem>
                <SelectItem value="error">
                  <div className="flex items-center gap-2">
                    {getTypeIcon('error')}
                    {t('modules.userManagement.notifications.inAppNotifications.typeError') || 'Error'}
                  </div>
                </SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="title">{t('modules.userManagement.notifications.inAppNotifications.messageTitle') || 'Notification Title'}</Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder={t('modules.userManagement.notifications.inAppNotifications.messageTitlePlaceholder') || 'Enter notification title'}
              disabled={isLoading}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="body">{t('modules.userManagement.notifications.inAppNotifications.messageBody') || 'Message Content'}</Label>
            <Textarea
              id="body"
              value={formData.body}
              onChange={(e) => setFormData({ ...formData, body: e.target.value })}
              placeholder={t('modules.userManagement.notifications.inAppNotifications.messageBodyPlaceholder') || 'Enter your message content'}
              disabled={isLoading}
              required
              rows={4}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="actionText">{t('modules.userManagement.notifications.inAppNotifications.actionText') || 'Action Button Text (Optional)'}</Label>
            <Input
              id="actionText"
              value={formData.actionText}
              onChange={(e) => setFormData({ ...formData, actionText: e.target.value })}
              placeholder={t('modules.userManagement.notifications.inAppNotifications.actionTextPlaceholder') || 'Learn More'}
              disabled={isLoading}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="actionUrl">{t('modules.userManagement.notifications.inAppNotifications.actionUrl') || 'Action Button URL (Optional)'}</Label>
            <Input
              id="actionUrl"
              type="url"
              value={formData.actionUrl}
              onChange={(e) => setFormData({ ...formData, actionUrl: e.target.value })}
              placeholder={t('modules.userManagement.notifications.inAppNotifications.actionUrlPlaceholder') || 'https://example.com/page'}
              disabled={isLoading}
            />
          </div>

          <div className="flex items-center space-x-2">
            <Switch
              id="persistent"
              checked={formData.persistent}
              onCheckedChange={(checked) => setFormData({ ...formData, persistent: checked })}
              disabled={isLoading}
            />
            <div className="space-y-1">
              <Label htmlFor="persistent">{t('modules.userManagement.notifications.inAppNotifications.persistent') || 'Persistent Notification'}</Label>
              <p className="text-sm text-muted-foreground">{t('modules.userManagement.notifications.inAppNotifications.persistentHelp') || 'Persistent notifications remain until dismissed by user'}</p>
            </div>
          </div>

          <Button type="submit" disabled={isLoading || groupsLoading} className="w-full">
            {isLoading ? (
              <>
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                {t('modules.userManagement.notifications.inAppNotifications.sending') || 'Sending...'}
              </>
            ) : (
              <>
                <Send className="w-4 h-4 mr-2" />
                {t('modules.userManagement.notifications.inAppNotifications.sendTo') || 'Send to'} {selectedTopicInfo?.label || t('modules.userManagement.notifications.inAppNotifications.selectTargetGroup') || 'Selected Group'}
              </>
            )}
          </Button>
          </form>
        )}
      </CardContent>
    </Card>
  );
} 