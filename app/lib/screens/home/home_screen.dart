import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<GData> _chartData = [
    GData('Positive', 40, AppColors.green),
    GData('Neutral', 30, AppColors.beige),
    GData('Negative', 20, AppColors.red),
  ];

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
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Amazing Online Store",
                      style: AppTextStyles.appName,
                    ),
                    Center(
                      child: SfCircularChart(
                        title: ChartTitle(
                            text: 'Overview of Sentiments',
                            textStyle: AppTextStyles.bold_18),
                        legend: Legend(isVisible: true),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CircularSeries>[
                          PieSeries<GData, String>(
                            dataSource: _chartData,
                            xValueMapper: (GData data, _) => data.x,
                            yValueMapper: (GData data, _) => data.y,
                            pointColorMapper: (GData data, _) => data.color,
                            dataLabelSettings:
                                const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Number of reviews analyzed: 100',
                      style: AppTextStyles.italic_14,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.upload_file,
                  color: AppColors.black,
                ),
                label: const Text(
                  'Upload CSV',
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

class GData {
  GData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
