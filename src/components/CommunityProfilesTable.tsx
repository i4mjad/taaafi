"use client"

import * as React from "react"
import {
  type ColumnDef,
  type ColumnFiltersState,
  type Row,
  type SortingState,
  type VisibilityState,
  flexRender,
  getCoreRowModel,
  getFacetedRowModel,
  getFacetedUniqueValues,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table"
import {
  ChevronDownIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  ChevronsLeftIcon,
  ChevronsRightIcon,
  ColumnsIcon,
  MoreVerticalIcon,
  Crown,
  Users,
  Calendar,
  Trophy,
  Eye,
  UserMinus,
  Clock,
  Ban,
  AlertTriangle,
  Shield,
} from "lucide-react"
import { format } from "date-fns"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

interface CommunityProfileData {
  cpId: string
  userUID: string
  displayName: string
  gender: string
  isAnonymous: boolean
  createdAt: Date
  nextJoinAllowedAt?: Date | null
  customCooldownDuration?: number | null
  cooldownReason?: string | null
  memberships: Array<{
    id: string
    groupId: string
    groupName: string
    role: 'admin' | 'member'
    isActive: boolean
    joinedAt: Date
    leftAt?: Date
    pointsTotal: number
  }>
  activeBans: Array<{
    id: string
    reason: string
    restrictedFeatures: string[]
    issuedAt: Date
  }>
  activeWarnings: Array<{
    id: string
    type: string
    reason: string
    severity: string
    issuedAt: Date
  }>
}

interface CommunityProfilesTableProps {
  data: CommunityProfileData[]
  groups: any[]
  dictionary: any
  lang: string
  onRemoveProfile: (profile: CommunityProfileData) => void
}

const getColumns = (
  dictionary: any,
  lang: string,
  groups: any[],
  onRemoveProfile: (profile: CommunityProfileData) => void
): ColumnDef<CommunityProfileData>[] => [
  {
    id: "select",
    header: ({ table }) => (
      <div className="flex items-center justify-center">
        <Checkbox
          checked={table.getIsAllPageRowsSelected() || (table.getIsSomePageRowsSelected() && "indeterminate")}
          onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
          aria-label="Select all"
        />
      </div>
    ),
    cell: ({ row }) => (
      <div className="flex items-center justify-center">
        <Checkbox
          checked={row.getIsSelected()}
          onCheckedChange={(value) => row.toggleSelected(!!value)}
          aria-label="Select row"
        />
      </div>
    ),
    enableSorting: false,
    enableHiding: false,
  },
  {
    accessorKey: "displayName",
    header: dictionary.headers?.profileInfo || "Profile Info",
    cell: ({ row }) => {
      const profile = row.original
      return (
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center">
            <Users className="h-4 w-4" />
          </div>
          <div className="min-w-0">
            <div className="font-medium truncate">{profile.displayName}</div>
            <div className="text-xs text-muted-foreground font-mono">CP: {profile.cpId}</div>
            <div className="text-xs text-muted-foreground font-mono">User: {profile.userUID}</div>
          </div>
        </div>
      )
    },
  },
  {
    accessorKey: "activeMemberships",
    header: dictionary.headers?.activeMemberships || "Active Memberships",
    cell: ({ row }) => {
      const profile = row.original
      const activeMemberships = profile.memberships.filter(m => m.isActive)
      
      return (
        <div className="space-y-1">
          {activeMemberships.length === 0 ? (
            <Badge variant="outline" className="text-xs">{dictionary.memberships?.noActiveMemberships || 'No active memberships'}</Badge>
          ) : (
            activeMemberships.map(membership => (
              <div key={membership.id} className="flex items-center justify-between p-1 bg-green-50 border border-green-200 rounded text-xs">
                <div className="flex items-center gap-1">
                  <Badge variant={membership.role === 'admin' ? 'default' : 'secondary'} className="text-xs">
                    {membership.role === 'admin' && <Crown className="h-2 w-2 mr-1" />}
                    {dictionary.roles?.[membership.role as keyof typeof dictionary.roles] || membership.role}
                  </Badge>
                  <span className="truncate max-w-[100px]" title={membership.groupName}>
                    {membership.groupName}
                  </span>
                </div>
                <div className="flex items-center gap-1">
                  <Trophy className="h-2 w-2 text-yellow-600" />
                  <span>{membership.pointsTotal}</span>
                </div>
              </div>
            ))
          )}
        </div>
      )
    },
  },
  {
    accessorKey: "status",
    header: dictionary.headers?.status || "Status & Restrictions",
    cell: ({ row }) => {
      const profile = row.original
      const now = new Date()
      
      return (
        <div className="space-y-1">
          {/* Cooldown Status */}
          {profile.nextJoinAllowedAt && profile.nextJoinAllowedAt instanceof Date && !isNaN(profile.nextJoinAllowedAt.getTime()) && profile.nextJoinAllowedAt > now ? (
            <Badge variant="outline" className="text-orange-600 border-orange-300 bg-orange-50 text-xs">
              <Clock className="h-2 w-2 mr-1" />
              {dictionary.status?.cooldownUntil || 'Cooldown until'} {format(profile.nextJoinAllowedAt, 'MMM dd')}
            </Badge>
          ) : (
            <Badge variant="outline" className="text-green-600 border-green-300 bg-green-50 text-xs">
              <Shield className="h-2 w-2 mr-1" />
              {dictionary.status?.noRestrictions || 'No restrictions'}
            </Badge>
          )}
          
          {/* Bans */}
          {profile.activeBans.length > 0 && (
            <Badge variant="destructive" className="text-xs">
              <Ban className="h-2 w-2 mr-1" />
              {profile.activeBans.length} {dictionary.status?.bans || 'bans'}
            </Badge>
          )}
          
          {/* Warnings */}
          {profile.activeWarnings.length > 0 && (
            <Badge variant="outline" className="text-yellow-600 border-yellow-300 bg-yellow-50 text-xs">
              <AlertTriangle className="h-2 w-2 mr-1" />
              {profile.activeWarnings.length} {dictionary.status?.warnings || 'warnings'}
            </Badge>
          )}
        </div>
      )
    },
  },
  {
    accessorKey: "membershipStats",
    header: dictionary.headers?.membershipStats || "Membership Stats",
    cell: ({ row }) => {
      const profile = row.original
      const activeMemberships = profile.memberships.filter(m => m.isActive)
      const totalPoints = profile.memberships.reduce((sum, m) => sum + (m.pointsTotal || 0), 0)
      
      return (
        <div className="space-y-1 text-sm">
          <div className="flex items-center gap-2">
            <Users className="h-3 w-3 text-blue-600" />
            <span>{activeMemberships.length}/{profile.memberships.length} {dictionary.memberships?.groups || 'groups'}</span>
          </div>
          <div className="flex items-center gap-2">
            <Trophy className="h-3 w-3 text-yellow-600" />
            <span>{totalPoints} {dictionary.memberships?.totalPoints || 'total points'}</span>
          </div>
          <div className="flex items-center gap-2">
            <Calendar className="h-3 w-3 text-muted-foreground" />
            <span>
              {profile.createdAt && profile.createdAt instanceof Date && !isNaN(profile.createdAt.getTime()) 
                ? format(profile.createdAt, 'MMM dd, yyyy') 
                : (dictionary.status?.unknownDate || 'Unknown date')
              }
            </span>
          </div>
        </div>
      )
    },
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const profile = row.original
      const hasActiveMemership = profile.memberships.some(m => m.isActive)
      
      return (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="flex size-8 text-muted-foreground data-[state=open]:bg-muted" size="icon">
              <MoreVerticalIcon className="h-4 w-4" />
              <span className="sr-only">{dictionary.actions?.openMenu || 'Open menu'}</span>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align={lang === "ar" ? "start" : "end"} className="w-48">
            <DropdownMenuItem onClick={() => {
              window.location.href = `/${lang}/user-management/users/${profile.userUID}`;
            }}>
              <Eye className="mr-2 h-4 w-4" />
              {dictionary.actions?.viewUserProfile || 'View User Profile'}
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem 
              onClick={() => onRemoveProfile(profile)}
              className="text-red-600 focus:text-red-600"
              disabled={!hasActiveMemership}
            >
              <UserMinus className="mr-2 h-4 w-4" />
              {dictionary.actions?.removeFromGroup || 'Remove from Group'}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      )
    },
  },
]

