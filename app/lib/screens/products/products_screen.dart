import 'package:app/provider/review_provider.dart';
import 'package:app/screens/products/product_review_card.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_text_field.dart';
import 'package:app/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController searchController = TextEditingController();

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
                        ref.read(searchTextProvider.notifier).state = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCategoryDropdown(ref),
                        const SizedBox(width: 60),
                        _buildDateRangePicker(context, ref),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ProductReviewCard(
                              product: filteredProducts[index],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.download,
                  color: AppColors.black,
                ),
                label: const Text(
                  'Download CSV',
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
}

Widget _buildCategoryDropdown(WidgetRef ref) {
  // final categoryItems = [
  //   "Electronics",
  //   "Grocery",
  //   "Clothing",
  //   "All Categories"
  // ];

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

  return InkWell(
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
  );
}
