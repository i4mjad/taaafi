import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/library/library_notifier.dart';
import 'package:reboot_app_3/features/vault/data/library/models/cursor_content.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_item_widget.dart';

class ContentTypeScreen extends ConsumerStatefulWidget {
  const ContentTypeScreen(this.typeId, this.typeName, {super.key});

  final String typeId;
  final String typeName;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ContentTypeScreenState();
}

class _ContentTypeScreenState extends ConsumerState<ContentTypeScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = true;

  List<CursorContent> content = [];
  List<CursorContent> filteredData = [];

  @override
  void initState() {
    super.initState();
    _loadContent();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadContent() async {
    try {
      final contentList = await ref
          .read(libraryNotifierProvider.notifier)
          .getContentByType(widget.typeId);
      setState(() {
        content = contentList;
        filteredData = contentList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // You might want to show an error message here
    }
  }

  void _onSearchChanged() {
    setState(() {
      String searchQuery = searchController.text.toLowerCase();
      filteredData = content
          .where((item) => item.name.toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, widget.typeName, false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                validator: (data) => null,
                controller: searchController,
                prefixIcon: LucideIcons.search,
                inputType: TextInputType.text,
                focusNode: _focusNode,
              ),
              verticalSpace(Spacing.points16),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.primary[700],
                        ),
                      )
                    : filteredData.isEmpty
                        ? Center(
                            child: Text(
                              'No content found',
                              style: TextStyles.body.copyWith(
                                color: theme.grey[600],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredData.length,
                            separatorBuilder: (context, index) =>
                                verticalSpace(Spacing.points8),
                            itemBuilder: (context, index) {
                              return ContentItem(
                                content: filteredData[index],
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
