import 'package:cloud_firestore/cloud_firestore.dart';

enum FeatureCategory {
  core,
  social,
  content,
  communication,
  settings,
}

class AppFeature {
  final String id;
  final String uniqueName; // Generated from English name for linking
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final FeatureCategory category;
  final String iconName;
  final bool isActive;
  final bool isBannable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppFeature({
    required this.id,
    required this.uniqueName,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.category,
    required this.iconName,
    required this.isActive,
    required this.isBannable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppFeature.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppFeature(
      id: doc.id,
      uniqueName: data['uniqueName'] as String,
      nameEn: data['nameEn'] as String,
      nameAr: data['nameAr'] as String,
      descriptionEn: data['descriptionEn'] as String,
      descriptionAr: data['descriptionAr'] as String,
      category: FeatureCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => FeatureCategory.core,
      ),
      iconName: data['iconName'] as String,
      isActive: data['isActive'] as bool? ?? true,
      isBannable: data['isBannable'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uniqueName': uniqueName,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'category': category.name,
      'iconName': iconName,
      'isActive': isActive,
      'isBannable': isBannable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String getLocalizedName(String languageCode) {
    return languageCode == 'ar' ? nameAr : nameEn;
  }

  String getLocalizedDescription(String languageCode) {
    return languageCode == 'ar' ? descriptionAr : descriptionEn;
  }

  AppFeature copyWith({
    String? id,
    String? uniqueName,
    String? nameEn,
    String? nameAr,
    String? descriptionEn,
    String? descriptionAr,
    FeatureCategory? category,
    String? iconName,
    bool? isActive,
    bool? isBannable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppFeature(
      id: id ?? this.id,
      uniqueName: uniqueName ?? this.uniqueName,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      isBannable: isBannable ?? this.isBannable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to generate unique name from English name
  static String generateUniqueName(String nameEn) {
    return nameEn
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
}
