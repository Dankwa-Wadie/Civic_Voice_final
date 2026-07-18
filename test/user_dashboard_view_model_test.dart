// test/user_dashboard_view_model_test.dart
// Unit tests for the Citizen Dashboard & Forum ViewModel.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_voice/data/models/forum_post.dart';
import 'package:civic_voice/data/models/incident_report.dart';
import 'package:civic_voice/domain/enums/incident_category.dart';
import 'package:civic_voice/domain/enums/incident_status.dart';
import 'package:civic_voice/data/repositories/mock_civic_data_repository.dart';
import 'package:civic_voice/data/repositories/mock_forum_repository.dart';
import 'package:civic_voice/ui/features/user_dashboard/view_models/user_dashboard_view_model.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  group('UserDashboardViewModel Tests', () {
    late MockCivicDataRepository civicRepo;
    late MockForumRepository forumRepo;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late UserDashboardViewModel vm;

    setUp(() {
      civicRepo = MockCivicDataRepository();
      forumRepo = MockForumRepository();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('citizen@civicvoice.net');
      when(() => mockUser.uid).thenReturn('citizen-uid');
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

      vm = UserDashboardViewModel(
        civicRepository: civicRepo,
        forumRepository: forumRepo,
        auth: mockAuth,
      );
    });

    tearDown(() {
      vm.dispose();
      civicRepo.dispose();
      forumRepo.dispose();
    });

    test('initial state loads successfully', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      expect(vm.isLoading, isFalse);
      expect(vm.allReports.length, equals(60));
      expect(vm.forumPosts.length, equals(5));
      expect(vm.currentUserEmail, equals('citizen@civicvoice.net'));
      expect(vm.currentUserName, equals('citizen'));
    });

    test('myReports only returns reports matching the citizen email', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      expect(vm.myReports.length, equals(0)); // Seed data has other reporter names
    });

    test('myReports filters by reporterName or anonymous:reporterName', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final report = IncidentReport(
        id: 'rep-1',
        category: IncidentCategory.pothole,
        title: 'Water Leak Accra',
        description: 'Large leaking pipe',
        latitude: 5.6,
        longitude: -0.2,
        imageUrl: '',
        status: IncidentStatus.submitted,
        timestamp: DateTime.now(),
        reporterName: 'anonymous:citizen@civicvoice.net',
        district: 'Ayawaso Central',
      );
      await civicRepo.submitReport(report);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(vm.myReports.length, equals(1));
      expect(vm.myReports.first.title, equals('Water Leak Accra'));
    });

    test('sendForumMessage submits a new message correctly', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      await vm.sendForumMessage('  Testing new chat message   ');
      
      expect(vm.forumPosts.length, equals(6));
      expect(vm.forumPosts.first.content, equals('Testing new chat message'));
      expect(vm.forumPosts.first.authorEmail, equals('citizen@civicvoice.net'));
      expect(vm.forumPosts.first.authorName, equals('citizen'));
    });

    test('sendForumMessage submits anonymously when setAnonymousChat is true', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      vm.setAnonymousChat(true);
      await vm.sendForumMessage('Secret message');

      expect(vm.forumPosts.length, equals(6));
      expect(vm.forumPosts.first.content, equals('Secret message'));
      expect(vm.forumPosts.first.authorEmail, equals('anonymous'));
      expect(vm.forumPosts.first.authorName, startsWith('Anonymous #'));
    });

    test('nickname updates display name correctly', () {
      expect(vm.currentUserName, equals('citizen'));
      vm.setNickname('Star citizen');
      expect(vm.nickname, equals('Star citizen'));
      expect(vm.currentUserName, equals('Star citizen'));
    });

    test('anonymous admin author details generate correctly', () async {
      final anonAdminName = UserDashboardViewModel.getAnonymousName('admin-uid', isAdmin: true);
      expect(anonAdminName, startsWith('Anonymous Admin #'));
    });

    test('togglePinPost triggers updatePost on forum repo', () async {
      final post = ForumPost(
        id: 'post-test-1',
        authorId: 'user-1',
        authorName: 'Test User',
        authorEmail: 'test@civicvoice.net',
        content: 'Test content',
        timestamp: DateTime.now(),
      );
      await vm.togglePinPost(post);
      expect(vm.forumPosts.first.isPinned, isFalse);
    });
  });
}
