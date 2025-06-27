'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { 
  ResponsiveDialog as Dialog, 
  ResponsiveDialogContent as DialogContent, 
  ResponsiveDialogDescription as DialogDescription, 
  ResponsiveDialogFooter as DialogFooter, 
  ResponsiveDialogHeader as DialogHeader, 
  ResponsiveDialogTitle as DialogTitle 
} from '@/components/ui/responsive-dialog';
import { Plus, X } from 'lucide-react';
import { useTranslation } from "@/contexts/TranslationContext";
import { toast } from "sonner";

interface NotificationDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  messagingToken: string;
  userDisplayName?: string;
}

interface CustomData {
  key: string;
  value: string;
}

export function NotificationDialog({
  open,
  onOpenChange,
  messagingToken,
  userDisplayName
}: NotificationDialogProps) {
  const { t } = useTranslation();
  
  const [formData, setFormData] = useState({
    title: '',
    body: '',
    imageUrl: '',
    clickAction: '',
    priority: 'normal',
    sound: 'default',
    badge: '',
    ttl: '',
    collapseKey: '',
  });
  
  const [customData, setCustomData] = useState<CustomData[]>([]);
  const [sending, setSending] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.title.trim()) {
      newErrors.title = t('modules.userManagement.notificationDialog.errors.titleRequired') || 'Title is required';
    }
    
    if (!formData.body.trim()) {
      newErrors.body = t('modules.userManagement.notificationDialog.errors.messageRequired') || 'Message is required';
    }
    
    if (formData.imageUrl && !isValidUrl(formData.imageUrl)) {
      newErrors.imageUrl = t('modules.userManagement.notificationDialog.errors.invalidImageUrl') || 'Please enter a valid image URL';
    }
    
    if (formData.clickAction && !isValidUrl(formData.clickAction)) {
      newErrors.clickAction = t('modules.userManagement.notificationDialog.errors.invalidClickAction') || 'Please enter a valid URL';
    }
    
    if (formData.badge && isNaN(Number(formData.badge))) {
      newErrors.badge = t('modules.userManagement.notificationDialog.errors.invalidBadge') || 'Badge count must be a number';
    }
    
    if (formData.ttl && isNaN(Number(formData.ttl))) {
      newErrors.ttl = t('modules.userManagement.notificationDialog.errors.invalidTtl') || 'TTL must be a number';
    }
    
    // Check for duplicate data keys
    const dataKeys = customData.map(item => item.key).filter(key => key.trim() !== '');
    const uniqueKeys = new Set(dataKeys);
    if (dataKeys.length !== uniqueKeys.size) {
      newErrors.data = t('modules.userManagement.notificationDialog.errors.duplicateDataKey') || 'Data keys must be unique';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const isValidUrl = (string: string) => {
    try {
      new URL(string);
      return true;
    } catch (_) {
      return false;
    }
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const addCustomDataField = () => {
    setCustomData(prev => [...prev, { key: '', value: '' }]);
  };

  const removeCustomDataField = (index: number) => {
    setCustomData(prev => prev.filter((_, i) => i !== index));
  };

  const updateCustomDataField = (index: number, field: 'key' | 'value', value: string) => {
    setCustomData(prev => prev.map((item, i) => 
      i === index ? { ...item, [field]: value } : item
    ));
  };

  const handleSend = async () => {
    if (!validateForm()) return;
    
    setSending(true);
    
    try {
      const notificationData = {
        token: messagingToken,
        notification: {
          title: formData.title,
          body: formData.body,
          ...(formData.imageUrl && { image: formData.imageUrl }),
        },
        webpush: formData.clickAction ? {
          fcmOptions: {
            link: formData.clickAction
          }
        } : undefined,
        android: {
          priority: formData.priority,
          notification: {
            ...(formData.sound !== 'default' && { sound: formData.sound }),
            ...(formData.badge && { notificationCount: parseInt(formData.badge) }),
          },
          ...(formData.ttl && { ttl: parseInt(formData.ttl) * 1000 }),
          ...(formData.collapseKey && { collapseKey: formData.collapseKey }),
        },
        apns: {
          payload: {
            aps: {
              ...(formData.badge && { badge: parseInt(formData.badge) }),
              ...(formData.sound !== 'default' && { sound: formData.sound }),
            }
          }
        },
        data: customData.reduce((acc, item) => {
          if (item.key.trim() && item.value.trim()) {
            acc[item.key] = item.value;
          }
          return acc;
        }, {} as Record<string, string>)
      };

      const response = await fetch('/api/admin/notifications/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(notificationData),
      });

      if (!response.ok) {
        throw new Error('Failed to send notification');
      }

      toast.success(t('modules.userManagement.notificationDialog.success') || 'Notification sent successfully');
      onOpenChange(false);
      
      // Reset form
      setFormData({
        title: '',
        body: '',
        imageUrl: '',
        clickAction: '',
        priority: 'normal',
        sound: 'default',
        badge: '',
        ttl: '',
        collapseKey: '',
      });
      setCustomData([]);
      
    } catch (error) {
      console.error('Error sending notification:', error);
      toast.error(t('modules.userManagement.notificationDialog.error') || 'Failed to send notification');
    } finally {
      setSending(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            {t('modules.userManagement.notificationDialog.title') || 'Send Push Notification'}
          </DialogTitle>
          <DialogDescription>
            {t('modules.userManagement.notificationDialog.description') || 'Send a push notification to this user\'s device'}
            {userDisplayName && ` - ${userDisplayName}`}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Basic Message Fields */}
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="title">
                {t('modules.userManagement.notificationDialog.messageTitle') || 'Title'} *
              </Label>
                             <Input
                 id="title"
                 value={formData.title}
                 onChange={(e: React.ChangeEvent<HTMLInputElement>) => handleInputChange('title', e.target.value)}
                 placeholder={t('modules.userManagement.notificationDialog.messageTitlePlaceholder') || 'Enter notification title'}
                 className={errors.title ? 'border-red-500' : ''}
               />
              {errors.title && <p className="text-sm text-red-500">{errors.title}</p>}
            </div>

            <div className="space-y-2">
              <Label htmlFor="body">
                {t('modules.userManagement.notificationDialog.messageBody') || 'Message'} *
              </Label>
              <Textarea
                id="body"
                value={formData.body}
                onChange={(e) => handleInputChange('body', e.target.value)}
                placeholder={t('modules.userManagement.notificationDialog.messageBodyPlaceholder') || 'Enter notification message'}
                className={errors.body ? 'border-red-500' : ''}
                rows={3}
              />
              {errors.body && <p className="text-sm text-red-500">{errors.body}</p>}
            </div>
          </div>

          {/* Advanced Options */}
          <div className="space-y-4">
            <h4 className="font-medium">Advanced Options</h4>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="imageUrl">
                  {t('modules.userManagement.notificationDialog.imageUrl') || 'Image URL'}
                </Label>
                <Input
                  id="imageUrl"
                  value={formData.imageUrl}
                  onChange={(e) => handleInputChange('imageUrl', e.target.value)}
                  placeholder={t('modules.userManagement.notificationDialog.imageUrlPlaceholder') || 'https://example.com/image.jpg'}
                  className={errors.imageUrl ? 'border-red-500' : ''}
                />
                <p className="text-xs text-muted-foreground">
                  {t('modules.userManagement.notificationDialog.imageUrlHelp') || 'Optional image to display in the notification'}
                </p>
                {errors.imageUrl && <p className="text-sm text-red-500">{errors.imageUrl}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="clickAction">
                  {t('modules.userManagement.notificationDialog.clickAction') || 'Click Action'}
                </Label>
                <Input
                  id="clickAction"
                  value={formData.clickAction}
                  onChange={(e) => handleInputChange('clickAction', e.target.value)}
                  placeholder={t('modules.userManagement.notificationDialog.clickActionPlaceholder') || 'https://example.com'}
                  className={errors.clickAction ? 'border-red-500' : ''}
                />
                <p className="text-xs text-muted-foreground">
                  {t('modules.userManagement.notificationDialog.clickActionHelp') || 'URL to open when notification is clicked'}
                </p>
                {errors.clickAction && <p className="text-sm text-red-500">{errors.clickAction}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="priority">
                  {t('modules.userManagement.notificationDialog.priority') || 'Priority'}
                </Label>
                <Select value={formData.priority} onValueChange={(value) => handleInputChange('priority', value)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="normal">
                      {t('modules.userManagement.notificationDialog.priorityNormal') || 'Normal'}
                    </SelectItem>
                    <SelectItem value="high">
                      {t('modules.userManagement.notificationDialog.priorityHigh') || 'High'}
                    </SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">
                  {t('modules.userManagement.notificationDialog.priorityHelp') || 'High priority notifications are delivered immediately'}
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="badge">
                  {t('modules.userManagement.notificationDialog.badge') || 'Badge Count'}
                </Label>
                <Input
                  id="badge"
                  type="number"
                  value={formData.badge}
                  onChange={(e) => handleInputChange('badge', e.target.value)}
                  placeholder={t('modules.userManagement.notificationDialog.badgePlaceholder') || '1'}
                  className={errors.badge ? 'border-red-500' : ''}
                />
                <p className="text-xs text-muted-foreground">
                  {t('modules.userManagement.notificationDialog.badgeHelp') || 'Number to display on the app icon badge'}
                </p>
                {errors.badge && <p className="text-sm text-red-500">{errors.badge}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="ttl">
                  {t('modules.userManagement.notificationDialog.ttl') || 'Time to Live (TTL)'}
                </Label>
                <Input
                  id="ttl"
                  type="number"
                  value={formData.ttl}
                  onChange={(e) => handleInputChange('ttl', e.target.value)}
                  placeholder={t('modules.userManagement.notificationDialog.ttlPlaceholder') || '3600'}
                  className={errors.ttl ? 'border-red-500' : ''}
                />
                <p className="text-xs text-muted-foreground">
                  {t('modules.userManagement.notificationDialog.ttlHelp') || 'Time in seconds for how long the message should be kept in FCM storage'}
                </p>
                {errors.ttl && <p className="text-sm text-red-500">{errors.ttl}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="collapseKey">
                  {t('modules.userManagement.notificationDialog.collapseKey') || 'Collapse Key'}
                </Label>
                <Input
                  id="collapseKey"
                  value={formData.collapseKey}
                  onChange={(e) => handleInputChange('collapseKey', e.target.value)}
                  placeholder={t('modules.userManagement.notificationDialog.collapseKeyPlaceholder') || 'update_available'}
                />
                <p className="text-xs text-muted-foreground">
                  {t('modules.userManagement.notificationDialog.collapseKeyHelp') || 'Identifier for a group of messages that can be collapsed'}
                </p>
              </div>
            </div>
          </div>

          {/* Custom Data */}
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-medium">
                  {t('modules.userManagement.notificationDialog.data') || 'Custom Data'}
                </h4>
                <p className="text-sm text-muted-foreground">
                  {t('modules.userManagement.notificationDialog.dataHelp') || 'Additional key-value pairs to send with the notification'}
                </p>
              </div>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={addCustomDataField}
              >
                <Plus className="h-4 w-4 mr-1" />
                {t('modules.userManagement.notificationDialog.addDataField') || 'Add Data Field'}
              </Button>
            </div>

            {customData.map((item, index) => (
              <div key={index} className="flex gap-2 items-end">
                <div className="flex-1 space-y-2">
                  <Label>
                    {t('modules.userManagement.notificationDialog.dataKey') || 'Key'}
                  </Label>
                  <Input
                    value={item.key}
                    onChange={(e) => updateCustomDataField(index, 'key', e.target.value)}
                    placeholder={t('modules.userManagement.notificationDialog.dataKeyPlaceholder') || 'custom_key'}
                  />
                </div>
                <div className="flex-1 space-y-2">
                  <Label>
                    {t('modules.userManagement.notificationDialog.dataValue') || 'Value'}
                  </Label>
                  <Input
                    value={item.value}
                    onChange={(e) => updateCustomDataField(index, 'value', e.target.value)}
                    placeholder={t('modules.userManagement.notificationDialog.dataValuePlaceholder') || 'custom_value'}
                  />
                </div>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => removeCustomDataField(index)}
                  className="mb-0"
                >
                  <X className="h-4 w-4" />
                  {t('modules.userManagement.notificationDialog.removeDataField') || 'Remove'}
                </Button>
              </div>
            ))}
            
            {errors.data && <p className="text-sm text-red-500">{errors.data}</p>}
          </div>
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={sending}
          >
            {t('modules.userManagement.notificationDialog.cancel') || 'Cancel'}
          </Button>
          <Button
            onClick={handleSend}
            disabled={sending}
          >
            {sending ? (
              t('modules.userManagement.notificationDialog.sending') || 'Sending...'
            ) : (
              t('modules.userManagement.notificationDialog.send') || 'Send Notification'
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
} 