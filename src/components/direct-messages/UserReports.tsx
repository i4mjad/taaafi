'use client';

import { useState, useMemo } from 'react';
import { useTranslation } from '@/contexts/TranslationContext';
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, where, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { StatusBadge } from './StatusBadge';
import { Eye, CheckCircle, XCircle } from 'lucide-react';
import { format } from 'date-fns';
import { Skeleton } from '@/components/ui/skeleton';

export function UserReports() {
  const { t } = useTranslation();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('active');
  
  const reportsQuery = useMemo(() => {
    let constraints: any[] = [];
    
    if (statusFilter !== 'all') {
      constraints.push(where('status', '==', statusFilter));
    }
    
    // Filter for DM-related reports (those with conversationId)
    constraints.push(where('reportType', '==', 'message'));
    constraints.push(orderBy('createdAt', 'desc'));
    constraints.push(limit(50));
    
    return query(collection(db, 'usersReports'), ...constraints);
  }, [statusFilter]);
  
  const [snapshot, loading, error] = useCollection(reportsQuery);
  
  // Extract data from snapshot and add document IDs
  const reports = useMemo(() => {
    if (!snapshot) return [];
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  }, [snapshot]);
  
  const filteredReports = useMemo(() => {
    if (!reports) return [];
    
    // Filter for reports with conversationId (DM reports)
    const dmReports = reports.filter((report: any) => report.conversationId);
    
    if (!searchTerm) return dmReports;
    
    return dmReports.filter((report: any) =>
      report.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      report.reporterCpId?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      report.userMessage?.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [reports, searchTerm]);
  
  if (loading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <Skeleton key={i} className="h-16 w-full" />
        ))}
      </div>
    );
  }
  
  if (error) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="space-y-2">
            <p className="text-destructive font-semibold">{t('modules.community.directMessages.common.error')}</p>
            <p className="text-sm text-muted-foreground">{error.message}</p>
            {error.code && <p className="text-xs text-muted-foreground">Error Code: {error.code}</p>}
          </div>
        </CardContent>
      </Card>
    );
  }
  
  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle>{t('modules.community.directMessages.reports.title')}</CardTitle>
          <CardDescription>
            {t('modules.community.directMessages.reports.description')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input
              placeholder={t('modules.community.directMessages.common.search')}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All</SelectItem>
                <SelectItem value="active">{t('modules.community.directMessages.statuses.active')}</SelectItem>
                <SelectItem value="resolved">{t('modules.community.directMessages.statuses.resolved')}</SelectItem>
                <SelectItem value="dismissed">{t('modules.community.directMessages.statuses.dismissed')}</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>
      
      <Card>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>{t('modules.community.directMessages.reports.columns.reportId')}</TableHead>
              <TableHead>{t('modules.community.directMessages.reports.columns.reportType')}</TableHead>
              <TableHead>{t('modules.community.directMessages.reports.columns.reporter')}</TableHead>
              <TableHead>{t('modules.community.directMessages.reports.columns.description')}</TableHead>
              <TableHead>{t('modules.community.directMessages.reports.columns.status')}</TableHead>
              <TableHead>{t('modules.community.directMessages.reports.columns.createdAt')}</TableHead>
              <TableHead>{t('modules.community.directMessages.reports.columns.actions')}</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredReports.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-8">
                  {t('modules.community.directMessages.reports.empty')}
                </TableCell>
              </TableRow>
            ) : (
              filteredReports.map((report: any) => (
                <TableRow key={report.id}>
                  <TableCell>
                    <code className="text-xs">{report.id.slice(0, 8)}...</code>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">
                      {t(`modules.community.directMessages.reportTypes.${report.reportType}`)}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <code className="text-xs">{report.reporterCpId?.slice(0, 8)}...</code>
                  </TableCell>
                  <TableCell>
                    <p className="text-sm max-w-md truncate">{report.userMessage}</p>
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={report.status} type="report" />
                  </TableCell>
                  <TableCell>
                    <span className="text-xs text-muted-foreground">
                      {report.createdAt && format(report.createdAt.toDate(), 'PP')}
                    </span>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-2">
                      <Button size="sm" variant="ghost">
                        <Eye className="h-4 w-4" />
                      </Button>
                      {report.status === 'active' && (
                        <>
                          <Button size="sm" variant="ghost">
                            <CheckCircle className="h-4 w-4" />
                          </Button>
                          <Button size="sm" variant="ghost">
                            <XCircle className="h-4 w-4" />
                          </Button>
                        </>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </Card>
    </div>
  );
}

