// lib/providers/review_notifier.dart

import 'dart:io';
import 'package:app/data/model/product.dart';
import 'package:app/providers/csv_data_notifier.dart';
import 'package:app/services/sentiment_service.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class ReviewNotifier extends StateNotifier<List<Product>> {
  ReviewNotifier() : super([]);
  final _apiService = SentimentAnalysisService();
  final Map<String, Map<String, dynamic>> _productsMap = {};
  final Map<String, List<double>> _productRatings = {};
  final csvDataProvider =
      StateNotifierProvider<CSVDataNotifier, List<CSVFileData>>((ref) {
    return CSVDataNotifier();
  });

  Future<UploadResult> uploadCSVFile(WidgetRef ref) async {
    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return UploadResult(false, 'No file selected');

      final file = File(result.files.single.path!);

      // Analyze CSV using the API service
      debugPrint('Sending file to sentiment analysis server...');
      final analysisResult =
          await _apiService.analyzeCsv(file, textColumn: 'comment');

      if (!analysisResult.containsKey('result_file')) {
        return UploadResult(
            false, 'Error: No result file received from server');
      }

      // Download the analyzed CSV
      final analyzedFile =
          await _apiService.downloadResults(analysisResult['result_file']);
      final analyzedCsvString = await analyzedFile.readAsString();

      // Process the analyzed CSV data
      final List<List<dynamic>> analyzedRows =
          const CsvToListConverter().convert(analyzedCsvString);

      if (analyzedRows.isEmpty) {
        return UploadResult(false, 'Analyzed CSV file is empty');
      }

      final headers =
          analyzedRows[0].map((e) => e.toString().toLowerCase()).toList();
      final indices = {
        'id': headers.indexOf('id'),
        'name': headers.indexOf('name'),
        'category': headers.indexOf('category'),
        'rating': headers.indexOf('rating'),
        'comment': headers.indexOf('comment'),
        'userId': headers.indexOf('userid'),
        'createdAt': headers.indexOf('createdat'),
        'sentiment': headers.indexOf('sentiment'),
      };

      if (indices.values.any((i) => i == -1)) {
        return UploadResult(false, 'Missing required columns in analyzed CSV');
      }

      int newCommentsCount = 0;
      int updatedProductsCount = 0;

      // First pass: Collect all ratings from the current CSV
      for (var i = 1; i < analyzedRows.length; i++) {
        final row = analyzedRows[i];
        final productId = row[indices['id']!].toString();
        final rating =
            double.tryParse(row[indices['rating']!].toString()) ?? 0.0;

        if (!_productRatings.containsKey(productId)) {
          _productRatings[productId] = [];
        }
        _productRatings[productId]!.add(rating);
      }

      // Second pass: Process products and comments
      for (var i = 1; i < analyzedRows.length; i++) {
        final row = analyzedRows[i];
        final productId = row[indices['id']!].toString();

        // Create or update product
        if (!_productsMap.containsKey(productId)) {
          _productsMap[productId] = {
            'id': productId,
            'name': row[indices['name']!],
            'category': row[indices['category']!],
            'rating': 0.0, // Will be updated with correct average
            'comments': <Map<String, dynamic>>[],
          };
          updatedProductsCount++;
        }

        // Process comment
        final newComment = {
          'comment': row[indices['comment']!],
          'userId': row[indices['userId']!].toString(),
          'createdAt': row[indices['createdAt']!].toString(),
          'sentiment': row[indices['sentiment']!],
        };

        bool commentExists = (_productsMap[productId]!['comments'] as List).any(
            (existing) =>
                existing['comment'] == newComment['comment'] &&
                existing['userId'] == newComment['userId']);

        if (!commentExists) {
          (_productsMap[productId]!['comments'] as List<Map<String, dynamic>>)
              .add(newComment);
          newCommentsCount++;
        }

        // Calculate and update the true average rating
        if (_productRatings.containsKey(productId)) {
          final allRatings = _productRatings[productId]!;
          if (allRatings.isNotEmpty) {
            final averageRating =
                allRatings.reduce((a, b) => a + b) / allRatings.length;
            _productsMap[productId]!['rating'] = averageRating;
          }
        }
      }

      // Store the analyzed CSV and update state
      ref.read(csvDataProvider.notifier).addCSVFile(analyzedCsvString);

      final products = _productsMap.values.map((productMap) {
        return Product.fromMap(productMap);
      }).toList();

      state = products;

      await _downloadAndStoreVisualizations();

      return UploadResult(
          true,
          'Successfully processed ${updatedProductsCount > 0 ? "$updatedProductsCount new products and " : ""}'
          '$newCommentsCount new comments');
    } catch (e) {
      debugPrint('Error in uploadCSVFile: $e');
      return UploadResult(false, 'Error processing CSV: $e');
    }
  }

  Future<void> _downloadAndStoreVisualizations() async {
    try {
      // Download visualization files
      await _apiService.getVisualization('sentiment_distribution.png');
      await _apiService.getVisualization('confidence_distribution.png');
    } catch (e) {
      debugPrint('Error downloading visualizations: $e');
    }
  }

  Future<Map<String, dynamic>?> getAnalysisStatistics() async {
    final latestFile = state.isNotEmpty ? _generateUpdatedCSV(state) : null;
    if (latestFile == null) return null;

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_analysis.csv');
    await tempFile.writeAsString(latestFile);

    try {
      final result = await _apiService.analyzeCsv(tempFile);
      return result['statistics'];
    } catch (e) {
      debugPrint('Error getting analysis statistics: $e');
      return null;
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}

String _generateUpdatedCSV(List<Product> products) {
  List<List<dynamic>> updatedCsvRows = [
    [
      'id',
      'name',
      'category',
      'rating',
      'comment',
      'userid',
      'createdat',
      'sentiment'
    ]
  ];

  for (var product in products) {
    for (var comment in product.comments) {
      updatedCsvRows.add([
        product.id,
        product.name,
        product.category,
        product.rating,
        comment.comment,
        comment.userId,
        comment.createdAt.toIso8601String(),
        comment.sentiment
      ]);
    }
  }

  return const ListToCsvConverter().convert(updatedCsvRows);
}

class UploadResult {
  final bool success;
  final String message;

  UploadResult(this.success, this.message);
}
