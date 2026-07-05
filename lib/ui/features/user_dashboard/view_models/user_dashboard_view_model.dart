// lib/ui/features/user_dashboard/view_models/user_dashboard_view_model.dart
// Business logic (state management) for the Citizen Dashboard & Forum.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_voice/data/models/incident_report.dart';
import 'package:civic_voice/data/models/forum_post.dart';
import 'package:civic_voice/data/repositories/i_civic_repository.dart';
import 'package:civic_voice/data/repositories/i_forum_repository.dart';
import 'package:uuid/uuid.dart';

class UserDashboardViewModel extends ChangeNotifier {
  UserDashboardViewModel({
    required ICivicRepository civicRepository,
    required IForumRepository forumRepository,
    FirebaseAuth? auth,
  })  : _civicRepository = civicRepository,
        _forumRepository = forumRepository,
        _auth = auth ?? FirebaseAuth.instance {
    _initStreams();
    _authListener = _auth.authStateChanges().listen((user) {
      _isAnonymousChat = false;
      notifyListeners();
    });
  }

  final ICivicRepository _civicRepository;
  final IForumRepository _forumRepository;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  // ── Subscriptions ─────────────────────────────────────────────────────────
  StreamSubscription<List<IncidentReport>>? _reportsSub;
  StreamSubscription<List<ForumPost>>? _postsSub;
  StreamSubscription<User?>? _authListener;

  // ── State ──────────────────────────────────────────────────────────────────
  List<IncidentReport> _allReports = [];
  List<ForumPost> _forumPosts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isAnonymousChat = false;

  List<IncidentReport> get allReports => _allReports;
  List<ForumPost> get forumPosts => _forumPosts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAnonymousChat => _isAnonymousChat;

  String _nickname = '';
  String get nickname => _nickname;

  void setNickname(String val) {
    _nickname = val.trim();
    notifyListeners();
  }

  bool get isAdmin => currentUserEmail.toLowerCase().contains('admin');

  void setAnonymousChat(bool v) {
    _isAnonymousChat = v;
    notifyListeners();
  }

  /// Generates a consistent, short pseudonym tag based on a hash of the authorId
  static String getAnonymousName(String authorId, {bool isAdmin = false}) {
    if (authorId.isEmpty) return isAdmin ? 'Anonymous Admin' : 'Anonymous';
    final hash = authorId.codeUnits.fold(0, (prev, element) => prev + element);
    final hex = (hash % 4096).toRadixString(16).toUpperCase().padLeft(3, '0');
    return isAdmin ? 'Anonymous Admin #$hex' : 'Anonymous #$hex';
  }

  /// Returns only the reports submitted by the currently logged-in citizen.
  List<IncidentReport> get myReports {
    final email = currentUserEmail;
    if (email.isEmpty) return [];
    return _allReports
        .where((r) => r.reporterName == email || r.reporterName == 'anonymous:$email')
        .toList();
  }

  /// Returns the email of the currently authenticated user, or empty string.
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  /// Returns the UID of the currently authenticated user, or empty string.
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Returns a clean display name derived from the user's email.
  String get currentUserName {
    if (_nickname.isNotEmpty) return _nickname;
    final email = currentUserEmail;
    if (email.isEmpty) return 'Citizen';
    return email.split('@').first.replaceAll(RegExp(r'[._-]'), ' ');
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> sendForumMessage(String content) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;

    final String authorName;
    final String authorEmail;
    if (_isAnonymousChat) {
      authorName = getAnonymousName(_auth.currentUser?.uid ?? 'anon-uid', isAdmin: isAdmin);
      authorEmail = 'anonymous';
    } else {
      authorName = currentUserName;
      authorEmail = currentUserEmail;
    }

    final post = ForumPost(
      id: _uuid.v4(),
      authorId: _auth.currentUser?.uid ?? 'anon-uid',
      authorName: authorName,
      authorEmail: authorEmail,
      content: cleanContent,
      timestamp: DateTime.now(),
    );

    try {
      await _forumRepository.submitPost(post);
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> togglePinPost(ForumPost post) async {
    try {
      final updated = post.copyWith(isPinned: !post.isPinned);
      await _forumRepository.updatePost(updated);
    } catch (e) {
      _errorMessage = 'Failed to toggle pin: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Internal Helpers ───────────────────────────────────────────────────────
  void _initStreams() {
    _isLoading = true;
    notifyListeners();

    _reportsSub = _civicRepository.watchReports().listen(
      (reports) {
        _allReports = reports;
        _isLoading = false;
        _errorMessage = '';
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _postsSub = _forumRepository.watchPosts().listen(
      (posts) {
        _forumPosts = posts;
        _isLoading = false;
        _errorMessage = '';
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _reportsSub?.cancel();
    _postsSub?.cancel();
    _authListener?.cancel();
    super.dispose();
  }
}
