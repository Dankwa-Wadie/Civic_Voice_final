import 'package:flutter/material.dart';
import '../../../domain/enums/incident_status.dart';
import '../../../domain/enums/incident_category.dart';
import '../theme/app_theme.dart';

/// Color-coded pill badge for IncidentStatus display.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppTheme.radiusChip,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(IncidentStatus s) => switch (s) {
    IncidentStatus.submitted => AppTheme.statusSubmitted,
    IncidentStatus.reviewed => AppTheme.statusReviewed,
    IncidentStatus.dispatched => AppTheme.statusDispatched,
    IncidentStatus.resolved => AppTheme.statusResolved,
  };
}

/// Color-coded pill badge for IncidentCategory display.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category});
  final IncidentCategory category;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(category);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppTheme.radiusChip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            category.displayName,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(IncidentCategory c) => switch (c) {
    IncidentCategory.pothole => AppTheme.categoryPothole,
    IncidentCategory.waterLeak => AppTheme.categoryWaterLeak,
    IncidentCategory.structuralLightFailure => AppTheme.categoryLightFailure,
    IncidentCategory.drainageBlockage => AppTheme.categoryDrainage,
    IncidentCategory.roadDamage => AppTheme.categoryRoadDamage,
  };
}
