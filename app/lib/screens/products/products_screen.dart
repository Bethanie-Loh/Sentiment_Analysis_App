import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends State<ProductsScreen> {
  final List<String> categoryItems = [
    "Mobile Phones",
    "Laptops",
    "Tablets",
    "Smartwatches",
    "Accessories"
  ];

  final List<String> sentimentItems = [
    "All Sentiments",
    "Positive",
    "Neutral",
    "Negative"
  ];

  String? selectedCategory;
  String? selectedSentiment;
  DateTimeRange? selectedDateRange;

  // Method to show date range picker
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 500,
            ),
            child: child,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Date Range Picker
                        _buildDropdown(
                          "Date",
                          selectedDateRange != null
                              ? [
                                  '${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}'
                                ]
                              : ['Select Date Range'],
                          selectedDateRange != null
                              ? '${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}'
                              : 'Select Date Range',
                          (newValue) => _selectDateRange(context),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Category Dropdown
                        _buildDropdown(
                            "Categories", categoryItems, selectedCategory,
                            (newValue) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        }),

                        const SizedBox(width: 60),

                        // Sentiment Dropdown
                        _buildDropdown(
                            "Sentiment", sentimentItems, selectedSentiment,
                            (newValue) {
                          setState(() {
                            selectedSentiment = newValue;
                          });
                        }),
                      ],
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

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButton<String>(
      value: value,
      hint: Text(label),
      icon: const Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 16,
      style: AppTextStyles.bold_14,
      underline: const SizedBox(),
      onChanged: onChanged,
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }
}
