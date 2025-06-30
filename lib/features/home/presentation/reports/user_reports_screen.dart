import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/models/user_report.dart';
import 'package:reboot_app_3/features/home/data/user_reports_notifier.dart';

class UserReportsScreen extends ConsumerWidget {
  const UserReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);
    final reportsAsyncValue = ref.watch(userReportsNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'my-reports', false, true),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: reportsAsyncValue.when(
            data: (reports) {
              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.fileText,
                        size: 64,
                        color: theme.grey[400],
                      ),
                      verticalSpace(Spacing.points16),
                      Text(
                        localization.translate('no-reports'),
                        style: TextStyles.h6.copyWith(
                          color: theme.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: reports.length,
                separatorBuilder: (context, index) =>
                    verticalSpace(Spacing.points12),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return ReportCard(report: report);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 64,
                    color: theme.error[600],
                  ),
                  verticalSpace(Spacing.points16),
                  Text(
                    'Error: $error',
                    style: TextStyles.body.copyWith(
                      color: theme.error[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportCard extends ConsumerWidget {
  final UserReport report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localization = AppLocalizations.of(context);

    String statusKey;
    Color statusColor;
    Color borderColor;

    switch (report.status) {
      case ReportStatus.pending:
        statusKey = 'pending';
        statusColor = theme.warn[600]!;
        borderColor = theme.warn[300]!;
        break;
      case ReportStatus.inProgress:
        statusKey = 'in-progress';
        statusColor = theme.primary[600]!;
        borderColor = theme.primary[300]!;
        break;
      case ReportStatus.waitingForAdminResponse:
        statusKey = 'waiting-for-admin-response';
        statusColor = theme.primary[400]!;
        borderColor = theme.primary[200]!;
        break;
      case ReportStatus.closed:
        statusKey = 'closed';
        statusColor = theme.grey[600]!;
        borderColor = theme.grey[300]!;
        break;
      case ReportStatus.finalized:
        statusKey = 'finalized';
        statusColor = theme.success[600]!;
        borderColor = theme.success[300]!;
        break;
    }

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          RouteNames.reportConversation.name,
          pathParameters: {'reportId': report.id},
        );
      },
      child: WidgetsContainer(
        padding: EdgeInsets.all(16),
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(color: borderColor, width: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.messageSquare,
                        size: 16,
                        color: statusColor,
                      ),
                      horizontalSpace(Spacing.points8),
                      Expanded(
                        child: Text(
                          localization.translate('report-data-error'),
                          style: TextStyles.body.copyWith(
                            color: theme.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    localization.translate(statusKey),
                    style: TextStyles.small.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            verticalSpace(Spacing.points12),
            Text(
              report.initialMessage,
              style: TextStyles.body.copyWith(
                color: theme.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            verticalSpace(Spacing.points12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: theme.grey[500],
                    ),
                    horizontalSpace(Spacing.points4),
                    Text(
                      getDisplayDateTime(
                        report.lastUpdated,
                        localization.locale.languageCode,
                      ),
                      style: TextStyles.small.copyWith(
                        color: theme.grey[500],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      size: 14,
                      color: theme.grey[500],
                    ),
                    horizontalSpace(Spacing.points4),
                    Text(
                      '${report.messagesCount} ${localization.translate("messages-count").toLowerCase()}',
                      style: TextStyles.small.copyWith(
                        color: theme.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
