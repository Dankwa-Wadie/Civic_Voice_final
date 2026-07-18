import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-screen loading overlay widget.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.lg),
                decoration: BoxDecoration(
                  color: context.themeSurfaceElevated,
                  borderRadius: AppTheme.radiusCard,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 3,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppTheme.md),
                      Text(
                        message!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Inline shimmer-like placeholder for loading states in lists.
class ShimmerPlaceholder extends StatefulWidget {
  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: context.themeDivider.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? AppTheme.radiusButton,
          ),
        );
      },
    );
  }
}

/// Empty state widget for when no data matches filters.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.lg),
              decoration: BoxDecoration(
                color: context.themeSurfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: context.themeOnSurfaceDim),
            ),
            const SizedBox(height: AppTheme.md),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: AppTheme.lg),
              OutlinedButton(onPressed: action, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
