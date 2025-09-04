'use client';

import { useState, useMemo } from 'react';
import { useParams } from 'next/navigation';
import { useTranslation } from '@/contexts/TranslationContext';
import { useGroupMembers, useGroup } from '@/hooks/useGroupAdmin';
import { doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { AdminRoute } from '@/components/AdminRoute';
import { AdminLayout } from '@/components/AdminLayout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { 
  Users, 
  Search, 
  MoreHorizontal, 
  UserMinus, 
  Crown, 
  Trophy,
  Calendar,
  AlertTriangle
} from 'lucide-react';
import { format } from 'date-fns';
import { toast } from 'sonner';

export default function GroupMembersPage() {
  const params = useParams();
  const groupId = params.groupId as string;
  const { t } = useTranslation();
  const { group } = useGroup(groupId);
  const { members, loading, error } = useGroupMembers(groupId);
  const [search, setSearch] = useState('');
  const [selectedMember, setSelectedMember] = useState<any>(null);
  const [showRemoveDialog, setShowRemoveDialog] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);

  // Filter members based on search
  const filteredMembers = useMemo(() => {
    if (!search) return members;
    return members.filter(member => 
      member.cpId.toLowerCase().includes(search.toLowerCase())
    );
  }, [members, search]);

  // Sort members by role (admins first) then by points
  const sortedMembers = useMemo(() => {
    return [...filteredMembers].sort((a, b) => {
      // Admins first
      if (a.role === 'admin' && b.role !== 'admin') return -1;
      if (b.role === 'admin' && a.role !== 'admin') return 1;
      
      // Then by points (descending)
      return (b.pointsTotal || 0) - (a.pointsTotal || 0);
    });
  }, [filteredMembers]);

  const handleRemoveMember = async () => {
    if (!selectedMember) return;

    setIsUpdating(true);
    try {
      await updateDoc(doc(db, 'group_memberships', selectedMember.id), {
        isActive: false,
        leftAt: new Date(),
      });

      toast.success(t('admin.members.memberRemoved'));
      setShowRemoveDialog(false);
      setSelectedMember(null);
    } catch (error) {
      console.error('Error removing member:', error);
      toast.error(t('admin.members.removeMemberError'));
    } finally {
      setIsUpdating(false);
    }
  };

  const handlePromoteToAdmin = async (member: any) => {
    setIsUpdating(true);
    try {
      await updateDoc(doc(db, 'group_memberships', member.id), {
        role: 'admin',
      });

      toast.success(t('admin.members.memberPromoted'));
    } catch (error) {
      console.error('Error promoting member:', error);
      toast.error(t('admin.members.promoteMemberError'));
    } finally {
      setIsUpdating(false);
    }
  };

  const handleDemoteFromAdmin = async (member: any) => {
    setIsUpdating(true);
    try {
      await updateDoc(doc(db, 'group_memberships', member.id), {
        role: 'member',
      });

      toast.success(t('admin.members.memberDemoted'));
    } catch (error) {
      console.error('Error demoting member:', error);
      toast.error(t('admin.members.demoteMemberError'));
    } finally {
      setIsUpdating(false);
    }
  };

  const stats = {
    totalMembers: members.length,
    admins: members.filter(m => m.role === 'admin').length,
    members: members.filter(m => m.role === 'member').length,
    averagePoints: members.length > 0 
      ? Math.round(members.reduce((sum, m) => sum + (m.pointsTotal || 0), 0) / members.length)
      : 0,
  };

  if (loading) {
    return (
      <AdminRoute groupId={groupId}>
        <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin/members`}>
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4 animate-pulse" />
              <p className="text-muted-foreground">{t('admin.members.loading')}</p>
            </div>
          </div>
        </AdminLayout>
      </AdminRoute>
    );
  }

  if (error) {
    return (
      <AdminRoute groupId={groupId}>
        <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin/members`}>
          <div className="flex items-center justify-center py-12">
            <Card className="w-full max-w-md">
              <CardContent className="flex flex-col items-center justify-center p-8">
                <AlertTriangle className="h-12 w-12 text-destructive mb-4" />
                <p className="text-center text-destructive font-medium">
                  {t('admin.members.loadError')}
                </p>
              </CardContent>
            </Card>
          </div>
        </AdminLayout>
      </AdminRoute>
    );
  }

  return (
    <AdminRoute groupId={groupId}>
      <AdminLayout groupId={groupId} currentPath={`/community/groups/${groupId}/admin/members`}>
        <div className="space-y-6">
          {/* Header */}
          <div>
            <h1 className="text-2xl lg:text-3xl font-bold tracking-tight">
              {t('admin.members.title')}
            </h1>
            <p className="text-muted-foreground mt-1">
              {t('admin.members.description')}
            </p>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.members.stats.total')}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.totalMembers}</div>
                <p className="text-xs text-muted-foreground">
                  {group?.memberCapacity ? `${t('admin.members.stats.of')} ${group.memberCapacity}` : ''}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.members.stats.admins')}
                </CardTitle>
                <Crown className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.admins}</div>
                <p className="text-xs text-muted-foreground">
                  {stats.members} {t('admin.members.stats.regularMembers')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.members.stats.averagePoints')}
                </CardTitle>
                <Trophy className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.averagePoints}</div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.members.stats.perMember')}
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {t('admin.members.stats.capacity')}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {group?.memberCapacity && group.memberCapacity > 0 ? Math.round((stats.totalMembers / group.memberCapacity) * 100) : 0}%
                </div>
                <p className="text-xs text-muted-foreground">
                  {t('admin.members.stats.used')}
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Search */}
          <Card>
            <CardHeader>
              <CardTitle>{t('admin.members.search.title')}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder={t('admin.members.search.placeholder')}
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-10"
                />
              </div>
            </CardContent>
          </Card>

          {/* Members List */}
          <Card>
            <CardHeader>
              <CardTitle>
                {t('admin.members.list.title')} ({sortedMembers.length})
              </CardTitle>
              <CardDescription>
                {t('admin.members.list.description')}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {sortedMembers.length === 0 ? (
                <div className="text-center py-8">
                  <Users className="mx-auto h-12 w-12 text-muted-foreground/50" />
                  <h3 className="mt-4 text-lg font-semibold">
                    {search ? t('admin.members.noSearchResults') : t('admin.members.noMembers')}
                  </h3>
                  <p className="text-muted-foreground">
                    {search ? t('admin.members.tryDifferentSearch') : t('admin.members.noMembersDesc')}
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  {sortedMembers.map((member) => (
                    <div key={member.id} className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50 transition-colors">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center">
                          <Users className="h-5 w-5" />
                        </div>
                        
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <p className="font-medium truncate">{member.cpId}</p>
                            <Badge 
                              variant={member.role === 'admin' ? 'default' : 'secondary'}
                              className="text-xs"
                            >
                              {member.role === 'admin' ? (
                                <><Crown className="h-3 w-3 mr-1" />{t('admin.members.roles.admin')}</>
                              ) : (
                                t('admin.members.roles.member')
                              )}
                            </Badge>
                          </div>
                          
                          <div className="flex items-center gap-4 text-sm text-muted-foreground">
                            <div className="flex items-center gap-1">
                              <Calendar className="h-3 w-3" />
                              {t('admin.members.joined')} {format(member.joinedAt, 'MMM dd, yyyy')}
                            </div>
                            <div className="flex items-center gap-1">
                              <Trophy className="h-3 w-3" />
                              {member.pointsTotal || 0} {t('admin.members.points')}
                            </div>
                          </div>
                        </div>
                      </div>

                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" className="h-8 w-8 p-0">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          {member.role === 'member' ? (
                            <DropdownMenuItem 
                              onClick={() => handlePromoteToAdmin(member)}
                              disabled={isUpdating}
                            >
                              <Crown className="mr-2 h-4 w-4" />
                              {t('admin.members.actions.promoteToAdmin')}
                            </DropdownMenuItem>
                          ) : (
                            <DropdownMenuItem 
                              onClick={() => handleDemoteFromAdmin(member)}
                              disabled={isUpdating}
                            >
                              <Users className="mr-2 h-4 w-4" />
                              {t('admin.members.actions.demoteFromAdmin')}
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuItem 
                            onClick={() => {
                              setSelectedMember(member);
                              setShowRemoveDialog(true);
                            }}
                            className="text-destructive"
                            disabled={isUpdating}
                          >
                            <UserMinus className="mr-2 h-4 w-4" />
                            {t('admin.members.actions.removeMember')}
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Remove Member Dialog */}
          <Dialog open={showRemoveDialog} onOpenChange={setShowRemoveDialog}>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>{t('admin.members.removeDialog.title')}</DialogTitle>
                <DialogDescription>
                  {t('admin.members.removeDialog.description', { 
                    member: selectedMember?.cpId || ''
                  })}
                </DialogDescription>
              </DialogHeader>
              <DialogFooter>
                <Button 
                  variant="outline" 
                  onClick={() => setShowRemoveDialog(false)}
                  disabled={isUpdating}
                >
                  {t('common.cancel')}
                </Button>
                <Button 
                  variant="destructive" 
                  onClick={handleRemoveMember}
                  disabled={isUpdating}
                >
                  {isUpdating ? t('admin.members.removing') : t('admin.members.removeMember')}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </AdminLayout>
    </AdminRoute>
  );
}
