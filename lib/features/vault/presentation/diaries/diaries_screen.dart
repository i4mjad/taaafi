import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';

class DiariesScreen extends ConsumerStatefulWidget {
  const DiariesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DiariesScreenState();
}

class _DiariesScreenState extends ConsumerState<DiariesScreen> {
  final searchController = TextEditingController();
  List<Diary> filteredDiaryEntries = [];

  @override
  void initState() {
    super.initState();
    // Initially, show all diary entries
    filteredDiaryEntries = diaryEntries;

    // Add listener to searchController to filter the list
    searchController.addListener(_filterDiaries);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterDiaries);
    searchController.dispose();
    super.dispose();
  }

  void _filterDiaries() {
    final query = searchController.text.toLowerCase();
    setState(() {
      // Filter the list based on the search query
      filteredDiaryEntries = diaryEntries.where((diary) {
        return diary.title.toLowerCase().contains(query) ||
            diary.body.toLowerCase().contains(query);
      }).toList();
    });
  }

  final List<Diary> diaryEntries = [
    Diary(
        "خطة عطلة نهاية الأسبوع",
        "استمتعت بيوم مريح على الشاطئ مع الأصدقاء. قضينا الوقت في السباحة والاستمتاع بأشعة الشمس. كانت هذه فرصة مثالية للابتعاد عن ضغوط العمل والاسترخاء التام. تناولنا وجبة غداء لذيذة في أحد المطاعم القريبة وتحدثنا عن خططنا للأيام القادمة.",
        DateTime.parse("2024-08-20 10:09:49.972123"),
        ["تمرين", "عمل", "قراءة"]),
    Diary(
        "ملخص يوم العمل",
        "أعددت خطة للأنشطة القادمة في عطلة نهاية الأسبوع. عقدنا اجتماعاً طويلاً ولكن مثمراً حيث ناقشنا الأهداف الرئيسية للفريق خلال الأسابيع القادمة. على الرغم من التحديات التي واجهناها، إلا أننا توصلنا إلى حلول فعالة لتحسين الأداء وضمان الالتزام بالمواعيد النهائية.",
        DateTime.parse("2024-08-26 10:09:49.972150"),
        ["اجتماع", "بريد إلكتروني"]),
    Diary(
        "قائمة القراءة",
        "استمتعت بيوم مريح على الشاطئ مع الأصدقاء. قضيت معظم الوقت في قراءة كتاب جديد يتحدث عن التنمية الذاتية وكيفية تحسين جودة الحياة. الكتاب كان ملهمًا وساعدني في التفكير بشكل أعمق في أهدافي المستقبلية وكيفية تحقيق التوازن بين العمل والحياة الشخصية.",
        DateTime.parse("2024-08-18 10:09:49.972164"),
        ["استرخاء", "تأمل"]),
    Diary(
        "قائمة القراءة",
        "كان اليوم مثمراً، تمكنت من إكمال جميع المهام المحددة لليوم. بدأت صباحي بقراءة كتاب عن تاريخ الحضارات القديمة والذي أعطاني الكثير من الأفكار حول كيفية تطور المجتمعات عبر الزمن. أنهيت يومي بكتابة ملاحظاتي وتخطيطي لليوم التالي.",
        DateTime.parse("2024-09-04 10:09:49.972173"),
        ["قراءة", "كتابة"]),
    Diary(
        "روتين الصباح",
        "كانت جلسة رائعة في صالة الألعاب الرياضية اليوم، أشعر بالقوة والنشاط. بدأت اليوم بممارسة التمارين المعتادة ولكن مع زيادة في شدة التدريب. أشعر أنني أحرز تقدمًا كبيرًا في أهدافي الصحية. بعد التدريب، استمتعت بتناول وجبة إفطار صحية وشعرت بطاقة إيجابية لبقية اليوم.",
        DateTime.parse("2024-09-12 10:09:49.972181"),
        ["شاطئ", "سباحة"])
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "diaries", false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomTextField(
                        controller: searchController,
                        prefixIcon: LucideIcons.search,
                        inputType: TextInputType.text,
                        width: width * 0.75,
                        validator: (value) {
                          return null;
                        },
                      ),
                      horizontalSpace(Spacing.points24),
                      Icon(LucideIcons.slidersHorizontal)
                    ],
                  ),
                  verticalSpace(Spacing.points16),
                  Builder(builder: (BuildContext context) {
                    if (filteredDiaryEntries.isEmpty) {
                      return Center(
                        child: Text("There is no data matching your search"),
                      );
                    } else {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return DiaryWidget(
                            diary: filteredDiaryEntries[index],
                            index: index + 1,
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            verticalSpace(Spacing.points8),
                        itemCount: filteredDiaryEntries.length,
                      );
                    }
                  })
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DiaryWidget extends ConsumerWidget {
  const DiaryWidget({super.key, required this.diary, required this.index});
  final Diary diary;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    return GestureDetector(
      onTap: () => context.go("/vault/diaries/diary/${index}"),
      child: WidgetsContainer(
        padding: EdgeInsets.all(12),
        backgroundColor: theme.primary[50],
        borderSide: BorderSide(color: theme.primary[100]!),
        borderRadius: BorderRadius.circular(10.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              index.toString(),
              style: TextStyles.footnoteSelected.copyWith(
                color: theme.grey[900],
              ),
            ),
            horizontalSpace(Spacing.points8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [Text(diary.title, style: TextStyles.footnote)],
                  ),
                  verticalSpace(Spacing.points4),
                  Text(
                    getDisplayDateTime(diary.date, locale!.languageCode),
                    style: TextStyles.caption.copyWith(color: theme.grey[700]),
                  ),
                  Text(
                    diary.body,
                    style: TextStyles.small.copyWith(color: theme.grey[700]),
                    maxLines: 3, // Set the maximum number of lines
                    overflow: TextOverflow.ellipsis, // Ellipses after max lines
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronLeft,
              color: theme.grey[300],
            )
          ],
        ),
      ),
    );
  }
}
