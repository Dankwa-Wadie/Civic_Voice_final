import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../../data/models/incident_report.dart';
import '../../../../../domain/enums/incident_category.dart';
import '../../view_models/user_dashboard_view_model.dart';

class UserMapTab extends StatefulWidget {
  const UserMapTab({super.key});

  @override
  State<UserMapTab> createState() => _UserMapTabState();
}

class _UserMapTabState extends State<UserMapTab> {
  final MapController _mapController = MapController();
  IncidentReport? _selectedReport;

  bool _permissionChecked = false;
  bool _permissionGranted = false;
  bool _isFetchingLocation = false;
  LatLng? _userLocation;

  // Accra city center
  static const LatLng _accraCentre = LatLng(5.6037, -0.1870);
  static const double _initialZoom = 13.0;

  IncidentCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        setState(() {
          _permissionGranted = true;
          _permissionChecked = true;
        });
        _getUserLocation();
      } else if (kIsWeb && permission == LocationPermission.denied) {
        // On web, request permission directly on load if not yet granted/prompted
        setState(() {
          _permissionChecked = true;
        });
        await _requestLocationPermission();
      } else {
        setState(() {
          _permissionGranted = false;
          _permissionChecked = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      setState(() {
        _permissionChecked = true;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isFetchingLocation = true;
    });
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        setState(() {
          _permissionGranted = true;
        });
        await _getUserLocation();
      } else {
        setState(() {
          _permissionGranted = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied. Map centered on Accra.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final isServiceEnabled = kIsWeb
          ? true
          : await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: kIsWeb ? 15 : 5),
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      // Move map to user location on initial fetch
      _mapController.move(_userLocation!, _initialZoom);
    } catch (e) {
      debugPrint('Error getting user location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (!_permissionGranted) {
      return _buildPermissionGatingScreen();
    }

    return Consumer<UserDashboardViewModel>(
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
                initialCenter: _userLocation ?? _accraCentre,
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
            // ── Bottom right: Map control actions ───────────────────────
            Positioned(
              right: AppTheme.md,
              bottom: _selectedReport != null ? 240 : AppTheme.md,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Center on location FAB
                  FloatingActionButton(
                    heroTag: 'my_location_btn',
                    mini: true,
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.primary,
                    onPressed: () async {
                      await _getUserLocation();
                      if (_userLocation != null) {
                        _mapController.move(_userLocation!, 15.0);
                      } else {
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to retrieve current location',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Icon(Icons.my_location_rounded, size: 20),
                  ),
                  const SizedBox(height: AppTheme.sm),
                  _ZoomControls(
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
                      _mapController.move(
                        _userLocation ?? _accraCentre,
                        _initialZoom,
                      );
                    },
                  ),
                ],
              ),
            ),
            // ── Legend ──────────────────────────────────────────────────
            Positioned(
              left: AppTheme.md,
              bottom: _selectedReport != null ? 240 : AppTheme.md,
              child: _MapLegend(reports: vm.allReports),
            ),
            // ── Report detail card ──────────────────────────────────────
            if (_selectedReport != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _ReportDetailCard(
                  report: _selectedReport!,
                  onClose: () => setState(() => _selectedReport = null),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionGatingScreen() {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(AppTheme.xl),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.lg),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 80,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: AppTheme.lg),
              Text(
                'Location Access Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.md),
              Text(
                'Civic Voice needs your location permission to show active infrastructure reports around you and mark your position on the map.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.xl),
              ElevatedButton.icon(
                onPressed: _isFetchingLocation
                    ? null
                    : _requestLocationPermission,
                icon: _isFetchingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.onPrimary,
                        ),
                      )
                    : const Icon(
                        Icons.gps_fixed_rounded,
                        color: AppTheme.onPrimary,
                      ),
                label: Text(
                  _isFetchingLocation
                      ? 'Requesting Access...'
                      : 'Grant Location Access',
                  style: const TextStyle(
                    color: AppTheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.xl,
                    vertical: AppTheme.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusButton,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.md),
              TextButton(
                onPressed: () {
                  setState(() {
                    _permissionGranted =
                        true; // Temporary bypass to show Accra center
                  });
                },
                child: const Text(
                  'Continue without Location',
                  style: TextStyle(color: AppTheme.onSurfaceMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(List<IncidentReport> reports) {
    final list = <Marker>[];

    // User location marker
    if (_userLocation != null) {
      list.add(
        Marker(
          point: _userLocation!,
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Incident markers
    for (final report in reports) {
      final color = _categoryToColor(report.category);
      list.add(
        Marker(
          point: LatLng(report.latitude, report.longitude),
          width: 40,
          height: 40,
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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      report.category.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return list;
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
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.xs),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedCategory == null,
              onSelected: (_) => onSelected(null),
              backgroundColor: AppTheme.surface.withValues(alpha: 0.9),
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primary,
              side: BorderSide(
                color: selectedCategory == null
                    ? AppTheme.primary
                    : AppTheme.divider,
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
                onSelected: (selected) => onSelected(selected ? cat : null),
                backgroundColor: AppTheme.surface.withValues(alpha: 0.9),
                selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primary,
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : AppTheme.divider,
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
    return Card(
      color: AppTheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: onZoomIn,
            tooltip: 'Zoom In',
          ),
          const Divider(height: 1, indent: 8, endIndent: 8),
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            onPressed: onZoomOut,
            tooltip: 'Zoom Out',
          ),
          const Divider(height: 1, indent: 8, endIndent: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: onReset,
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.reports});
  final List<IncidentReport> reports;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface.withValues(alpha: 0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.md,
          vertical: AppTheme.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Active Reports: ${reports.length}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailCard extends StatelessWidget {
  const _ReportDetailCard({required this.report, required this.onClose});
  final IncidentReport report;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'MMM dd, yyyy - hh:mm a',
    ).format(report.timestamp);

    return Container(
      margin: const EdgeInsets.all(AppTheme.md),
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusCard,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${report.category.emoji} ${report.category.displayName}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.xs),
          Text(
            report.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.xs),
          Text(
            report.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: report.status),
              Text(
                formattedDate,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
