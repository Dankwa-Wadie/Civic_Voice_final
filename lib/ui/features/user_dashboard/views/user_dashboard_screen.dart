// lib/ui/features/user_dashboard/views/user_dashboard_screen.dart
// Premium landing dashboard for citizens of Accra to track reports and converse.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:civic_voice/data/models/incident_report.dart';
import 'package:civic_voice/data/models/forum_post.dart';
import 'package:civic_voice/domain/enums/incident_status.dart';
import 'package:civic_voice/domain/enums/incident_category.dart';
import 'package:civic_voice/ui/core/theme/app_theme.dart';
import 'package:civic_voice/ui/core/theme/theme_provider.dart';
import 'package:civic_voice/ui/features/reporting/views/report_form_screen.dart';
import 'package:civic_voice/ui/features/auth/views/login_screen.dart';
import '../view_models/user_dashboard_view_model.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'tabs/user_map_tab.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  static const routeName = '/user-dashboard';

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<UserDashboardViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CivicVoice Portal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Welcome, ${vm.currentUserName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppTheme.primaryLight, size: 22),
            tooltip: 'Profile Settings',
            onPressed: () => _showProfileSheet(context, vm),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
            tooltip: 'Logout',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await vm.logout();
              navigator.pushReplacementNamed(LoginScreen.routeName);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.onSurface,
          unselectedLabelColor: AppTheme.onSurfaceMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.assignment_rounded, size: 18), text: 'My Reports'),
            Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Incident Map'),
            Tab(icon: Icon(Icons.forum_rounded, size: 18), text: 'Community Forum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyReportsTab(vm: vm),
          const UserMapTab(),
          ForumTab(
            vm: vm,
            messageController: _messageController,
            scrollController: _scrollController,
            onSend: () {
              vm.sendForumMessage(_messageController.text);
              _messageController.clear();
              _scrollToBottom();
            },
          ),
        ],
      ),
      floatingActionButton: _tabController.index != 2
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed(ReportFormScreen.routeName);
              },
              icon: const Icon(Icons.add_location_alt_rounded, color: AppTheme.onPrimary),
              label: const Text('Report Issue', style: TextStyle(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.primary,
            )
          : null,
    );
  }
}

// ── Reports Tab ─────────────────────────────────────────────────────────────
class _MyReportsTab extends StatelessWidget {
  const _MyReportsTab({required this.vm});
  final UserDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final reports = vm.myReports;

