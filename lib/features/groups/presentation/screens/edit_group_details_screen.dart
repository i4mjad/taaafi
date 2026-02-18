import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/providers/group_settings_provider.dart';

class EditGroupDetailsScreen extends ConsumerStatefulWidget {
  const EditGroupDetailsScreen({super.key});

  @override
  ConsumerState<EditGroupDetailsScreen> createState() =>
      _EditGroupDetailsScreenState();
}

class _EditGroupDetailsScreenState
    extends ConsumerState<EditGroupDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _hasChanges = false;
  String? _initialName;
  String? _initialDescription;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFields();
    });
  }

  void _initializeFields() {
    final settingsAsync = ref.read(groupSettingsProvider);
    settingsAsync.whenData((state) {
      if (state.group != null && mounted) {
        setState(() {
          _initialName = state.group!.name;
          _initialDescription = state.group!.description;
          _nameController.text = state.group!.name;
          _descriptionController.text = state.group!.description;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges = _nameController.text != _initialName ||
          _descriptionController.text != _initialDescription;
    });
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) return;

    final l10n = AppLocalizations.of(context);

    // Show confirmation if there are unsaved changes
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('save-changes')),
        content: Text(l10n.translate('confirm-save-changes')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('save')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Determine what changed
    final String? newName =
        _nameController.text != _initialName ? _nameController.text : null;
    final String? newDescription = _descriptionController.text != _initialDescription
        ? _descriptionController.text
        : null;

    // Update details
    await ref.read(groupSettingsProvider.notifier).updateDetails(
          name: newName,
          description: newDescription,
        );

    if (!mounted) return;

    // Check for errors or success
    final state = await ref.read(groupSettingsProvider.future);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate(state.error!)),
          backgroundColor: Colors.red,
        ),
      );
    } else if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate(state.successMessage!)),
          backgroundColor: Colors.green,
        ),
      );
      // Clear messages and go back
      ref.read(groupSettingsProvider.notifier).clearMessages();
      context.pop();
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final l10n = AppLocalizations.of(context);
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('unsaved-changes-warning')),
        content: Text(l10n.translate('unsaved-changes-warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('discard-changes')),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(groupSettingsProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: appBar(context, ref, "edit-group-details", false, true),
        body: settingsAsync.when(
          data: (state) {
            if (state.group == null) {
              return Center(
                child: Text(l10n.translate('group-not-found')),
              );
            }

            if (!state.isUserAdmin) {
              return Center(
                child: Text(l10n.translate('error-admin-permission-required')),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Name Field
                    Text(
                      l10n.translate('group-name-label'),
                      style: TextStyles.h5.copyWith(color: theme.grey[900]),
                    ),
                    verticalSpace(Spacing.points8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: l10n.translate('group-name-label'),
                        counterText:
                            '${_nameController.text.length}/60 ${l10n.translate('characters-remaining').replaceAll('{count}', (60 - _nameController.text.length).toString())}',
                        filled: true,
                        fillColor: theme.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLength: 60,
                      style: TextStyles.body.copyWith(color: theme.grey[900]),
                      onChanged: (_) => _checkForChanges(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.translate('name-required');
                        }
                        if (value.trim().length > 60) {
                          return l10n.translate('name-too-long');
                        }
                        return null;
                      },
                    ),

                    verticalSpace(Spacing.points24),

                    // Group Description Field
                    Text(
                      l10n.translate('group-description-label'),
                      style: TextStyles.h5.copyWith(color: theme.grey[900]),
                    ),
                    verticalSpace(Spacing.points8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: l10n.translate('group-description-label'),
                        counterText:
                            '${_descriptionController.text.length}/500 ${l10n.translate('characters-remaining').replaceAll('{count}', (500 - _descriptionController.text.length).toString())}',
                        filled: true,
                        fillColor: theme.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLength: 500,
                      maxLines: 5,
                      style: TextStyles.body.copyWith(color: theme.grey[900]),
                      onChanged: (_) => _checkForChanges(),
                      validator: (value) {
                        if (value != null && value.trim().length > 500) {
                          return l10n.translate('description-too-long');
                        }
                        return null;
                      },
                    ),

                    const Spacer(),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _hasChanges && !state.isLoading ? _saveDetails : null,
                        child: state.isLoading 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.translate('save-changes')),
                      ),
                    ),

                    verticalSpace(Spacing.points8),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: Text(l10n.translate('cancel')),
                      ),
                    ),

                    verticalSpace(Spacing.points16),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(l10n.translate('error-loading-data')),
          ),
        ),
      ),
    );
  }
}

