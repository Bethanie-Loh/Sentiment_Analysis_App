import 'package:app/provider/review_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/data/model/product.dart';

final reviewNotifierProvider =
    StateNotifierProvider<ReviewNotifier, List<Product>>((ref) {
  return ReviewNotifier();
});

// Search text provider
final searchTextProvider = StateProvider<String>((ref) => '');

// Selected category provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Selected date range provider
final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// Selected sentiment filter provider
final selectedSentimentFilterProvider = StateProvider<String?>((ref) => null);

final categoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(reviewNotifierProvider);
  final categories =
      products.map((product) => product.category).toSet().toList();
  categories.sort(); // Optionally sort alphabetically
  categories.add('All Categories'); // Add "All Categories" option at the end
  return categories;
});

// Filtered products provider
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(reviewNotifierProvider);
  final searchText = ref.watch(searchTextProvider).toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final dateRange = ref.watch(selectedDateRangeProvider);
  final selectedSentiment = ref.watch(selectedSentimentFilterProvider);

  return products.where((product) {
    // Search filter
    bool matchesSearch = searchText.isEmpty ||
        product.name.toLowerCase().contains(searchText) ||
        product.id.toLowerCase().contains(searchText);

    // Category filter
    bool matchesCategory =
        selectedCategory == null || product.category == selectedCategory;

    // Date range filter
    bool matchesDateRange = dateRange == null ||
        product.comments.any((comment) =>
            comment.createdAt.isAfter(dateRange.start) &&
            comment.createdAt
                .isBefore(dateRange.end.add(const Duration(days: 1))));

    bool matchesSentiment = selectedSentiment == null ||
        product.comments.any((comment) =>
            comment.sentiment.toLowerCase() == selectedSentiment.toLowerCase());

    return matchesSearch &&
        matchesCategory &&
        matchesDateRange &&
        matchesSentiment;
  }).toList();
});
