import 'package:app/data/model/comment.dart';
import 'package:app/data/model/product.dart';
import 'package:app/providers/providers.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProductReviewCard extends ConsumerStatefulWidget {
  final String productId;

  const ProductReviewCard({super.key, required this.productId});

  @override
  ConsumerState<ProductReviewCard> createState() => _ProductReviewCardState();
}

class _ProductReviewCardState extends ConsumerState<ProductReviewCard> {
  String? selectedFilter;

  List<Comment> getFilteredComments(List<Comment> comments) {
    if (selectedFilter == null) {
      return comments;
    }
    return comments
        .where((comment) => comment.sentiment.toLowerCase() == selectedFilter)
        .toList();
  }

  void showFilteredReviews(String sentiment) {
    setState(() {
      selectedFilter = selectedFilter == sentiment ? null : sentiment;
    });
  }

  void resetFilters() {
    setState(() {
      selectedFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(filteredProductsProvider);
    debugPrint('\n===== Product Review Card Debug =====');
    debugPrint('Building card for product ID: ${widget.productId}');

    final product = products.firstWhere(
      (product) => product.id == widget.productId,
      orElse: () => Product(
          id: '',
          name: 'Product not found',
          category: '',
          rating: 0.0,
          comments: []),
    );
    debugPrint('Found product: ${product.name}');
    debugPrint('Number of comments: ${product.comments.length}');
    final filteredComments = getFilteredComments(product.comments);

    Color cardColor = AppColors.pink;
    if (selectedFilter != null) {
      switch (selectedFilter) {
        case 'positive':
          cardColor = AppColors.green;
          break;
        case 'negative':
          cardColor = AppColors.red;
          break;
        case 'neutral':
          cardColor = AppColors.blue;
          break;
      }
    }

    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(product.name, style: AppTextStyles.bold_16),
                      const SizedBox(width: 10),
                      Text(
                        '(${filteredComments.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Text(
                        "Product ID: ${product.id}",
                        style: AppTextStyles.regular_gray_12,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy Product ID',
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: product.id)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRatingStars(product.rating),
                    if (selectedFilter != null ||
                        filteredComments.length != product.comments.length)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Reset filters',
                        onPressed: resetFilters,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSentimentStats(product),
                const SizedBox(height: 16),
                _buildCommentsList(filteredComments),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentStats(Product product) {
    final Map<String, int> sentimentCounts = {
      'positive': 0,
      'neutral': 0,
      'negative': 0,
    };

    for (final comment in product.comments) {
      final normalizedSentiment = comment.sentiment.toLowerCase();
      if (sentimentCounts.containsKey(normalizedSentiment)) {
        sentimentCounts[normalizedSentiment] =
            (sentimentCounts[normalizedSentiment] ?? 0) + 1;
      }
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
          AppColors.blue,
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

  // Rest of the widget methods remain the same...
  Widget _buildRatingStars(double rating) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return Stack(
              children: [
                Icon(
                  index < rating.floor()
                      ? Icons.star
                      : index < rating
                          ? Icons.star_half
                          : Icons.star_border,
                  color: Colors.black,
                  size: 22,
                ),
                Icon(
                  index < rating.floor()
                      ? Icons.star
                      : index < rating
                          ? Icons.star_half
                          : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                ),
              ],
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

  Widget _buildCommentsList(List<Comment> comments) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        itemCount: comments.length,
        separatorBuilder: (context, index) => const Divider(
          color: AppColors.gray,
          thickness: 1,
        ),
        itemBuilder: (context, index) {
          final comment = comments[index];
          final sentiment = comment.sentiment.toLowerCase();

          Color bgColor;
          switch (sentiment) {
            case 'positive':
              bgColor = AppColors.green;
              break;
            case 'negative':
              bgColor = AppColors.red;
              break;
            default:
              bgColor = AppColors.blue;
          }

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
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
                    _buildSentimentIndicator(sentiment),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "User ID: ${comment.userId}",
                          style: AppTextStyles.regular_gray_12,
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 14),
                          tooltip: 'Copy User ID',
                          onPressed: () => Clipboard.setData(
                              ClipboardData(text: comment.userId)),
                        ),
                      ],
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

  Widget _buildSentimentIndicator(String sentiment) {
    IconData icon;
    Color color;

    switch (sentiment) {
      case 'positive':
        icon = Icons.sentiment_satisfied_rounded;
        color = AppColors.green;
        break;
      case 'negative':
        icon = Icons.sentiment_dissatisfied_rounded;
        color = AppColors.red;
        break;
      default:
        icon = Icons.sentiment_neutral_rounded;
        color = AppColors.blue;
    }

    return Icon(
      icon,
      color: color,
      size: 24,
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
          color: isSelected ? backgroundColor : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected ? Border.all(color: Colors.black26, width: 2) : null,
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
}
