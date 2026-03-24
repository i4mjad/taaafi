'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Loader2, CalendarDays, Smartphone, Apple, Info } from 'lucide-react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useDocument } from 'react-firebase-hooks/firestore';
import { doc, setDoc, serverTimestamp, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/auth/AuthProvider';
import { toast } from 'sonner';
import { format } from 'date-fns';

interface PlatformConfig {
  minimumVersion: string;
  enforcement: 'optional' | 'forced';
  forceAfterDate: Date | null;
  dismissCooldownHours: number;
  title: { ar: string; en: string };
  message: { ar: string; en: string };
  enabled: boolean;
}

const defaultPlatformConfig: PlatformConfig = {
  minimumVersion: '',
  enforcement: 'optional',
  forceAfterDate: null,
  dismissCooldownHours: 24,
  title: { ar: '', en: '' },
  message: { ar: '', en: '' },
  enabled: false,
};

function parsePlatformConfig(data: Record<string, unknown> | undefined): PlatformConfig {
  if (!data) return { ...defaultPlatformConfig };
  return {
    minimumVersion: (data.minimumVersion as string) ?? '',
    enforcement: (data.enforcement as 'optional' | 'forced') ?? 'optional',
    forceAfterDate: data.forceAfterDate
      ? (data.forceAfterDate as Timestamp).toDate()
      : null,
    dismissCooldownHours: (data.dismissCooldownHours as number) ?? 24,
    title: {
      ar: (data.title as Record<string, string>)?.ar ?? '',
      en: (data.title as Record<string, string>)?.en ?? '',
    },
    message: {
      ar: (data.message as Record<string, string>)?.ar ?? '',
      en: (data.message as Record<string, string>)?.en ?? '',
    },
    enabled: (data.enabled as boolean) ?? false,
  };
}

function PlatformCard({
  platform,
  icon: Icon,
  config,
  onSave,
  saving,
}: {
  platform: string;
  icon: React.ElementType;
  config: PlatformConfig;
  onSave: (config: PlatformConfig) => Promise<void>;
  saving: boolean;
}) {
  const { t } = useTranslation();
  const [form, setForm] = useState<PlatformConfig>(config);
  const [dateOpen, setDateOpen] = useState(false);

  useEffect(() => {
    setForm(config);
  }, [config]);

  const handleSave = async () => {
    if (!form.minimumVersion.match(/^\d+\.\d+\.\d+$/)) {
      toast.error(t('modules.features.forceUpdate.invalidVersion'));
      return;
    }
    await onSave(form);
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <Icon className="h-5 w-5" />
          <CardTitle>{platform}</CardTitle>
          <Badge variant={form.enabled ? 'default' : 'secondary'}>
            {form.enabled
              ? t('modules.features.forceUpdate.enabled')
              : t('modules.features.forceUpdate.disabled')}
          </Badge>
        </div>
        <CardDescription>
          {t('modules.features.forceUpdate.platformDescription', { platform })}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Enabled toggle */}
        <div className="flex items-center justify-between">
          <Label htmlFor={`${platform}-enabled`}>
            {t('modules.features.forceUpdate.enabledLabel')}
          </Label>
          <Switch
            id={`${platform}-enabled`}
            checked={form.enabled}
            onCheckedChange={(checked) => setForm({ ...form, enabled: checked })}
          />
        </div>

        {/* Minimum Version */}
        <div className="space-y-2">
          <Label htmlFor={`${platform}-version`}>
            {t('modules.features.forceUpdate.minimumVersion')}
          </Label>
          <Input
            id={`${platform}-version`}
            placeholder="5.5.3"
            value={form.minimumVersion}
            onChange={(e) => setForm({ ...form, minimumVersion: e.target.value })}
          />
        </div>

        {/* Enforcement */}
        <div className="space-y-2">
          <Label>{t('modules.features.forceUpdate.enforcement')}</Label>
          <Select
            value={form.enforcement}
            onValueChange={(value: 'optional' | 'forced') =>
              setForm({ ...form, enforcement: value })
            }
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="optional">
                {t('modules.features.forceUpdate.optional')}
              </SelectItem>
              <SelectItem value="forced">
                {t('modules.features.forceUpdate.forced')}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>

        {/* Auto-escalation date (only for optional) */}
        {form.enforcement === 'optional' && (
          <>
            <div className="space-y-2">
              <Label>{t('modules.features.forceUpdate.forceAfterDate')}</Label>
              <Popover open={dateOpen} onOpenChange={setDateOpen}>
                <PopoverTrigger asChild>
                  <Button variant="outline" className="w-full justify-start text-left font-normal">
                    <CalendarDays className="mr-2 h-4 w-4" />
                    {form.forceAfterDate
                      ? format(form.forceAfterDate, 'PPP')
                      : t('modules.features.forceUpdate.selectDate')}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="single"
                    selected={form.forceAfterDate ?? undefined}
                    onSelect={(date) => {
                      setForm({ ...form, forceAfterDate: date ?? null });
                      setDateOpen(false);
                    }}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
              {form.forceAfterDate && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setForm({ ...form, forceAfterDate: null })}
                >
                  {t('modules.features.forceUpdate.clearDate')}
                </Button>
              )}
            </div>

            {/* Dismiss cooldown */}
            <div className="space-y-2">
              <Label htmlFor={`${platform}-cooldown`}>
                {t('modules.features.forceUpdate.dismissCooldown')}
              </Label>
              <Input
                id={`${platform}-cooldown`}
                type="number"
                min={1}
                value={form.dismissCooldownHours}
                onChange={(e) =>
                  setForm({ ...form, dismissCooldownHours: parseInt(e.target.value) || 24 })
                }
              />
            </div>
          </>
        )}

        {/* Title AR */}
        <div className="space-y-2">
          <Label htmlFor={`${platform}-title-ar`}>
            {t('modules.features.forceUpdate.titleAr')}
          </Label>
          <Input
            id={`${platform}-title-ar`}
            dir="rtl"
            value={form.title.ar}
            onChange={(e) =>
              setForm({ ...form, title: { ...form.title, ar: e.target.value } })
            }
          />
        </div>

        {/* Title EN */}
        <div className="space-y-2">
          <Label htmlFor={`${platform}-title-en`}>
            {t('modules.features.forceUpdate.titleEn')}
          </Label>
          <Input
            id={`${platform}-title-en`}
            dir="ltr"
            value={form.title.en}
            onChange={(e) =>
              setForm({ ...form, title: { ...form.title, en: e.target.value } })
            }
          />
        </div>

        {/* Message AR */}
        <div className="space-y-2">
          <Label htmlFor={`${platform}-msg-ar`}>
            {t('modules.features.forceUpdate.messageAr')}
          </Label>
          <Textarea
            id={`${platform}-msg-ar`}
            dir="rtl"
            value={form.message.ar}
            onChange={(e) =>
              setForm({ ...form, message: { ...form.message, ar: e.target.value } })
            }
          />
        </div>

        {/* Message EN */}
        <div className="space-y-2">
          <Label htmlFor={`${platform}-msg-en`}>
            {t('modules.features.forceUpdate.messageEn')}
          </Label>
          <Textarea
            id={`${platform}-msg-en`}
            dir="ltr"
            value={form.message.en}
            onChange={(e) =>
              setForm({ ...form, message: { ...form.message, en: e.target.value } })
            }
          />
        </div>

        {/* Save */}
        <Button onClick={handleSave} disabled={saving} className="w-full">
          {saving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          {t('modules.features.forceUpdate.save')}
        </Button>
      </CardContent>
    </Card>
  );
}

