"use client";

import {
  useState,
  useMemo,
  useCallback,
  useEffect,
  useRef,
  useLayoutEffect,
} from "react";
import { useTranslation } from "@/contexts/TranslationContext";
import {
  collection,
  query,
  orderBy,
  limit as queryLimit,
  startAfter,
  doc,
  updateDoc,
  QueryDocumentSnapshot,
  DocumentData,
  where,
  getCountFromServer,
  QueryConstraint,
} from "firebase/firestore";
import { useCollection } from "react-firebase-hooks/firestore";
import { db } from "@/lib/firebase";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  MessageSquare,
  Eye,
  EyeOff,
  Trash2,
  CheckCircle,
  MoreHorizontal,
  Flag,
  Users,
  ChevronLeft,
  ChevronRight,
  Loader2,
  RefreshCw,
} from "lucide-react";
import { format } from "date-fns";
import { toast } from "sonner";

interface GroupMessage {
  id: string;
  groupId: string;
  senderCpId: string;
  body: string;
  replyToMessageId?: string;
  isDeleted: boolean;
  isHidden: boolean;
  moderation: {
    status: "pending" | "approved" | "blocked" | "manual_review";
    reason?: string;
    ai?: {
      reason: string;
      violationType?: string;
      severity?: "low" | "medium" | "high";
      confidence?: number;
      detectedContent?: string[];
      culturalContext?: string | null;
    };
    finalDecision?: {
      action: string;
      reason: string;
      violationType?: string | null;
      confidence: number;
    };
  };
  createdAt: any;
}

interface MessagesTableProps {
  groupFilter?: string;
  statusFilter?: string;
  searchQuery?: string;
  groups: Array<{ id: string; name: string }>;
  reports: Array<{ relatedContent?: { contentId: string } }>;
  onBulkAction?: (
    selectedIds: string[],
    action: "approve" | "hide" | "delete",
    reason?: string
  ) => Promise<void>;
  onMessageModeration?: (
    messageId: string,
    action: "approve" | "block" | "hide" | "delete" | "unhide",
    reason?: string,
    violationType?: string
  ) => Promise<boolean>;
  onStatsUpdate?: (stats: MessageStats) => void;
  locale?: string;
}

export interface MessageStats {
  total: number;
  pending: number;
  approved: number;
  blocked: number;
  manual_review: number;
  reported: number;
  hidden: number;
  deleted: number;
  currentPage: number;
  totalPages: number;
  itemsShown: number;
}

const PAGE_SIZE = 20;

