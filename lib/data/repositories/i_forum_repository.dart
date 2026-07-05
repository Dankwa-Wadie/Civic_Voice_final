// lib/data/repositories/i_forum_repository.dart
// Abstract contract (interface) for forum data repositories.

import 'package:civic_voice/data/models/forum_post.dart';

abstract class IForumRepository {
  /// Fetches a list of all posts in the forum.
  Future<List<ForumPost>> fetchPosts();

  /// Persists a new [post] to the data store.
  Future<void> submitPost(ForumPost post);

  /// Updates an existing [post] in the data store.
  Future<void> updatePost(ForumPost post);

  /// Emits real-time updates when posts change.
  Stream<List<ForumPost>> watchPosts();
}
