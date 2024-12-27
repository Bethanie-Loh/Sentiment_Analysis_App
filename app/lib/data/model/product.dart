import 'package:app/data/model/comment.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double rating;
  final List<Comment> comments;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.comments,
  });

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? rating,
    List<Comment>? comments,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      comments: comments ?? this.comments,
    );
  }

  factory Product.fromMap(Map<String, dynamic> product) {
    return Product(
      id: product['id'] as String,
      name: product['name'] as String,
      category: product['category'] as String,
      rating: product['rating'] as double,
      comments: (product['comments'] as List<dynamic>)
          .map((e) => Comment.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rating': rating,
      'comments': comments.map((comment) => comment.toMap()).toList(),
    };
  }
}
