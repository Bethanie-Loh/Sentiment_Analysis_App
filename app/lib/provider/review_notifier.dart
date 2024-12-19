import 'package:app/data/model/comment.dart';
import 'package:app/data/model/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewNotifier extends StateNotifier<List<Product>> {
  ReviewNotifier() : super([]) {
    _loadInitialData();
  }

  void _loadInitialData() {
    state = _getDummyProducts();
  }

  List<Product> _getDummyProducts() {
    return [
      Product(
        id: 'P00123',
        name: 'Wireless Earbuds',
        category: 'Electronics',
        rating: 4.2,
        comments: [
          Comment(
            comment: 'Amazing sound quality! Comfortable fit.',
            userId: 'GM8Tv9KcFA',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            sentiment: 'positive',
          ),
          Comment(
            comment: 'Neutral comment for earbuds',
            userId: 'asdfgf242',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            sentiment: 'neutral',
          ),
          Comment(
            comment: 'Negative comment for earbuds',
            userId: 'asdfgf242',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            sentiment: 'negative',
          ),
        ],
      ),
      Product(
        id: 'P00456',
        name: 'Organic Coffee Beans',
        category: 'Grocery',
        rating: 4.0,
        comments: [
          Comment(
            comment: 'Good flavor, but a bit pricey.',
            userId: 'uXbpvEYVtX',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            sentiment: 'neutral',
          ),
        ],
      ),
      Product(
        id: 'P00789',
        name: 'Cotton T-Shirt',
        category: 'Clothing',
        rating: 3.5,
        comments: [
          Comment(
            comment: 'Comfortable, but shrank slightly in the wash.',
            userId: 'YVCZz4KNua',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            sentiment: 'negative',
          ),
        ],
      ),
    ];
  }

// Filter Products by date range
  void filterByDateRange(DateTime start, DateTime end) {
    state = _getDummyProducts().where((product) {
      return product.comments.any((comment) {
        return comment.createdAt.isAfter(start) &&
            comment.createdAt.isBefore(end.add(const Duration(days: 1)));
      });
    }).toList();
  }

  // Add a new Product
  void addProduct(Product product) {
    state = [...state, product];
  }

  // Update existing Product
  void updateProduct(Product updatedReview) {
    state = state.map((review) {
      if (review.id == updatedReview.id) {
        return updatedReview;
      }
      return review;
    }).toList();
  }

  // // Delete review
  // void deleteReview(String reviewId) {
  //   state = state.where((review) => review.id != reviewId).toList();
  // }

  // Reset to initial data
  void resetData() {
    state = _getDummyProducts();
  }
}
