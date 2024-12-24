import 'package:app/providers/providers.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_loading.dart';
import 'package:app/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Add a loading state provider
final isLoadingProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(reviewNotifierProvider);
    final isLoading = ref.watch(isLoadingProvider);

    // Group comments by product ID and combine sentiments
    final Map<String, Map<String, int>> productStats = {};

    for (final product in products) {
      if (!productStats.containsKey(product.id)) {
        productStats[product.id] = {
          'positive': 0,
          'neutral': 0,
          'negative': 0,
        };
      }

      for (final comment in product.comments) {
        final sentiment = comment.sentiment.toLowerCase();
        if (productStats[product.id]!.containsKey(sentiment)) {
          productStats[product.id]![sentiment] =
              productStats[product.id]![sentiment]! + 1;
        }
      }
    }

    // Aggregate all sentiments
    final Map<String, int> totalStats = {
      'positive': 0,
      'neutral': 0,
      'negative': 0,
    };

    for (final stats in productStats.values) {
      for (final entry in stats.entries) {
        totalStats[entry.key] = totalStats[entry.key]! + entry.value;
      }
    }

    // Prepare chart data
    final List<GData> chartData = [
      GData('Positive', totalStats['positive']!.toDouble(), AppColors.green),
      GData('Neutral', totalStats['neutral']!.toDouble(), AppColors.orange),
      GData('Negative', totalStats['negative']!.toDouble(), AppColors.red),
    ];

    final totalReviews = totalStats.values.reduce((a, b) => a + b);

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
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Amazing Online Store",
                      style: AppTextStyles.appName,
                    ),
                    if (products.isEmpty && !isLoading)
                      const Center(
                        child: Text(
                          "No data available. Please upload a CSV file.",
                          style: AppTextStyles.italic_14,
                        ),
                      )
                    else if (isLoading)
                      const Center(child: AppLoading())
                    else
                      Center(
                        child: SfCircularChart(
                          title: ChartTitle(
                            text: 'Overview of Sentiments',
                            textStyle: AppTextStyles.bold_18,
                          ),
                          legend: Legend(
                            isVisible: true,
                            position: LegendPosition.bottom,
                          ),
                          tooltipBehavior: TooltipBehavior(enable: true),
                          series: <CircularSeries>[
                            PieSeries<GData, String>(
                              dataSource: chartData,
                              xValueMapper: (GData data, _) => data.x,
                              yValueMapper: (GData data, _) => data.y,
                              pointColorMapper: (GData data, _) => data.color,
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                labelPosition: ChartDataLabelPosition.outside,
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (!isLoading && products.isNotEmpty)
                      Text(
                        'Number of reviews analyzed: ${totalReviews.toString()}',
                        style: AppTextStyles.italic_14,
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        try {
                          ref.read(isLoadingProvider.notifier).state = true;

                          final result = await ref
                              .read(reviewNotifierProvider.notifier)
                              .uploadCSVFile(ref);

                          if (context.mounted) {
                            // Custom SnackBar with improved styling
                            final snackBar = SnackBar(
                              content: Text(
                                result.message,
                                style: AppTextStyles.italic_14,
                              ),
                              backgroundColor: result.success
                                  ? AppColors.green
                                  : AppColors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(20),
                              duration: const Duration(seconds: 4),
                            );

                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to upload CSV: $e',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: AppColors.red.withOpacity(0.9),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(20),
                              ),
                            );
                          }
                        } finally {
                          ref.read(isLoadingProvider.notifier).state = false;
                        }
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.black),
                        ),
                      )
                    : const Icon(
                        Icons.upload_file,
                        color: AppColors.black,
                      ),
                label: Text(
                  isLoading ? 'Uploading...' : 'Upload CSV',
                  style: AppTextStyles.bold_16,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLoading
                      ? AppColors.turquiose.withOpacity(0.7)
                      : AppColors.turquiose,
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

class GData {
  GData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
