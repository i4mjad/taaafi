// TODO: Uncomment when switching to real Firestore implementation
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';

class ForumRepository {
  // TODO: Uncomment when switching to real Firestore implementation
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get post categories - currently returns mocks, will be replaced with backend later
  Future<List<PostCategory>> getPostCategories() async {
    // TODO: Replace with actual backend call when admin panel is ready
    // For now, return mock categories
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return _getMockCategories();
  }

  // Stream of post categories - currently returns mocks, will be replaced with backend later
  Stream<List<PostCategory>> watchPostCategories() {
    // TODO: Replace with actual Firestore stream when admin panel is ready
    // For now, return mock categories as a stream
    return Stream.fromFuture(Future.delayed(const Duration(milliseconds: 300))
        .then((_) => _getMockCategories()));
  }

  // Mock categories for development - will be replaced with backend data
  List<PostCategory> _getMockCategories() {
    return [
      const PostCategory(
        id: 'discussion',
        name: 'Discussion',
        nameAr: 'نقاش',
        iconName: 'discussion',
        colorHex: '#10B981',
        isActive: true,
        sortOrder: 1,
      ),
      const PostCategory(
        id: 'question',
        name: 'Question',
        nameAr: 'سؤال',
        iconName: 'question',
        colorHex: '#3B82F6',
        isActive: true,
        sortOrder: 2,
      ),
      const PostCategory(
        id: 'support',
        name: 'Support',
        nameAr: 'دعم',
        iconName: 'support',
        colorHex: '#F59E0B',
        isActive: true,
        sortOrder: 3,
      ),
      const PostCategory(
        id: 'motivation',
        name: 'Motivation',
        nameAr: 'تحفيز',
        iconName: 'lightbulb',
        colorHex: '#8B5CF6',
        isActive: true,
        sortOrder: 4,
      ),
      const PostCategory(
        id: 'success_story',
        name: 'Success Story',
        nameAr: 'قصة نجاح',
        iconName: 'chat',
        colorHex: '#06B6D4',
        isActive: true,
        sortOrder: 5,
      ),
      const PostCategory(
        id: 'advice',
        name: 'Advice',
        nameAr: 'نصيحة',
        iconName: 'tips',
        colorHex: '#EC4899',
        isActive: true,
        sortOrder: 6,
      ),
      const PostCategory(
        id: 'general',
        name: 'General',
        nameAr: 'عام',
        iconName: 'chat',
        colorHex: '#6B7280',
        isActive: true,
        sortOrder: 7,
      ),
    ];
  }

  // Create a new post (placeholder for future implementation)
  Future<String> createPost({
    required String title,
    required String content,
    required String categoryId,
    required bool isAnonymous,
    List<String>? attachmentUrls,
  }) async {
    // TODO: Implement post creation logic
    // This is where you'll create the post in Firestore
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // For now, just return a mock post ID
    return 'post_${DateTime.now().millisecondsSinceEpoch}';
  }
}
