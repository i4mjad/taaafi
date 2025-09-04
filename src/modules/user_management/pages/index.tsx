'use client';

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Plus,
  Search,
  Filter,
  MoreHorizontal,
  Edit,
  Trash2,
  UserCheck,
  UserX,
  Users,
  UserPlus,
  Shield,
} from 'lucide-react';
import { UserProfile, UserFilters } from '@/types/user';
import { InMemoryUserRepository } from '../repositories/InMemoryUserRepository';

interface UserManagementPageProps {
  t: (key: string) => string;
  locale: string;
}

export default function UserManagementPage({ t, locale }: UserManagementPageProps) {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<UserFilters>({});
  const [searchQuery, setSearchQuery] = useState('');

  // Using in-memory repository for demo
  const userRepository = new InMemoryUserRepository();

  useEffect(() => {
    loadUsers();
  }, [filters]);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const fetchedUsers = await userRepository.findAll(filters);
      setUsers(fetchedUsers);
    } catch (error) {
      console.error('Error loading users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async () => {
    if (searchQuery.trim()) {
      setFilters({ ...filters, search: searchQuery });
    } else {
      const { search, ...restFilters } = filters;
      setFilters(restFilters);
    }
  };

  const handleStatusChange = async (uid: string, status: 'active' | 'inactive' | 'suspended') => {
    try {
      await userRepository.updateStatus(uid, status);
      await loadUsers();
    } catch (error) {
      console.error('Error updating user status:', error);
    }
  };

  const handleDeleteUser = async (uid: string) => {
    try {
      await userRepository.delete(uid);
      await loadUsers();
    } catch (error) {
      console.error('Error deleting user:', error);
    }
  };

  const getStatusBadge = (status: string) => {
    const variants = {
      active: 'default',
      inactive: 'secondary',
      suspended: 'destructive',
    } as const;

    return (
      <Badge variant={variants[status as keyof typeof variants] || 'secondary'}>
        {t(`modules.userManagement.userStatus.${status}`) || status}
      </Badge>
    );
  };

  const getRoleBadge = (role: string) => {
    const variants = {
      admin: 'default',
      moderator: 'secondary',
      user: 'outline',
    } as const;

    return (
      <Badge variant={variants[role as keyof typeof variants] || 'outline'}>
        <Shield className="h-3 w-3 mr-1" />
        {t(`modules.userManagement.userRole.${role}`) || role}
      </Badge>
    );
  };

  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  };

  const stats = {
    total: users.length,
    active: users.filter(u => u.status === 'active').length,
    admins: users.filter(u => u.role === 'admin').length,
    moderators: users.filter(u => u.role === 'moderator').length,
  };

  return (
    <div className="h-full flex flex-col">
      {/* Header - full width with padding */}
      <div className="flex items-center justify-between px-6 py-4 border-b bg-background">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{t('modules.userManagement.title')}</h1>
          <p className="text-muted-foreground">
            {t('modules.userManagement.description')}
          </p>
        </div>
        <Button>
          <UserPlus className="h-4 w-4 mr-2" />
          {t('modules.userManagement.createUser')}
        </Button>
      </div>

      {/* Content area - full width with internal padding */}
      <div className="flex-1 overflow-auto">
        <div className="p-6 space-y-6 max-w-none">
          {/* Stats Cards */}
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{t('modules.userManagement.totalUsers')}</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.total}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{t('modules.userManagement.activeUsers')}</CardTitle>
                <UserCheck className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.active}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{t('modules.userManagement.admins')}</CardTitle>
                <Shield className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.admins}</div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">{t('modules.userManagement.moderators')}</CardTitle>
                <UserCheck className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.moderators}</div>
              </CardContent>
            </Card>
          </div>

          {/* Filters */}
          <Card>
            <CardHeader>
              <CardTitle>{t('common.search')}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex flex-col gap-4 md:flex-row md:items-end">
                <div className="flex-1">
                  <Input
                    placeholder={t('modules.userManagement.searchPlaceholder')}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                  />
                </div>
                <Select
                  value={filters.role || ''}
                  onValueChange={(value) => setFilters({ ...filters, role: value as any })}
                >
                  <SelectTrigger className="w-[180px]">
                    <SelectValue placeholder={t('modules.userManagement.filterByRole')} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="admin">Admin</SelectItem>
                    <SelectItem value="moderator">Moderator</SelectItem>
                    <SelectItem value="user">User</SelectItem>
                  </SelectContent>
                </Select>
                <Select
                  value={filters.status || ''}
                  onValueChange={(value) => setFilters({ ...filters, status: value as any })}
                >
                  <SelectTrigger className="w-[180px]">
                    <SelectValue placeholder={t('modules.userManagement.filterByStatus')} />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="inactive">Inactive</SelectItem>
                    <SelectItem value="suspended">Suspended</SelectItem>
                  </SelectContent>
                </Select>
                <Button onClick={handleSearch}>
                  <Search className="h-4 w-4 mr-2" />
                  {t('common.search')}
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Users Table */}
          <Card>
            <CardHeader>
              <CardTitle>{t('modules.userManagement.users')}</CardTitle>
              <CardDescription>
                {t('modules.userManagement.usersDescription')}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => (
                    <Skeleton key={i} className="h-16 w-full" />
                  ))}
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>{t('modules.userManagement.user')}</TableHead>
                      <TableHead>{t('modules.userManagement.userRole')}</TableHead>
                      <TableHead>{t('modules.userManagement.userStatus')}</TableHead>
                      <TableHead>{t('modules.userManagement.lastLogin')}</TableHead>
                      <TableHead>{t('modules.userManagement.createdAt')}</TableHead>
                      <TableHead className="text-right">{t('common.actions')}</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {users.map((user) => (
                      <TableRow key={user.uid}>
                        <TableCell>
                          <div className="flex items-center gap-3">
                            <Avatar className="h-9 w-9">
                              <AvatarImage src={user.photoURL} alt={user.displayName} />
                              <AvatarFallback>
                                {user.displayName?.charAt(0) || user.email.charAt(0).toUpperCase()}
                              </AvatarFallback>
                            </Avatar>
                            <div className="space-y-1">
                              <p className="text-sm font-medium">{user.displayName || user.email}</p>
                              <p className="text-xs text-muted-foreground">{user.email}</p>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell>{getRoleBadge(user.role)}</TableCell>
                        <TableCell>{getStatusBadge(user.status)}</TableCell>
                        <TableCell>
                          {user.lastLoginAt ? formatDate(user.lastLoginAt) : t('common.never')}
                        </TableCell>
                        <TableCell>{formatDate(user.createdAt)}</TableCell>
                        <TableCell className="text-right">
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" className="h-8 w-8 p-0">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem>
                                <Edit className="h-4 w-4 mr-2" />
                                {t('common.edit')}
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              {user.status === 'active' ? (
                                <DropdownMenuItem
                                  onClick={() => handleStatusChange(user.uid, 'suspended')}
                                >
                                  <UserX className="h-4 w-4 mr-2" />
                                  {t('modules.userManagement.suspendUser')}
                                </DropdownMenuItem>
                              ) : (
                                <DropdownMenuItem
                                  onClick={() => handleStatusChange(user.uid, 'active')}
                                >
                                  <UserCheck className="h-4 w-4 mr-2" />
                                  {t('modules.userManagement.activateUser')}
                                </DropdownMenuItem>
                              )}
                              <DropdownMenuSeparator />
                              <DropdownMenuItem
                                onClick={() => handleDeleteUser(user.uid)}
                                className="text-red-600"
                              >
                                <Trash2 className="h-4 w-4 mr-2" />
                                {t('common.delete')}
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}

              {!loading && users.length === 0 && (
                <div className="text-center py-8">
                  <Users className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                  <p className="text-lg font-medium">{t('common.noData')}</p>
                  <p className="text-muted-foreground">
                    {t('modules.userManagement.noUsersFound')}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
} 