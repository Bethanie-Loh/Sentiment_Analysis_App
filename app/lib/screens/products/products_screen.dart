import 'dart:io';

import 'package:app/data/model/comment.dart';
import 'package:app/data/model/product.dart';
import 'package:app/providers/csv_data_notifier.dart';
import 'package:app/providers/providers.dart';
import 'package:app/screens/products/product_review_card.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_text_field.dart';
import 'package:app/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

final csvDataProvider =
    StateNotifierProvider<CSVDataNotifier, List<CSVFileData>>((ref) {
  return CSVDataNotifier();
});

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      ref.read(searchTextProvider.notifier).state = searchController.text;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool isDownloading = false;

  Future<void> downloadCSV() async {
    setState(() => isDownloading = true);

    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      final products = ref.read(filteredProductsProvider);
      final csv =
          generateCSV(products); // Implement this based on your data structure

      // Get download directory
      final dir = Directory('/storage/emulated/0/Download');

      final timestamp =
          DateTime.now().toString().replaceAll(RegExp(r'[:.]'), '-');
      final fileName = 'reviews_analysis_$timestamp.csv';
      final filePath = '${dir.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsString(csv);

      // Store CSV data in provider
      ref.read(csvDataProvider.notifier).addCSVFile(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV file downloaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error downloading CSV: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading CSV: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isDownloading = false);
    }
  }

  String generateCSV(List<Product> products) {
    final buffer = StringBuffer();

    // Add headers
    buffer.writeln(
        'Product ID,Product Name,Category,Overall Rating,Total Reviews,Positive %,Neutral %,Negative %');

    for (var product in products) {
      final sentiments = calculateSentiments(product.comments);
      buffer.writeln(
          '${product.id},${product.name},${product.category},${product.rating},'
          '${product.comments.length},${sentiments['positive']},'
          '${sentiments['neutral']},${sentiments['negative']}');
    }

    return buffer.toString();
  }

  Map<String, String> calculateSentiments(List<Comment> comments) {
    if (comments.isEmpty) {
      return {'positive': '0', 'neutral': '0', 'negative': '0'};
    }

    int positive = 0, neutral = 0, negative = 0;

    for (var comment in comments) {
      switch (comment.sentiment.toLowerCase()) {
        case 'positive':
          positive++;
        case 'neutral':
          neutral++;
        case 'negative':
          negative++;
      }
    }

    final total = comments.length;
    return {
      'positive': ((positive / total) * 100).toStringAsFixed(1),
      'neutral': ((neutral / total) * 100).toStringAsFixed(1),
      'negative': ((negative / total) * 100).toStringAsFixed(1),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = ref.watch(filteredProductsProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/gradient.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        "Reviews Sentiment Analysis",
                        style: AppTextStyles.bold_18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppTextfield(
                      hintText: "Search Product By Name, Id",
                      controller: searchController,
                      onChanged: (value) {
                        ref.read(searchTextProvider.notifier).state =
                            value.trim();
                      },
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCategoryDropdown(ref),
                          const SizedBox(width: 16),
                          _buildDateRangePicker(context, ref),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                       child: filteredProducts.isEmpty
                          ? const Center(
                              child: Text(
                                'No products found with matching reviews',
                                style: AppTextStyles.bold_16,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ProductReviewCard(
                              productId: product.id,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: isDownloading ? null : downloadCSV,
                icon: isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.black),
                        ),
                      )
                    : const Icon(Icons.download, color: AppColors.black),
                label: Text(
                  isDownloading ? 'Downloading...' : 'Download CSV',
                  style: AppTextStyles.bold_16,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turquiose,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  shadowColor: Colors.black,
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(WidgetRef ref) {
    final categoryItems = ref.watch(categoriesProvider);

    return DropdownButton<String>(
      value: ref.watch(selectedCategoryProvider),
      hint: const Text('Categories'),
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 16,
      style: AppTextStyles.bold_14,
      underline: const SizedBox(),
      onChanged: (String? newValue) {
        ref.read(selectedCategoryProvider.notifier).state =
            newValue == "All Categories" ? null : newValue;
      },
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      items: categoryItems.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value == "All Categories" ? null : value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangePicker(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(selectedDateRangeProvider);
    debugPrint('\n===== Date Picker Debug =====');
    debugPrint('Current date range: ${dateRange?.start} to ${dateRange?.end}');
    return Row(
      children: [
        InkWell(
          onTap: () async {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: dateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.turquiose,
                      onPrimary: AppColors.white,
                      onSurface: AppColors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              debugPrint(
                  'New date range selected: ${picked.start} to ${picked.end}');
              ref.read(selectedDateRangeProvider.notifier).state = picked;
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  dateRange == null
                      ? 'Select Date Range'
                      : '${DateFormat('MM/dd').format(dateRange.start)} - ${DateFormat('MM/dd').format(dateRange.end)}',
                  style: AppTextStyles.regular_14,
                ),
              ],
            ),
          ),
        ),
        if (dateRange != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              ref.read(selectedDateRangeProvider.notifier).state = null;
            },
            tooltip: 'Reset date filter',
          ),
        ],
      ],
    );
  }
}
