import 'package:app/data/model/comment.dart';
import 'package:app/data/model/product.dart';
import 'package:app/provider/review_provider.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProductReviewCard extends ConsumerWidget {
  final Product product;

  const ProductReviewCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedSentimentFilterProvider);

    // Determine card color based on selected filter
    Color cardColor = AppColors.white;
    switch (selectedFilter) {
      case 'positive':
        cardColor = AppColors.green;
      case 'negative':
        cardColor = AppColors.red;
      case 'neutral':
        cardColor = AppColors.orange;
      default:
        cardColor = AppColors.white;
    }

    // Function to handle sentiment filter selection
    void showFilteredReviews(String sentiment) {
      final currentFilter = ref.read(selectedSentimentFilterProvider);
      if (currentFilter == sentiment) {
        ref.read(selectedSentimentFilterProvider.notifier).state = null;
      } else {
        ref.read(selectedSentimentFilterProvider.notifier).state = sentiment;
      }
    }

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(product.name, style: AppTextStyles.bold_18),
                      const SizedBox(width: 8),
                      Text(
                        '(${product.comments.length} reviews)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // IconButton(
                //   icon: const Icon(Icons.refresh),
                //   onPressed: () {
                //     // Reset the sentiment filter
                //     ref.read(selectedSentimentFilterProvider.notifier).state =
                //         null;
                //     // Access the ReviewNotifier through a provider and reset
                //     ref.read(reviewsProvider.notifier).resetData();
                //   },
                // ),
              ],
            ),
            Row(children: [
              Text("Product ID: ${product.id}",
                  style: AppTextStyles.regular_gray_12),
            ]),
            const SizedBox(height: 8),
            _buildRatingStars(product.rating),
            const SizedBox(height: 16),
            _buildSentimentStats(product, selectedFilter, showFilteredReviews),
            const SizedBox(height: 16),
            _buildCommentsList(product.comments),
          ],
        ),
      ),
    );
  }
}

Widget _buildRatingStars(double rating) {
  return Row(
    children: [
      Row(
        children: List.generate(5, (index) {
          return Icon(
            index < rating.floor()
                ? Icons.star
                : index < rating
                    ? Icons.star_half
                    : Icons.star_border,
            color: Colors.amber,
            size: 20,
          );
        }),
      ),
      const SizedBox(width: 8),
      Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
      ),
    ],
  );
}

Widget _buildSentimentStats(Product product, String? selectedFilter,
    void Function(String) showFilteredReviews) {
  final Map<String, int> sentimentCounts = {
    'positive': 0,
    'neutral': 0,
    'negative': 0,
  };

  for (final comment in product.comments) {
    sentimentCounts[comment.sentiment] =
        (sentimentCounts[comment.sentiment] ?? 0) + 1;
  }

  final total = product.comments.length;
  final Map<String, double> sentimentPercentages = {
    'positive': total > 0 ? (sentimentCounts['positive']! / total) * 100 : 0,
    'neutral': total > 0 ? (sentimentCounts['neutral']! / total) * 100 : 0,
    'negative': total > 0 ? (sentimentCounts['negative']! / total) * 100 : 0,
  };

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _buildSentimentButton(
        '😊',
        sentimentPercentages['positive']!.round(),
        AppColors.green,
        selectedFilter == 'positive',
        () => showFilteredReviews('positive'),
      ),
      _buildSentimentButton(
        '😐',
        sentimentPercentages['neutral']!.round(),
        AppColors.orange,
        selectedFilter == 'neutral',
        () => showFilteredReviews('neutral'),
      ),
      _buildSentimentButton(
        '☹️',
        sentimentPercentages['negative']!.round(),
        AppColors.red,
        selectedFilter == 'negative',
        () => showFilteredReviews('negative'),
      ),
    ],
  );
}

Widget _buildSentimentButton(
  String emoji,
  int percentage,
  Color backgroundColor,
  bool isSelected,
  VoidCallback onTap,
) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? backgroundColor.withOpacity(0.7) : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: Colors.black26, width: 2) : null,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCommentsList(List<Comment> comments) {
  return SizedBox(
    height: 150,
    child: ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      comment.comment,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    _getSentimentEmoji(comment.sentiment),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "User ID: ${comment.userId}",
                    style: AppTextStyles.regular_gray_12,
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(comment.createdAt),
                    style: AppTextStyles.regular_gray_12,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

String _getSentimentEmoji(String sentiment) {
  switch (sentiment.toLowerCase()) {
    case 'positive':
      return '😊';
    case 'negative':
      return '☹️';
    case 'neutral':
    default:
      return '😐';
  }
}
