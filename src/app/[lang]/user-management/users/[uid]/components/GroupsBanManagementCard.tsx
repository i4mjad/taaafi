'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Users,
  MessageSquare,
  UserPlus,
  Clock,
  Shield,
  AlertTriangle,
  Settings,
  Eye,
  Plus,
  Calendar,
  Loader2,
  CheckCircle,
  XCircle,
  Ban,
} from 'lucide-react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useAuth } from '@/auth/AuthProvider';
import { useCollection, useDocument } from 'react-firebase-hooks/firestore';
import { collection, addDoc, query, where, orderBy, serverTimestamp, Timestamp, updateDoc, doc, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { toast } from 'sonner';
import { format } from 'date-fns';

interface GroupsBanManagementProps {
  userId: string;
  userDisplayName?: string;
}

interface CommunityProfile {
  id: string;
  userUID: string;
  displayName: string;
  nextJoinAllowedAt?: Timestamp | Date | null;
  rejoinCooldownOverrideUntil?: Timestamp | Date | null;
  customCooldownDuration?: number | null;
  cooldownReason?: string | null;
  cooldownIssuedBy?: string | null;
  isGroupsBanned?: boolean;
  groupsBanExpiresAt?: Timestamp | Date | null;
  groupsWarningCount?: number;
  lastGroupViolationAt?: Timestamp | Date | null;
}

interface GroupsBan {
  id?: string;
  userId: string;
  type: 'feature_ban';
  scope: 'feature_specific';
  reason: string;
  description?: string;
  severity: 'temporary' | 'permanent';
  issuedBy: string;
  issuedAt: Timestamp | Date;
  expiresAt?: Timestamp | Date | null;
  isActive: boolean;
  restrictedFeatures: string[];
}

const convertTimestamp = (timestamp: Timestamp | Date | null | undefined): Date | null => {
  if (!timestamp) return null;
  if (timestamp instanceof Timestamp) {
    return timestamp.toDate();
  }
  return timestamp;
};

const formatTimeRemaining = (targetDate: Date): string => {
  const now = new Date();
  const diff = targetDate.getTime() - now.getTime();
  
  if (diff <= 0) return 'Expired';
  
  const hours = Math.floor(diff / (1000 * 60 * 60));
  const days = Math.floor(hours / 24);
  
  if (days > 0) return `${days}d ${hours % 24}h`;
  return `${hours}h`;
};

export default function GroupsBanManagementCard({ userId, userDisplayName }: GroupsBanManagementProps) {
  const { t } = useTranslation();
  const { currentUser } = useAuth();
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [isOverrideDialogOpen, setIsOverrideDialogOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  
  const [cooldownForm, setCooldownForm] = useState({
    duration: 24,
    reason: '',
  });

  // Fetch community profile
  const [profileDoc, profileLoading, profileError] = useDocument(
    doc(db, 'communityProfiles', userId)
  );

  // Fetch active groups bans
  const [bansSnapshot, bansLoading, bansError] = useCollection(
    query(
      collection(db, 'bans'),
      where('userId', '==', userId),
      where('isActive', '==', true),
      where('restrictedFeatures', 'array-contains-any', ['sending_in_groups', 'create_or_join_a_group']),
      orderBy('issuedAt', 'desc')
    )
  );

  // Fetch active groups warnings  
  const [warningsSnapshot, warningsLoading, warningsError] = useCollection(
    query(
      collection(db, 'warnings'),
      where('userId', '==', userId),
      where('isActive', '==', true),
      where('type', 'in', ['group_harassment', 'group_spam', 'group_inappropriate_content', 'group_disruption']),
      orderBy('issuedAt', 'desc')
    )
  );

  const profile = profileDoc?.data() as CommunityProfile | undefined;
  const activeBans = bansSnapshot?.docs.map(doc => ({ id: doc.id, ...doc.data() })) as GroupsBan[] || [];
  const activeWarnings = warningsSnapshot?.docs || [];

  const currentCooldown = convertTimestamp(profile?.nextJoinAllowedAt);
  const cooldownOverride = convertTimestamp(profile?.rejoinCooldownOverrideUntil);
  const isCooldownActive = currentCooldown && currentCooldown > new Date();
  const isOverrideActive = cooldownOverride && cooldownOverride > new Date();

  const handleExtendCooldown = async () => {
    if (!currentUser?.email) return;
    
    setIsLoading(true);
    try {
      const profileRef = doc(db, 'communityProfiles', userId);
      const newCooldownEnd = new Date();
      newCooldownEnd.setHours(newCooldownEnd.getHours() + cooldownForm.duration);

      await updateDoc(profileRef, {
        customCooldownDuration: cooldownForm.duration,
        nextJoinAllowedAt: Timestamp.fromDate(newCooldownEnd),
        cooldownReason: cooldownForm.reason,
        cooldownIssuedBy: currentUser.email,
        updatedAt: serverTimestamp()
      });

      toast.success(t('modules.userManagement.modules.userManagement.groups-ban.cooldown-extended') || 'Cooldown extended successfully');
      setIsDialogOpen(false);
      setCooldownForm({ duration: 24, reason: '' });
    } catch (error) {
      console.error('Error extending cooldown:', error);
      toast.error(t('modules.userManagement.groups-ban.cooldown-extend-failed') || 'Failed to extend cooldown');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCooldownOverride = async () => {
    if (!currentUser?.email) return;
    
    setIsLoading(true);
    try {
      const overrideEnd = new Date();
      overrideEnd.setHours(overrideEnd.getHours() + 1); // 1 hour override window

      const profileRef = doc(db, 'communityProfiles', userId);
      await updateDoc(profileRef, {
        rejoinCooldownOverrideUntil: Timestamp.fromDate(overrideEnd),
        updatedAt: serverTimestamp()
      });

      toast.success(t('modules.userManagement.groups-ban.cooldown-override-activated') || 'Cooldown override activated for 1 hour');
      setIsOverrideDialogOpen(false);
    } catch (error) {
      console.error('Error activating override:', error);
      toast.error(t('modules.userManagement.groups-ban.cooldown-override-failed') || 'Failed to activate override');
    } finally {
      setIsLoading(false);
    }
  };

  const handleQuickBan = async (featureType: 'sending_in_groups' | 'create_or_join_a_group' | 'both') => {
    if (!currentUser?.email) return;
    
    setIsLoading(true);
    try {
      const restrictedFeatures = featureType === 'both' 
        ? ['sending_in_groups', 'create_or_join_a_group']
        : [featureType];

      const banData = {
        userId,
        type: 'feature_ban',
        scope: 'feature_specific',
        reason: `Quick ban for ${featureType}`,
        severity: 'temporary',
        issuedBy: currentUser.email,
        issuedAt: serverTimestamp(),
        expiresAt: null, // Set manually later if needed
        isActive: true,
        restrictedFeatures,
        deviceIds: [], // Add device tracking if needed
      };

      await addDoc(collection(db, 'bans'), banData);
      
      // Update community profile for fast lookups
      const profileRef = doc(db, 'communityProfiles', userId);
      await updateDoc(profileRef, {
        isGroupsBanned: true,
        lastGroupViolationAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });

      toast.success(t('modules.userManagement.groups-ban.quick-ban-applied') || 'Quick ban applied successfully');
    } catch (error) {
      console.error('Error applying quick ban:', error);
      toast.error(t('modules.userManagement.groups-ban.quick-ban-failed') || 'Failed to apply quick ban');
    } finally {
      setIsLoading(false);
    }
  };

  if (profileLoading || bansLoading || warningsLoading) {
    return (
      <Card className="w-full">
        <CardContent className="flex items-center justify-center py-6">
          <Loader2 className="h-6 w-6 animate-spin" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Users className="h-5 w-5" />
          {t('modules.userManagement.groups-ban.title') || 'Groups Management'}
        </CardTitle>
        <CardDescription>
          {t('modules.userManagement.groups-ban.description', { name: userDisplayName }) || `Manage ${userDisplayName}'s groups participation and cooldown periods`}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        
        {/* Current Status Section */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm flex items-center gap-2">
                <Ban className="h-4 w-4" />
                {t('modules.userManagement.groups-ban.ban-status') || 'Ban Status'}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {activeBans.length > 0 ? (
                <Badge variant="destructive" className="w-full justify-center">
                  <XCircle className="h-3 w-3 mr-1" />
                  {activeBans.length} Active Ban{activeBans.length > 1 ? 's' : ''}
                </Badge>
              ) : (
                <Badge variant="outline" className="w-full justify-center">
                  <CheckCircle className="h-3 w-3 mr-1" />
                  {t('modules.userManagement.groups-ban.no-bans') || 'No Active Bans'}
                </Badge>
              )}
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm flex items-center gap-2">
                <Clock className="h-4 w-4" />
                {t('modules.userManagement.groups-ban.cooldown-status') || 'Cooldown Status'}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {isOverrideActive ? (
                <Badge variant="secondary" className="w-full justify-center">
                  <Shield className="h-3 w-3 mr-1" />
                  Override Active
                </Badge>
              ) : isCooldownActive ? (
                <Badge variant="secondary" className="w-full justify-center border-orange-300 text-orange-700 bg-orange-50">
                  <Clock className="h-3 w-3 mr-1" />
                  {formatTimeRemaining(currentCooldown!)}
                </Badge>
              ) : (
                <Badge variant="outline" className="w-full justify-center">
                  <CheckCircle className="h-3 w-3 mr-1" />
                  {t('modules.userManagement.groups-ban.no-cooldown') || 'No Cooldown'}
                </Badge>
              )}
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm flex items-center gap-2">
                <AlertTriangle className="h-4 w-4" />
                {t('modules.userManagement.groups-ban.warnings') || 'Warnings'}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <Badge variant={activeWarnings.length > 0 ? "destructive" : "outline"} className="w-full justify-center">
                {activeWarnings.length} Active
              </Badge>
            </CardContent>
          </Card>
        </div>

        {/* Active Bans Section */}
        {activeBans.length > 0 && (
          <div className="space-y-4">
            <h4 className="font-medium flex items-center gap-2">
              <Ban className="h-4 w-4" />
              {t('modules.userManagement.groups-ban.active-bans') || 'Active Groups Bans'}
            </h4>
            <div className="space-y-2">
              {activeBans.map((ban) => (
                <Card key={ban.id} className="p-3">
                  <div className="flex items-start justify-between">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <Badge variant="destructive" className="text-xs">
                          {ban.restrictedFeatures.join(', ')}
                        </Badge>
                        <Badge variant="outline" className="text-xs">
                          {ban.severity}
                        </Badge>
                      </div>
                      <p className="text-sm font-medium">{ban.reason}</p>
                      {ban.description && (
                        <p className="text-xs text-muted-foreground">{ban.description}</p>
                      )}
                      <p className="text-xs text-muted-foreground">
                        Issued: {format(convertTimestamp(ban.issuedAt) || new Date(), 'PPp')}
                        {ban.expiresAt && ` • Expires: ${format(convertTimestamp(ban.expiresAt) || new Date(), 'PPp')}`}
                      </p>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        )}

        {/* Cooldown Management */}
        <div className="space-y-4">
          <h4 className="font-medium flex items-center gap-2">
            <Clock className="h-4 w-4" />
            {t('modules.userManagement.groups-ban.cooldown-management') || 'Cooldown Management'}
          </h4>
          
          {isCooldownActive && (
            <Card className="p-3 border-orange-200 bg-orange-50">
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-medium text-orange-800">Active Cooldown</span>
                  <Badge variant="secondary" className="border-orange-300 text-orange-700 bg-orange-50">{formatTimeRemaining(currentCooldown!)}</Badge>
                </div>
                {profile?.cooldownReason && (
                  <p className="text-sm text-orange-700">Reason: {profile.cooldownReason}</p>
                )}
                {profile?.cooldownIssuedBy && (
                  <p className="text-xs text-orange-600">Issued by: {profile.cooldownIssuedBy}</p>
                )}
              </div>
            </Card>
          )}

          <div className="flex gap-2 flex-wrap">
            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
              <DialogTrigger asChild>
                <Button variant="outline">
                  <Clock className="h-4 w-4 mr-2" />
                  {t('modules.userManagement.groups-ban.extend-cooldown') || 'Extend Cooldown'}
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>{t('modules.userManagement.groups-ban.extend-cooldown') || 'Extend Cooldown'}</DialogTitle>
                  <DialogDescription>
                    {t('modules.userManagement.groups-ban.extend-cooldown-desc') || 'Set a custom cooldown duration for this user'}
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label>{t('modules.userManagement.groups-ban.cooldown-duration') || 'Cooldown Duration'}</Label>
                    <Select 
                      value={cooldownForm.duration.toString()}
                      onValueChange={(value) => setCooldownForm(prev => ({
                        ...prev, 
                        duration: parseInt(value)
                      }))}
                    >
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="24">24 hours (Default)</SelectItem>
                        <SelectItem value="48">48 hours</SelectItem>
                        <SelectItem value="72">72 hours</SelectItem>
                        <SelectItem value="168">1 week</SelectItem>
                        <SelectItem value="720">1 month</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  
                  <div className="space-y-2">
                    <Label>{t('modules.userManagement.groups-ban.cooldown-reason') || 'Reason for Extended Cooldown'}</Label>
                    <Textarea
                      value={cooldownForm.reason}
                      onChange={(e) => setCooldownForm(prev => ({
                        ...prev,
                        reason: e.target.value
                      }))}
                      placeholder={t('modules.userManagement.groups-ban.cooldown-reason-placeholder') || "Reason for cooldown extension..."}
                      rows={3}
                    />
                  </div>
                </div>
                <DialogFooter>
                  <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
                    {t('common.cancel') || 'Cancel'}
                  </Button>
                  <Button onClick={handleExtendCooldown} disabled={isLoading}>
                    {isLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                    {t('modules.userManagement.groups-ban.apply-cooldown') || 'Apply Cooldown'}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
            
            <Dialog open={isOverrideDialogOpen} onOpenChange={setIsOverrideDialogOpen}>
              <DialogTrigger asChild>
                <Button variant="secondary" disabled={!isCooldownActive}>
                  <Shield className="h-4 w-4 mr-2" />
                  {t('modules.userManagement.groups-ban.override-cooldown') || 'Override Cooldown'}
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>{t('modules.userManagement.groups-ban.override-cooldown') || 'Override Cooldown'}</DialogTitle>
                  <DialogDescription>
                    {t('modules.userManagement.groups-ban.override-cooldown-desc') || 'Grant temporary access by overriding the current cooldown for 1 hour'}
                  </DialogDescription>
                </DialogHeader>
                <DialogFooter>
                  <Button variant="outline" onClick={() => setIsOverrideDialogOpen(false)}>
                    {t('common.cancel') || 'Cancel'}
                  </Button>
                  <Button onClick={handleCooldownOverride} disabled={isLoading}>
                    {isLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                    {t('modules.userManagement.groups-ban.activate-override') || 'Activate Override'}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </div>
        </div>

        {/* Quick Actions for Groups */}
        <div className="space-y-4">
          <h4 className="font-medium flex items-center gap-2">
            <Settings className="h-4 w-4" />
            {t('modules.userManagement.groups-ban.quick-actions') || 'Quick Actions'}
          </h4>
          <div className="flex flex-wrap gap-2">
            <Button 
              size="sm" 
              variant="outline" 
              onClick={() => handleQuickBan('sending_in_groups')}
              disabled={isLoading}
            >
              <MessageSquare className="h-4 w-4 mr-2" />
              {t('modules.userManagement.groups-ban.ban-chat-only') || 'Ban from Chat Only'}
            </Button>
            <Button 
              size="sm" 
              variant="outline"
              onClick={() => handleQuickBan('create_or_join_a_group')}
              disabled={isLoading}
            >  
              <UserPlus className="h-4 w-4 mr-2" />
              {t('modules.userManagement.groups-ban.ban-create-join') || 'Ban from Creating/Joining'}
            </Button>
            <Button 
              size="sm" 
              variant="destructive"
              onClick={() => handleQuickBan('both')}
              disabled={isLoading}
            >
              <Users className="h-4 w-4 mr-2" />
              {t('modules.userManagement.groups-ban.ban-all-groups') || 'Ban from All Groups'}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
