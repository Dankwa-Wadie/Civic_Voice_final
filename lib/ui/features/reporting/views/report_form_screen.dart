import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    _titleCtrl.text = 'Large pothole on Spintex Road';
    _descCtrl.text =
        'There is a massive pothole in the middle of the road near the traffic light, causing drivers to swerve dangerously.';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vm = Provider.of<ReportSubmissionViewModel>(context, listen: false);
        vm.setTitle(_titleCtrl.text);
        vm.setDescription(_descCtrl.text);
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
  @override
  void initState() {
    super.initState();
    final vm = context.read<ReportSubmissionViewModel>();
    if (!vm.isFetchingLocation) {
      vm.fetchMockLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportSubmissionViewModel>(
      builder: (context, vm, _) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Location & Photo',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppTheme.xs),
              Text(
                'Confirm your GPS location and attach a photo (optional).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.xl),
              // GPS card
              Container(
                padding: const EdgeInsets.all(AppTheme.md),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.radiusCard,
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.sm),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: AppTheme.radiusButton,
                      ),
                      child: vm.isFetchingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : const Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: AppTheme.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vm.isFetchingLocation
                                ? 'Fetching GPS location…'
                                : 'Location captured',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              color: vm.isFetchingLocation
                                  ? AppTheme.onSurfaceMuted
                                  : AppTheme.success,
                            ),
                          ),
                          if (!vm.isFetchingLocation)
                            Text(
                              '${vm.latitude.toStringAsFixed(4)}° N, '
                              '${vm.longitude.toStringAsFixed(4)}° '
                              '${vm.longitude < 0 ? 'W' : 'E'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: vm.fetchMockLocation,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.lg),
              // Photo section
              Text(
                'Attach Photo',
                style: Theme.of(context).textTheme.titleLarge,
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
              const Spacer(),
              _NextButton(
                enabled: !vm.isFetchingLocation,
                label: 'Review & Submit',
                onPressed: () => vm.nextStep(),
              ),
            ],
          ),
        );
      },
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

class _Step4Review extends StatelessWidget {
  const _Step4Review({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportSubmissionViewModel>(
      builder: (context, vm, _) {
        if (vm.isSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SubmissionSuccessScreen(
                  reportId: vm.submittedId,
                ),
              ),
            );
          });
        }
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
              if (vm.errorMessage.isNotEmpty) ...[
                const SizedBox(height: AppTheme.md),
                Container(
                  padding: const EdgeInsets.all(AppTheme.sm),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.10),
                    borderRadius: AppTheme.radiusButton,
                    border: Border.all(
                      color: AppTheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    vm.errorMessage,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.xl),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: vm.isSubmitting ? null : vm.submit,
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