export function MessagesTable({
  groupFilter = "all",
  statusFilter = "all",
  searchQuery = "",
  groups = [],
  reports = [],
  onBulkAction,
  onMessageModeration,
  onStatsUpdate,
  locale = "en",
}: MessagesTableProps) {
  const { t } = useTranslation();
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(PAGE_SIZE);
  const [cursors, setCursors] = useState<QueryDocumentSnapshot<DocumentData>[]>(
    []
  );

  // Bulk action dialog state
  const [showBulkDialog, setShowBulkDialog] = useState(false);
  const [bulkAction, setBulkAction] = useState<"approve" | "hide" | "delete">(
    "approve"
  );
  const [bulkReason, setBulkReason] = useState("");
  const [isProcessingBulk, setIsProcessingBulk] = useState(false);

  // Message detail dialog state
  const [selectedMessage, setSelectedMessage] = useState<GroupMessage | null>(
    null
  );
  const [showMessageDialog, setShowMessageDialog] = useState(false);
  const [statusToSet, setStatusToSet] = useState<
    "pending" | "approved" | "blocked" | "manual_review"
  >("pending");
  const [isUpdatingStatus, setIsUpdatingStatus] = useState(false);

  // Individual moderation dialog state
  const [showModerationDialog, setShowModerationDialog] = useState(false);
  const [moderationAction, setModerationAction] = useState<
    "approve" | "block" | "hide" | "delete" | "unhide"
  >("block");
  const [moderationReason, setModerationReason] = useState("");
  const [violationType, setViolationType] = useState("");
  const [isProcessingModeration, setIsProcessingModeration] = useState(false);

  // Build the Firestore query with pagination at DB level
  const messagesQuery = useMemo(() => {
    const constraints: QueryConstraint[] = [orderBy("createdAt", "desc")];

    if (groupFilter && groupFilter !== "all") {
      constraints.push(where("groupId", "==", groupFilter));
    }

    if (statusFilter && statusFilter !== "all" && statusFilter !== "reported") {
      constraints.push(where("moderation.status", "==", statusFilter));
    }

    // Add cursor for pagination (after first page)
    const cursor = cursors[currentPage - 2]; // -2 because page 1 has no cursor
    if (cursor && currentPage > 1) {
      constraints.push(startAfter(cursor));
    }

    constraints.push(queryLimit(pageSize + 1)); // +1 to check if there's more

    return query(collection(db, "group_messages"), ...constraints);
  }, [groupFilter, statusFilter, currentPage, pageSize, cursors]);

  // Use react-firebase-hooks for real-time data
  const [messagesSnapshot, loading, error] = useCollection(messagesQuery);

  // Process messages from snapshot
  const { messages, hasNextPage, lastDoc } = useMemo(() => {
    if (!messagesSnapshot) {
      return { messages: [], hasNextPage: false, lastDoc: null };
    }

    let docs = messagesSnapshot.docs;
    const hasMore = docs.length > pageSize;

    // Trim to pageSize if we have more
    if (hasMore) {
      docs = docs.slice(0, pageSize);
    }

    const msgs = docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    })) as GroupMessage[];

    return {
      messages: msgs,
      hasNextPage: hasMore,
      lastDoc: docs.length > 0 ? docs[docs.length - 1] : null,
    };
  }, [messagesSnapshot, pageSize]);

  // Apply client-side filters (search and reported status)
  const filteredMessages = useMemo(() => {
    let result = messages;

    // Search filter (client-side since Firestore doesn't support full-text search)
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      result = result.filter(
        (message) =>
          message.body?.toLowerCase().includes(query) ||
          message.senderCpId?.toLowerCase().includes(query)
      );
    }

    // Reported filter (client-side since it requires joining with reports)
    if (statusFilter === "reported") {
      const reportedIds = new Set(
        reports
          .filter((r) => r.relatedContent?.contentId)
          .map((r) => r.relatedContent!.contentId)
      );
      result = result.filter((message) => reportedIds.has(message.id));
    }

    return result;
  }, [messages, searchQuery, statusFilter, reports]);

  // Groups lookup
  const groupsLookup = useMemo(() => {
    return groups.reduce((acc, group) => {
      acc[group.id] = group;
      return acc;
    }, {} as Record<string, any>);
  }, [groups]);

  // Reported message IDs
  const reportedMessageIds = useMemo(() => {
    return new Set(
      reports
        .filter((report) => report.relatedContent?.contentId)
        .map((report) => report.relatedContent!.contentId)
    );
  }, [reports]);

  // Store callback in ref to avoid infinite loops
  const onStatsUpdateRef = useRef(onStatsUpdate);
  useLayoutEffect(() => {
    onStatsUpdateRef.current = onStatsUpdate;
  }, [onStatsUpdate]);

  // Global stats state
  const [globalStats, setGlobalStats] = useState<MessageStats>({
    total: 0,
    pending: 0,
    approved: 0,
    blocked: 0,
    manual_review: 0,
    reported: 0,
    hidden: 0,
    deleted: 0,
    currentPage: 1,
    totalPages: 1,
    itemsShown: 0,
  });

  // Fetch global stats using aggregation queries (efficient, no full document fetch)
  useEffect(() => {
    const fetchGlobalStats = async () => {
      try {
        const messagesRef = collection(db, "group_messages");

        // Build base constraints for group filter
        const baseConstraints =
          groupFilter && groupFilter !== "all"
            ? [where("groupId", "==", groupFilter)]
            : [];

        // Query counts for each status in parallel
        const [
          totalSnapshot,
          pendingSnapshot,
          approvedSnapshot,
          blockedSnapshot,
          manualReviewSnapshot,
          hiddenSnapshot,
          deletedSnapshot,
        ] = await Promise.all([
          getCountFromServer(query(messagesRef, ...baseConstraints)),
          getCountFromServer(
            query(
              messagesRef,
              ...baseConstraints,
              where("moderation.status", "==", "pending")
            )
          ),
          getCountFromServer(
            query(
              messagesRef,
              ...baseConstraints,
              where("moderation.status", "==", "approved")
            )
          ),
          getCountFromServer(
            query(
              messagesRef,
              ...baseConstraints,
              where("moderation.status", "==", "blocked")
            )
          ),
          getCountFromServer(
            query(
              messagesRef,
              ...baseConstraints,
              where("moderation.status", "==", "manual_review")
            )
          ),
          getCountFromServer(
            query(
              messagesRef,
              ...baseConstraints,
              where("isHidden", "==", true)
            )
          ),
          getCountFromServer(
            query(
              messagesRef,
              ...baseConstraints,
              where("isDeleted", "==", true)
            )
          ),
        ]);

        const total = totalSnapshot.data().count;
        const pending = pendingSnapshot.data().count;
        const approved = approvedSnapshot.data().count;
        const blocked = blockedSnapshot.data().count;
        const manual_review = manualReviewSnapshot.data().count;
        const hidden = hiddenSnapshot.data().count;
        const deleted = deletedSnapshot.data().count;

        // Reported count comes from the reports prop (can't query efficiently)
        const reported = reports.filter(
          (r) => r.relatedContent?.contentId
        ).length;

        setGlobalStats({
          total,
          pending,
          approved,
          blocked,
          manual_review,
          reported,
          hidden,
          deleted,
          currentPage,
          totalPages: Math.max(1, Math.ceil(total / pageSize)),
          itemsShown: filteredMessages.length,
        });
      } catch (error) {
        console.error("Error fetching global stats:", error);
      }
    };

    fetchGlobalStats();
  }, [groupFilter, reports, pageSize]); // Only re-fetch when group filter or reports change

  // Report stats to parent
  useEffect(() => {
    const callback = onStatsUpdateRef.current;
    if (!callback) return;

    callback({
      ...globalStats,
      currentPage,
      itemsShown: filteredMessages.length,
    });
  }, [globalStats, currentPage, filteredMessages.length]);

  // Pagination handlers
  const handleNextPage = useCallback(() => {
    if (hasNextPage && lastDoc) {
      setCursors((prev) => {
        const newCursors = [...prev];
        newCursors[currentPage - 1] = lastDoc;
        return newCursors;
      });
      setCurrentPage((prev) => prev + 1);
      setSelectedIds([]);
    }
  }, [hasNextPage, lastDoc, currentPage]);

  const handlePrevPage = useCallback(() => {
    if (currentPage > 1) {
      setCurrentPage((prev) => prev - 1);
      setSelectedIds([]);
    }
  }, [currentPage]);

  // Reset pagination when filters change
  const handlePageSizeChange = useCallback((newSize: number) => {
    setPageSize(newSize);
    setCurrentPage(1);
    setCursors([]);
    setSelectedIds([]);
  }, []);

  // Reset pagination when filters change
  const isFirstRender = useRef(true);
  useEffect(() => {
    if (isFirstRender.current) {
      isFirstRender.current = false;
      return;
    }
    setCurrentPage(1);
    setCursors([]);
    setSelectedIds([]);
  }, [groupFilter, statusFilter, searchQuery]);

  // Selection handlers
  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      const moderatableIds = filteredMessages
        .filter((m) => !m.isDeleted)
        .map((m) => m.id);
      setSelectedIds(moderatableIds);
    } else {
      setSelectedIds([]);
    }
  };

  const handleSelectMessage = (messageId: string, checked: boolean) => {
    if (checked) {
      setSelectedIds((prev) => [...prev, messageId]);
    } else {
      setSelectedIds((prev) => prev.filter((id) => id !== messageId));
    }
  };

  // Get moderation badge
  const getModerationBadge = (message: GroupMessage) => {
    const status = message.moderation?.status || "pending";
    const variants = {
      pending: "secondary" as const,
      approved: "default" as const,
      blocked: "destructive" as const,
      manual_review: "secondary" as const,
    };

    return (
      <Badge variant={variants[status]} className="text-xs">
        {t(`modules.admin.content.status.${status}`)}
      </Badge>
    );
  };

  // Handle individual message moderation
  const handleIndividualModeration = (
    message: GroupMessage,
    action: "approve" | "block" | "hide" | "delete" | "unhide"
  ) => {
    setSelectedMessage(message);
    setModerationAction(action);
    setModerationReason("");
    setViolationType("");
    setShowModerationDialog(true);
  };

  const confirmIndividualModeration = async () => {
    if (!selectedMessage || !onMessageModeration) return;

    setIsProcessingModeration(true);
    try {
      const success = await onMessageModeration(
        selectedMessage.id,
        moderationAction,
        moderationReason || undefined,
        violationType || undefined
      );

      if (success) {
        const actionKey = `message${
          moderationAction.charAt(0).toUpperCase() + moderationAction.slice(1)
        }ed`;
        toast.success(t(`modules.admin.content.${actionKey}`));
        setShowModerationDialog(false);
        setModerationReason("");
        setViolationType("");
      } else {
        toast.error(t("modules.admin.content.moderationError"));
      }
    } catch (error) {
      console.error("Error moderating message:", error);
      toast.error(t("modules.admin.content.moderationError"));
    } finally {
      setIsProcessingModeration(false);
    }
  };

  // Handle bulk actions
  const handleBulkAction = async (action: "approve" | "hide" | "delete") => {
    if (selectedIds.length === 0) {
      toast.error(t("modules.admin.content.bulk.error"));
      return;
    }

    setBulkAction(action);
    setShowBulkDialog(true);
  };

  const confirmBulkAction = async () => {
    if (!onBulkAction) return;

    setIsProcessingBulk(true);
    try {
      await onBulkAction(selectedIds, bulkAction, bulkReason);
      setSelectedIds([]);
      setShowBulkDialog(false);
      setBulkReason("");
      toast.success(
        t("modules.admin.content.bulk.success", { count: selectedIds.length })
      );
    } catch (error) {
      toast.error(t("modules.admin.content.bulk.error"));
    } finally {
      setIsProcessingBulk(false);
    }
  };

  const moderatableCount = filteredMessages.filter((m) => !m.isDeleted).length;
  const allModeratable =
    selectedIds.length > 0 && selectedIds.length === moderatableCount;
  const someSelected =
    selectedIds.length > 0 && selectedIds.length < moderatableCount;

  return (
    <div className="space-y-4">
      {/* Bulk Actions Toolbar */}
      {selectedIds.length > 0 && (
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <span className="text-sm font-medium">
                  {t("modules.admin.content.bulk.selected", {
                    count: selectedIds.length,
                  })}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setSelectedIds([])}
                >
                  {t("modules.admin.content.bulk.clearSelection")}
                </Button>
              </div>
              <div className="flex items-center gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkAction("approve")}
                >
                  <CheckCircle className="h-4 w-4 mr-2" />
                  {t("modules.admin.content.actions.approve")}
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkAction("hide")}
                >
                  <EyeOff className="h-4 w-4 mr-2" />
                  {t("modules.admin.content.actions.hide")}
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={() => handleBulkAction("delete")}
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  {t("modules.admin.content.actions.delete")}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Messages Table */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>
            {t("modules.admin.content.messages.title")}
            {!loading && ` (${filteredMessages.length} ${t("common.shown")})`}
          </CardTitle>
          <Button
            variant="outline"
            size="sm"
            onClick={() => {
              setCurrentPage(1);
              setCursors([]);
            }}
            disabled={loading}
          >
            <RefreshCw
              className={`h-4 w-4 mr-2 ${loading ? "animate-spin" : ""}`}
            />
            {t("common.refresh") || "Refresh"}
          </Button>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="h-8 w-8 animate-spin" />
            </div>
          ) : error ? (
            <div className="text-center py-8 text-destructive">
              {t("modules.admin.content.loadError")}
            </div>
          ) : filteredMessages.length === 0 ? (
            <div className="text-center py-8">
              <MessageSquare className="mx-auto h-12 w-12 text-muted-foreground/50" />
              <h3 className="mt-4 text-lg font-semibold">
                {t("modules.admin.content.noMessages")}
              </h3>
              <p className="text-muted-foreground">
                {t("modules.admin.content.tryDifferentFilters")}
              </p>
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[50px]">
                      <Checkbox
                        checked={
                          allModeratable
                            ? true
                            : someSelected
                            ? "indeterminate"
                            : false
                        }
                        onCheckedChange={handleSelectAll}
                      />
                    </TableHead>
                    <TableHead>
                      {t("modules.admin.content.messageDetails.sender")}
                    </TableHead>
                    <TableHead>
                      {t("modules.admin.content.messageDetails.content")}
                    </TableHead>
                    <TableHead>{t("common.group")}</TableHead>
                    <TableHead>
                      {t("modules.admin.content.messageDetails.status")}
                    </TableHead>
                    <TableHead>
                      {t("modules.admin.content.messageDetails.created")}
                    </TableHead>
                    <TableHead className="w-[100px]">
                      {t("common.actions")}
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredMessages.map((message) => {
                    const group = groupsLookup[message.groupId];
                    const isReported = reportedMessageIds.has(message.id);
                    const canModerate = !message.isDeleted;

                    return (
                      <TableRow
                        key={message.id}
                        className="cursor-pointer"
                        onClick={() => {
                          setSelectedMessage(message);
                          setStatusToSet(
                            message.moderation?.status || "pending"
                          );
                          setShowMessageDialog(true);
                        }}
                      >
                        <TableCell>
                          {canModerate && (
                            <Checkbox
                              checked={selectedIds.includes(message.id)}
                              onCheckedChange={(checked) =>
                                handleSelectMessage(
                                  message.id,
                                  checked as boolean
                                )
                              }
                              onClick={(e) => e.stopPropagation()}
                            />
                          )}
                        </TableCell>
                        <TableCell className="font-medium">
                          {message.senderCpId}
                        </TableCell>
                        <TableCell className="max-w-[300px]">
                          {message.isDeleted ? (
                            <span className="text-muted-foreground italic">
                              {t("modules.admin.content.messageDeleted")}
                            </span>
                          ) : (
                            <div className="space-y-1">
                              {message.isHidden && (
                                <Badge
                                  variant="outline"
                                  className="text-xs text-orange-600 border-orange-600"
                                >
                                  {t("modules.admin.content.messageHidden")}
                                </Badge>
                              )}
                              <div
                                className={`truncate ${
                                  message.isHidden
                                    ? "text-muted-foreground"
                                    : ""
                                }`}
                                title={message.body}
                              >
                                {message.body}
                              </div>
                            </div>
                          )}
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline" className="text-xs">
                            <Users className="h-3 w-3 mr-1" />
                            {group?.name || message.groupId}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            {getModerationBadge(message)}
                            {isReported && (
                              <Badge
                                variant="outline"
                                className="text-xs text-orange-600 border-orange-600"
                              >
                                <Flag className="h-3 w-3 mr-1" />
                                {t("modules.admin.content.status.reported")}
                              </Badge>
                            )}
                          </div>
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {format(message.createdAt, "MMM dd, yyyy HH:mm")}
                        </TableCell>
                        <TableCell>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button
                                variant="ghost"
                                className="h-8 w-8 p-0"
                                onClick={(e) => e.stopPropagation()}
                              >
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent
                              align="end"
                              onClick={(e) => e.stopPropagation()}
                            >
                              <DropdownMenuItem
                                onClick={() => {
                                  setSelectedMessage(message);
                                  setStatusToSet(
                                    message.moderation?.status || "pending"
                                  );
                                  setShowMessageDialog(true);
                                }}
                              >
                                <Eye className="mr-2 h-4 w-4" />
                                {t("modules.admin.content.actions.viewDetails")}
                              </DropdownMenuItem>

                              {onMessageModeration && (
                                <>
                                  <DropdownMenuItem
                                    onClick={() =>
                                      handleIndividualModeration(
                                        message,
                                        "approve"
                                      )
                                    }
                                  >
                                    <CheckCircle className="mr-2 h-4 w-4" />
                                    {t("modules.admin.content.approveMessage")}
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={() =>
                                      handleIndividualModeration(
                                        message,
                                        "block"
                                      )
                                    }
                                  >
                                    <Flag className="mr-2 h-4 w-4" />
                                    {t("modules.admin.content.blockMessage")}
                                  </DropdownMenuItem>
                                  {message.isHidden ? (
                                    <DropdownMenuItem
                                      onClick={() =>
                                        handleIndividualModeration(
                                          message,
                                          "unhide"
                                        )
                                      }
                                    >
                                      <Eye className="mr-2 h-4 w-4" />
                                      {t("modules.admin.content.unhideMessage")}
                                    </DropdownMenuItem>
                                  ) : (
                                    <DropdownMenuItem
                                      onClick={() =>
                                        handleIndividualModeration(
                                          message,
                                          "hide"
                                        )
                                      }
                                    >
                                      <EyeOff className="mr-2 h-4 w-4" />
                                      {t("modules.admin.content.hideMessage")}
                                    </DropdownMenuItem>
                                  )}
                                  <DropdownMenuItem
                                    onClick={() =>
                                      handleIndividualModeration(
                                        message,
                                        "delete"
                                      )
                                    }
                                    className="text-destructive"
                                  >
                                    <Trash2 className="mr-2 h-4 w-4" />
                                    {t("modules.admin.content.deleteMessage")}
                                  </DropdownMenuItem>
                                </>
                              )}
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>

              {/* Pagination */}
              <div className="flex items-center justify-between pt-4">
                <div className="text-sm text-muted-foreground">
                  {filteredMessages.length > 0 ? (
                    <>
                      {t("common.showing")} {filteredMessages.length}{" "}
                      {t("common.items")} • {t("common.page")} {currentPage}
                    </>
                  ) : (
                    t("common.noItemsFound")
                  )}
                </div>
                <div className="flex items-center gap-4">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">
                      {t("common.rowsPerPage") || "Rows per page"}
                    </span>
                    <Select
                      value={`${pageSize}`}
                      onValueChange={(value) =>
                        handlePageSizeChange(Number(value))
                      }
                    >
                      <SelectTrigger className="h-8 w-[70px]">
                        <SelectValue placeholder={pageSize} />
                      </SelectTrigger>
                      <SelectContent side="top">
                        {[10, 20, 30, 50, 100].map((size) => (
                          <SelectItem key={size} value={`${size}`}>
                            {size}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handlePrevPage}
                      disabled={currentPage === 1 || loading}
                    >
                      <ChevronLeft className="h-4 w-4 mr-2" />
                      {t("common.previous")}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handleNextPage}
                      disabled={!hasNextPage || loading}
                    >
                      {t("common.next")}
                      <ChevronRight className="h-4 w-4 ml-2" />
                    </Button>
                  </div>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Bulk Action Dialog */}
      <Dialog open={showBulkDialog} onOpenChange={setShowBulkDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {bulkAction === "approve" &&
                t("modules.admin.content.bulk.approveTitle")}
              {bulkAction === "hide" &&
                t("modules.admin.content.bulk.hideTitle")}
              {bulkAction === "delete" &&
                t("modules.admin.content.bulk.deleteTitle")}
            </DialogTitle>
            <DialogDescription>
              {t("modules.admin.content.bulk.confirmAction", {
                count: selectedIds.length,
                action: t(
                  `modules.admin.content.actions.${bulkAction}`
                ).toLowerCase(),
              })}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="bulk-reason">
                {t("modules.admin.content.moderation.reason")}
              </Label>
              <Textarea
                id="bulk-reason"
                placeholder={t(
                  "modules.admin.content.moderation.reasonPlaceholder"
                )}
                value={bulkReason}
                onChange={(e) => setBulkReason(e.target.value)}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setShowBulkDialog(false)}>
              {t("common.cancel")}
            </Button>
            <Button
              onClick={confirmBulkAction}
              disabled={isProcessingBulk}
              variant={bulkAction === "delete" ? "destructive" : "default"}
            >
              {isProcessingBulk
                ? t("modules.admin.content.bulk.processing")
                : t("modules.admin.content.bulk.confirm", {
                    action: t(`modules.admin.content.actions.${bulkAction}`),
                  })}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Message Detail Dialog */}
      {selectedMessage && (
        <Dialog open={showMessageDialog} onOpenChange={setShowMessageDialog}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>
                {t("modules.admin.content.messageDetails.title")}
              </DialogTitle>
              <DialogDescription>
                {t("modules.admin.content.messageDetails.description")}
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label className="text-sm font-medium">
                    {t("modules.admin.content.messageDetails.sender")}
                  </Label>
                  <p className="text-sm text-muted-foreground">
                    {selectedMessage.senderCpId}
                  </p>
                </div>
                <div>
                  <Label className="text-sm font-medium">
                    {t("modules.admin.content.messageDetails.created")}
                  </Label>
                  <p className="text-sm text-muted-foreground">
                    {format(selectedMessage.createdAt, "MMM dd, yyyy HH:mm")}
                  </p>
                </div>
              </div>

              <div>
                <Label className="text-sm font-medium">
                  {t("modules.admin.content.messageDetails.content")}
                </Label>
                <div className="mt-1 p-3 bg-muted rounded-md">
                  <p className="text-sm whitespace-pre-wrap">
                    {selectedMessage.body}
                  </p>
                </div>
              </div>

              <div>
                <Label className="text-sm font-medium">
                  {t("modules.admin.content.messageDetails.status")}
                </Label>
                <div className="mt-1">
                  {getModerationBadge(selectedMessage)}
                </div>
              </div>

              {/* AI Justification */}
              {selectedMessage.moderation?.ai && (
                <div className="space-y-2">
                  <Label className="text-sm font-medium">
                    {t(
                      "modules.admin.content.messageDetails.aiJustification"
                    ) || "AI Justification"}
                  </Label>
                  <div className="p-3 bg-muted rounded-md text-sm space-y-1">
                    <p>
                      <strong>{t("common.reason") || "Reason"}:</strong>{" "}
                      {selectedMessage.moderation.ai.reason}
                    </p>
                    {selectedMessage.moderation.ai.violationType && (
                      <p>
                        <strong>
                          {t("modules.admin.content.violationType") ||
                            "Violation"}
                          :
                        </strong>{" "}
                        {selectedMessage.moderation.ai.violationType}
                      </p>
                    )}
                    {typeof selectedMessage.moderation.ai.confidence ===
                      "number" && (
                      <p>
                        <strong>
                          {t("common.confidence") || "Confidence"}:
                        </strong>{" "}
                        {Math.round(
                          (selectedMessage.moderation.ai.confidence || 0) * 100
                        )}
                        %
                      </p>
                    )}
                    {selectedMessage.moderation.ai.severity && (
                      <p>
                        <strong>{t("common.severity") || "Severity"}:</strong>{" "}
                        {selectedMessage.moderation.ai.severity}
                      </p>
                    )}
                    {selectedMessage.moderation.ai.detectedContent &&
                      selectedMessage.moderation.ai.detectedContent.length >
                        0 && (
                        <div>
                          <p>
                            <strong>
                              {t("modules.admin.content.detectedContent") ||
                                "Detected Content"}
                              :
                            </strong>
                          </p>
                          <ul className="list-disc list-inside">
                            {selectedMessage.moderation.ai.detectedContent.map(
                              (c, idx) => (
                                <li key={idx}>{c}</li>
                              )
                            )}
                          </ul>
                        </div>
                      )}
                    {selectedMessage.moderation.ai.culturalContext && (
                      <p>
                        <strong>
                          {t("modules.admin.content.culturalContext") ||
                            "Cultural Context"}
                          :
                        </strong>{" "}
                        {selectedMessage.moderation.ai.culturalContext}
                      </p>
                    )}
                  </div>
                </div>
              )}

              {/* Change Status */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">
                  {t("modules.admin.content.updateStatus") || "Update Status"}
                </Label>
                <div className="flex gap-2 items-center">
                  <Select
                    value={statusToSet}
                    onValueChange={(v) => setStatusToSet(v as any)}
                  >
                    <SelectTrigger className="w-56">
                      <SelectValue
                        placeholder={
                          t("modules.admin.content.selectStatus") ||
                          "Select status"
                        }
                      />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pending">
                        {t("modules.admin.content.status.pending")}
                      </SelectItem>
                      <SelectItem value="approved">
                        {t("modules.admin.content.status.approved")}
                      </SelectItem>
                      <SelectItem value="manual_review">
                        {t("modules.admin.content.status.manual_review")}
                      </SelectItem>
                      <SelectItem value="blocked">
                        {t("modules.admin.content.status.blocked")}
                      </SelectItem>
                    </SelectContent>
                  </Select>
                  <Button
                    onClick={async () => {
                      if (!selectedMessage) return;
                      setIsUpdatingStatus(true);
                      try {
                        const ref = doc(
                          db,
                          "group_messages",
                          selectedMessage.id
                        );
                        await updateDoc(ref, {
                          "moderation.status": statusToSet,
                        });
                        toast.success(
                          t("modules.admin.content.statusUpdated") ||
                            "Status updated"
                        );
                        setSelectedMessage({
                          ...selectedMessage,
                          moderation: {
                            ...selectedMessage.moderation,
                            status: statusToSet,
                          },
                        });
                      } catch (e) {
                        console.error("Failed to update status", e);
                        toast.error(
                          t("modules.admin.content.statusUpdateFailed") ||
                            "Failed to update status"
                        );
                      } finally {
                        setIsUpdatingStatus(false);
                      }
                    }}
                    disabled={isUpdatingStatus}
                  >
                    {isUpdatingStatus
                      ? t("common.updating")
                      : t("modules.admin.content.updateStatus")}
                  </Button>
                </div>
              </div>
            </div>

            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => setShowMessageDialog(false)}
              >
                {t("common.close")}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Individual Message Moderation Dialog */}
      {selectedMessage && (
        <Dialog
          open={showModerationDialog}
          onOpenChange={setShowModerationDialog}
        >
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>
                {t("modules.admin.content.moderateMessage")}
              </DialogTitle>
              <DialogDescription>
                {t(`modules.admin.content.${moderationAction}Confirm`)}
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4">
              {/* Message Content */}
              <div>
                <Label className="text-sm font-medium">
                  {t("modules.admin.content.messageDetails.content")}
                </Label>
                <div className="mt-1 p-3 bg-muted rounded-md">
                  <p className="text-sm whitespace-pre-wrap">
                    {selectedMessage.body}
                  </p>
                </div>
              </div>

              {/* Violation Type Selection (for block action) */}
              {moderationAction === "block" && (
                <div className="space-y-2">
                  <Label htmlFor="violation-type">
                    {t("modules.admin.content.violationType")}
                  </Label>
                  <Select
                    value={violationType}
                    onValueChange={setViolationType}
                  >
                    <SelectTrigger>
                      <SelectValue
                        placeholder={t(
                          "modules.admin.content.selectViolationType"
                        )}
                      />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="social_media_sharing">
                        {t(
                          "modules.admin.content.violationTypes.social_media_sharing"
                        )}
                      </SelectItem>
                      <SelectItem value="sexual_content">
                        {t(
                          "modules.admin.content.violationTypes.sexual_content"
                        )}
                      </SelectItem>
                      <SelectItem value="cuckoldry_content">
                        {t(
                          "modules.admin.content.violationTypes.cuckoldry_content"
                        )}
                      </SelectItem>
                      <SelectItem value="homosexuality_content">
                        {t(
                          "modules.admin.content.violationTypes.homosexuality_content"
                        )}
                      </SelectItem>
                      <SelectItem value="inappropriate_content">
                        {t(
                          "modules.admin.content.violationTypes.inappropriate_content"
                        )}
                      </SelectItem>
                      <SelectItem value="spam">
                        {t("modules.admin.content.violationTypes.spam")}
                      </SelectItem>
                      <SelectItem value="harassment">
                        {t("modules.admin.content.violationTypes.harassment")}
                      </SelectItem>
                      <SelectItem value="other">
                        {t("modules.admin.content.violationTypes.other")}
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              )}

              {/* Moderation Reason */}
              <div className="space-y-2">
                <Label htmlFor="moderation-reason">
                  {t("modules.admin.content.moderationReason")}
                </Label>
                <Textarea
                  id="moderation-reason"
                  placeholder={t(
                    "modules.admin.content.moderationReasonPlaceholder"
                  )}
                  value={moderationReason}
                  onChange={(e) => setModerationReason(e.target.value)}
                />
              </div>
            </div>

            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => setShowModerationDialog(false)}
              >
                {t("common.cancel")}
              </Button>
              <Button
                onClick={confirmIndividualModeration}
                disabled={isProcessingModeration}
                variant={
                  moderationAction === "delete" ? "destructive" : "default"
                }
              >
                {isProcessingModeration ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    {t("modules.admin.content.processing")}
                  </>
                ) : (
                  t(`modules.admin.content.${moderationAction}Message`)
                )}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
}
