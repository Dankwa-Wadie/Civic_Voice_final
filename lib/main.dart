import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/repositories/mock_civic_data_repository.dart';
import 'data/repositories/firebase_firestore_repository.dart';
import 'data/repositories/i_civic_repository.dart';
import 'data/repositories/i_forum_repository.dart';
import 'data/repositories/mock_forum_repository.dart';
import 'data/repositories/firebase_forum_repository.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/core/theme/theme_provider.dart';
import 'ui/features/auth/views/login_screen.dart';
import 'ui/features/admin_dashboard/views/dashboard_screen.dart';
import 'ui/features/admin_dashboard/view_models/dashboard_view_model.dart';
import 'ui/features/reporting/view_models/report_submission_view_model.dart';
import 'ui/features/reporting/views/report_form_screen.dart';
import 'ui/features/user_dashboard/views/user_dashboard_screen.dart';
import 'ui/features/user_dashboard/view_models/user_dashboard_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const CivicVoiceApp());
}

/// Root application widget.
///
/// DI strategy:
/// - Dynamic fallback: If Firebase is initialized, uses [FirebaseFirestoreRepository].
///   Otherwise, falls back to [MockCivicDataRepository] to prevent runtime crashes.
class CivicVoiceApp extends StatefulWidget {
  const CivicVoiceApp({super.key});

  @override
  State<CivicVoiceApp> createState() => _CivicVoiceAppState();
}

class _CivicVoiceAppState extends State<CivicVoiceApp> {
  // Single shared repository instance — Dynamic fallback swap.
  late final ICivicRepository _repository;
  late final IForumRepository _forumRepository;

  @override
  void initState() {
    super.initState();
    // ── Phase 2: Dynamic Repository Swapping ──────────────────────────────────
    final hasFirebase = Firebase.apps.isNotEmpty;
    if (hasFirebase) {
      _repository = FirebaseFirestoreRepository();
      _forumRepository = FirebaseForumRepository();
    } else {
      _repository = MockCivicDataRepository();
      _forumRepository = MockForumRepository();
    }
  }

  @override
  void dispose() {
    // Clean up StreamController in mock repositories
    final repo = _repository;
    if (repo is MockCivicDataRepository) {
      repo.dispose();
    }
    final forumRepo = _forumRepository;
    if (forumRepo is MockForumRepository) {
      forumRepo.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Theme Provider ───────────────────────────────────────────────────
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        // ── Dashboard ViewModel ───────────────────────────────────────────────
        ChangeNotifierProvider<DashboardViewModel>(
          create: (_) => DashboardViewModel(repository: _repository),
        ),
        // ── Report Submission ViewModel ───────────────────────────────────────
        ChangeNotifierProvider<ReportSubmissionViewModel>(
          create: (_) => ReportSubmissionViewModel(repository: _repository),
        ),
        // ── User Dashboard & Forum ViewModel ──────────────────────────────────
        ChangeNotifierProvider<UserDashboardViewModel>(
          create: (_) => UserDashboardViewModel(
            civicRepository: _repository,
            forumRepository: _forumRepository,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'CivicVoice',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: LoginScreen.routeName,
            routes: {
              LoginScreen.routeName: (_) => const LoginScreen(),
              DashboardScreen.routeName: (_) => const DashboardScreen(),
              UserDashboardScreen.routeName: (_) => const UserDashboardScreen(),
              ReportFormScreen.routeName: (ctx) => ChangeNotifierProvider.value(
                value: ctx.read<ReportSubmissionViewModel>()..reset(),
                child: const ReportFormScreen(),
              ),
            },
            // 404 fallback
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );
        },
      ),
    );
  }
}
