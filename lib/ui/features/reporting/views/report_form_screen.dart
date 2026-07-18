import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:civic_voice/data/repositories/mock_civic_data_repository.dart';
import '../view_models/report_submission_view_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../../domain/enums/incident_category.dart';
import 'submission_success_screen.dart';

class ReportFormScreen extends StatelessWidget {
  const ReportFormScreen({super.key});

  static const routeName = '/report';

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportSubmissionViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text('Report Incident — Step ${vm.currentStep + 1} of ${vm.totalSteps}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (vm.canGoBack) {
                  vm.previousStep();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                // ── Progress bar ────────────────────────────────────────────
                LinearProgressIndicator(
                  value: (vm.currentStep + 1) / vm.totalSteps,
                  backgroundColor: AppTheme.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 3,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: _buildStep(context, vm),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, ReportSubmissionViewModel vm) {
    return switch (vm.currentStep) {
      0 => _Step1Category(key: const ValueKey(0)),
      1 => _Step2Details(key: const ValueKey(1)),
      2 => _Step3Location(key: const ValueKey(2)),
      3 => _Step4Review(key: const ValueKey(3)),
      _ => const SizedBox.shrink(),
    };
  }
}

// ── STEP 1: Category selector ─────────────────────────────────────────────────

class _Step1Category extends StatelessWidget {
  const _Step1Category({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportSubmissionViewModel>(
      builder: (context, vm, _) {
        final width = MediaQuery.of(context).size.width;
        final double ratio = width < 360 ? 1.5 : 1.35; // Responsive child aspect ratio for grid
        return Padding(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What type of issue are you reporting?',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppTheme.xs),
              Text(
                'Select the category that best describes the problem.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.xl),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppTheme.md,
                  mainAxisSpacing: AppTheme.md,
                  childAspectRatio: ratio,
                  children: IncidentCategory.values.map((cat) {
                    final isSelected = vm.selectedCategory == cat;
                    final color = AppTheme.categoryColor(cat.name);
                    return Card(
                      margin: EdgeInsets.zero,
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusCard,
                        side: BorderSide(
                          color: isSelected ? color : AppTheme.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => vm.selectCategory(cat),
                        borderRadius: AppTheme.radiusCard,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cat.emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: AppTheme.sm),
                            Text(
                              cat.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                color: isSelected ? color : null,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppTheme.lg),
              _NextButton(
                enabled: vm.step1Valid,
                onPressed: () => vm.nextStep(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── STEP 2: Title & Description ───────────────────────────────────────────────

class _Step2Details extends StatefulWidget {
  const _Step2Details({super.key});

  @override
  State<_Step2Details> createState() => _Step2DetailsState();
}

class _Step2DetailsState extends State<_Step2Details> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vm = Provider.of<ReportSubmissionViewModel>(context, listen: false);
        
        // Define category-based sample titles & descriptions
        String sampleTitle = 'Pothole on main highway';
        String sampleDesc = 'There is a large pothole in the middle of the road near the intersection, causing hazardous driving conditions.';

        final category = vm.selectedCategory;
        if (category != null) {
          switch (category.firestoreValue) {
            case 'road':
              sampleTitle = 'Blocked road / major pothole';
              sampleDesc = 'A large pothole has formed in the center lane of the road. Vehicles are swerving to avoid it, creating unsafe traffic conditions.';
              break;
            case 'waste':
              sampleTitle = 'Uncollected garbage accumulation';
              sampleDesc = 'A heap of public waste has piled up near the street corner. It is blocking the sidewalk and starting to emit a foul odor.';
              break;
            case 'utility':
              sampleTitle = 'Water main leak / pipe burst';
              sampleDesc = 'Clean water is gushing out from a broken underground pipe onto the sidewalk, causing localized flooding and low pressure.';
              break;
            case 'safety':
              sampleTitle = 'Broken streetlights at intersection';
              sampleDesc = 'Several streetlights at the intersection are completely dark, causing very poor visibility for pedestrians and drivers at night.';
              break;
            case 'other':
              sampleTitle = 'Public property damage / issue';
              sampleDesc = 'Damage observed to public facilities that requires inspection or repair by community responders.';
              break;
          }
        }

        _titleCtrl.text = sampleTitle;
        _descCtrl.text = sampleDesc;
        vm.setTitle(sampleTitle);
        vm.setDescription(sampleDesc);
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportSubmissionViewModel>(
      builder: (context, vm, _) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.lg),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Describe the issue',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppTheme.xs),
                Text(
                  'Help responders understand the severity.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.xl),
                TextFormField(
                  controller: _titleCtrl,
                  onChanged: vm.setTitle,
                  maxLength: 80,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Short title *',
                    hintText: 'e.g. Large pothole on Spintex Road',
                    prefixIcon: Icon(Icons.title_rounded, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'Title must be at least 5 characters'
                      : null,
                ),
                const SizedBox(height: AppTheme.md),
                TextFormField(
                  controller: _descCtrl,
                  onChanged: vm.setDescription,
                  maxLines: 5,
                  maxLength: 500,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Detailed description *',
                    hintText:
                        'Describe the size, risk level, and exact location within the street…',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 64),
                      child: Icon(Icons.notes_rounded, size: 18),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Description must be at least 10 characters'
                      : null,
                ),
                const SizedBox(height: AppTheme.lg),
                _NextButton(
                  enabled: vm.step2Valid,
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      vm.nextStep();
                    }
                  },
                ),
              ],
            ),
          ),
         ),
        );
      },
    );
  }
}

// ── STEP 3: Location & Photo ──────────────────────────────────────────────────

class _Step3Location extends StatefulWidget {
  const _Step3Location({super.key});

  @override
  State<_Step3Location> createState() => _Step3LocationState();
}

class _Step3LocationState extends State<_Step3Location> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _matchingDistricts = [];

  // Accra centre — used as the default initial map position.
  static const LatLng _accraCentre = LatLng(5.6037, -0.1870);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Location method callbacks ───────────────────────────────────────────────

  Future<void> _useLiveLocation() async {
    final vm = context.read<ReportSubmissionViewModel>();
    vm.setLocationChosen(true);

    await vm.fetchLocation();

    // After GPS resolves, pan the map to the new position.
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _mapController.move(
              LatLng(vm.latitude, vm.longitude),
              14.0,
            );
          } catch (_) {
            // Map not ready yet — ignore; initialCenter already uses vm coords.
          }
        }
      });
    }
  }

  void _pinOnMap() {
    context.read<ReportSubmissionViewModel>().setLocationChosen(true);
  }

  // ── District lookup helpers ─────────────────────────────────────────────────

  Map<String, LatLng> _getDistrictCenters() {
    final grouped = <String, List<LatLng>>{};
    for (final r in MockCivicDataRepository.seedData) {
      grouped.putIfAbsent(r.district, () => []).add(LatLng(r.latitude, r.longitude));
    }
    return grouped.map((district, pts) {
      final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
      final lng = pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
      return MapEntry(district, LatLng(lat, lng));
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final districtCenters = _getDistrictCenters();
    final uniqueDistricts =
        MockCivicDataRepository.seedData.map((r) => r.district).toSet().toList();

    return Consumer<ReportSubmissionViewModel>(
      builder: (context, vm, _) {
        final currentLatLng = LatLng(vm.latitude, vm.longitude);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Location & Photo',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppTheme.xs),
              Text(
                'Choose how you want to provide the incident location.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.md),

              // ── Step A: Pick method ─────────────────────────────────────────
              if (!vm.locationChosen) ..._buildLocationChoiceCard(context, vm),

              // ── Step B: Map + search (shown after method chosen) ────────────
              if (vm.locationChosen) ...[
                // District search
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Type district to search (e.g. Osu Klottey)',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _matchingDistricts = [];
                            }),
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _matchingDistricts = val.trim().isEmpty
                          ? []
                          : uniqueDistricts
                              .where((d) => d
                                  .toLowerCase()
                                  .contains(val.trim().toLowerCase()))
                              .toList();
                    });
                  },
                ),
                if (_matchingDistricts.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.xs),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: AppTheme.radiusCard,
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _matchingDistricts.length,
                      itemBuilder: (ctx, i) {
                        final dist = _matchingDistricts[i];
                        return ListTile(
                          dense: true,
                          title: Text(dist,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          onTap: () {
                            final center =
                                districtCenters[dist] ?? _accraCentre;
                            vm.setLocation(
                                center.latitude, center.longitude);
                            setState(() {
                              _searchCtrl.text = dist;
                              _matchingDistricts = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.md),

                // Interactive map
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.radiusCard,
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: ClipRRect(
                    borderRadius: AppTheme.radiusCard,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: currentLatLng,
                        initialZoom: 14.0,
                        onTap: (_, latLng) =>
                            vm.setLocation(latLng.latitude, latLng.longitude),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.civicvoice.civic_voice',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: currentLatLng,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.sm),

                // Coords row + Change button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        vm.isFetchingLocation
                            ? 'Fetching location…'
                            : '${vm.latitude.toStringAsFixed(4)}° N, '
                                '${vm.longitude.toStringAsFixed(4)}° '
                                '${vm.longitude < 0 ? 'W' : 'E'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSurfaceMuted,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: vm.isFetchingLocation
                          ? null
                          : () => vm.setLocationChosen(false),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                      label:
                          const Text('Change', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],

              const Divider(height: AppTheme.xl),

              // ── Photo section ───────────────────────────────────────────────
              Text(
                'Attach Photo (Optional)',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.sm),
              vm.imageFile != null
                  ? _ImagePreview(
                      filePath: vm.imageFile!.path,
                      onRemove: vm.clearImage,
                    )
                  : _PhotoPickerButtons(
                      onCamera: kIsWeb ? null : vm.pickImageFromCamera,
                      onGallery: vm.pickImageFromGallery,
                    ),
              const SizedBox(height: AppTheme.xl),

              // ── CTA button ─────────────────────────────────────────────────
              if (vm.isFetchingLocation)
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    label: const Text('Getting your location…'),
                  ),
                )
              else
                _NextButton(
                  enabled: vm.step3Valid,
                  label: 'Review & Submit',
                  onPressed: () => vm.nextStep(),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the two-option card shown before the user picks a location method.
  List<Widget> _buildLocationChoiceCard(BuildContext context, ReportSubmissionViewModel vm) {
    return [
      Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.radiusCard,
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.sm),
                Expanded(
                  child: Text(
                    'How would you like to set the location?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.md),

            // Option 1 — Live GPS
            _LocationOptionTile(
              icon: Icons.my_location_rounded,
              iconColor: AppTheme.primary,
              title: 'Use My Live Location',
              subtitle: 'Automatically detect where you are right now',
              onTap: _useLiveLocation,
            ),

            const SizedBox(height: AppTheme.sm),

            // Option 2 — Pin on Map
            _LocationOptionTile(
              icon: Icons.map_outlined,
              iconColor: Colors.teal,
              title: 'Select on Map',
              subtitle: 'Tap the map to pin the exact incident location',
              onTap: _pinOnMap,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppTheme.md),
    ];
  }
}

// ── Location Option Tile ──────────────────────────────────────────────────────

class _LocationOptionTile extends StatelessWidget {
  const _LocationOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.radiusCard,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.md,
          vertical: AppTheme.sm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: AppTheme.radiusCard,
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceMuted,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.filePath, required this.onRemove});
  final String filePath;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppTheme.radiusCard,
          child: kIsWeb
              ? Image.network(
                  filePath,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(filePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: AppTheme.xs,
          right: AppTheme.xs,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoPickerButtons extends StatelessWidget {
  const _PhotoPickerButtons({this.onCamera, required this.onGallery});
  final VoidCallback? onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onCamera != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Camera'),
            ),
          ),
          const SizedBox(width: AppTheme.sm),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Gallery'),
          ),
        ),
      ],
    );
  }
}

