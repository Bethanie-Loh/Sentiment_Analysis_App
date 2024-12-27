// api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class SentimentAnalysisService {
  final String baseUrl;

  // SentimentAnalysisService({this.baseUrl = 'http://10.1.104.60:5000'});
  SentimentAnalysisService({this.baseUrl = 'http://192.168.0.111:5000'});

  Future<Map<String, dynamic>> analyzeCsv(File csvFile,
      {String? textColumn}) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'));

      var fileStream = http.ByteStream(csvFile.openRead());
      var length = await csvFile.length();
      var multipartFile = http.MultipartFile('file', fileStream, length,
          filename: csvFile.path.split('/').last);
      request.files.add(multipartFile);

      // Add text column if provided
      if (textColumn != null) {
        request.fields['text_column'] = textColumn;
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to analyze CSV: $responseData');
      }
    } catch (e) {
      throw Exception('Error analyzing CSV: $e');
    }
  }

  Future<File> downloadResults(String filename) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/download/$filename'));

      if (response.statusCode == 200) {
        // Save file locally
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception('Failed to download results');
      }
    } catch (e) {
      throw Exception('Error downloading results: $e');
    }
  }

  Future<File> getVisualization(String filename) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/visualization/$filename'));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception('Failed to download visualization');
      }
    } catch (e) {
      throw Exception('Error downloading visualization: $e');
    }
  }
}
