import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/application/library/library_notifier.dart';
import 'package:reboot_app_3/features/vault/data/library/models/cursor_content_list.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_item_widget.dart';

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen(this.id, {super.key});
  final String id;

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  CursorContentList? listDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadListDetails();
  }

  Future<void> _loadListDetails() async {
    try {
      final details = await ref
          .read(libraryNotifierProvider.notifier)
          .getListDetails(widget.id);
      setState(() {
        listDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: plainAppBar(context, ref, listDetails?.name ?? '', false, true),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.primary,
                  ),
                  verticalSpace(Spacing.points16),
                  Text(
                    AppLocalizations.of(context).translate("loading"),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      WidgetsContainer(
                        backgroundColor: theme.backgroundColor,
                        borderSide:
                            BorderSide(color: theme.grey[600]!, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(50, 50, 93, 0.25),
                            blurRadius: 5,
                            spreadRadius: -1,
                            offset: Offset(
                              0,
                              2,
                            ),
                          ),
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.3),
                            blurRadius: 3,
                            spreadRadius: -1,
                            offset: Offset(
                              0,
                              1,
                            ),
                          ),
                        ],
                        width: width,
                        child: Text(
                          listDetails?.description ?? '',
                          style: TextStyles.small.copyWith(
                            color: theme.grey[900],
                          ),
                        ),
                      ),
                      verticalSpace(Spacing.points16),
                      Text(
                        AppLocalizations.of(context).translate("list-content"),
                        style: TextStyles.h6.copyWith(
                          color: theme.grey[900],
                        ),
                      ),
                      verticalSpace(Spacing.points8),
                      if (listDetails?.contents != null)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: listDetails!.contents.length,
                          separatorBuilder: (context, index) =>
                              verticalSpace(Spacing.points8),
                          itemBuilder: (context, index) {
                            final item = listDetails!.contents[index];
                            return ContentItem(
                              content: item,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
