class Bookmark {
  final String id;
  final String type; // 'chat' (notes/study guide) or 'quiz'
  final String title; // topic or user query
  final String content; // text content (markdown) or quiz JSON
  final DateTime timestamp;

  Bookmark({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
