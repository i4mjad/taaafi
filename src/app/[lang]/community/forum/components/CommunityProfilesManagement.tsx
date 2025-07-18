'use client';

import { useState, useMemo } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Search, User, Users, UserCheck, Eye, Edit, MoreHorizontal } from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { format } from 'date-fns';
import { CommunityProfile } from '@/types/community';
import { toast } from 'sonner';

export default function CommunityProfilesManagement() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [genderFilter, setGenderFilter] = useState<string>('all');
  const [anonymousFilter, setAnonymousFilter] = useState<string>('all');
  const [selectedProfile, setSelectedProfile] = useState<CommunityProfile | null>(null);
  const [showDetails, setShowDetails] = useState(false);

  // Fetch community profiles
  const [value, loading, error] = useCollection(
    query(collection(db, 'communityProfiles'), orderBy('createdAt', 'desc'))
  );

  const profiles = useMemo(() => {
    if (!value) return [];
    
    return value.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      updatedAt: doc.data().updatedAt?.toDate(),
    })) as CommunityProfile[];
  }, [value]);

  // Apply filters
  const filteredProfiles = useMemo(() => {
    return profiles.filter(profile => {
      const matchesSearch = !search || 
        profile.displayName.toLowerCase().includes(search.toLowerCase()) ||
        profile.id.toLowerCase().includes(search.toLowerCase());
      
      const matchesGender = genderFilter === 'all' || profile.gender === genderFilter;
      const matchesAnonymous = anonymousFilter === 'all' || 
        (anonymousFilter === 'true' && profile.isAnonymous) ||
        (anonymousFilter === 'false' && !profile.isAnonymous);
      
      return matchesSearch && matchesGender && matchesAnonymous;
    });
  }, [profiles, search, genderFilter, anonymousFilter]);

  // Calculate stats
  const stats = useMemo(() => {
    const total = profiles.length;
    const anonymous = profiles.filter(p => p.isAnonymous).length;
    const male = profiles.filter(p => p.gender === 'male').length;
    const female = profiles.filter(p => p.gender === 'female').length;
    const other = profiles.filter(p => p.gender === 'other').length;

    return { total, anonymous, male, female, other };
  }, [profiles]);



  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <Card key={i}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  <div className="h-4 bg-muted rounded animate-pulse" />
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-8 bg-muted rounded animate-pulse mb-2" />
                <div className="h-3 bg-muted rounded animate-pulse" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <p className="text-destructive">{t('common.error')}</p>
        <Button 
          onClick={() => window.location.reload()} 
          variant="outline" 
          className="mt-4"
        >
          {t('common.retry')}
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-bold tracking-tight">{t('modules.community.profiles.title')}</h2>
        <p className="text-muted-foreground">
          {t('modules.community.profiles.description')}
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.profiles.totalProfiles')}
            </CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total}</div>
            <p className="text-xs text-muted-foreground">
              {t('modules.features.percentOfTotal', { percent: '100' })}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.profiles.anonymousProfiles')}
            </CardTitle>
            <UserCheck className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.anonymous}</div>
            <p className="text-xs text-muted-foreground">
              {stats.total > 0 
                ? `${Math.round((stats.anonymous / stats.total) * 100)}% ${t('modules.features.ofTotal')}`
                : '0%'
              }
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.profiles.male')}
            </CardTitle>
            <User className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.male}</div>
            <p className="text-xs text-muted-foreground">
              {stats.total > 0 
                ? `${Math.round((stats.male / stats.total) * 100)}%`
                : '0%'
              }
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              {t('modules.community.profiles.female')}
            </CardTitle>
            <User className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.female}</div>
            <p className="text-xs text-muted-foreground">
              {stats.total > 0 
                ? `${Math.round((stats.female / stats.total) * 100)}%`
                : '0%'
              }
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">{t('modules.content.items.filters')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">{t('common.search')}</label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder={t('modules.community.profiles.searchPlaceholder')}
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">{t('modules.community.profiles.filterByGender')}</label>
              <Select value={genderFilter} onValueChange={setGenderFilter}>
                <SelectTrigger>
                  <SelectValue placeholder={t('modules.community.profiles.selectGender')} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('common.all')}</SelectItem>
                  <SelectItem value="male">{t('modules.community.profiles.male')}</SelectItem>
                  <SelectItem value="female">{t('modules.community.profiles.female')}</SelectItem>
                  <SelectItem value="other">{t('modules.community.profiles.other')}</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">{t('modules.community.profiles.filterByAnonymous')}</label>
              <Select value={anonymousFilter} onValueChange={setAnonymousFilter}>
                <SelectTrigger>
                  <SelectValue placeholder={t('modules.community.profiles.isAnonymous')} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">{t('common.all')}</SelectItem>
                  <SelectItem value="true">{t('common.yes')}</SelectItem>
                  <SelectItem value="false">{t('common.no')}</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Data Table */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.profiles.list')}</CardTitle>
          <CardDescription>
            {t('modules.community.profiles.listDescription')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {filteredProfiles.length === 0 ? (
            <div className="text-center py-8">
              <Users className="mx-auto h-12 w-12 text-muted-foreground/50" />
              <h3 className="mt-4 text-lg font-semibold">{t('modules.community.profiles.noProfilesFound')}</h3>
              <p className="text-muted-foreground">
                {profiles.length === 0 
                  ? t('common.noData')
                  : 'Try adjusting your search or filter criteria'
                }
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full border-collapse">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-4 font-medium">{t('modules.community.profiles.displayName')}</th>
                    <th className="text-left py-3 px-4 font-medium">{t('modules.community.profiles.gender')}</th>
                    <th className="text-left py-3 px-4 font-medium">{t('modules.community.profiles.isAnonymous')}</th>
                    <th className="text-left py-3 px-4 font-medium">{t('modules.community.profiles.memberSince')}</th>
                    <th className="text-left py-3 px-4 font-medium">{t('common.actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredProfiles.map((profile) => (
                    <tr key={profile.id} className="border-b hover:bg-muted/50">
                      <td className="py-3 px-4">
                        <div className="flex items-center space-x-3">
                          <Avatar className="h-8 w-8">
                            <AvatarImage src={profile.avatarUrl} alt={profile.displayName} />
                            <AvatarFallback>
                              {profile.displayName.charAt(0).toUpperCase()}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <div className="font-medium">{profile.displayName}</div>
                            <div className="text-sm text-muted-foreground">{profile.id}</div>
                          </div>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <Badge variant="outline">
                          {profile.gender === 'male' && t('modules.community.profiles.male')}
                          {profile.gender === 'female' && t('modules.community.profiles.female')}
                          {profile.gender === 'other' && t('modules.community.profiles.other')}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        <Badge variant={profile.isAnonymous ? 'secondary' : 'default'}>
                          {profile.isAnonymous ? t('common.yes') : t('common.no')}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        <div className="text-sm">
                          {format(profile.createdAt, 'MMM dd, yyyy')}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="h-8 w-8 p-0">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => {
                              setSelectedProfile(profile);
                              setShowDetails(true);
                            }}>
                              <Eye className="mr-2 h-4 w-4" />
                              {t('modules.community.profiles.viewProfile')}
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => {
                              toast.info('Edit functionality coming soon');
                            }}>
                              <Edit className="mr-2 h-4 w-4" />
                              {t('modules.community.profiles.editProfile')}
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Profile Details Dialog */}
      <Dialog open={showDetails} onOpenChange={setShowDetails}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{t('modules.community.profiles.profileDetails')}</DialogTitle>
            <DialogDescription>
              Detailed information about the selected community profile
            </DialogDescription>
          </DialogHeader>
          
          {selectedProfile && (
            <div className="space-y-6">
              <div className="flex items-center space-x-4">
                <Avatar className="h-16 w-16">
                  <AvatarImage src={selectedProfile.avatarUrl} alt={selectedProfile.displayName} />
                  <AvatarFallback className="text-lg">
                    {selectedProfile.displayName.charAt(0).toUpperCase()}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <h3 className="text-xl font-semibold">{selectedProfile.displayName}</h3>
                  <p className="text-muted-foreground">{selectedProfile.id}</p>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('modules.community.profiles.gender')}</label>
                  <p className="text-sm">
                    {selectedProfile.gender === 'male' && t('modules.community.profiles.male')}
                    {selectedProfile.gender === 'female' && t('modules.community.profiles.female')}
                    {selectedProfile.gender === 'other' && t('modules.community.profiles.other')}
                  </p>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('modules.community.profiles.isAnonymous')}</label>
                  <p className="text-sm">
                    {selectedProfile.isAnonymous ? t('common.yes') : t('common.no')}
                  </p>
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('modules.community.profiles.memberSince')}</label>
                  <p className="text-sm">
                    {format(selectedProfile.createdAt, 'MMMM dd, yyyy HH:mm')}
                  </p>
                </div>

                {selectedProfile.referralCode && (
                  <div className="space-y-2">
                    <label className="text-sm font-medium">{t('modules.community.profiles.referralCode')}</label>
                    <p className="text-sm font-mono">{selectedProfile.referralCode}</p>
                  </div>
                )}
              </div>

              {selectedProfile.avatarUrl && (
                <div className="space-y-2">
                  <label className="text-sm font-medium">{t('modules.community.profiles.avatarUrl')}</label>
                  <p className="text-sm break-all">{selectedProfile.avatarUrl}</p>
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
} 