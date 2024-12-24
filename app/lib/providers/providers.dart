// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:app/providers/review_notifier.dart';
import 'package:app/data/model/product.dart';

// Main review notifier provider
final reviewNotifierProvider =
    StateNotifierProvider<ReviewNotifier, List<Product>>((ref) {
  return ReviewNotifier();
});

// Search and filter providers
final searchTextProvider = StateProvider((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// Categories provider
final categoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(reviewNotifierProvider);
  final categories =
      products.map((product) => product.category).toSet().toList();
  categories.sort();
  categories.add('All Categories');
  return categories;
});

// Filtered products provider
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(reviewNotifierProvider);
  final searchText = ref.watch(searchTextProvider).toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final dateRange = ref.watch(selectedDateRangeProvider);

  return products.where((product) {
    bool matchesSearch = searchText.isEmpty ||
        product.name.toLowerCase().contains(searchText) ||
        product.id.toLowerCase().contains(searchText);

    bool matchesCategory = selectedCategory == null ||
        selectedCategory == 'All Categories' ||
        product.category == selectedCategory;

    // Simplified date range logic
    bool matchesDateRange = dateRange == null ||
        product.comments.any((comment) =>
            comment.createdAt.isAfter(dateRange.start) &&
            comment.createdAt
                .isBefore(dateRange.end.add(const Duration(days: 1))));

    return matchesSearch && matchesCategory && matchesDateRange;
  }).toList();
});
