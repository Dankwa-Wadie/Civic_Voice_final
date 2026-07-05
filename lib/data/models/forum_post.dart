// lib/data/models/forum_post.dart
// Immutable value object representing a community discussion board post.

class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.content,
    required this.timestamp,
    this.isPinned = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorEmail;
  final String content;
  final DateTime timestamp;
  final bool isPinned;

  /// Returns a new [ForumPost] with the given fields replaced.
  ForumPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorEmail,
    String? content,
    DateTime? timestamp,
    bool? isPinned,
  }) {
    return ForumPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// Converts this [ForumPost] to a [Map] suitable for Firestore writes.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isPinned': isPinned,
    };
  }

  /// Constructs a [ForumPost] from a Map.
  factory ForumPost.fromMap(Map<String, dynamic> map) {
    final DateTime parsedTimestamp;
    final dynamic rawTimestamp = map['timestamp'];
    if (rawTimestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.parse(rawTimestamp);
    } else if (rawTimestamp != null &&
        rawTimestamp.runtimeType.toString() == 'Timestamp') {
      parsedTimestamp = (rawTimestamp as dynamic).toDate() as DateTime;
    } else {
      parsedTimestamp = DateTime.now();
    }

    return ForumPost(
      id: map['id'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      authorEmail: map['authorEmail'] as String? ?? '',
      content: map['content'] as String? ?? '',
      timestamp: parsedTimestamp,
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ForumPost) return false;
    return id == other.id &&
        authorId == other.authorId &&
        authorName == other.authorName &&
        authorEmail == other.authorEmail &&
        content == other.content &&
        timestamp == other.timestamp &&
        isPinned == other.isPinned;
  }

  @override
  int get hashCode => Object.hash(
        id,
        authorId,
        authorName,
        authorEmail,
        content,
        timestamp,
        isPinned,
      );

  @override
  String toString() {
    return 'ForumPost(id: $id, authorName: $authorName, content: $content, timestamp: $timestamp, isPinned: $isPinned)';
  }
}
