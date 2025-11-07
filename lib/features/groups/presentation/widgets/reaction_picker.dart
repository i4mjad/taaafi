import 'package:flutter/material.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

/// A widget that displays a picker for selecting emoji reactions
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;

  const ReactionPicker({
    super.key,
    required this.onEmojiSelected,
  });

  // Common reaction emojis
  static const List<String> _defaultEmojis = [
    '👍', // thumbs up
    '❤️', // heart
    '😂', // laughing
    '😮', // surprised
    '😢', // sad
    '🙏', // praying
    '🎉', // celebration
    '🔥', // fire
    '👏', // clapping
    '💯', // 100
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            l10n.translate('react-to-message'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Emoji grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _defaultEmojis.length,
            itemBuilder: (context, index) {
              final emoji = _defaultEmojis[index];
              return _EmojiButton(
                emoji: emoji,
                onTap: () {
                  onEmojiSelected(emoji);
                  Navigator.of(context).pop();
                },
              );
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Show the reaction picker as a bottom sheet
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionPicker(
        onEmojiSelected: (emoji) {
          Navigator.of(context).pop(emoji);
        },
      ),
    );
  }
}

/// Individual emoji button widget
class _EmojiButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}

