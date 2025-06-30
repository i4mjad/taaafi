'use client';

import React, { useState, useMemo } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

import { useTranslation } from '@/contexts/TranslationContext';
import { toast } from 'sonner';
import {
  Plus,
  Search,
  MoreHorizontal,
  Edit,
  Trash2,
  Eye,
  EyeOff,
  Settings,
} from 'lucide-react';

// Firebase imports
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, query, orderBy, deleteDoc, doc, updateDoc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

// Import our custom dialog
import ReportTypeDialog from './ReportTypeDialog';

interface ReportType {
  id: string;
  nameEn: string;
  nameAr: string;
  descriptionEn: string;
  descriptionAr: string;
  isActive: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface ReportTypesManagementProps {
  trigger: React.ReactNode;
}

export default function ReportTypesManagement({ trigger }: ReportTypesManagementProps) {
  const { t, locale } = useTranslation();
  
  const [isOpen, setIsOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [isReportTypeDialogOpen, setIsReportTypeDialogOpen] = useState(false);
  const [selectedReportType, setSelectedReportType] = useState<ReportType | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [reportTypeToDelete, setReportTypeToDelete] = useState<ReportType | null>(null);

  // Fetch report types using react-firebase-hooks
  const [reportTypesSnapshot, reportTypesLoading, reportTypesError] = useCollection(
    query(
      collection(db, 'reportTypes'),
      orderBy('updatedAt', 'desc')
    )
  );

  // Convert Firebase data to ReportType objects
  const allReportTypes: ReportType[] = useMemo(() => {
    if (!reportTypesSnapshot) return [];
    
    return reportTypesSnapshot.docs.map(doc => ({
      id: doc.id,
      nameEn: doc.data().nameEn || '',
      nameAr: doc.data().nameAr || '',
      descriptionEn: doc.data().descriptionEn || '',
      descriptionAr: doc.data().descriptionAr || '',
      isActive: doc.data().isActive ?? true,
      createdAt: doc.data().createdAt || Timestamp.now(),
      updatedAt: doc.data().updatedAt || Timestamp.now(),
    }));
  }, [reportTypesSnapshot]);

  // Filter report types based on search
  const filteredReportTypes = useMemo(() => {
    if (!searchQuery.trim()) return allReportTypes;

    const query = searchQuery.toLowerCase();
    return allReportTypes.filter(reportType => 
      reportType.nameEn.toLowerCase().includes(query) ||
      reportType.nameAr.toLowerCase().includes(query) ||
      reportType.descriptionEn.toLowerCase().includes(query) ||
      reportType.descriptionAr.toLowerCase().includes(query)
    );
  }, [allReportTypes, searchQuery]);

  // Calculate stats
  const stats = useMemo(() => {
    const total = allReportTypes.length;
    const active = allReportTypes.filter(rt => rt.isActive).length;
    const inactive = total - active;

    return { total, active, inactive };
  }, [allReportTypes]);

  const formatDate = (timestamp: Timestamp) => {
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(timestamp.toDate());
  };

  const getReportTypeName = (reportType: ReportType) => {
    return locale === 'ar' ? reportType.nameAr : reportType.nameEn;
  };

  const getReportTypeDescription = (reportType: ReportType) => {
    return locale === 'ar' ? reportType.descriptionAr : reportType.descriptionEn;
  };

  const handleCreateNew = () => {
    setSelectedReportType(null);
    setIsReportTypeDialogOpen(true);
  };

  const handleEdit = (reportType: ReportType) => {
    setSelectedReportType(reportType);
    setIsReportTypeDialogOpen(true);
  };

  const handleToggleStatus = async (reportType: ReportType) => {
    try {
      const reportTypeRef = doc(db, 'reportTypes', reportType.id);
      await updateDoc(reportTypeRef, {
        isActive: !reportType.isActive,
        updatedAt: Timestamp.now(),
      });

      toast.success(t('modules.userManagement.reports.reportTypes.statusUpdateSuccess') || 'Status updated successfully');
    } catch (error) {
      console.error('Error updating report type status:', error);
      toast.error(t('modules.userManagement.reports.reportTypes.statusUpdateError') || 'Failed to update status');
    }
  };

  const handleDeleteClick = (reportType: ReportType) => {
    setReportTypeToDelete(reportType);
    setDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!reportTypeToDelete) return;

    try {
      await deleteDoc(doc(db, 'reportTypes', reportTypeToDelete.id));
      toast.success(t('modules.userManagement.reports.reportTypes.deleteSuccess') || 'Report type deleted successfully');
      setDeleteDialogOpen(false);
      setReportTypeToDelete(null);
    } catch (error) {
      console.error('Error deleting report type:', error);
      toast.error(t('modules.userManagement.reports.reportTypes.deleteError') || 'Failed to delete report type');
    }
  };

  const handleDialogSuccess = () => {
    // The useCollection hook will automatically refresh the data
    setIsReportTypeDialogOpen(false);
    setSelectedReportType(null);
  };

  return (
    <>
      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogTrigger asChild>
          {trigger}
        </DialogTrigger>
        
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-hidden">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Settings className="h-5 w-5" />
              {t('modules.userManagement.reports.reportTypes.title') || 'Report Types'}
            </DialogTitle>
          </DialogHeader>

          <div className="flex flex-col gap-4 overflow-hidden">
            {/* Header with stats and create button */}
            <div className="flex items-center justify-between">
              <p className="text-muted-foreground">
                {t('modules.userManagement.reports.reportTypes.description') || 'Define and manage different types of reports that users can submit'}
              </p>
              <Button onClick={handleCreateNew}>
                <Plus className="h-4 w-4 mr-2" />
                {t('modules.userManagement.reports.reportTypes.create') || 'Create Report Type'}
              </Button>
            </div>

            {/* Stats Cards */}
            <div className="grid gap-4 md:grid-cols-3">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.reportTypes.totalTypes') || 'Total Types'}
                  </CardTitle>
                  <Settings className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.total}</div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.reportTypes.activeTypes') || 'Active Types'}
                  </CardTitle>
                  <Eye className="h-4 w-4 text-green-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.active}</div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">
                    {t('modules.userManagement.reports.reportTypes.inactiveTypes') || 'Inactive Types'}
                  </CardTitle>
                  <EyeOff className="h-4 w-4 text-gray-600" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{stats.inactive}</div>
                </CardContent>
              </Card>
            </div>

            {/* Search */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder={t('modules.userManagement.reports.reportTypes.searchPlaceholder') || 'Search report types...'}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>

            {/* Table */}
            <div className="flex-1 overflow-auto">
              {reportTypesError ? (
                <div className="text-center py-8">
                  <p className="text-red-500">Error loading report types: {reportTypesError.message}</p>
                </div>
              ) : reportTypesLoading ? (
                <div className="space-y-3">
                  {[...Array(3)].map((_, i) => (
                    <Skeleton key={i} className="h-16 w-full" />
                  ))}
                </div>
              ) : filteredReportTypes.length === 0 ? (
                <div className="text-center py-8">
                  <Settings className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                  <h3 className="text-lg font-semibold mb-2">
                    {t('modules.userManagement.reports.reportTypes.noTypesFound') || 'No report types found'}
                  </h3>
                  <p className="text-muted-foreground mb-4">
                    {searchQuery 
                      ? 'Try adjusting your search criteria.'
                      : 'Create your first report type to get started.'
                    }
                  </p>
                  {!searchQuery && (
                    <Button onClick={handleCreateNew}>
                      <Plus className="h-4 w-4 mr-2" />
                      {t('modules.userManagement.reports.reportTypes.create') || 'Create Report Type'}
                    </Button>
                  )}
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>{locale === 'ar' ? t('modules.userManagement.reports.reportTypes.nameAr') : t('modules.userManagement.reports.reportTypes.nameEn')}</TableHead>
                      <TableHead>{t('modules.userManagement.reports.status') || 'Status'}</TableHead>
                      <TableHead>{t('modules.userManagement.reports.reportTypes.updatedAt') || 'Last Updated'}</TableHead>
                      <TableHead className="text-right">{t('modules.userManagement.reports.actions') || 'Actions'}</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredReportTypes.map((reportType) => (
                      <TableRow key={reportType.id}>
                        <TableCell>
                          <div className="space-y-1">
                            <p className="font-medium">{getReportTypeName(reportType)}</p>
                            <p className="text-sm text-muted-foreground max-w-[300px] truncate">
                              {getReportTypeDescription(reportType)}
                            </p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant={reportType.isActive ? 'default' : 'secondary'}>
                            {reportType.isActive ? (
                              <>
                                <Eye className="h-3 w-3 mr-1" />
                                {t('common.active') || 'Active'}
                              </>
                            ) : (
                              <>
                                <EyeOff className="h-3 w-3 mr-1" />
                                {t('common.inactive') || 'Inactive'}
                              </>
                            )}
                          </Badge>
                        </TableCell>
                        <TableCell>{formatDate(reportType.updatedAt)}</TableCell>
                        <TableCell className="text-right">
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" className="h-8 w-8 p-0">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onClick={() => handleEdit(reportType)}>
                                <Edit className="h-4 w-4 mr-2" />
                                {t('common.edit') || 'Edit'}
                              </DropdownMenuItem>
                              <DropdownMenuItem onClick={() => handleToggleStatus(reportType)}>
                                {reportType.isActive ? (
                                  <>
                                    <EyeOff className="h-4 w-4 mr-2" />
                                    {t('common.deactivate') || 'Deactivate'}
                                  </>
                                ) : (
                                  <>
                                    <Eye className="h-4 w-4 mr-2" />
                                    {t('common.activate') || 'Activate'}
                                  </>
                                )}
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              <DropdownMenuItem 
                                onClick={() => handleDeleteClick(reportType)}
                                className="text-red-600"
                              >
                                <Trash2 className="h-4 w-4 mr-2" />
                                {t('common.delete') || 'Delete'}
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Report Type Create/Edit Dialog */}
      <ReportTypeDialog
        isOpen={isReportTypeDialogOpen}
        onClose={() => setIsReportTypeDialogOpen(false)}
        reportType={selectedReportType}
        onSuccess={handleDialogSuccess}
      />

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {t('modules.userManagement.reports.reportTypes.deleteTitle') || 'Delete Report Type'}
            </DialogTitle>
          </DialogHeader>
          <div className="py-4">
            <p className="text-muted-foreground">
              {t('modules.userManagement.reports.reportTypes.deleteDescription') || 'Are you sure you want to delete this report type? This action cannot be undone.'}
            </p>
          </div>
          <div className="flex justify-end space-x-2">
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              {t('common.cancel') || 'Cancel'}
            </Button>
            <Button 
              onClick={handleDeleteConfirm}
              className="bg-red-600 hover:bg-red-700 text-white"
            >
              {t('common.delete') || 'Delete'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
} 