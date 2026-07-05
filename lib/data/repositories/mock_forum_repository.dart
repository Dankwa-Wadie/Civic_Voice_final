// lib/data/repositories/mock_forum_repository.dart
// In-memory mock implementation of IForumRepository.

import 'dart:async';
import 'package:civic_voice/data/models/forum_post.dart';
import 'package:civic_voice/data/repositories/i_forum_repository.dart';

class MockForumRepository implements IForumRepository {
  MockForumRepository() {
    _posts = _buildSeedData();
    Future.microtask(() => _controller.add(List.from(_posts)));
  }

  late List<ForumPost> _posts;
  final StreamController<List<ForumPost>> _controller =
      StreamController<List<ForumPost>>.broadcast();

  void dispose() {
    _controller.close();
  }

  @override
  Future<List<ForumPost>> fetchPosts() {
    return Future.value(List.from(_posts));
  }

  @override
  Future<void> submitPost(ForumPost post) {
    _posts.insert(0, post);
    _controller.add(List.from(_posts));
    return Future.value();
  }

  @override
  Future<void> updatePost(ForumPost post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _posts[index] = post;
      _controller.add(List.from(_posts));
    }
    return Future.value();
  }

  @override
  Stream<List<ForumPost>> watchPosts() {
    return _controller.stream;
  }

  List<ForumPost> _buildSeedData() {
    return [
      ForumPost(
        id: 'post-1',
        authorId: 'user-1',
        authorName: 'Ekow Mensah',
        authorEmail: 'ekow@civicvoice.net',
        content: 'Has anyone seen the progress on the Spintex Road pothole? It was marked "In Progress" yesterday!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ForumPost(
        id: 'post-2',
        authorId: 'user-2',
        authorName: 'Amma Osei',
        authorEmail: 'amma@civicvoice.net',
        content: 'Yes! The crews are actually working near the traffic lights today. Great response time!',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      ),
      ForumPost(
        id: 'post-3',
        authorId: 'user-3',
        authorName: 'Kofi Mensah',
        authorEmail: 'kofi@civicvoice.net',
        content: 'Reported a water leak in East Legon. Hope the municipal workers get to it soon.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ForumPost(
        id: 'post-4',
        authorId: 'user-4',
        authorName: 'Abena Agyei',
        authorEmail: 'abena@civicvoice.net',
        content: 'Thanks for reporting, Kofi. I also added a light failure post on the main avenue. Stay safe!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ForumPost(
        id: 'post-5',
        authorId: 'user-5',
        authorName: 'Yaw Boateng',
        authorEmail: 'yaw@civicvoice.net',
        content: 'Love this community effort. Together we can keep our city clean and functional!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }
}
