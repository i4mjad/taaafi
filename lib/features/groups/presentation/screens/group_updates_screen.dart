import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';

/// Model for update items in the group with date for grouping
class GroupUpdateItemWithDate {
  final String id;
  final String title;
  final String time;
  final DateTime date;
  final IconData? icon;
  final Color iconColor;

  const GroupUpdateItemWithDate({
    required this.id,
    required this.title,
    required this.time,
    required this.date,
    this.icon,
    required this.iconColor,
  });
}

class GroupUpdatesScreen extends ConsumerWidget {
  const GroupUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final updates = _getDemoUpdatesWithDates();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "group-updates", false, true),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GroupedListView<GroupUpdateItemWithDate, DateTime>(
          elements: updates,
          groupBy: (update) => DateTime(
            update.date.year,
            update.date.month,
            update.date.day,
          ), // Group by day only
          useStickyGroupSeparators: true,
          groupSeparatorBuilder: (DateTime date) => Container(
            color: theme.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                getDisplayDate(date, locale!.languageCode),
                style: TextStyles.footnoteSelected
                    .copyWith(color: theme.grey[900]),
              ),
            ),
          ),
          itemBuilder: (context, update) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildUpdateItem(context, theme, update),
          ),
          order: GroupedListOrder.DESC, // Show newest first
        ),
      ),
    );
  }

  Widget _buildUpdateItem(
    BuildContext context,
    CustomThemeData theme,
    GroupUpdateItemWithDate update,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.grey[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.grey[100]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        textDirection: TextDirection.rtl, // RTL layout for Arabic
        children: [
          // Time (rightmost in RTL)
          Text(
            update.time,
            style: TextStyles.caption.copyWith(
              color: theme.grey[500],
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 12),

          // User Avatar (middle)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: update.iconColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: update.icon != null
                ? Icon(
                    update.icon,
                    size: 18,
                    color: Colors.white,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // Main text content (leftmost in RTL)
          Expanded(
            child: Text(
              update.title,
              style: TextStyles.body.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  List<GroupUpdateItemWithDate> _getDemoUpdatesWithDates() {
    final now = DateTime.now();
    return [
      // Today's updates
      GroupUpdateItemWithDate(
        id: '1',
        title: 'أكمل صلاة الفجر اليوم ستين يوم بدون إجابة بالورده',
        time: '12:00',
        date: now,
        icon: LucideIcons.check,
        iconColor: Colors.green[400]!,
      ),
      GroupUpdateItemWithDate(
        id: '2',
        title: 'أكمل يوسف يوسف بـ 5 أيام بدون إجابة',
        time: '10:30',
        date: now,
        icon: LucideIcons.calendar,
        iconColor: Colors.orange[400]!,
      ),
      GroupUpdateItemWithDate(
        id: '3',
        title: 'انضم عضو جديد: محمد أحمد إلى المجموعة',
        time: '09:15',
        date: now,
        icon: LucideIcons.userPlus,
        iconColor: Colors.blue[400]!,
      ),

      // Yesterday's updates
      GroupUpdateItemWithDate(
        id: '4',
        title: 'تقدم يوسف يوسف إلى المركز الأول في تحدي 30 يوم بدون إجابة',
        time: '18:45',
        date: now.subtract(const Duration(days: 1)),
        icon: LucideIcons.trophy,
        iconColor: Colors.amber[400]!,
      ),
      GroupUpdateItemWithDate(
        id: '5',
        title: 'أنهى سيف حمد مقام اليوم',
        time: '16:20',
        date: now.subtract(const Duration(days: 1)),
        icon: LucideIcons.checkCircle,
        iconColor: Colors.brown[400]!,
      ),
      GroupUpdateItemWithDate(
        id: '6',
        title: 'تمت مشاركة تحدي جديد: صيام الاثنين والخميس',
        time: '14:00',
        date: now.subtract(const Duration(days: 1)),
        icon: LucideIcons.share,
        iconColor: Colors.purple[400]!,
      ),

      // Two days ago
      GroupUpdateItemWithDate(
        id: '7',
        title: 'أكمل أحمد علي 15 يوم متتالي من صلاة الفجر',
        time: '20:30',
        date: now.subtract(const Duration(days: 2)),
        icon: LucideIcons.sunrise,
        iconColor: Colors.indigo[400]!,
      ),
      GroupUpdateItemWithDate(
        id: '8',
        title: 'تم إنشاء تحدي جماعي جديد: قراءة القرآن',
        time: '15:45',
        date: now.subtract(const Duration(days: 2)),
        icon: LucideIcons.book,
        iconColor: Colors.teal[400]!,
      ),

      // Three days ago
      GroupUpdateItemWithDate(
        id: '9',
        title: 'حصل فريق المجموعة على إنجاز: 100 يوم بدون إجابة',
        time: '11:20',
        date: now.subtract(const Duration(days: 3)),
        icon: LucideIcons.award,
        iconColor: Colors.red[400]!,
      ),
      GroupUpdateItemWithDate(
        id: '10',
        title: 'انضم 3 أعضاء جدد إلى المجموعة اليوم',
        time: '09:00',
        date: now.subtract(const Duration(days: 3)),
        icon: LucideIcons.users,
        iconColor: Colors.cyan[400]!,
      ),

      // A week ago
      GroupUpdateItemWithDate(
        id: '11',
        title: 'تم تحديث إعدادات المجموعة من قبل المدير',
        time: '17:30',
        date: now.subtract(const Duration(days: 7)),
        icon: LucideIcons.settings,
        iconColor: Colors.grey[600]!,
      ),
      GroupUpdateItemWithDate(
        id: '12',
        title: 'بدأ تحدي جماعي: قيام الليل لمدة شهر',
        time: '12:15',
        date: now.subtract(const Duration(days: 7)),
        icon: LucideIcons.moon,
        iconColor: Colors.deepPurple[400]!,
      ),
    ];
  }
}