export function ForceUpdateSettings() {
  const { t, locale } = useTranslation();
  const { user } = useAuth();
  const [saving, setSaving] = useState<'ios' | 'android' | null>(null);

  const docRef = doc(db, 'appConfig', 'forceUpdate');
  const [snapshot, loading, error] = useDocument(docRef);

  const data = snapshot?.data() as Record<string, unknown> | undefined;
  const iosConfig = parsePlatformConfig(data?.ios as Record<string, unknown> | undefined);
  const androidConfig = parsePlatformConfig(data?.android as Record<string, unknown> | undefined);

  const handleSave = async (platform: 'ios' | 'android', config: PlatformConfig) => {
    setSaving(platform);
    try {
      const platformData: Record<string, unknown> = {
        minimumVersion: config.minimumVersion,
        enforcement: config.enforcement,
        forceAfterDate: config.forceAfterDate
          ? Timestamp.fromDate(config.forceAfterDate)
          : null,
        dismissCooldownHours: config.dismissCooldownHours,
        title: config.title,
        message: config.message,
        enabled: config.enabled,
      };

      await setDoc(
        docRef,
        {
          [platform]: platformData,
          updatedAt: serverTimestamp(),
          updatedBy: user?.uid ?? 'unknown',
        },
        { merge: true }
      );

      toast.success(t('modules.features.forceUpdate.saved'));
    } catch (err) {
      console.error('Failed to save force update config:', err);
      toast.error(t('modules.features.forceUpdate.saveFailed'));
    } finally {
      setSaving(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (error) {
    return (
      <Card>
        <CardContent className="py-8 text-center text-destructive">
          {t('modules.features.forceUpdate.loadError')}
        </CardContent>
      </Card>
    );
  }

  const updatedAt = data?.updatedAt
    ? (data.updatedAt as Timestamp).toDate().toLocaleString(locale === 'ar' ? 'ar-SA' : 'en-US')
    : null;

  return (
    <div className="space-y-6">
      {/* Status card */}
      {updatedAt && (
        <Card>
          <CardContent className="flex items-center gap-2 py-4">
            <Info className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm text-muted-foreground">
              {t('modules.features.forceUpdate.lastUpdated')}: {updatedAt}
              {data?.updatedBy && ` (${data.updatedBy})`}
            </span>
          </CardContent>
        </Card>
      )}

      <div className="grid gap-6 md:grid-cols-2">
        <PlatformCard
          platform="iOS"
          icon={Apple}
          config={iosConfig}
          onSave={(config) => handleSave('ios', config)}
          saving={saving === 'ios'}
        />
        <PlatformCard
          platform="Android"
          icon={Smartphone}
          config={androidConfig}
          onSave={(config) => handleSave('android', config)}
          saving={saving === 'android'}
        />
      </div>
    </div>
  );
}
