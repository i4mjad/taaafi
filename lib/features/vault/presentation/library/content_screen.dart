import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_item_widget.dart';

class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, String>> dummyData = [
    {
      "title": "عنوان المحتوى 1",
      "description": "مقطع مرئي • تصنيف المحتوى • المصدر 1"
    },
    {
      "title": "عنوان المحتوى 2",
      "description": "مقطع مرئي • تصنيف المحتوى • المصدر 2"
    },
    // Other items...
  ];

  List<Map<String, String>> filteredData = [];

  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();

    filteredData = dummyData;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      String searchQuery = searchController.text.toLowerCase();
      filteredData = dummyData
          .where((item) =>
              item["title"]!.toLowerCase().contains(searchQuery) ||
              item["description"]!.toLowerCase().contains(searchQuery))
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

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'explore-content', false, true),
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
              Expanded(
                child: ListView.separated(
                  itemCount: filteredData.length,
                  separatorBuilder: (context, index) =>
                      verticalSpace(Spacing.points8),
                  itemBuilder: (context, index) {
                    final item = filteredData[index];
                    return ContentItem(
                      title: item["title"]!,
                      description: item["description"]!,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
