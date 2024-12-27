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

  debugPrint('===== Date Filter Debug =====');
  debugPrint('Selected date range: ${dateRange?.start} to ${dateRange?.end}');
  debugPrint('Total products before filtering: ${products.length}');

   return products
      .map((product) {
        debugPrint('\nProcessing product: ${product.id}');

        bool matchesSearch = searchText.isEmpty ||
            product.name.toLowerCase().contains(searchText) ||
            product.id.toLowerCase().contains(searchText);

        bool matchesCategory = selectedCategory == null ||
            selectedCategory == 'All Categories' ||
            product.category == selectedCategory;

        if (!matchesSearch || !matchesCategory) {
          debugPrint('Product filtered out by search/category');
          return null;
        }

        if (dateRange != null) {
          final filteredComments = product.comments.where((comment) {
            final isAfterStart = comment.createdAt.isAfter(dateRange.start);
            final isBeforeEnd = comment.createdAt
                .isBefore(dateRange.end.add(const Duration(days: 1)));
            return isAfterStart && isBeforeEnd;
          }).toList();

          // Return null if no comments match the date range
          if (filteredComments.isEmpty) {
            return null;
          }

          return Product(
            id: product.id,
            name: product.name,
            category: product.category,
            rating: product.rating,
            comments: filteredComments,
          );
        }

        // Return null if product has no comments
        if (product.comments.isEmpty) {
          return null;
        }

        return product;
      })
      .where((product) => product != null)
      .cast<Product>()
      .toList();
});
