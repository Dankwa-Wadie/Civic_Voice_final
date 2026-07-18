import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../view_models/dashboard_view_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import 'tabs/overview_tab.dart';
import 'tabs/reports_table_tab.dart';
import 'tabs/map_tab.dart';
import '../../../features/reporting/views/report_form_screen.dart';
import '../../auth/views/login_screen.dart';
import 'package:civic_voice/ui/features/user_dashboard/views/user_dashboard_screen.dart';
import 'package:civic_voice/ui/features/user_dashboard/view_models/user_dashboard_view_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Overview',
    ),
    _NavItem(
      icon: Icons.table_chart_outlined,
      selectedIcon: Icons.table_chart_rounded,
      label: 'Reports',
    ),
    _NavItem(
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      label: 'Map',
    ),
    _NavItem(
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum_rounded,
      label: 'Forum',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWide) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppTheme.sm),
            ],
            const Text('CivicVoice'),
            const SizedBox(width: AppTheme.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.xs + 2,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: AppTheme.radiusChip,
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.error,
              size: 20,
            ),
            tooltip: 'Logout',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              navigator.pushReplacementNamed(LoginScreen.routeName);
            },
          ),
          // Refresh button
          Consumer<DashboardViewModel>(
            builder: (context, vm, _) => IconButton(
              icon: vm.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              onPressed: vm.isLoading ? null : vm.refresh,
              tooltip: 'Refresh reports',
            ),
          ),
          // Theme Toggle Button (Dark / Light mode)
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              final isDark = themeProvider.isDarkMode;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                  color: isDark ? Colors.amber[400] : AppTheme.primary,
                  size: 20,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () {
                  themeProvider.setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
              );
            },
          ),
          // Report new incident button
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.sm),
            child: isWide
                ? FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReportFormScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('New Report'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.md,
                        vertical: AppTheme.sm,
                      ),
                      minimumSize: const Size(0, 40),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    tooltip: 'New Report',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReportFormScreen(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (i) =>
                        setState(() => _selectedIndex = i),
                    extended: MediaQuery.of(context).size.width > 900,
                    minExtendedWidth: 180,
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.md),
                          child: Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              final isDark = themeProvider.isDarkMode;
                              final isExtended =
                                  MediaQuery.of(context).size.width > 900;
                              if (isExtended) {
                                return TextButton.icon(
                                  onPressed: () {
                                    themeProvider.setThemeMode(
                                      isDark
                                          ? ThemeMode.light
                                          : ThemeMode.dark,
                                    );
                                  },
                                  icon: Icon(
                                    isDark
                                        ? Icons.wb_sunny_rounded
                                        : Icons.dark_mode_rounded,
                                    color: isDark
                                        ? Colors.amber[400]
                                        : AppTheme.primary,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isDark ? 'Light Mode' : 'Dark Mode',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.amber[400]
                                          : AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return IconButton(
                                icon: Icon(
                                  isDark
                                      ? Icons.wb_sunny_rounded
                                      : Icons.dark_mode_rounded,
                                  color: isDark
                                      ? Colors.amber[400]
                                      : AppTheme.primary,
                                  size: 20,
                                ),
                                tooltip: isDark
                                    ? 'Switch to Light Mode'
                                    : 'Switch to Dark Mode',
                                onPressed: () {
                                  themeProvider.setThemeMode(
                                    isDark ? ThemeMode.light : ThemeMode.dark,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    destinations: _navItems
                        .map(
                          (item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildBody()),
                ],
              )
            : _buildBody(),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              backgroundColor: context.themeSurface,
              indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
              destinations: _navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon, color: context.themeOnSurfaceDim),
                      selectedIcon: Icon(
                        item.selectedIcon,
                        color: AppTheme.primary,
                      ),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildBody() {
    return switch (_selectedIndex) {
      0 => const OverviewTab(),
      1 => const ReportsTableTab(),
      2 => const MapTab(),
      3 => const _AdminForumTab(),
      _ => const OverviewTab(),
    };
  }
}

class _AdminForumTab extends StatefulWidget {
  const _AdminForumTab();

  @override
  State<_AdminForumTab> createState() => _AdminForumTabState();
}

class _AdminForumTabState extends State<_AdminForumTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDashboardViewModel>(
      builder: (context, vm, _) {
        return ForumTab(
          vm: vm,
          isAdminOverride: true,
          messageController: _messageController,
          scrollController: _scrollController,
          onSend: (bool isPinned) {
            vm.sendForumMessage(_messageController.text, isPinned: isPinned);
            _messageController.clear();
            _scrollToBottom();
          },
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
