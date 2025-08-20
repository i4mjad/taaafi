import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/domain/entities/group_invitation_entity.dart';

class GroupInvitationsModal extends ConsumerStatefulWidget {
  final List<GroupInvitationEntity> invitations;

  const GroupInvitationsModal({
    super.key,
    required this.invitations,
  });

  @override
  ConsumerState<GroupInvitationsModal> createState() =>
      _GroupInvitationsModalState();
}

class _GroupInvitationsModalState extends ConsumerState<GroupInvitationsModal> {
  Set<String> _processingInvitations = {};

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24), // Balance the close button
              Text(
                l10n.translate('group-invitations-title'),
                style: TextStyles.h4.copyWith(
                  color: theme.grey[900],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: theme.grey[600],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Invitations count
          Text(
            l10n.translate('invitations-count').replaceAll(
                  '{count}',
                  widget.invitations.length.toString(),
                ),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
            ),
          ),

          const SizedBox(height: 16),

          // Invitations list
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: widget.invitations.map((invitation) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildInvitationCard(invitation, theme, l10n),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(
    GroupInvitationEntity invitation,
    dynamic theme,
    AppLocalizations l10n,
  ) {
    final isProcessing = _processingInvitations.contains(invitation.id);

    return WidgetsContainer(
      backgroundColor: theme.grey[50],
      borderSide: BorderSide(
        color: theme.grey[200]!,
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group info section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.users,
                  size: 20,
                  color: theme.primary[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.groupName,
                      style: TextStyles.body.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.translate('invited-by').replaceAll(
                            '{inviter}',
                            invitation.inviterName,
                          ),
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: invitation.groupType == 'public'
                      ? theme.success[100]
                      : theme.warn[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  invitation.groupType == 'public'
                      ? l10n.translate('group-type-public')
                      : l10n.translate('group-type-private'),
                  style: TextStyles.caption.copyWith(
                    color: invitation.groupType == 'public'
                        ? theme.success[700]
                        : theme.warn[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Group details
          Row(
            children: [
              Icon(
                LucideIcons.users2,
                size: 14,
                color: theme.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                l10n.translate('member-count-text').replaceAll(
                      '{count}',
                      invitation.memberCount.toString(),
                    ),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                LucideIcons.clock,
                size: 14,
                color: theme.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _formatInvitationDate(invitation.invitedAt, l10n),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                ),
              ),
            ],
          ),

          if (invitation.groupDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              invitation.groupDescription!,
              style: TextStyles.caption.copyWith(
                color: theme.grey[600],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isProcessing
                      ? null
                      : () => _declineInvitation(invitation.id),
                  child: WidgetsContainer(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    backgroundColor:
                        isProcessing ? theme.grey[200] : theme.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.grey[300]!,
                      width: 1,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isProcessing) ...[
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.grey[600]!,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          l10n.translate('decline-invitation'),
                          style: TextStyles.caption.copyWith(
                            color: isProcessing
                                ? theme.grey[500]
                                : theme.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: isProcessing
                      ? null
                      : () => _acceptInvitation(invitation.id),
                  child: WidgetsContainer(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    backgroundColor:
                        isProcessing ? theme.grey[300] : theme.primary[600],
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isProcessing) ...[
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          l10n.translate('accept-invitation'),
                          style: TextStyles.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatInvitationDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return l10n.translate('days-ago').replaceAll(
            '{days}',
            difference.inDays.toString(),
          );
    } else if (difference.inHours > 0) {
      return l10n.translate('hours-ago').replaceAll(
            '{hours}',
            difference.inHours.toString(),
          );
    } else {
      return l10n.translate('minutes-ago').replaceAll(
            '{minutes}',
            difference.inMinutes.toString(),
          );
    }
  }

  void _acceptInvitation(String invitationId) {
    setState(() {
      _processingInvitations.add(invitationId);
    });

    // TODO: Implement accept invitation logic
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _processingInvitations.remove(invitationId);
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accepted invitation: $invitationId')),
        );
      }
    });
  }

  void _declineInvitation(String invitationId) {
    setState(() {
      _processingInvitations.add(invitationId);
    });

    // TODO: Implement decline invitation logic
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _processingInvitations.remove(invitationId);
          // Remove invitation from list
          widget.invitations.removeWhere((inv) => inv.id == invitationId);
        });

        if (widget.invitations.isEmpty) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Declined invitation: $invitationId')),
        );
      }
    });
  }
}