export function CommunityProfilesTable({ data, groups, dictionary, lang, onRemoveProfile }: CommunityProfilesTableProps) {
  const [rowSelection, setRowSelection] = React.useState({})
  const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>({})
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([])
  const [sorting, setSorting] = React.useState<SortingState>([])
  const [globalFilter, setGlobalFilter] = React.useState("")
  const [pagination, setPagination] = React.useState({
    pageIndex: 0,
    pageSize: 10,
  })

  const columns = React.useMemo(() => getColumns(
    dictionary, 
    lang, 
    groups, 
    onRemoveProfile
  ), [dictionary, lang, groups, onRemoveProfile])

  const table = useReactTable({
    data,
    columns,
    state: {
      sorting,
      columnVisibility,
      rowSelection,
      columnFilters,
      globalFilter,
      pagination,
    },
    enableRowSelection: true,
    onRowSelectionChange: setRowSelection,
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onColumnVisibilityChange: setColumnVisibility,
    onGlobalFilterChange: setGlobalFilter,
    onPaginationChange: setPagination,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFacetedRowModel: getFacetedRowModel(),
    getFacetedUniqueValues: getFacetedUniqueValues(),
  })

  return (
    <>
      <div className="space-y-4">
        {/* Table Controls */}
        <div className="flex items-center justify-between">
          <div className="flex flex-1 items-center space-x-2">
            <Input
              placeholder={dictionary.searchPlaceholder || "Search community profiles..."}
              value={globalFilter}
              onChange={(event) => setGlobalFilter(event.target.value)}
              className="h-8 w-[150px] lg:w-[250px]"
            />
          </div>
          <div className="flex items-center gap-2">
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="outline" size="sm" className="ml-auto">
                  <ColumnsIcon className="mr-2 h-4 w-4" />
                  {dictionary.columnsText || "Columns"}
                  <ChevronDownIcon className="ml-2 h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-[150px]">
                {table
                  .getAllColumns()
                  .filter((column) => typeof column.accessorFn !== "undefined" && column.getCanHide())
                  .map((column) => {
                    return (
                      <DropdownMenuCheckboxItem
                        key={column.id}
                        className="capitalize"
                        checked={column.getIsVisible()}
                        onCheckedChange={(value) => column.toggleVisibility(!!value)}
                      >
                        {column.id}
                      </DropdownMenuCheckboxItem>
                    )
                  })}
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>

        {/* Table */}
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              {table.getHeaderGroups().map((headerGroup) => (
                <TableRow key={headerGroup.id}>
                  {headerGroup.headers.map((header) => {
                    return (
                      <TableHead key={header.id}>
                        {header.isPlaceholder
                          ? null
                          : flexRender(header.column.columnDef.header, header.getContext())}
                      </TableHead>
                    )
                  })}
                </TableRow>
              ))}
            </TableHeader>
            <TableBody>
              {table.getRowModel().rows?.length ? (
                table.getRowModel().rows.map((row) => (
                  <TableRow
                    key={row.id}
                    data-state={row.getIsSelected() && "selected"}
                    className="hover:bg-muted/50"
                  >
                    {row.getVisibleCells().map((cell) => (
                      <TableCell key={cell.id} onClick={(e) => {
                        if (cell.column.id === 'actions' || cell.column.id === 'select') {
                          e.stopPropagation()
                        }
                      }}>
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={columns.length} className="h-24 text-center">
                    {dictionary.noDataText || "No community profiles found."}
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between px-2">
          <div className="flex-1 text-sm text-muted-foreground">
            {table.getFilteredSelectedRowModel().rows.length} of{" "}
            {table.getFilteredRowModel().rows.length} {dictionary.pagination?.selected || "row(s) selected."}
          </div>
          <div className="flex items-center space-x-6 lg:space-x-8">
            <div className="flex items-center space-x-2">
              <p className="text-sm font-medium">{dictionary.pagination?.rowsPerPage || "Rows per page"}</p>
              <Select
                value={`${table.getState().pagination.pageSize}`}
                onValueChange={(value) => {
                  table.setPageSize(Number(value))
                }}
              >
                <SelectTrigger className="h-8 w-[70px]">
                  <SelectValue placeholder={table.getState().pagination.pageSize} />
                </SelectTrigger>
                <SelectContent side="top">
                  {[10, 20, 30, 40, 50].map((pageSize) => (
                    <SelectItem key={pageSize} value={`${pageSize}`}>
                      {pageSize}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex w-[100px] items-center justify-center text-sm font-medium">
              {dictionary.pagination?.page || "Page"} {table.getState().pagination.pageIndex + 1} {dictionary.pagination?.of || "of"}{" "}
              {table.getPageCount()}
            </div>
            <div className="flex items-center space-x-2">
              <Button
                variant="outline"
                className="hidden h-8 w-8 p-0 lg:flex"
                onClick={() => table.setPageIndex(0)}
                disabled={!table.getCanPreviousPage()}
              >
                <span className="sr-only">Go to first page</span>
                <ChevronsLeftIcon className="h-4 w-4" />
              </Button>
              <Button
                variant="outline"
                className="h-8 w-8 p-0"
                onClick={() => table.previousPage()}
                disabled={!table.getCanPreviousPage()}
              >
                <span className="sr-only">Go to previous page</span>
                <ChevronLeftIcon className="h-4 w-4" />
              </Button>
              <Button
                variant="outline"
                className="h-8 w-8 p-0"
                onClick={() => table.nextPage()}
                disabled={!table.getCanNextPage()}
              >
                <span className="sr-only">Go to next page</span>
                <ChevronRightIcon className="h-4 w-4" />
              </Button>
              <Button
                variant="outline"
                className="hidden h-8 w-8 p-0 lg:flex"
                onClick={() => table.setPageIndex(table.getPageCount() - 1)}
                disabled={!table.getCanNextPage()}
              >
                <span className="sr-only">Go to last page</span>
                <ChevronsRightIcon className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
