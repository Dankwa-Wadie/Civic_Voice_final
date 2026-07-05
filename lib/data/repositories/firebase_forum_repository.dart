// lib/data/repositories/firebase_forum_repository.dart
// Firestore-backed implementation of IForumRepository.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_voice/data/models/forum_post.dart';
import 'package:civic_voice/data/repositories/i_forum_repository.dart';

class FirebaseForumRepository implements IForumRepository {
  final FirebaseFirestore _firestore;

  FirebaseForumRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'forum_posts';

  @override
  Future<List<ForumPost>> fetchPosts() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ForumPost.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<void> submitPost(ForumPost post) async {
    final docRef = _firestore.collection(_collection).doc(post.id);
    final map = post.toMap();
    // Convert int millisecond timestamp to Firestore Timestamp for rule compliance and db formatting
    map['timestamp'] = Timestamp.fromDate(post.timestamp);
    await docRef.set(map);
  }

  @override
  Future<void> updatePost(ForumPost post) async {
    final docRef = _firestore.collection(_collection).doc(post.id);
    final map = post.toMap();
    map['timestamp'] = Timestamp.fromDate(post.timestamp);
    await docRef.update(map);
  }

  @override
  Stream<List<ForumPost>> watchPosts() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ForumPost.fromMap(doc.data()))
            .toList());
  }
}
