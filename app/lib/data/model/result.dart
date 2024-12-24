import 'package:app/data/model/product.dart';

class CSVUploadResult {
  final bool success;
  final String message;
  final List<Product>? products;

  CSVUploadResult({
    required this.success,
    required this.message,
    this.products,
  });
}
