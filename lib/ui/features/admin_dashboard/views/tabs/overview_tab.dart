import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../view_models/dashboard_view_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../../domain/enums/incident_category.dart';
import '../../../../../domain/enums/incident_status.dart';
import '../../../../../data/models/incident_report.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        final stats = vm.stats;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppTheme.xs),
              Text(
                Firebase.apps.isNotEmpty
                    ? 'Incident reports across Accra — live data from Firestore'
                    : 'Incident reports across Accra — live data from mock engine',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.xl),
              // ── Status stat cards ────────────────────────────────────────
              Text(
                'BY STATUS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.sm),
              _ResponsiveStatGrid(
                cards: [
                  StatCard(
                    title: 'Total Reports',
                    value: stats.total,
                    icon: Icons.assessment_rounded,
                    color: AppTheme.primary,
                  ),
                  StatCard(
                    title: 'Submitted',
                    value: stats.submitted,
                    icon: Icons.upload_rounded,
                    color: AppTheme.statusSubmitted,
                    subtitle: 'Awaiting review',
                  ),
                  StatCard(
                    title: 'Reviewed',
                    value: stats.reviewed,
                    icon: Icons.fact_check_outlined,
                    color: AppTheme.statusReviewed,
                    subtitle: 'Pending dispatch',
                  ),
                  StatCard(
                    title: 'Dispatched',
                    value: stats.dispatched,
                    icon: Icons.local_shipping_rounded,
                    color: AppTheme.statusDispatched,
                    subtitle: 'Crew en route',
                  ),
                  StatCard(
                    title: 'Resolved',
                    value: stats.resolved,
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.statusResolved,
                    subtitle: 'Issues closed',
                  ),
                  StatCard(
                    title: 'Resolved This Week',
                    value: stats.resolvedThisWeek,
                    icon: Icons.trending_up_rounded,
                    color: AppTheme.success,
                    subtitle: 'Last 7 days',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.xl),
              // ── Category breakdown ───────────────────────────────────────
              Text(
                'BY CATEGORY',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.sm),
              _CategoryBarChart(
                byCategory: stats.byCategory,
                total: stats.total,
              ),
              const SizedBox(height: AppTheme.xl),
              // ── District breakdown ───────────────────────────────────────
              Text(
                'BY DISTRICT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.sm),
              _DistrictTable(reports: vm.allReports),
            ],
          ),
        );
      },
    );
  }
}

class _ResponsiveStatGrid extends StatelessWidget {
  const _ResponsiveStatGrid({required this.cards});
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount;
    final double aspectRatio;

    if (width > 1200) {
      crossAxisCount = 3;
      aspectRatio = 1.9;
    } else if (width > 800) {
      crossAxisCount = 3;
      aspectRatio = 1.6;
    } else if (width > 600) {
      crossAxisCount = 2;
      aspectRatio = 1.7;
    } else {
      crossAxisCount = 1;
      aspectRatio =
          2.1; // Taller card height on mobile to prevent text clipping
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppTheme.md,
      mainAxisSpacing: AppTheme.md,
      childAspectRatio: aspectRatio,
      children: cards,
    );
  }
}

class _CategoryBarChart extends StatelessWidget {
  const _CategoryBarChart({required this.byCategory, required this.total});

  final Map<IncidentCategory, int> byCategory;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    final categories = IncidentCategory.values;
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppTheme.radiusCard,
        border: Border.all(color: context.themeDivider),
      ),
      child: Column(
        children: categories.map((cat) {
          final count = byCategory[cat] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          final color = AppTheme.categoryColor(cat.name.toLowerCase());
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: AppTheme.sm),
                    Expanded(
                      child: Text(
                        cat.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '$count (${(pct * 100).toStringAsFixed(0)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.xs),
                ClipRRect(
                  borderRadius: AppTheme.radiusChip,
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DistrictTable extends StatelessWidget {
  const _DistrictTable({required this.reports});
  final List<IncidentReport> reports;

  @override
  Widget build(BuildContext context) {
    // Group by district
    final Map<String, Map<String, int>> districtStats = {};
    for (final r in reports) {
      districtStats.putIfAbsent(
        r.district,
        () => {'total': 0, 'resolved': 0, 'active': 0},
      );
      districtStats[r.district]!['total'] =
          (districtStats[r.district]!['total'] ?? 0) + 1;
      if (r.status == IncidentStatus.resolved) {
        districtStats[r.district]!['resolved'] =
            (districtStats[r.district]!['resolved'] ?? 0) + 1;
      } else {
        districtStats[r.district]!['active'] =
            (districtStats[r.district]!['active'] ?? 0) + 1;
      }
    }

    final sorted = districtStats.entries.toList()
      ..sort(
        (a, b) => (b.value['total'] ?? 0).compareTo(a.value['total'] ?? 0),
      );

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppTheme.radiusCard,
        border: Border.all(color: context.themeDivider),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md,
              vertical: AppTheme.sm + 2,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'District',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Resolved',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...sorted.asMap().entries.map((entry) {
            final idx = entry.key;
            final district = entry.value.key;
            final stats = entry.value.value;
            return Container(
              color: idx.isOdd
                  ? context.themeSurfaceVariant.withValues(alpha: 0.5)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.md,
                vertical: AppTheme.sm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      district,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${stats['total']}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${stats['active']}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${stats['resolved']}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
