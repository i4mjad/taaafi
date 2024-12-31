import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/utils/icon_mapper.dart';
import 'package:reboot_app_3/features/vault/data/library/featured_list_item.dart';

class ContentListsScreen extends ConsumerStatefulWidget {
  const ContentListsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentListsScreen> {
  final TextEditingController searchController = TextEditingController();

  final content = [
    FeaturedListItem(
        IconMapper.getIconFromString("airVent"),
        "التعامل مع الانتكاسة",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    FeaturedListItem(LucideIcons.planeTakeoff, "كيف أبدأ؟",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    FeaturedListItem(LucideIcons.heart, "ما هو الأدمان؟",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    FeaturedListItem(LucideIcons.airVent, "قائمة عوالم",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    FeaturedListItem(LucideIcons.brain, "العقل والإدمان",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    FeaturedListItem(LucideIcons.heartHandshake, "الدعم والمساندة",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    FeaturedListItem(LucideIcons.target, "تحديد الأهداف",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    FeaturedListItem(LucideIcons.smile, "الصحة النفسية",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    FeaturedListItem(LucideIcons.users, "قصص نجاح",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    FeaturedListItem(LucideIcons.bookOpen, "مصادر تعليمية",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
  ];

  List<FeaturedListItem> filteredData = [];

  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();

    filteredData = content;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      String searchQuery = searchController.text.toLowerCase();
      filteredData = content
          .where((item) =>
              item.listName.toLowerCase().contains(searchQuery) ||
              item.description.toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;

    final content = [
      FeaturedListItem(LucideIcons.planeLanding, "التعامل مع الانتكاسة",
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
      FeaturedListItem(LucideIcons.planeTakeoff, "كيف أبدأ؟",
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
      FeaturedListItem(LucideIcons.heart, "ما هو الأدمان؟",
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
      FeaturedListItem(LucideIcons.airVent, "قائمة عوالم",
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    ];

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'explore-content-lists', false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                validator: (data) {
                  return null;
                },
                controller: searchController,
                prefixIcon: LucideIcons.search,
                inputType: TextInputType.text,
                focusNode: _focusNode,
              ),
              verticalSpace(Spacing.points16),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.5 / 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  return FeaturedListItemWidget(filteredData[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeaturedListItemWidget extends StatelessWidget {
  const FeaturedListItemWidget(this.listItem, {super.key});

  final FeaturedListItem listItem;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        context.goNamed(RouteNames.libraryList.name, pathParameters: {
          "name": listItem.listName,
        });
      },
      child: WidgetsContainer(
        padding: EdgeInsets.all(8),
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 5,
            spreadRadius: 0,
            offset: Offset(
              0,
              0,
            ),
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 1,
            spreadRadius: 0,
            offset: Offset(
              0,
              0,
            ),
          ),
        ],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              listItem.icon,
              color: theme.primary[700],
            ),
            horizontalSpace(Spacing.points4),
            Expanded(
              child: Text(
                listItem.listName,
                style: TextStyles.small.copyWith(
                  color: theme.grey[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.arrowLeft,
              size: 16,
              color: theme.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}
