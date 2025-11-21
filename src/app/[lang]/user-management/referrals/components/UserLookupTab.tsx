'use client';

import { useState, useCallback, useEffect } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Search, User, Mail, Calendar, TrendingUp, Eye, Loader2 } from 'lucide-react';
import { UserDetailsModal } from './UserDetailsModal';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

interface SearchResult {
  userId: string;
  displayName: string;
  email: string;
  photoURL?: string | null;
  createdAt: string | null;
  stats: any;
  verification: any;
  matchType: 'id' | 'email' | 'code';
}

export function UserLookupTab() {
  const { t } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');
  const [searchType, setSearchType] = useState<'all' | 'email' | 'id' | 'code'>('all');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Debounced search
  useEffect(() => {
    if (searchQuery.length < 2) {
      setResults([]);
      setHasSearched(false);
      return;
    }

    const timer = setTimeout(() => {
      performSearch();
    }, 500);

    return () => clearTimeout(timer);
  }, [searchQuery, searchType]);

  const performSearch = async () => {
    setIsSearching(true);
    setError(null);
    setHasSearched(true);

    try {
      const response = await fetch(
        `/api/admin/referrals/search?q=${encodeURIComponent(searchQuery)}&type=${searchType}`
      );

      if (!response.ok) {
        throw new Error('Failed to search users');
      }

      const data = await response.json();
      setResults(data.results || []);
    } catch (err) {
      console.error('Search error:', err);
      setError(err instanceof Error ? err.message : 'Search failed');
      setResults([]);
    } finally {
      setIsSearching(false);
    }
  };

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map((n) => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString();
  };

  const getMatchTypeBadgeColor = (matchType: string) => {
    switch (matchType) {
      case 'id':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200';
      case 'email':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
      case 'code':
        return 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200';
    }
  };

  return (
    <div className="space-y-6">
      {/* Search Bar */}
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.userManagement.referralDashboard.userLookup.title')}</CardTitle>
          <CardDescription>
            {t('modules.userManagement.referralDashboard.userLookup.description')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col sm:flex-row gap-3">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                type="text"
                placeholder={t('modules.userManagement.referralDashboard.userLookup.searchPlaceholder')}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={searchType} onValueChange={(value: any) => setSearchType(value)}>
              <SelectTrigger className="w-full sm:w-[180px]">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">
                  {t('modules.userManagement.referralDashboard.userLookup.searchTypes.all')}
                </SelectItem>
                <SelectItem value="email">
                  {t('modules.userManagement.referralDashboard.userLookup.searchTypes.email')}
                </SelectItem>
                <SelectItem value="id">
                  {t('modules.userManagement.referralDashboard.userLookup.searchTypes.id')}
                </SelectItem>
                <SelectItem value="code">
                  {t('modules.userManagement.referralDashboard.userLookup.searchTypes.code')}
                </SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Loading State */}
      {isSearching && (
        <div className="flex items-center justify-center py-8">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          <span className="ml-3 text-sm text-muted-foreground">
            {t('modules.userManagement.referralDashboard.userLookup.searching')}
          </span>
        </div>
      )}

      {/* Error State */}
      {error && !isSearching && (
        <Card className="border-destructive">
          <CardContent className="pt-6">
            <p className="text-sm text-destructive text-center">{error}</p>
          </CardContent>
        </Card>
      )}

      {/* Empty State */}
      {!isSearching && hasSearched && results.length === 0 && !error && (
        <Card>
          <CardContent className="pt-6">
            <div className="text-center py-8">
              <User className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <h3 className="text-lg font-semibold mb-2">
                {t('modules.userManagement.referralDashboard.userLookup.noResults')}
              </h3>
              <p className="text-sm text-muted-foreground">
                {t('modules.userManagement.referralDashboard.userLookup.noResultsDesc')}
              </p>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Results */}
      {!isSearching && results.length > 0 && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">
              {t('modules.userManagement.referralDashboard.userLookup.resultsCount', {
                count: results.length,
              })}
            </p>
          </div>

          <div className="grid gap-4">
            {results.map((result) => (
              <Card key={result.userId} className="hover:shadow-md transition-shadow">
                <CardContent className="pt-6">
                  <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
                    {/* User Info */}
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                      <Avatar className="h-12 w-12">
                        <AvatarImage src={result.photoURL || undefined} />
                        <AvatarFallback>{getInitials(result.displayName)}</AvatarFallback>
                      </Avatar>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <p className="font-semibold truncate">{result.displayName}</p>
                          <Badge className={getMatchTypeBadgeColor(result.matchType)}>
                            {result.matchType}
                          </Badge>
                        </div>
                        <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-3 text-xs text-muted-foreground">
                          <span className="flex items-center gap-1">
                            <Mail className="h-3 w-3" />
                            <span className="truncate">{result.email}</span>
                          </span>
                          {result.createdAt && (
                            <span className="flex items-center gap-1">
                              <Calendar className="h-3 w-3" />
                              {formatDate(result.createdAt)}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Stats */}
                    <div className="flex items-center gap-4 w-full sm:w-auto">
                      {result.stats && (
                        <div className="flex gap-4 text-sm">
                          <div className="text-center">
                            <p className="text-2xl font-bold text-primary">
                              {result.stats.totalReferred || 0}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              {t('modules.userManagement.referralDashboard.userLookup.referred')}
                            </p>
                          </div>
                          <div className="text-center">
                            <p className="text-2xl font-bold text-green-600">
                              {result.stats.totalVerified || 0}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              {t('modules.userManagement.referralDashboard.userLookup.verified')}
                            </p>
                          </div>
                        </div>
                      )}
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => setSelectedUserId(result.userId)}
                        className="whitespace-nowrap"
                      >
                        <Eye className="h-4 w-4 mr-2" />
                        {t('modules.userManagement.referralDashboard.userLookup.viewDetails')}
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* User Details Modal */}
      {selectedUserId && (
        <UserDetailsModal
          userId={selectedUserId}
          open={!!selectedUserId}
          onClose={() => setSelectedUserId(null)}
        />
      )}
    </div>
  );
}

