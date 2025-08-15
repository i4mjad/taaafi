/// Model class for post search filters
/// 
/// This encapsulates all the search and filtering parameters
/// that can be applied when searching posts.
class PostSearchFilters {
  final String? searchQuery;
  final String? category;
  final String sortBy;
  final DateTime? startDate;
  final DateTime? endDate;

  const PostSearchFilters({
    this.searchQuery,
    this.category,
    this.sortBy = 'newest_first',
    this.startDate,
    this.endDate,
  });

  /// Creates a copy with updated values
  PostSearchFilters copyWith({
    String? searchQuery,
    String? category,
    String? sortBy,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return PostSearchFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  /// Check if the filters have any active filtering criteria
  bool get hasActiveFilters {
    return (searchQuery != null && searchQuery!.isNotEmpty) ||
           (category != null && category!.isNotEmpty) ||
           startDate != null ||
           endDate != null ||
           sortBy != 'newest_first';
  }

  /// Check if text search is active
  bool get hasTextSearch {
    return searchQuery != null && searchQuery!.isNotEmpty;
  }

  /// Check if category filter is active
  bool get hasCategoryFilter {
    return category != null && category!.isNotEmpty;
  }

  /// Check if date range filter is active
  bool get hasDateFilter {
    return startDate != null || endDate != null;
  }

  /// Check if custom sorting is applied
  bool get hasCustomSort {
    return sortBy != 'newest_first';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostSearchFilters &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          category == other.category &&
          sortBy == other.sortBy &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      category.hashCode ^
      sortBy.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;

  @override
  String toString() {
    return 'PostSearchFilters('
        'searchQuery: $searchQuery, '
        'category: $category, '
        'sortBy: $sortBy, '
        'startDate: $startDate, '
        'endDate: $endDate'
        ')';
  }
}