import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_slider.dart';
import 'package:reboot_app_3/core/shared_widgets/confirmation_sheet.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/groups/providers/group_settings_provider.dart';

/// Unified admin settings sheet for managing group capacity and details
/// 
/// This bottom sheet consolidates all admin-only settings in one place:
/// - Edit group name and description
/// - Adjust member capacity
/// - View current group stats
class AdminSettingsSheet extends ConsumerStatefulWidget {
  const AdminSettingsSheet({super.key});

  @override
  ConsumerState<AdminSettingsSheet> createState() => _AdminSettingsSheetState();
}

class _AdminSettingsSheetState extends ConsumerState<AdminSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  
  int? _selectedCapacity;
  bool _hasNameChanges = false;
  bool _hasDescriptionChanges = false;
  bool _hasCapacityChanges = false;
  
  String? _initialName;
  String? _initialDescription;
  int? _initialCapacity;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFields();
    });
  }

  Future<void> _initializeFields() async {
    try {
      final state = await ref.read(groupSettingsProvider.future);
      if (state.group != null && mounted) {
        setState(() {
          _initialName = state.group!.name;
          _initialDescription = state.group!.description;
          _initialCapacity = state.group!.memberCapacity;
          
          _nameController.text = state.group!.name;
          _descriptionController.text = state.group!.description;
          _selectedCapacity = state.group!.memberCapacity;
        });
      }
    } catch (e) {
      print('Error initializing fields: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    setState(() {
      _hasNameChanges = _nameController.text != _initialName;
      _hasDescriptionChanges = _descriptionController.text != _initialDescription;
      _hasCapacityChanges = _selectedCapacity != _initialCapacity;
    });
  }

  bool get _hasAnyChanges => _hasNameChanges || _hasDescriptionChanges || _hasCapacityChanges;

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || !_hasAnyChanges) return;

    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(groupSettingsProvider.notifier);

    // Show confirmation sheet
    final confirmed = await showConfirmationSheet(
      context: context,
      title: l10n.translate('save-changes'),
      message: l10n.translate('confirm-save-changes'),
      confirmText: l10n.translate('save'),
      cancelText: l10n.translate('cancel'),
      icon: LucideIcons.save,
      isDestructive: false,
    );

    if (confirmed != true) return;

    // Save capacity changes
    if (_hasCapacityChanges && _selectedCapacity != null) {
      await notifier.updateCapacity(_selectedCapacity!);
    }

    // Save details changes
    if (_hasNameChanges || _hasDescriptionChanges) {
      await notifier.updateDetails(
        name: _hasNameChanges ? _nameController.text : null,
        description: _hasDescriptionChanges ? _descriptionController.text : null,
      );
    }

    if (!mounted) return;

    // Check for errors or success
    final state = await ref.read(groupSettingsProvider.future);
    if (state.error != null) {
      getErrorSnackBar(context, state.error!);
    } else if (state.successMessage != null) {
      getSuccessSnackBar(context, state.successMessage!);
      // Clear messages and close sheet
      ref.read(groupSettingsProvider.notifier).clearMessages();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(groupSettingsProvider);

    return settingsAsync.when(
      data: (state) {
        if (state.group == null || !state.isUserAdmin) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(l10n.translate('error-admin-permission-required')),
            ),
          );
        }

        // Use actual member count from state (fetched via provider)
        final currentMemberCount = state.actualMemberCount ?? state.group!.memberCount;
        final isUserPlus = state.isUserPlus;
        
        // Calculate max capacity based on subscription status
        // If user has Plus: can go up to 50
        // If user doesn't have Plus but current capacity > 6: can only maintain or decrease (not increase)
        // If user doesn't have Plus and capacity <= 6: can adjust up to 6
        final double maxCapacity;
        if (isUserPlus) {
          maxCapacity = 50.0;
        } else if (state.group!.memberCapacity > 6) {
          // User previously had Plus but cancelled - allow them to manage current capacity
          // but not increase it beyond what they already have
          maxCapacity = state.group!.memberCapacity.toDouble();
        } else {
          maxCapacity = 6.0;
        }

        // Calculate the actual minimum capacity (greater of 2 or current member count)
        final minCapacity = currentMemberCount < 2 ? 2 : currentMemberCount;
        
        // Initialize selected capacity and ensure it's within valid bounds
        _selectedCapacity ??= state.group!.memberCapacity;
        
        // Clamp the value to ensure it's between minCapacity and maxCapacity
        if (_selectedCapacity! < minCapacity) {
          _selectedCapacity = minCapacity;
        }
        if (_selectedCapacity! > maxCapacity) {
          _selectedCapacity = maxCapacity.toInt();
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.settings,
                      color: theme.primary[600],
                      size: 24,
                    ),
                    horizontalSpace(Spacing.points12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('admin-settings'),
                            style: TextStyles.h4.copyWith(
                              color: theme.grey[900],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          verticalSpace(Spacing.points4),
                          Text(
                            l10n.translate('manage-group-settings'),
                            style: TextStyles.small.copyWith(
                              color: theme.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: theme.grey[600]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: theme.grey[200]),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group Details Section
                        _buildSectionHeader(
                          l10n.translate('edit-group-details'),
                          LucideIcons.fileText,
                          theme,
                        ),
                        verticalSpace(Spacing.points16),

                        // Group Name
                        Text(
                          l10n.translate('group-name-label'),
                          style: TextStyles.footnote.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        verticalSpace(Spacing.points8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: l10n.translate('group-name-label'),
                            counterText: '${_nameController.text.length}/60',
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

                        verticalSpace(Spacing.points16),

                        // Group Description
                        Text(
                          l10n.translate('group-description-label'),
                          style: TextStyles.footnote.copyWith(
                            color: theme.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        verticalSpace(Spacing.points8),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: l10n.translate('group-description-label'),
                            counterText: '${_descriptionController.text.length}/500',
                            filled: true,
                            fillColor: theme.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLength: 500,
                          maxLines: 4,
                          style: TextStyles.body.copyWith(color: theme.grey[900]),
                          onChanged: (_) => _checkForChanges(),
                          validator: (value) {
                            if (value != null && value.trim().length > 500) {
                              return l10n.translate('description-too-long');
                            }
                            return null;
                          },
                        ),

                        verticalSpace(Spacing.points32),

                        // Capacity Section
                        _buildSectionHeader(
                          l10n.translate('group-capacity'),
                          LucideIcons.users,
                          theme,
                        ),
                        verticalSpace(Spacing.points16),

                        // Current Stats Card
                        WidgetsContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: theme.grey[50],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                l10n.translate('current-members'),
                                currentMemberCount.toString(),
                                LucideIcons.userCheck,
                                theme,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: theme.grey[300],
                              ),
                              _buildStatItem(
                                l10n.translate('current-capacity'),
                                state.group!.memberCapacity.toString(),
                                LucideIcons.users,
                                theme,
                              ),
                            ],
                          ),
                        ),

                        verticalSpace(Spacing.points20),

                        // Capacity Slider
                        // Minimum is the greater of 2 or current member count
                        PlatformSlider(
                          value: _selectedCapacity!.toDouble(),
                          min: minCapacity.toDouble(),
                          max: maxCapacity,
                          divisions: (maxCapacity - minCapacity).toInt(),
                          label: l10n.translate('new-capacity'),
                          valueFormatter: (value) => '${value.toInt()} ${l10n.translate('members')}',
                          showValue: true,
                          showMinMaxLabels: true,
                          valueDisplayPosition: ValueDisplayPosition.above,
                          onChanged: (value) {
                            setState(() {
                              _selectedCapacity = value.toInt();
                            });
                            _checkForChanges();
                          },
                          activeColor: theme.primary[600],
                          inactiveColor: theme.grey[300],
                        ),

                        // Plus status info banners
                        if (_selectedCapacity! > 6 && isUserPlus)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildInfoBanner(
                              l10n.translate('plus-feature-active'),
                              LucideIcons.star,
                              theme.primary[50]!,
                              theme.primary[600]!,
                              theme.primary[700]!,
                            ),
                          ),

                        // User cancelled Plus but still has capacity > 6
                        if (!isUserPlus && state.group!.memberCapacity > 6)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildInfoBanner(
                              l10n.translate('subscription-cancelled-capacity-locked'),
                              LucideIcons.alertCircle,
                              theme.warn[50]!,
                              theme.warn[600]!,
                              theme.warn[700]!,
                            ),
                          ),

                        // Regular user trying to increase capacity
                        if (!isUserPlus && _selectedCapacity! >= 6 && state.group!.memberCapacity <= 6)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildInfoBanner(
                              l10n.translate('upgrade-to-plus-for-capacity'),
                              LucideIcons.lock,
                              theme.secondary[50]!,
                              theme.secondary[600]!,
                              theme.secondary[700]!,
                            ),
                          ),

                        verticalSpace(Spacing.points32),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  border: Border(
                    top: BorderSide(color: theme.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: WidgetsContainer(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.backgroundColor,
                          borderSide: BorderSide(color: theme.grey[300]!, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              l10n.translate('cancel'),
                              style: TextStyles.footnote.copyWith(
                                color: theme.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    horizontalSpace(Spacing.points12),
                    // Save Button
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _hasAnyChanges && !state.isLoading ? _saveChanges : null,
                        child: WidgetsContainer(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _hasAnyChanges && !state.isLoading 
                              ? theme.primary[600]
                              : theme.grey[300],
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: state.isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.backgroundColor,
                                      ),
                                    ),
                                  )
                                : Text(
                                    l10n.translate('save-changes'),
                                    style: TextStyles.footnote.copyWith(
                                      color: _hasAnyChanges && !state.isLoading
                                          ? theme.backgroundColor
                                          : theme.grey[600],
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(AppLocalizations.of(context).translate('error-loading-data')),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, dynamic theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.grey[700]),
        horizontalSpace(Spacing.points8),
        Text(
          title,
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, dynamic theme) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.grey[600]),
        verticalSpace(Spacing.points8),
        Text(
          value,
          style: TextStyles.h4.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w700,
          ),
        ),
        verticalSpace(Spacing.points4),
        Text(
          label,
          style: TextStyles.small.copyWith(
            color: theme.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(String message, IconData icon, Color bgColor, Color iconColor, Color textColor) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(12),
      backgroundColor: bgColor,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          horizontalSpace(Spacing.points8),
          Expanded(
            child: Text(
              message,
              style: TextStyles.small.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

