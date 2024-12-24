import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CSVFileData {
  final String fileName;
  final String content;
  final DateTime timestamp;

  CSVFileData({
    required this.fileName,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Create a state notifier to manage the CSV files
class CSVDataNotifier extends StateNotifier<List<CSVFileData>> {
  CSVDataNotifier() : super([]);

  void addCSVFile(String content) {
    final timestamp = DateTime.now();
    final fileName =
        'CSV_${timestamp.toString().replaceAll(RegExp(r'[:.]'), '-')}.csv';

    state = [
      ...state,
      CSVFileData(
        fileName: fileName,
        content: content,
        timestamp: timestamp,
      ),
    ];

    debugPrint('New CSV File saved: $fileName');
    debugPrint('Content: $content');
  }

  void clearFiles() {
    state = [];
  }

  CSVFileData? getLatestFile() {
    if (state.isEmpty) return null;
    return state.last;
  }
}
