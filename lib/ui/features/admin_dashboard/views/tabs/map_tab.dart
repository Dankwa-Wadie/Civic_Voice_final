import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/dashboard_view_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../../data/models/incident_report.dart';
import '../../../../../domain/enums/incident_category.dart';
import '../../../../../domain/enums/incident_status.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  IncidentReport? _selectedReport;

  // Accra city center
  static const LatLng _accraCentre = LatLng(5.6037, -0.1870);
  static const double _initialZoom = 12.0;

  IncidentCategory? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        final reports = _categoryFilter == null
            ? vm.allReports
            : vm.allReports
                  .where((r) => r.category == _categoryFilter)
                  .toList();

        final markers = _buildMarkers(reports);

        return Stack(
          children: [
            // ── OpenStreetMap via flutter_map ────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _accraCentre,
                initialZoom: _initialZoom,
                onTap: (_, __) => setState(() => _selectedReport = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.civicvoice.civic_voice',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            // ── Top overlay: category filter chips ──────────────────────
            Positioned(
              top: AppTheme.md,
              left: AppTheme.md,
              right: AppTheme.md,
              child: _CategoryFilterChips(
                selectedCategory: _categoryFilter,
                onSelected: (cat) => setState(() => _categoryFilter = cat),
              ),
            ),
            // ── Bottom right: zoom controls ─────────────────────────────
            Positioned(
              right: AppTheme.md,
              bottom: _selectedReport != null ? 280 : AppTheme.md,
              child: _ZoomControls(
                onZoomIn: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
                onZoomOut: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                onReset: () {
                  _mapController.move(_accraCentre, _initialZoom);
                },
              ),
            ),
            // ── Legend ──────────────────────────────────────────────────
            Positioned(
              left: AppTheme.md,
              bottom: _selectedReport != null ? 280 : AppTheme.md,
              child: _MapLegend(reports: vm.allReports),
            ),
            // ── Report detail sheet ─────────────────────────────────────
            if (_selectedReport != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _ReportBottomSheet(
                  report: _selectedReport!,
                  onClose: () => setState(() => _selectedReport = null),
                  onStatusUpdate: (id, status) => vm.updateStatus(id, status),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Marker> _buildMarkers(List<IncidentReport> reports) {
    return reports.map((report) {
      final color = _categoryToColor(report.category);
      return Marker(
        point: LatLng(report.latitude, report.longitude),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedReport = report);
            _mapController.move(
              LatLng(report.latitude, report.longitude),
              15.0,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Color _categoryToColor(IncidentCategory category) => switch (category) {
    IncidentCategory.pothole => AppTheme.categoryPothole,
    IncidentCategory.waterLeak => AppTheme.categoryWaterLeak,
    IncidentCategory.structuralLightFailure => AppTheme.categoryLightFailure,
    IncidentCategory.drainageBlockage => AppTheme.categoryDrainage,
    IncidentCategory.roadDamage => AppTheme.categoryRoadDamage,
  };
}

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({
    required this.selectedCategory,
    required this.onSelected,
  });

  final IncidentCategory? selectedCategory;
  final void Function(IncidentCategory?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.xs),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedCategory == null,
              onSelected: (_) => onSelected(null),
              backgroundColor: AppTheme.surface.withValues(alpha: 0.92),
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primary,
              side: BorderSide(
                color: selectedCategory == null
                    ? AppTheme.primary
                    : AppTheme.divider,
              ),
              labelStyle: TextStyle(
                color: selectedCategory == null
                    ? AppTheme.primary
                    : AppTheme.onSurfaceMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...IncidentCategory.values.map((cat) {
            final isSelected = selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.xs),
              child: FilterChip(
                label: Text('${cat.emoji} ${cat.displayName}'),
                selected: isSelected,
                onSelected: (_) => onSelected(isSelected ? null : cat),
                backgroundColor: AppTheme.surface.withValues(alpha: 0.92),
                selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primary,
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : AppTheme.divider,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.onSurfaceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapControlButton(icon: Icons.add_rounded, onTap: onZoomIn),
        const SizedBox(height: AppTheme.xs),
        _MapControlButton(icon: Icons.remove_rounded, onTap: onZoomOut),
        const SizedBox(height: AppTheme.xs),
        _MapControlButton(icon: Icons.my_location_rounded, onTap: onReset),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.radiusButton,
      elevation: 4,
      shadowColor: Colors.black45,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radiusButton,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: AppTheme.onSurface, size: 20),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.reports});
  final List<IncidentReport> reports;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sm + 2),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        borderRadius: AppTheme.radiusCard,
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legend',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.xs),
          ...IncidentCategory.values.map((cat) {
            final count = reports.where((r) => r.category == cat).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${cat.displayName} ($count)',
                    style: Theme.of(context).textTheme.bodySmall,
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

class _ReportBottomSheet extends StatelessWidget {
  const _ReportBottomSheet({
    required this.report,
    required this.onClose,
    required this.onStatusUpdate,
  });

  final IncidentReport report;
  final VoidCallback onClose;
  final void Function(String id, IncidentStatus status) onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    final nextStatuses = report.status.nextStatuses;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppTheme.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppTheme.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: AppTheme.radiusChip,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.lg,
                right: AppTheme.lg,
                top: AppTheme.sm,
                bottom: AppTheme.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: AppTheme.xs),
                                Text(
                                  report.district,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: onClose,
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.sm),
                      Wrap(
                        spacing: AppTheme.sm,
                        children: [
                          StatusBadge(status: report.status),
                          CategoryBadge(category: report.category),
                        ],
                      ),
                      const SizedBox(height: AppTheme.sm),
                      Text(
                        report.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.sm),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: AppTheme.onSurfaceDim,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report.reporterName.startsWith('anonymous:')
                                ? 'Anonymous Citizen'
                                : report.reporterName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppTheme.md),
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppTheme.onSurfaceDim,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'MMM d, y · HH:mm',
                            ).format(report.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (nextStatuses.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.md),
                        const Divider(),
                        const SizedBox(height: AppTheme.sm),
                        Text(
                          'Advance Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.sm),
                        Wrap(
                          spacing: AppTheme.sm,
                          runSpacing: AppTheme.xs,
                          children: nextStatuses.map((s) {
                            return ElevatedButton(
                              onPressed: () {
                                onStatusUpdate(report.id, s);
                                onClose();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _statusColor(
                                  s,
                                ).withValues(alpha: 0.15),
                                foregroundColor: _statusColor(s),
                                side: BorderSide(color: _statusColor(s)),
                                elevation: 0,
                              ),
                              child: Text(
                                '→ ${s.displayName}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(IncidentStatus s) => switch (s) {
    IncidentStatus.submitted => AppTheme.statusSubmitted,
    IncidentStatus.reviewed => AppTheme.statusReviewed,
    IncidentStatus.dispatched => AppTheme.statusDispatched,
    IncidentStatus.resolved => AppTheme.statusResolved,
  };
}
