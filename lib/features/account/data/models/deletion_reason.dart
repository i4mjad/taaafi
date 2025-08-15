class DeletionReason {
  final String id;
  final String translationKey;
  final String category;
  final bool requiresDetails;

  const DeletionReason({
    required this.id,
    required this.translationKey,
    required this.category,
    this.requiresDetails = false,
  });
}

class DeletionReasons {
  static const List<DeletionReason> reasons = [
    // Privacy & Security
    DeletionReason(
      id: 'privacy_concerns',
      translationKey: 'deletion-reason-privacy-concerns',
      category: 'privacy',
    ),
    DeletionReason(
      id: 'data_security',
      translationKey: 'deletion-reason-data-security',
      category: 'privacy',
    ),
    
    // App Experience
    DeletionReason(
      id: 'not_helpful',
      translationKey: 'deletion-reason-not-helpful',
      category: 'experience',
    ),
    DeletionReason(
      id: 'too_complex',
      translationKey: 'deletion-reason-too-complex',
      category: 'experience',
    ),
    DeletionReason(
      id: 'technical_issues',
      translationKey: 'deletion-reason-technical-issues',
      category: 'experience',
      requiresDetails: true,
    ),
    
    // Personal Reasons
    DeletionReason(
      id: 'no_longer_needed',
      translationKey: 'deletion-reason-no-longer-needed',
      category: 'personal',
    ),
    DeletionReason(
      id: 'switching_apps',
      translationKey: 'deletion-reason-switching-apps',
      category: 'personal',
    ),
    DeletionReason(
      id: 'temporary_break',
      translationKey: 'deletion-reason-temporary-break',
      category: 'personal',
    ),
    
    // Content & Features
    DeletionReason(
      id: 'missing_features',
      translationKey: 'deletion-reason-missing-features',
      category: 'features',
      requiresDetails: true,
    ),
    DeletionReason(
      id: 'content_inappropriate',
      translationKey: 'deletion-reason-content-inappropriate',
      category: 'content',
    ),
    
    // Support & Communication
    DeletionReason(
      id: 'poor_support',
      translationKey: 'deletion-reason-poor-support',
      category: 'support',
      requiresDetails: true,
    ),
    
    // Other
    DeletionReason(
      id: 'other',
      translationKey: 'deletion-reason-other',
      category: 'other',
      requiresDetails: true,
    ),
  ];

  static List<DeletionReason> getByCategory(String category) {
    return reasons.where((reason) => reason.category == category).toList();
  }

  static DeletionReason? findById(String id) {
    try {
      return reasons.firstWhere((reason) => reason.id == id);
    } catch (e) {
      return null;
    }
  }
}