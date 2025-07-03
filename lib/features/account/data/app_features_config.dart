import 'models/app_feature.dart';

/// Configuration class for app features
/// This defines all features that can be banned or restricted
class AppFeaturesConfig {
  // Feature unique names - these are used to link features to functionality
  static const String contactAdmin = 'contact_admin';
  static const String directMessaging = 'direct_messaging';
  static const String postCreation = 'post_creation';
  static const String commentCreation = 'comment_creation';
  static const String groupCreation = 'group_creation';
  static const String reportSubmission = 'report_submission';
  static const String feedbackSubmission = 'feedback_submission';
  static const String profileUpdate = 'profile_update';
  static const String dataExport = 'data_export';
  static const String communityAccess = 'community_access';

  /// Get all predefined app features
  /// This is used for initial feature setup in Firestore
  static List<AppFeature> getDefaultFeatures() {
    final now = DateTime.now();

    return [
      AppFeature(
        id: '',
        uniqueName: contactAdmin,
        nameEn: 'Contact Admin',
        nameAr: 'التواصل مع الإدارة',
        descriptionEn:
            'Ability to contact administrators through forms and support channels',
        descriptionAr:
            'إمكانية التواصل مع المديرين من خلال النماذج وقنوات الدعم',
        category: FeatureCategory.communication,
        iconName: 'message_square',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppFeature(
        id: '',
        uniqueName: directMessaging,
        nameEn: 'Direct Messaging',
        nameAr: 'الرسائل المباشرة',
        descriptionEn: 'Send and receive direct messages with other users',
        descriptionAr: 'إرسال واستقبال الرسائل المباشرة مع المستخدمين الآخرين',
        category: FeatureCategory.communication,
        iconName: 'message_circle',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppFeature(
        id: '',
        uniqueName: postCreation,
        nameEn: 'Post Creation',
        nameAr: 'إنشاء المنشورات',
        descriptionEn: 'Create and publish posts in the community',
        descriptionAr: 'إنشاء ونشر المنشورات في المجتمع',
        category: FeatureCategory.content,
        iconName: 'plus_square',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppFeature(
        id: '',
        uniqueName: commentCreation,
        nameEn: 'Comment Creation',
        nameAr: 'إنشاء التعليقات',
        descriptionEn: 'Add comments to posts and discussions',
        descriptionAr: 'إضافة تعليقات على المنشورات والمناقشات',
        category: FeatureCategory.social,
        iconName: 'message_square',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppFeature(
        id: '',
        uniqueName: groupCreation,
        nameEn: 'Group Creation',
        nameAr: 'إنشاء المجموعات',
        descriptionEn: 'Create and manage community groups',
        descriptionAr: 'إنشاء وإدارة مجموعات المجتمع',
        category: FeatureCategory.social,
        iconName: 'users',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppFeature(
        id: '',
        uniqueName: reportSubmission,
        nameEn: 'Report Submission',
        nameAr: 'تقديم التقارير',
        descriptionEn: 'Submit reports and tickets to support team',
        descriptionAr: 'تقديم التقارير والتذاكر لفريق الدعم',
        category: FeatureCategory.communication,
        iconName: 'flag',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppFeature(
        id: '',
        uniqueName: feedbackSubmission,
        nameEn: 'Feedback Submission',
        nameAr: 'تقديم الملاحظات',
        descriptionEn: 'Provide feedback and suggestions for app improvement',
        descriptionAr: 'تقديم ملاحظات واقتراحات لتحسين التطبيق',
        category: FeatureCategory.communication,
        iconName: 'thumbs_up',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppFeature(
        id: '',
        uniqueName: profileUpdate,
        nameEn: 'Profile Update',
        nameAr: 'تحديث الملف الشخصي',
        descriptionEn: 'Modify and update user profile information',
        descriptionAr: 'تعديل وتحديث معلومات الملف الشخصي للمستخدم',
        category: FeatureCategory.settings,
        iconName: 'user_cog',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppFeature(
        id: '',
        uniqueName: dataExport,
        nameEn: 'Data Export',
        nameAr: 'تصدير البيانات',
        descriptionEn: 'Export personal data and account information',
        descriptionAr: 'تصدير البيانات الشخصية ومعلومات الحساب',
        category: FeatureCategory.settings,
        iconName: 'download',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppFeature(
        id: '',
        uniqueName: communityAccess,
        nameEn: 'Community Access',
        nameAr: 'الوصول للمجتمع',
        descriptionEn:
            'Access community features and participate in discussions',
        descriptionAr: 'الوصول إلى ميزات المجتمع والمشاركة في المناقشات',
        category: FeatureCategory.social,
        iconName: 'users',
        isActive: true,
        isBannable: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Get feature by unique name for easy access
  static AppFeature? getFeatureByUniqueName(String uniqueName) {
    try {
      return getDefaultFeatures().firstWhere(
        (feature) => feature.uniqueName == uniqueName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a feature unique name is valid
  static bool isValidFeature(String uniqueName) {
    return getDefaultFeatures()
        .any((feature) => feature.uniqueName == uniqueName);
  }

  /// Get features by category
  static List<AppFeature> getFeaturesByCategory(FeatureCategory category) {
    return getDefaultFeatures()
        .where((feature) => feature.category == category)
        .toList();
  }

  /// Get all communication features
  static List<AppFeature> getCommunicationFeatures() {
    return getFeaturesByCategory(FeatureCategory.communication);
  }

  /// Get all social features
  static List<AppFeature> getSocialFeatures() {
    return getFeaturesByCategory(FeatureCategory.social);
  }

  /// Get all content features
  static List<AppFeature> getContentFeatures() {
    return getFeaturesByCategory(FeatureCategory.content);
  }

  /// Get all settings features
  static List<AppFeature> getSettingsFeatures() {
    return getFeaturesByCategory(FeatureCategory.settings);
  }
}