    return Column(
      children: [
        _StatsHeader(reports: reports),
        Expanded(
          child: reports.isEmpty
              ? _EmptyReportsState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.md),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _ReportCard(report: report);
                  },
                ),
        ),
      ],
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.reports});
  final List<IncidentReport> reports;

  @override
  Widget build(BuildContext context) {
    final total = reports.length;
    final workedOn = reports.where((r) => r.status != IncidentStatus.submitted).length;
    final resolved = reports.where((r) => r.status == IncidentStatus.resolved).length;

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.md, horizontal: AppTheme.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatCard(title: 'Total', value: total.toString(), color: AppTheme.info),
          _StatCard(title: 'Worked On', value: workedOn.toString(), color: AppTheme.warning),
          _StatCard(title: 'Resolved', value: resolved.toString(), color: AppTheme.success),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.color});
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: AppTheme.surfaceVariant,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.xs),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.radiusCard,
          side: BorderSide(color: AppTheme.divider.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.sm, horizontal: AppTheme.md),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppTheme.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_rounded, size: 72, color: AppTheme.onSurfaceDim.withOpacity(0.5)),
            const SizedBox(height: AppTheme.md),
            Text(
              'No Reports Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Help us maintain Accra! Report infrastructure issues like potholes, water leaks, or light failures today.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final IncidentReport report;

  Color _getStatusColor(IncidentStatus status) => switch (status) {
        IncidentStatus.submitted => AppTheme.statusSubmitted,
        IncidentStatus.reviewed => AppTheme.statusReviewed,
        IncidentStatus.dispatched => AppTheme.statusDispatched,
        IncidentStatus.resolved => AppTheme.statusResolved,
      };

  Color _getCategoryColor(IncidentCategory category) => switch (category) {
        IncidentCategory.pothole => AppTheme.categoryPothole,
        IncidentCategory.waterLeak => AppTheme.categoryWaterLeak,
        IncidentCategory.structuralLightFailure => AppTheme.categoryLightFailure,
        IncidentCategory.drainageBlockage => AppTheme.categoryDrainage,
        IncidentCategory.roadDamage => AppTheme.categoryRoadDamage,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(report.status);
    final categoryColor = _getCategoryColor(report.category);
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(report.timestamp);

    return Card(
      color: AppTheme.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppTheme.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.radiusCard,
        side: const BorderSide(color: AppTheme.divider),
      ),
      child: InkWell(
        borderRadius: AppTheme.radiusCard,
        onTap: () => _showReportDetailsSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  report.category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.sm),
                        _StatusBadge(status: report.status, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: AppTheme.xs),
                    Text(
                      report.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.sm),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: AppTheme.onSurfaceDim, size: 12),
                        const SizedBox(width: AppTheme.xs),
                        Expanded(
                          child: Text(
                            report.district,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final categoryColor = _getCategoryColor(report.category);
        final statusColor = _getStatusColor(report.status);

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppTheme.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: AppTheme.xs),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.15),
                          borderRadius: AppTheme.radiusChip,
                        ),
                        child: Row(
                          children: [
                            Text(
                              report.category.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: AppTheme.xs),
                            Text(
                              report.category.displayName,
                              style: TextStyle(color: categoryColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(status: report.status, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: AppTheme.md),
                  Text(
                    report.title,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: AppTheme.xs),
                  Text(
                    'Reference ID: ${report.id.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: AppTheme.md),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: AppTheme.md),
                  Text(
                    'DESCRIPTION',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.xs),
                  Text(
                    report.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppTheme.lg),
                  Text(
                    'LOCATION',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.xs),
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: AppTheme.primary, size: 16),
                      const SizedBox(width: AppTheme.xs),
                      Text(
                        '${report.district} (${report.latitude.toStringAsFixed(5)}° N, ${report.longitude.toStringAsFixed(5)}° E)',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.lg),
                  if (report.imageUrl.isNotEmpty) ...[
                    Text(
                      'PHOTO',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppTheme.xs),
                    ClipRRect(
                      borderRadius: AppTheme.radiusCard,
                      child: Image.network(
                        report.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: 200,
                          color: AppTheme.surfaceVariant,
                          child: const Icon(Icons.image_not_supported_rounded, color: AppTheme.onSurfaceDim, size: 36),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final IncidentStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: AppTheme.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppTheme.radiusChip,
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class PinnedAnnouncement extends StatelessWidget {
  const PinnedAnnouncement({required this.post, required this.vm});
  final ForumPost post;
  final UserDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: AppTheme.sm),
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.12),
        borderRadius: AppTheme.radiusCard,
        border: Border.all(color: AppTheme.warning.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin_rounded, color: AppTheme.warning, size: 16),
              const SizedBox(width: AppTheme.xs),
              Text(
                'PINNED ANNOUNCEMENT',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (vm.isAdmin)
                IconButton(
                  icon: const Icon(Icons.pin_drop_outlined, color: AppTheme.onSurfaceDim, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => vm.togglePinPost(post),
                  tooltip: 'Unpin broadcast',
                ),
            ],
          ),
          const SizedBox(height: AppTheme.xs),
          Text(
            post.content,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppTheme.xs),
          Text(
            'by ${post.authorName}',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Forum Tab ────────────────────────────────────────────────────────────────
class ForumTab extends StatelessWidget {
  const ForumTab({
    required this.vm,
    required this.messageController,
    required this.scrollController,
    required this.onSend,
  });

  final UserDashboardViewModel vm;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final posts = vm.forumPosts; // Index 0 is newest
    final pinnedPosts = posts.where((p) => p.isPinned).toList();

    return Column(
      children: [
        if (pinnedPosts.isNotEmpty) PinnedAnnouncement(post: pinnedPosts.first, vm: vm),
        Expanded(
          child: posts.isEmpty
              ? _EmptyForumState()
              : ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppTheme.md),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final isMe = post.authorId == vm.currentUserId;
                    return ForumMessageBubble(post: post, isMe: isMe, vm: vm);
                  },
                ),
        ),
        _ForumInputArea(
          vm: vm,
          controller: messageController,
          onSend: onSend,
        ),
      ],
    );
  }
}

class ForumMessageBubble extends StatelessWidget {
  const ForumMessageBubble({required this.post, required this.isMe, required this.vm});
  final ForumPost post;
  final bool isMe;
  final UserDashboardViewModel vm;

  Widget _buildRoleBadge(String email, String name) {
    final bool isAnonAdmin = name.contains('Anonymous Admin') || email == 'anonymous-admin';
    final bool isAnon = (name.contains('Anonymous') || email == 'anonymous') && !isAnonAdmin;
    final bool isAdmin = email.contains('admin') || name.toLowerCase().contains('admin');
    
    final Color bgColor;
    final Color textColor;
    final String label;

    if (isAnonAdmin) {
      label = 'Anonymous Admin';
      bgColor = Colors.deepOrange.withOpacity(0.15);
      textColor = Colors.deepOrange;
    } else if (isAnon) {
      label = 'Anonymous';
      bgColor = Colors.amber.withOpacity(0.15);
      textColor = Colors.amber[300]!;
    } else if (isAdmin) {
      label = 'Admin';
      bgColor = AppTheme.error.withOpacity(0.15);
      textColor = AppTheme.error;
    } else {
      label = 'Citizen';
      bgColor = AppTheme.primary.withOpacity(0.15);
      textColor = AppTheme.primaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('hh:mm a').format(post.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.xs),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: post.isPinned
              ? Border.all(color: AppTheme.warning.withOpacity(0.6), width: 1.5)
              : (isMe ? null : Border.all(color: AppTheme.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMe ? 'You (${post.authorName})' : post.authorName,
                      style: TextStyle(
                        color: isMe ? AppTheme.onPrimary.withOpacity(0.9) : AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: AppTheme.xs),
                    _buildRoleBadge(post.authorEmail, post.authorName),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (post.isPinned)
                      const Icon(Icons.push_pin_rounded, color: AppTheme.warning, size: 12),
                    if (vm.isAdmin) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => vm.togglePinPost(post),
                        child: Icon(
                          post.isPinned ? Icons.pin_drop_rounded : Icons.push_pin_outlined,
                          color: post.isPinned ? AppTheme.warning : AppTheme.onSurfaceDim,
                          size: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.xs + 2),
            Text(
              post.content,
              style: TextStyle(
                color: isMe ? AppTheme.onPrimary : AppTheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.xs),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                formattedTime,
                style: TextStyle(
                  color: isMe ? AppTheme.onPrimary.withOpacity(0.7) : AppTheme.onSurfaceDim,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumInputArea extends StatelessWidget {
  const _ForumInputArea({
    required this.vm,
    required this.controller,
    required this.onSend,
  });
  final UserDashboardViewModel vm;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: AppTheme.sm),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: AppTheme.onSurface),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        onSend();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: vm.isAnonymousChat
                          ? 'Share anonymously...'
                          : 'Share an update or discuss Accra issues...',
                      hintStyle: const TextStyle(color: AppTheme.onSurfaceMuted),
                      fillColor: AppTheme.background,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.radiusCard,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.md,
                        vertical: AppTheme.sm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.sm),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      onSend();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  vm.isAnonymousChat ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 14,
                  color: vm.isAnonymousChat ? Colors.amber[300] : AppTheme.onSurfaceDim,
                ),
                const SizedBox(width: 4),
                Text(
                  vm.isAnonymousChat ? 'Anonymous Mode' : 'Post publicly',
                  style: TextStyle(
                    fontSize: 11,
                    color: vm.isAnonymousChat ? Colors.amber[300] : AppTheme.onSurfaceDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Post Anonymously',
                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceDim),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 28,
                  child: Switch(
                    value: vm.isAnonymousChat,
                    onChanged: vm.setAnonymousChat,
                    activeColor: Colors.amber[400],
                    activeTrackColor: Colors.amber.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyForumState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 72, color: AppTheme.onSurfaceDim.withOpacity(0.5)),
            const SizedBox(height: AppTheme.md),
            Text(
              'No Conversations Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Start the conversation! Share news about infrastructure repairs, ask questions, or connect with other Accra residents.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void _showProfileSheet(BuildContext context, UserDashboardViewModel vm) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final themeProvider = Provider.of<ThemeProvider>(context);
      return _ProfileSheet(vm: vm, themeProvider: themeProvider);
    },
  );
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.vm, required this.themeProvider});
  final UserDashboardViewModel vm;
  final ThemeProvider themeProvider;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final TextEditingController _nicknameController;
  final ShorebirdCodePush _shorebird = ShorebirdCodePush();
  bool _isShorebirdAvailable = false;
  int? _currentPatch;
  bool _isCheckingForUpdates = false;
  bool _isUpdateAvailable = false;
  String _updateStatusText = '';
  bool _isDownloadingUpdate = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.vm.nickname);
    _isShorebirdAvailable = _shorebird.isShorebirdAvailable();
    if (_isShorebirdAvailable) {
      _updateStatusText = 'Updates enabled';
      _shorebird.currentPatchNumber().then((patch) {
        if (mounted) {
          setState(() {
            _currentPatch = patch;
          });
        }
      });
    } else {
      _updateStatusText = 'Shorebird not available in this build';
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    if (!_isShorebirdAvailable) return;
    setState(() {
      _isCheckingForUpdates = true;
      _updateStatusText = 'Checking for updates...';
    });
    try {
      final isUpdateAvailable = await _shorebird.isNewPatchAvailableForDownload();
      setState(() {
        _isCheckingForUpdates = false;
        _isUpdateAvailable = isUpdateAvailable;
        if (isUpdateAvailable) {
          _updateStatusText = 'New live update available!';
        } else {
          _updateStatusText = 'Application is up-to-date (Patch ${_currentPatch ?? 0})';
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingForUpdates = false;
        _updateStatusText = 'Check failed: $e';
      });
    }
  }

  Future<void> _downloadAndInstallUpdate() async {
    setState(() {
      _isDownloadingUpdate = true;
      _updateStatusText = 'Downloading live update...';
    });
    try {
      await _shorebird.downloadUpdateIfAvailable();
      setState(() {
        _isDownloadingUpdate = false;
        _updateStatusText = 'Update downloaded! Restart to apply changes.';
      });
    } catch (e) {
      setState(() {
        _isDownloadingUpdate = false;
        _updateStatusText = 'Download failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.md,
        right: AppTheme.md,
        top: AppTheme.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.lg,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Settings',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.vm.currentUserEmail,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.lg),
          Text(
            'NICKNAME',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: AppTheme.sm),
          TextField(
            controller: _nicknameController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter your nickname...',
              prefixIcon: const Icon(Icons.badge_outlined, size: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_rounded, color: AppTheme.success),
                onPressed: () {
                  widget.vm.setNickname(_nicknameController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nickname updated!')),
                  );
                },
              ),
            ),
            onSubmitted: (val) {
              widget.vm.setNickname(val);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nickname updated!')),
              );
            },
          ),
          const SizedBox(height: AppTheme.lg),
          Text(
            'APPEARANCE',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: AppTheme.sm),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.themeProvider.setThemeMode(ThemeMode.light),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                    decoration: BoxDecoration(
                      color: !isDark ? AppTheme.primary.withOpacity(0.12) : theme.colorScheme.surface,
                      borderRadius: AppTheme.radiusCard,
                      border: Border.all(
                        color: !isDark ? AppTheme.primary : theme.colorScheme.outline,
                        width: !isDark ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          color: !isDark ? AppTheme.primary : theme.colorScheme.onSurface,
                          size: 24,
                        ),
                        const SizedBox(height: AppTheme.sm),
                        Text(
                          'Light Mode',
                          style: TextStyle(
                            color: !isDark ? AppTheme.primary : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.themeProvider.setThemeMode(ThemeMode.dark),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.primary.withOpacity(0.12) : theme.colorScheme.surface,
                      borderRadius: AppTheme.radiusCard,
                      border: Border.all(
                        color: isDark ? AppTheme.primary : theme.colorScheme.outline,
                        width: isDark ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dark_mode_rounded,
                          color: isDark ? AppTheme.primary : theme.colorScheme.onSurface,
                          size: 24,
                        ),
                        const SizedBox(height: AppTheme.sm),
                        Text(
                          'Dark Mode',
                          style: TextStyle(
                            color: isDark ? AppTheme.primary : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.lg),
          Text(
            'APPLICATION UPDATES',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: AppTheme.sm),
          Container(
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: AppTheme.radiusCard,
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isShorebirdAvailable ? Icons.offline_bolt_rounded : Icons.offline_bolt_outlined,
                      color: _isShorebirdAvailable ? Colors.amber[300] : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isShorebirdAvailable ? 'Live updates active' : 'Live updates inactive',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _updateStatusText,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_currentPatch != null)
                      Chip(
                        label: Text('Patch $_currentPatch', style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                if (_isShorebirdAvailable) ...[
                  const SizedBox(height: AppTheme.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!_isUpdateAvailable)
                        TextButton.icon(
                          onPressed: _isCheckingForUpdates ? null : _checkForUpdates,
                          icon: _isCheckingForUpdates
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Check for Updates'),
                        ),
                      if (_isUpdateAvailable)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.onPrimary,
                          ),
                          onPressed: _isDownloadingUpdate ? null : _downloadAndInstallUpdate,
                          icon: _isDownloadingUpdate
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Download & Apply Update'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.lg),
        ],
      ),
    );
  }
}
