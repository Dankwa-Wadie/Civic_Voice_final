
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/incident_report.dart';
import '../../../../data/repositories/i_civic_repository.dart';
import '../../../../domain/enums/incident_category.dart';
import '../../../../domain/enums/incident_status.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:civic_voice/domain/utils/district_geocoder.dart';

enum SubmissionState { idle, loading, success, error }

const _uuid = Uuid();

/// ViewModel for the 4-step citizen report submission form.
class ReportSubmissionViewModel extends ChangeNotifier {
  ReportSubmissionViewModel({required ICivicRepository repository})
      : _repository = repository;

  final ICivicRepository _repository;
  final ImagePicker _imagePicker = ImagePicker();

  // ── Step state ─────────────────────────────────────────────────────────────
  int _currentStep = 0;
  int get currentStep => _currentStep;
  int get totalSteps => 4;
  bool get canGoBack => _currentStep > 0;
  bool get isLastStep => _currentStep == totalSteps - 1;
  bool _isAnonymous = false;
  bool get isAnonymous => _isAnonymous;

  void setAnonymous(bool v) {
    _isAnonymous = v;
    notifyListeners();
  }

  // ── Step 1: Category ───────────────────────────────────────────────────────
  IncidentCategory? _selectedCategory;
  IncidentCategory? get selectedCategory => _selectedCategory;

  void selectCategory(IncidentCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  bool get step1Valid => _selectedCategory != null;

  // ── Step 2: Title & Description ────────────────────────────────────────────
  String _title = '';
  String _description = '';
  String get title => _title;
  String get description => _description;

  void setTitle(String v) {
    _title = v.trim();
    notifyListeners();
  }

  void setDescription(String v) {
    _description = v.trim();
    notifyListeners();
  }

  bool get step2Valid => _title.length >= 5 && _description.length >= 10;

  // ── Step 3: Location & Photo ───────────────────────────────────────────────
  // Mock GPS — random Accra coordinate
  double _latitude = 5.6037;
  double _longitude = -0.1870;
  double get latitude => _latitude;
  double get longitude => _longitude;

  XFile? _imageFile;
  XFile? get imageFile => _imageFile;
  String get imageUrl => _imageFile != null
      ? _imageFile!.path
      : 'https://picsum.photos/seed/cv_new/400/300';

  bool _isFetchingLocation = false;
  bool get isFetchingLocation => _isFetchingLocation;

  Future<void> fetchLocation() async {
    _isFetchingLocation = true;
    notifyListeners();

    try {
      // Browsers manage location permission per-site rather than system-wide toggles.
      // Therefore, we bypass the service check on web.
      final bool serviceEnabled = kIsWeb ? true : await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // Increase time limit on web to allow the user to read and accept the browser permission dialog.
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _latitude = position.latitude;
      _longitude = position.longitude;
    } catch (e) {
      debugPrint('Failed to get actual location: $e. Falling back to Accra center.');
      _latitude = 5.6037;
      _longitude = -0.1870;
    } finally {
      _isFetchingLocation = false;
      notifyListeners();
    }
  }

  Future<void> fetchMockLocation() => fetchLocation();

  void setLocation(double lat, double lng) {
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }

  Future<void> pickImageFromCamera() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file != null) {
        _imageFile = file;
        notifyListeners();
      }
    } catch (_) {
      // Camera not available on web — silently ignore
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file != null) {
        _imageFile = file;
        notifyListeners();
      }
    } catch (_) {}
  }

  void clearImage() {
    _imageFile = null;
    notifyListeners();
  }

  bool get step3Valid => true; // Location auto-fetched; photo optional

  // ── Step 4: Review & Submit ────────────────────────────────────────────────
  SubmissionState _submissionState = SubmissionState.idle;
  String _submittedId = '';
  String _errorMessage = '';
  SubmissionState get submissionState => _submissionState;
  String get submittedId => _submittedId;
  String get errorMessage => _errorMessage;
  bool get isSubmitting => _submissionState == SubmissionState.loading;
  bool get isSuccess => _submissionState == SubmissionState.success;

  // ── Navigation ─────────────────────────────────────────────────────────────
  bool nextStep() {
    if (!_stepValid(_currentStep)) return false;
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
    return true;
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  bool _stepValid(int step) => switch (step) {
    0 => step1Valid,
    1 => step2Valid,
    2 => step3Valid,
    3 => true,
    _ => false,
  };

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> submit() async {
    if (_selectedCategory == null) return;
    _submissionState = SubmissionState.loading;
    notifyListeners();

    try {
      final reportId = _uuid.v4();
      String finalImageUrl = imageUrl;

      final hasFirebase = Firebase.apps.isNotEmpty;
      if (hasFirebase && _imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final storagePath = 'incident_media/$reportId.jpg';
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask;
        finalImageUrl = await snapshot.ref.getDownloadURL();
      }

      final report = IncidentReport(
        id: reportId,
        category: _selectedCategory!,
        title: _title,
        description: _description,
        latitude: _latitude,
        longitude: _longitude,
        imageUrl: finalImageUrl,
        status: IncidentStatus.submitted,
        timestamp: DateTime.now(),
        reporterName: _isAnonymous
            ? 'anonymous:${FirebaseAuth.instance.currentUser?.email ?? "anonymous"}'
            : (FirebaseAuth.instance.currentUser?.email ?? 'Anonymous Citizen'),
        district: AccraDistrictGeocoder.getDistrict(_latitude, _longitude),
      );
      _submittedId = await _repository.submitReport(report);
      _submissionState = SubmissionState.success;
    } catch (e) {
      _submissionState = SubmissionState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _selectedCategory = null;
    _title = '';
    _description = '';
    _latitude = 5.6037;
    _longitude = -0.1870;
    _imageFile = null;
    _isAnonymous = false;
    _submissionState = SubmissionState.idle;
    _submittedId = '';
    _errorMessage = '';
    notifyListeners();
  }
}
