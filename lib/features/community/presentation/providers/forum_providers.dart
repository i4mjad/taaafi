import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/data/repositories/forum_repository.dart';

// Forum Repository Provider
final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository();
});

// Post Categories Provider
final postCategoriesProvider = StreamProvider<List<PostCategory>>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return repository.watchPostCategories();
});

// Selected Category Provider for new post screen
final selectedCategoryProvider = StateProvider<PostCategory?>((ref) {
  return null;
});

// Post Content Provider for new post screen
final postContentProvider = StateProvider<String>((ref) {
  return '';
});

// Anonymous Post Provider for new post screen
final anonymousPostProvider = StateProvider<bool>((ref) {
  return false;
});

// Attachment URLs Provider for future implementation
final attachmentUrlsProvider = StateProvider<List<String>>((ref) {
  return [];
});
