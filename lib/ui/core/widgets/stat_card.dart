import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable stat card widget for the Admin Dashboard overview.
/// Displays an icon, title, count value with animated counter, and optional
/// trend indicator.
class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final double? trend; // positive = up, negative = down

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _countAnimation = Tween<double>(begin: 0, end: widget.value.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _countAnimation = Tween<double>(
        begin: oldWidget.value.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusCard,
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.sm),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  borderRadius: AppTheme.radiusButton,
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              if (widget.trend != null)
                _TrendBadge(trend: widget.trend!),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, _) {
              return Text(
                _countAnimation.value.toInt().toString(),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.xs),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurfaceMuted,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.trend});
  final double trend;

  @override
  Widget build(BuildContext context) {
    final isUp = trend >= 0;
    final color = isUp ? AppTheme.success : AppTheme.error;
    final icon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppTheme.radiusChip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 2),
          Text(
            '${trend.abs().toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
