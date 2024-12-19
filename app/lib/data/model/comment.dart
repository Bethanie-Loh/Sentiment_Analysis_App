class Comment {
  final String comment;
  final String userId;
  final DateTime createdAt;
  final String sentiment;

  Comment({
    required this.comment,
    required this.userId,
    required this.createdAt,
    required this.sentiment,
  });

  factory Comment.fromMap(Map<String, dynamic> comment) {
    return Comment(
      comment: comment['comment'] as String,
      userId: comment['userId'] as String,
      createdAt: DateTime.parse(comment['createdAt'] as String),
      sentiment: comment['sentiment'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comment': comment,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'sentiment': sentiment,
    };
  }
}
