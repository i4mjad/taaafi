'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Skeleton } from '@/components/ui/skeleton';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useTranslation } from "@/contexts/TranslationContext";
import {
  Database,
  ArrowRight,
  CheckCircle,
  AlertTriangle,
  RefreshCw,
  Calendar,
  Download,
  ChevronDown,
  ChevronUp,
  Info,
  X,
} from 'lucide-react';

// Firebase imports
import { useCollection } from 'react-firebase-hooks/firestore';
import { collection, doc, addDoc, Timestamp, writeBatch, deleteDoc, getDocs, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface FollowUp {
  id: string;
  time: Timestamp;
  type: 'relapse' | 'pornOnly' | 'mastOnly' | 'slipUp';
}

interface UserProfile {
  uid: string;
  userRelapses?: string[];
  userMasturbatingWithoutWatching?: string[];
  userWatchingWithoutMasturbating?: string[];
}

interface MigrationData {
  relapses: {
    legacy: string[];
    migrated: string[];
    missing: string[];
    duplicates: string[];
    duplicateCount: number;
    dateCount?: Map<string, number>;
    duplicateDetails?: Array<{date: string, count: number, extras: number}>;
    totalEntries?: number;
    uniqueEntries?: number;
  };
  mastOnly: {
    legacy: string[];
    migrated: string[];
    missing: string[];
    duplicates: string[];
    duplicateCount: number;
    dateCount?: Map<string, number>;
    duplicateDetails?: Array<{date: string, count: number, extras: number}>;
    totalEntries?: number;
    uniqueEntries?: number;
  };
  pornOnly: {
    legacy: string[];
    migrated: string[];
    missing: string[];
    duplicates: string[];
    duplicateCount: number;
    dateCount?: Map<string, number>;
    duplicateDetails?: Array<{date: string, count: number, extras: number}>;
    totalEntries?: number;
    uniqueEntries?: number;
  };
}

interface MigrationManagementCardProps {
  userId: string;
  user: UserProfile;
}

export default function MigrationManagementCard({ userId, user }: MigrationManagementCardProps) {
  const { t } = useTranslation();
  const [showDetails, setShowDetails] = useState(false);
  const [migrationData, setMigrationData] = useState<MigrationData | null>(null);
  const [migrating, setMigrating] = useState<string | null>(null);
  const [removingDuplicates, setRemovingDuplicates] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  // Fetch followups collection
  const [followupsSnapshot, followupsLoading, followupsError] = useCollection(
    userId ? collection(db, 'users', userId, 'followUps') : null
  );

  // Process migration data when data changes
  useEffect(() => {
    if (!user || followupsLoading) return;

    const followups = followupsSnapshot?.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    } as FollowUp)) || [];

    // Get legacy arrays first
    const legacyRelapses = user.userRelapses || [];
    const legacyMastOnly = user.userMasturbatingWithoutWatching || [];
    const legacyPornOnly = user.userWatchingWithoutMasturbating || [];

    // Group followups by type, convert timestamps to dates, and FILTER to only include legacy dates
    const followupsByType = {
      relapse: followups
        .filter(f => f.type === 'relapse')
        .map(f => f.time.toDate().toISOString().split('T')[0])
        .filter(date => legacyRelapses.includes(date)), // ONLY consider legacy dates
      pornOnly: followups
        .filter(f => f.type === 'pornOnly')
        .map(f => f.time.toDate().toISOString().split('T')[0])
        .filter(date => legacyPornOnly.includes(date)), // ONLY consider legacy dates
      mastOnly: followups
        .filter(f => f.type === 'mastOnly')
        .map(f => f.time.toDate().toISOString().split('T')[0])
        .filter(date => legacyMastOnly.includes(date)), // ONLY consider legacy dates
    };

    // Helper function to detect duplicates and get unique dates
    const analyzeDuplicates = (dates: string[]) => {
      const dateCount = new Map<string, number>();
      dates.forEach(date => {
        dateCount.set(date, (dateCount.get(date) || 0) + 1);
      });
      
      // Dates that appear more than once
      const duplicates = Array.from(dateCount.entries())
        .filter(([_, count]) => count > 1)
        .map(([date]) => date);
      
      // Total number of extra entries (total - unique)
      const duplicateCount = dates.length - new Set(dates).size;
      const unique = Array.from(new Set(dates));
      
      // Debug info
      const duplicateDetails = Array.from(dateCount.entries())
        .filter(([_, count]) => count > 1)
        .map(([date, count]) => ({ date, count, extras: count - 1 }));
      
      return { 
        duplicates, 
        duplicateCount, 
        unique, 
        dateCount,
        duplicateDetails,
        totalEntries: dates.length,
        uniqueEntries: unique.length
      };
    };

    // Analyze each type for duplicates (now only considering legacy dates)
    const relapseAnalysis = analyzeDuplicates(followupsByType.relapse);
    const mastOnlyAnalysis = analyzeDuplicates(followupsByType.mastOnly);
    const pornOnlyAnalysis = analyzeDuplicates(followupsByType.pornOnly);

    // Simple DATE-ONLY comparison: what's in the legacy array vs what's migrated for each type
    const migrationData: MigrationData = {
      relapses: {
        legacy: legacyRelapses,
        migrated: followupsByType.relapse,
        missing: legacyRelapses.filter(date => !relapseAnalysis.unique.includes(date)),
        duplicates: relapseAnalysis.duplicates,
        duplicateCount: relapseAnalysis.duplicateCount,
        dateCount: relapseAnalysis.dateCount,
        duplicateDetails: relapseAnalysis.duplicateDetails,
        totalEntries: relapseAnalysis.totalEntries,
        uniqueEntries: relapseAnalysis.uniqueEntries,
      },
      mastOnly: {
        legacy: legacyMastOnly,
        migrated: followupsByType.mastOnly,
        missing: legacyMastOnly.filter(date => !mastOnlyAnalysis.unique.includes(date)),
        duplicates: mastOnlyAnalysis.duplicates,
        duplicateCount: mastOnlyAnalysis.duplicateCount,
        dateCount: mastOnlyAnalysis.dateCount,
        duplicateDetails: mastOnlyAnalysis.duplicateDetails,
        totalEntries: mastOnlyAnalysis.totalEntries,
        uniqueEntries: mastOnlyAnalysis.uniqueEntries,
      },
      pornOnly: {
        legacy: legacyPornOnly,
        migrated: followupsByType.pornOnly,
        missing: legacyPornOnly.filter(date => !pornOnlyAnalysis.unique.includes(date)),
        duplicates: pornOnlyAnalysis.duplicates,
        duplicateCount: pornOnlyAnalysis.duplicateCount,
        dateCount: pornOnlyAnalysis.dateCount,
        duplicateDetails: pornOnlyAnalysis.duplicateDetails,
        totalEntries: pornOnlyAnalysis.totalEntries,
        uniqueEntries: pornOnlyAnalysis.uniqueEntries,
      },
    };

    setMigrationData(migrationData);
    setLastUpdated(new Date());
    
    
  }, [user, followupsSnapshot, followupsLoading]);

  const handleMigrateMissing = async (type: 'relapses' | 'mastOnly' | 'pornOnly') => {
    if (!migrationData || !userId) return;

    const missing = migrationData[type].missing;
    if (missing.length === 0) return;

    setMigrating(type);

    try {
      const followupsRef = collection(db, 'users', userId, 'followUps');
      
      // Map type names to the actual followup types
      const typeMapping = {
        relapses: 'relapse',
        mastOnly: 'mastOnly',
        pornOnly: 'pornOnly',
      } as const;

      const followupType = typeMapping[type];

      // Use batching like in the Flutter migration code (500 operations per batch limit)
      const batches = [];
      let currentBatch = writeBatch(db);
      let batchCount = 0;

      // Avoid duplicate entries by checking date-type combinations
      const dateTypeMap = new Map<string, Set<string>>();
      
      for (const dateString of missing) {
        const dateKey = dateString;
        
        if (!dateTypeMap.has(dateKey)) {
          dateTypeMap.set(dateKey, new Set());
        }
        
        const existingTypes = dateTypeMap.get(dateKey)!;
        
        if (!existingTypes.has(followupType)) {
          existingTypes.add(followupType);
          
          // Create timestamp at midnight UTC since legacy data only had dates (no time)
          const date = new Date(dateString + 'T00:00:00.000Z');
          const followupDocRef = doc(followupsRef);
          
          currentBatch.set(followupDocRef, {
            time: Timestamp.fromDate(date),
            type: followupType,
          });
          
          batchCount++;

          // Commit batch if it reaches Firestore's limit (500)
          if (batchCount >= 500) {
            batches.push(currentBatch);
            currentBatch = writeBatch(db);
            batchCount = 0;
          }
        }
      }

      // Add the last batch if it has any pending writes
      if (batchCount > 0) {
        batches.push(currentBatch);
      }

      // Commit each batch sequentially
      for (const batch of batches) {
        await batch.commit();
      }
      
      // Show success message (you can replace this with a toast notification)
      
      
      // Optional: Show success toast
      // toast.success(t('modules.userManagement.migrationManagement.migrateSuccess'));
      
    } catch (error) {
      console.error(`Error migrating ${type}:`, error);
      // Optional: Show error toast
      // toast.error(t('modules.userManagement.migrationManagement.migrateError'));
    } finally {
      setMigrating(null);
    }
  };

  const handleRemoveDuplicates = async (type: 'relapses' | 'mastOnly' | 'pornOnly') => {
    if (!migrationData || !userId) return;

    const duplicates = migrationData[type].duplicates;
    if (duplicates.length === 0) return;

    setRemovingDuplicates(type);

    try {
      const followupsRef = collection(db, 'users', userId, 'followUps');
      
      // Map type names to the actual followup types
      const typeMapping = {
        relapses: 'relapse',
        mastOnly: 'mastOnly',
        pornOnly: 'pornOnly',
      } as const;

      const followupType = typeMapping[type];

      // For each duplicate date, find all documents and delete extras
      for (const duplicateDate of duplicates) {
        // Find all documents for this date and type
        const duplicateQuery = query(
          followupsRef, 
          where('type', '==', followupType)
        );
        
        const querySnapshot = await getDocs(duplicateQuery);
        const documentsForDate = querySnapshot.docs.filter(doc => {
          const data = doc.data();
          const dateString = data.time.toDate().toISOString().split('T')[0];
          return dateString === duplicateDate;
        });

        // Keep the first document, delete the rest
        if (documentsForDate.length > 1) {
          const documentsToDelete = documentsForDate.slice(1); // Skip first, delete rest
          
          // Use batch for efficient deletion
          const batch = writeBatch(db);
          documentsToDelete.forEach(docToDelete => {
            batch.delete(docToDelete.ref);
          });
          
          await batch.commit();
          
        }
      }
      
      // Show success message
      
      
      // Optional: Show success toast
      // toast.success(t('modules.userManagement.migrationManagement.duplicatesRemoved'));
      
    } catch (error) {
      console.error(`Error removing duplicates for ${type}:`, error);
      // Optional: Show error toast
      // toast.error(t('modules.userManagement.migrationManagement.duplicateRemovalError'));
    } finally {
      setRemovingDuplicates(null);
    }
  };

  const getTotalMissingCount = () => {
    if (!migrationData) return 0;
    return migrationData.relapses.missing.length + 
           migrationData.mastOnly.missing.length + 
           migrationData.pornOnly.missing.length;
  };

  const getTotalFollowupsCount = () => {
    if (!migrationData) return 0;
    return migrationData.relapses.migrated.length + 
           migrationData.mastOnly.migrated.length + 
           migrationData.pornOnly.migrated.length;
  };

  const getTotalDuplicatesCount = () => {
    if (!migrationData) return 0;
    return migrationData.relapses.duplicateCount + 
           migrationData.mastOnly.duplicateCount + 
           migrationData.pornOnly.duplicateCount;
  };

  const isLoading = followupsLoading || !migrationData;
  const hasError = followupsError;
  const hasLegacyData = user.userRelapses || user.userMasturbatingWithoutWatching || user.userWatchingWithoutMasturbating;
  const totalMissing = getTotalMissingCount();
  const isMigrationComplete = totalMissing === 0 && hasLegacyData;

  if (!hasLegacyData) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="h-5 w-5" />
            {t('modules.userManagement.migrationManagement.title')}
          </CardTitle>
          <CardDescription>
            {t('modules.userManagement.migrationManagement.description')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            <Database className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>{t('modules.userManagement.migrationManagement.noLegacyData')}</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Database className="h-5 w-5" />
          {t('modules.userManagement.migrationManagement.title')}
          {isMigrationComplete ? (
            <Badge variant="default" className="ml-auto">
              <CheckCircle className="h-3 w-3 mr-1" />
              {t('modules.userManagement.migrationManagement.migrationComplete')}
            </Badge>
          ) : (
            <Badge variant="destructive" className="ml-auto">
              <AlertTriangle className="h-3 w-3 mr-1" />
              {t('modules.userManagement.migrationManagement.migrationIncomplete')}
            </Badge>
          )}
        </CardTitle>
        <CardDescription>
          {t('modules.userManagement.migrationManagement.description')}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Summary Statistics */}
        {isLoading ? (
          <div className="grid grid-cols-2 gap-4">
            <Skeleton className="h-20" />
            <Skeleton className="h-20" />
          </div>
        ) : hasError ? (
          <div className="text-center py-4 text-destructive">
            <AlertTriangle className="h-8 w-8 mx-auto mb-2" />
            <p>{t('modules.userManagement.migrationManagement.error')}</p>
          </div>
        ) : (
          <div className="grid grid-cols-3 gap-4">
            <div className="text-center p-4 bg-muted rounded-lg">
              <p className="text-2xl font-bold">{getTotalFollowupsCount()}</p>
              <p className="text-sm text-muted-foreground">
                {t('modules.userManagement.migrationManagement.totalFollowups')}
              </p>
            </div>
            <div className="text-center p-4 bg-muted rounded-lg">
              <p className="text-2xl font-bold text-destructive">{totalMissing}</p>
              <p className="text-sm text-muted-foreground">
                {t('modules.userManagement.migrationManagement.missingEntries')}
              </p>
            </div>
            <div className="text-center p-4 bg-muted rounded-lg">
              <p className="text-2xl font-bold text-orange-600">{getTotalDuplicatesCount()}</p>
              <p className="text-sm text-muted-foreground">
                {t('modules.userManagement.migrationManagement.duplicateEntries')}
              </p>
            </div>
          </div>
        )}

                 {/* Toggle Details Button */}
         <div className="flex items-center justify-between">
           <Button
             variant="outline"
             onClick={() => setShowDetails(!showDetails)}
             disabled={isLoading}
           >
             {showDetails ? (
               <>
                 <ChevronUp className="h-4 w-4 mr-2" />
                 {t('modules.userManagement.migrationManagement.hideMigrationStatus')}
               </>
             ) : (
               <>
                 <ChevronDown className="h-4 w-4 mr-2" />
                 {t('modules.userManagement.migrationManagement.viewMigrationStatus')}
               </>
             )}
           </Button>
           
           <div className="flex items-center gap-2">
             {lastUpdated && (
               <p className="text-xs text-muted-foreground">
                 {t('modules.userManagement.migrationManagement.lastUpdated')}: {lastUpdated.toLocaleTimeString()}
               </p>
             )}
             <Button
               variant="ghost"
               size="sm"
               onClick={() => {
                 setLastUpdated(new Date());
                 // Force re-fetch by updating a key or triggering useEffect
               }}
               disabled={isLoading}
               className="h-8 w-8 p-0"
               title={t('modules.userManagement.migrationManagement.refreshData')}
             >
               <RefreshCw className={`h-3 w-3 ${isLoading ? 'animate-spin' : ''}`} />
             </Button>
           </div>
         </div>

        {/* Detailed Migration Status */}
        {showDetails && (
          <div className="space-y-6">
            <Separator />
            
            {isLoading ? (
              <div className="space-y-4">
                <Skeleton className="h-32" />
                <Skeleton className="h-32" />
                <Skeleton className="h-32" />
              </div>
            ) : (
              <div className="space-y-6">
                {/* Relapses Section */}
                <MigrationSection
                  title={t('modules.userManagement.migrationManagement.relapses.title')}
                  description={t('modules.userManagement.migrationManagement.relapses.description')}
                  legacy={migrationData!.relapses.legacy}
                  migrated={migrationData!.relapses.migrated}
                  missing={migrationData!.relapses.missing}
                  duplicates={migrationData!.relapses.duplicates}
                  duplicateCount={migrationData!.relapses.duplicateCount}
                  onMigrate={() => handleMigrateMissing('relapses')}
                  onRemoveDuplicates={() => handleRemoveDuplicates('relapses')}
                  migrating={migrating === 'relapses'}
                  removingDuplicates={removingDuplicates === 'relapses'}
                />

                <Separator />

                {/* Masturbation Only Section */}
                <MigrationSection
                  title={t('modules.userManagement.migrationManagement.mastOnly.title')}
                  description={t('modules.userManagement.migrationManagement.mastOnly.description')}
                  legacy={migrationData!.mastOnly.legacy}
                  migrated={migrationData!.mastOnly.migrated}
                  missing={migrationData!.mastOnly.missing}
                  duplicates={migrationData!.mastOnly.duplicates}
                  duplicateCount={migrationData!.mastOnly.duplicateCount}
                  onMigrate={() => handleMigrateMissing('mastOnly')}
                  onRemoveDuplicates={() => handleRemoveDuplicates('mastOnly')}
                  migrating={migrating === 'mastOnly'}
                  removingDuplicates={removingDuplicates === 'mastOnly'}
                />

                <Separator />

                {/* Porn Only Section */}
                <MigrationSection
                  title={t('modules.userManagement.migrationManagement.pornOnly.title')}
                  description={t('modules.userManagement.migrationManagement.pornOnly.description')}
                  legacy={migrationData!.pornOnly.legacy}
                  migrated={migrationData!.pornOnly.migrated}
                  missing={migrationData!.pornOnly.missing}
                  duplicates={migrationData!.pornOnly.duplicates}
                  duplicateCount={migrationData!.pornOnly.duplicateCount}
                  onMigrate={() => handleMigrateMissing('pornOnly')}
                  onRemoveDuplicates={() => handleRemoveDuplicates('pornOnly')}
                  migrating={migrating === 'pornOnly'}
                  removingDuplicates={removingDuplicates === 'pornOnly'}
                />
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

interface MigrationSectionProps {
  title: string;
  description: string;
  legacy: string[];
  migrated: string[];
  missing: string[];
  duplicates: string[];
  duplicateCount: number;
  onMigrate: () => void;
  onRemoveDuplicates: () => void;
  migrating: boolean;
  removingDuplicates: boolean;
}

function MigrationSection({ 
  title, 
  description, 
  legacy, 
  migrated, 
  missing, 
  duplicates,
  duplicateCount,
  onMigrate, 
  onRemoveDuplicates,
  migrating,
  removingDuplicates
}: MigrationSectionProps) {
  const { t } = useTranslation();

  return (
    <div className="space-y-4">
      <div>
        <h4 className="font-semibold">{title}</h4>
        <p className="text-sm text-muted-foreground">{description}</p>
      </div>

      {/* Statistics */}
      <div className="grid grid-cols-4 gap-4">
        <div className="text-center p-3 bg-blue-50 rounded-lg border border-blue-200">
          <p className="text-lg font-bold text-blue-700">{legacy.length}</p>
          <p className="text-xs text-blue-600">
            {t('modules.userManagement.migrationManagement.relapses.legacyCount')}
          </p>
        </div>
        <div className="text-center p-3 bg-green-50 rounded-lg border border-green-200">
          <p className="text-lg font-bold text-green-700">{migrated.length}</p>
          <p className="text-xs text-green-600">
            {t('modules.userManagement.migrationManagement.relapses.newCount')}
          </p>
        </div>
        <div className="text-center p-3 bg-red-50 rounded-lg border border-red-200">
          <p className="text-lg font-bold text-red-700">{missing.length}</p>
          <p className="text-xs text-red-600">
            {t('modules.userManagement.migrationManagement.relapses.missingCount')}
          </p>
        </div>
        <div className="text-center p-3 bg-orange-50 rounded-lg border border-orange-200">
          <p className="text-lg font-bold text-orange-700">{duplicateCount}</p>
          <p className="text-xs text-orange-600">
            {t('modules.userManagement.migrationManagement.duplicateEntries')}
          </p>
        </div>
      </div>

      {/* Actions */}
      <div className="space-y-3">
        {/* Migration Action */}
        {missing.length > 0 ? (
          <div className="space-y-2">
            <Button
              onClick={onMigrate}
              disabled={migrating || removingDuplicates}
              size="sm"
              className="w-full"
            >
              {migrating ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  {t('modules.userManagement.migrationManagement.migrating')}
                </>
              ) : (
                <>
                  <Download className="h-4 w-4 mr-2" />
                  {t('modules.userManagement.migrationManagement.migrateMissing')} ({missing.length})
                </>
              )}
            </Button>
            
            {/* Show missing entries */}
            <details className="text-xs">
              <summary className="cursor-pointer text-muted-foreground hover:text-foreground">
                {t('modules.userManagement.migrationManagement.missingEntriesList')}
              </summary>
              <div className="mt-2 p-2 bg-muted rounded text-xs font-mono max-h-24 overflow-y-auto">
                {missing.map((date, index) => (
                  <div key={index} className="flex items-center gap-2">
                    <Calendar className="h-3 w-3" />
                    {date}
                  </div>
                ))}
              </div>
            </details>
          </div>
        ) : (
          <div className="text-center py-2">
            <Badge variant="default">
              <CheckCircle className="h-3 w-3 mr-1" />
              {t('modules.userManagement.migrationManagement.allMigrated')}
            </Badge>
          </div>
        )}

        {/* Duplicate Removal Action */}
        {duplicateCount > 0 && (
          <div className="space-y-2">
            <Button
              onClick={onRemoveDuplicates}
              disabled={migrating || removingDuplicates}
              size="sm"
              variant="outline"
              className="w-full border-orange-200 text-orange-700 hover:bg-orange-50"
            >
              {removingDuplicates ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  {t('modules.userManagement.migrationManagement.removingDuplicates')}
                </>
              ) : (
                <>
                  <AlertTriangle className="h-4 w-4 mr-2" />
                  {t('modules.userManagement.migrationManagement.removeDuplicates')} ({duplicateCount})
                </>
              )}
            </Button>
            
            {/* Show duplicate entries */}
            <details className="text-xs">
              <summary className="cursor-pointer text-muted-foreground hover:text-foreground">
                {t('modules.userManagement.migrationManagement.duplicatesList')}
              </summary>
              <div className="mt-2 p-2 bg-muted rounded text-xs font-mono max-h-24 overflow-y-auto">
                {duplicates.map((date, index) => (
                  <div key={index} className="flex items-center gap-2">
                    <Calendar className="h-3 w-3" />
                    {date}
                  </div>
                ))}
              </div>
            </details>
          </div>
        )}
      </div>
    </div>
  );
} 