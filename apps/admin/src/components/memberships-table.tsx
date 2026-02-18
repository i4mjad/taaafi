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
import { MembershipDetailsModal } from "@/components/membership-details-modal"

interface MembershipData {
  id: string
  cpId: string
  groupId: string
  groupName: string
  role: 'admin' | 'member'
  isActive: boolean
  joinedAt: Date
  leftAt?: Date
  pointsTotal?: number
}

interface MembershipsTableProps {
  data: MembershipData[]
  groups: any[]
  dictionary: any
  lang: string
}

const getColumns = (
  dictionary: any,
  lang: string,
  groups: any[],
  onViewDetails: (membership: MembershipData) => void,
  onRemoveMember: (membership: MembershipData) => void
): ColumnDef<MembershipData>[] => [
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
    accessorKey: "cpId",
    header: dictionary.headers?.userId || "User ID",
    cell: ({ row }) => (
      <div className="font-mono text-sm">
        {row.original.cpId}
      </div>
    ),
    enableHiding: false,
  },
  {
    accessorKey: "groupName",
    header: dictionary.headers?.groupName || "Group",
    cell: ({ row }) => (
      <div className="flex items-center gap-2">
        <Users className="h-4 w-4 text-muted-foreground" />
        <span className="font-medium">{row.original.groupName}</span>
      </div>
    ),
  },
  {
    accessorKey: "role",
    header: dictionary.headers?.role || "Role",
    cell: ({ row }) => (
      <Badge variant={row.original.role === 'admin' ? 'default' : 'secondary'} className="flex items-center gap-1">
        {row.original.role === 'admin' && <Crown className="h-3 w-3" />}
        {row.original.role === 'admin' ? (dictionary.roleLabels?.admin || 'Admin') : (dictionary.roleLabels?.member || 'Member')}
      </Badge>
    ),
  },
  {
    accessorKey: "isActive",
    header: dictionary.headers?.status || "Status",
    cell: ({ row }) => (
      <Badge variant={row.original.isActive ? 'default' : 'secondary'}>
        {row.original.isActive ? (dictionary.statusLabels?.active || 'Active') : (dictionary.statusLabels?.inactive || 'Inactive')}
      </Badge>
    ),
  },
  {
    accessorKey: "joinedAt",
    header: dictionary.headers?.joinedAt || "Joined",
    cell: ({ row }) => (
      <div className="flex items-center gap-2 text-sm text-muted-foreground">
        <Calendar className="h-4 w-4" />
        {format(row.original.joinedAt, 'MMM dd, yyyy')}
      </div>
    ),
  },
  {
    accessorKey: "pointsTotal",
    header: dictionary.headers?.points || "Points",
    cell: ({ row }) => (
      <div className="flex items-center gap-2 text-sm">
        <Trophy className="h-4 w-4 text-muted-foreground" />
        {row.original.pointsTotal || 0}
      </div>
    ),
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="flex size-8 text-muted-foreground data-[state=open]:bg-muted" size="icon">
            <MoreVerticalIcon className="h-4 w-4" />
            <span className="sr-only">Open menu</span>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align={lang === "ar" ? "start" : "end"} className="w-48">
          <DropdownMenuItem onClick={() => onViewDetails(row.original)}>
            <Eye className="mr-2 h-4 w-4" />
            {dictionary.actions?.viewDetails || 'View Details'}
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem 
            onClick={() => window.location.href = `/community/groups/${row.original.groupId}/admin`}
          >
            <Crown className="mr-2 h-4 w-4" />
            {dictionary.actions?.manageGroup || 'Manage Group'}
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem 
            onClick={() => onRemoveMember(row.original)}
            className="text-red-600 focus:text-red-600"
          >
            <UserMinus className="mr-2 h-4 w-4" />
            {dictionary.actions?.removeMember || 'Remove Member'}
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
]

export function MembershipsTable({ data, groups, dictionary, lang }: MembershipsTableProps) {
  const [rowSelection, setRowSelection] = React.useState({})
  const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>({})
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([])
  const [sorting, setSorting] = React.useState<SortingState>([])
  const [globalFilter, setGlobalFilter] = React.useState("")
  const [selectedMembership, setSelectedMembership] = React.useState<MembershipData | null>(null)
  const [showDetailsModal, setShowDetailsModal] = React.useState(false)
  const [pagination, setPagination] = React.useState({
    pageIndex: 0,
    pageSize: 10,
  })

  const columns = React.useMemo(() => getColumns(
    dictionary, 
    lang, 
    groups, 
    (membership) => {
      setSelectedMembership(membership)
      setShowDetailsModal(true)
    },
    (membership) => {
      // Navigate to the specific group detail page for removal
      window.location.href = `/groups-management/${membership.groupId}`;
    }
  ), [dictionary, lang, groups])

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

  const selectedGroup = groups.find(g => g.id === selectedMembership?.groupId)

  return (
    <>
      <div className="space-y-4">
        {/* Table Controls */}
        <div className="flex items-center justify-between">
          <div className="flex flex-1 items-center space-x-2">
            <Input
              placeholder={dictionary.searchPlaceholder || "Search memberships..."}
              value={globalFilter}
              onChange={(event) => setGlobalFilter(event.target.value)}
              className="h-8 w-[150px] lg:w-[250px]"
            />
          </div>
          <div className="flex items-center gap-2">
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="outline" size="sm">
                  <ColumnsIcon className="h-4 w-4" />
                  <span className="hidden lg:inline">{dictionary.columnsText || 'Columns'}</span>
                  <ChevronDownIcon className="h-4 w-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align={lang === "ar" ? "start" : "end"} className="w-56">
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
                      <TableHead key={header.id} colSpan={header.colSpan}>
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
                    className="cursor-pointer hover:bg-muted/50"
                    onClick={() => {
                      setSelectedMembership(row.original)
                      setShowDetailsModal(true)
                    }}
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
                    {dictionary.noDataText || 'No memberships found.'}
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between px-2">
          <div className="flex-1 text-sm text-muted-foreground">
            {table.getFilteredSelectedRowModel().rows.length} {dictionary.pagination?.of || 'of'}{" "}
            {table.getFilteredRowModel().rows.length} {dictionary.pagination?.selected || 'row(s) selected.'}
          </div>
          <div className="flex items-center space-x-6 lg:space-x-8">
            <div className="flex items-center space-x-2">
              <p className="text-sm font-medium">{dictionary.pagination?.rowsPerPage || 'Rows per page'}</p>
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
              {dictionary.pagination?.page || 'Page'} {table.getState().pagination.pageIndex + 1} {dictionary.pagination?.of || 'of'}{" "}
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

      {/* Details Modal */}
      <MembershipDetailsModal
        membership={selectedMembership}
        group={selectedGroup}
        open={showDetailsModal}
        onOpenChange={setShowDetailsModal}
      />

    </>
  )
}