// ── STEP 4: Review & Submit ───────────────────────────────────────────────────

class _Step4Review extends StatefulWidget {
  const _Step4Review({super.key});

  @override
  State<_Step4Review> createState() => _Step4ReviewState();
}

class _Step4ReviewState extends State<_Step4Review> {
  late ReportSubmissionViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<ReportSubmissionViewModel>();
    _vm.addListener(_onVmChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;

    // Navigate to success screen as soon as submission completes
    if (_vm.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SubmissionSuccessScreen(reportId: _vm.submittedId),
          ),
        );
      });
    }

    // Surface errors in a floating SnackBar so the user ALWAYS sees them,
    // regardless of scroll position. Include a Retry action.
    if (_vm.hasError && _vm.errorMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Submission failed: ${_vm.errorMessage}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleSubmit,
            ),
          ),
        );
      });
    }
  }

  Future<void> _handleSubmit() async {
    // Clear any previous error so the button becomes active again
    _vm.clearError();
    await _vm.submit();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportSubmissionViewModel>(
      builder: (context, vm, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Review your report',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppTheme.xs),
              Text(
                'Check the details below before submitting.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.xl),
              _ReviewCard(label: 'Category', value: vm.selectedCategory?.displayName ?? ''),
              const SizedBox(height: AppTheme.sm),
              _ReviewCard(label: 'Title', value: vm.title),
              const SizedBox(height: AppTheme.sm),
              _ReviewCard(label: 'Description', value: vm.description),
              const SizedBox(height: AppTheme.sm),
              _ReviewCard(
                label: 'GPS',
                value:
                    '${vm.latitude.toStringAsFixed(5)}° N, ${vm.longitude.toStringAsFixed(5)}° E',
              ),
              const SizedBox(height: AppTheme.sm),
              _ReviewCard(
                label: 'Photo',
                value: vm.imageFile != null ? 'Attached ✓' : 'None (optional)',
              ),
              const SizedBox(height: AppTheme.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md,
                  vertical: AppTheme.xs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: AppTheme.radiusCard,
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      vm.isAnonymous ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 18,
                      color: vm.isAnonymous ? Colors.amber[300] : AppTheme.primaryLight,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Anonymously',
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            vm.isAnonymous
                                ? 'Your identity is hidden from others'
                                : 'Your name will show on this report',
                            style: const TextStyle(
                              color: AppTheme.onSurfaceDim,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: vm.isAnonymous,
                      onChanged: vm.setAnonymous,
                      activeColor: Colors.amber[400],
                      activeTrackColor: Colors.amber.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.xl),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: vm.isSubmitting ? null : _handleSubmit,
                  icon: vm.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    vm.isSubmitting ? 'Submitting…' : 'Submit Report',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusCard,
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceDim,
            ),
          ),
          const SizedBox(height: AppTheme.xs),
          Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

// ── Shared: Next/Continue button ──────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.enabled,
    required this.onPressed,
    this.label = 'Continue',
  });

  final bool enabled;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            const SizedBox(width: AppTheme.sm),
            const Icon(Icons.arrow_forward_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
