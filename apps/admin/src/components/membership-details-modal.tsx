"use client"

import * as React from "react"
import { format } from "date-fns"
import { useCollection } from 'react-firebase-hooks/firestore'
import { collection, query, where } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { UserReport } from '@/types/reports'

import { useTranslation } from '@/contexts/TranslationContext'
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Separator } from "@/components/ui/separator"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { 
  Users, 
  Calendar, 
  Trophy, 
  Crown, 
  AlertTriangle,
  FileText,
  Clock,
  CheckCircle,
  XCircle,
  UserMinus,
  Shield
} from "lucide-react"

interface MembershipDetailsModalProps {
  membership: any
  group: any
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function MembershipDetailsModal({ 
  membership, 
  group, 
  open, 
  onOpenChange 
}: MembershipDetailsModalProps) {
  const { t } = useTranslation()
  const [showRemovalModal, setShowRemovalModal] = React.useState(false)

  // Fetch user reports related to this membership
  const [reportsSnapshot, reportsLoading] = useCollection(
    membership ? query(
      collection(db, 'usersReports'),
      where('reportedUserId', '==', membership.cpId)
    ) : null
  )

  const reports = React.useMemo(() => {
    if (!reportsSnapshot) return []
    return reportsSnapshot.docs.map(doc => {
      const data = doc.data()
      return {
        id: doc.id,
        uid: data.uid,
        time: data.time,
        reportTypeId: data.reportTypeId,
        status: data.status,
        initialMessage: data.initialMessage,
        lastUpdated: data.lastUpdated,
        messagesCount: data.messagesCount,
        relatedContent: data.relatedContent,
        targetId: data.targetId,
        targetType: data.targetType,
      } as UserReport
    })
  }, [reportsSnapshot])

  if (!membership || !group) return null

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="destructive" className="flex items-center gap-1"><AlertTriangle className="h-3 w-3" />Pending</Badge>
      case 'inProgress':
        return <Badge variant="default" className="flex items-center gap-1"><Clock className="h-3 w-3" />In Progress</Badge>
      case 'waitingForAdminResponse':
        return <Badge variant="secondary" className="flex items-center gap-1"><Clock className="h-3 w-3" />Waiting</Badge>
      case 'closed':
      case 'finalized':
        return <Badge variant="outline" className="flex items-center gap-1"><CheckCircle className="h-3 w-3" />Closed</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            {t('modules.admin.memberships.membershipDetails')}
          </DialogTitle>
          <DialogDescription>
            {t('modules.admin.memberships.membershipDetailsDesc')}
          </DialogDescription>
        </DialogHeader>

        <Tabs defaultValue="details" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="details">{t('modules.admin.memberships.membershipInfo')}</TabsTrigger>
            <TabsTrigger value="reports" className="flex items-center gap-2">
              {t('modules.admin.memberships.userReports')}
              {reports.length > 0 && (
                <Badge variant="destructive" className="text-xs">{reports.length}</Badge>
              )}
            </TabsTrigger>
          </TabsList>

          <TabsContent value="details" className="space-y-4">
            {/* Member Information */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Users className="h-4 w-4" />
                  {t('modules.admin.memberships.memberInfo')}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      {t('modules.admin.memberships.userId')}
                    </label>
                    <p className="font-mono text-sm">{membership.cpId}</p>
                  </div>
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      {t('modules.admin.memberships.role')}
                    </label>
                    <div className="flex items-center gap-2">
                      <Badge variant={membership.role === 'admin' ? 'default' : 'secondary'}>
                        {membership.role === 'admin' && <Crown className="h-3 w-3 mr-1" />}
                        {membership.role === 'admin' ? t('modules.admin.memberships.admin') : t('modules.admin.memberships.member')}
                      </Badge>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      {t('modules.admin.memberships.joinedAt')}
                    </label>
                    <div className="flex items-center gap-2">
                      <Calendar className="h-4 w-4 text-muted-foreground" />
                      <p>{format(membership.joinedAt, 'PPP')}</p>
                    </div>
                  </div>
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      {t('modules.admin.memberships.points')}
                    </label>
                    <div className="flex items-center gap-2">
                      <Trophy className="h-4 w-4 text-muted-foreground" />
                      <p>{membership.pointsTotal || 0} {t('modules.admin.memberships.pts')}</p>
                    </div>
                  </div>
                </div>

                <div>
                  <label className="text-sm font-medium text-muted-foreground">
                    {t('modules.admin.memberships.status')}
                  </label>
                  <Badge variant={membership.isActive ? 'default' : 'secondary'}>
                    {membership.isActive ? t('common.active') : t('common.inactive')}
                  </Badge>
                </div>
              </CardContent>
            </Card>

            {/* Group Information */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Users className="h-4 w-4" />
                  {t('modules.admin.memberships.groupInfo')}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      {t('modules.admin.memberships.groupName')}
                    </label>
                    <p className="font-medium">{group.name}</p>
                  </div>
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      {t('modules.admin.memberships.groupStatus')}
                    </label>
                    <Badge variant={group.isActive ? 'default' : 'secondary'}>
                      {group.isActive ? t('common.active') : t('common.inactive')}
                    </Badge>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      {t('modules.admin.memberships.capacity')}
                    </label>
                    <p>{group.memberCount || 0} / {group.memberCapacity} {t('modules.admin.memberships.members')}</p>
                  </div>
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      {t('modules.admin.memberships.groupCreated')}
                    </label>
                    <p>{format(group.createdAt?.toDate?.() || group.createdAt || new Date(), 'PPP')}</p>
                  </div>
                </div>

                {group.description && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">
                      {t('modules.admin.memberships.groupDescription')}
                    </label>
                    <p className="text-sm text-muted-foreground">{group.description}</p>
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="reports" className="space-y-4">
            {reportsLoading ? (
              <div className="flex items-center justify-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
              </div>
            ) : reports.length === 0 ? (
              <Card>
                <CardContent className="flex flex-col items-center justify-center py-8">
                  <FileText className="h-12 w-12 text-muted-foreground mb-4" />
                  <h3 className="font-medium mb-2">{t('modules.admin.memberships.noReports')}</h3>
                  <p className="text-sm text-muted-foreground text-center">
                    {t('modules.admin.memberships.noReportsDesc')}
                  </p>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-3">
                {reports.map((report) => (
                  <Card key={report.id}>
                    <CardHeader className="pb-3">
                      <div className="flex items-center justify-between">
                        <CardTitle className="text-base flex items-center gap-2">
                          <AlertTriangle className="h-4 w-4" />
                          {t('modules.admin.memberships.reportTitle')} #{report.id.slice(-6)}
                        </CardTitle>
                        {getStatusBadge(report.status)}
                      </div>
                      <CardDescription className="flex items-center gap-2">
                        <Clock className="h-3 w-3" />
                        {format(report.time?.toDate ? report.time.toDate() : new Date(), 'PPp')}
                      </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <div>
                        <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                          {t('modules.admin.memberships.reportType')}
                        </label>
                        <p className="text-sm">{report.reportTypeId || t('modules.admin.memberships.userReport')}</p>
                      </div>

                      {report.initialMessage && (
                        <div>
                          <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                            {t('modules.admin.memberships.reportReason')}
                          </label>
                          <p className="text-sm">{report.initialMessage}</p>
                        </div>
                      )}

                      {report.uid && (
                        <div>
                          <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                            {t('modules.admin.memberships.reportedBy')}
                          </label>
                          <p className="text-sm font-mono">{report.uid}</p>
                        </div>
                      )}

                      {report.relatedContent && (
                        <div>
                          <label className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
                            {t('modules.admin.memberships.relatedContent')}
                          </label>
                          <p className="text-sm">
                            {report.relatedContent.type}: {report.relatedContent.contentId}
                          </p>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </TabsContent>
        </Tabs>

        <Separator />

        <div className="flex justify-between gap-2">
          <div className="flex gap-2">
            <Button 
              variant="destructive"
              onClick={() => setShowRemovalModal(true)}
              className="flex items-center gap-2"
            >
              <UserMinus className="h-4 w-4" />
              {t('modules.userManagement.groups-removal.title') || 'Remove Member'}
            </Button>
          </div>
          <div className="flex gap-2">
            <Button 
              variant="outline" 
              onClick={() => window.location.href = `/community/groups/${group.id}/admin`}
            >
              <Shield className="h-4 w-4 mr-2" />
              {t('modules.admin.memberships.manageGroup')}
            </Button>
            <Button variant="outline" onClick={() => onOpenChange(false)}>
              {t('common.close')}
            </Button>
          </div>
        </div>

      </DialogContent>
    </Dialog>
  )
}
