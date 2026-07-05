import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../data/models/incident_report.dart';
import '../../../../data/repositories/i_civic_repository.dart';
import '../../../../domain/enums/incident_category.dart';
import '../../../../domain/enums/incident_status.dart';

/// Dashboard state snapshot — immutable value object passed to Views.
class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.byStatus,
    required this.byCategory,
    required this.resolvedThisWeek,
  });

  final int total;
  final Map<IncidentStatus, int> byStatus;
  final Map<IncidentCategory, int> byCategory;
  final int resolvedThisWeek;

  int get submitted => byStatus[IncidentStatus.submitted] ?? 0;
  int get reviewed => byStatus[IncidentStatus.reviewed] ?? 0;
  int get dispatched => byStatus[IncidentStatus.dispatched] ?? 0;
  int get resolved => byStatus[IncidentStatus.resolved] ?? 0;

  static DashboardStats empty() => DashboardStats(
    total: 0,
    byStatus: {},
    byCategory: {},
    resolvedThisWeek: 0,
  );

  static DashboardStats fromReports(List<IncidentReport> reports) {
    final byStatus = <IncidentStatus, int>{};
    final byCategory = <IncidentCategory, int>{};
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    int resolvedThisWeek = 0;

    for (final r in reports) {
      byStatus[r.status] = (byStatus[r.status] ?? 0) + 1;
      byCategory[r.category] = (byCategory[r.category] ?? 0) + 1;
      if (r.status == IncidentStatus.resolved &&
          r.timestamp.isAfter(weekAgo)) {
        resolvedThisWeek++;
      }
    }

    return DashboardStats(
      total: reports.length,
      byStatus: byStatus,
      byCategory: byCategory,
      resolvedThisWeek: resolvedThisWeek,
    );
  }
}

/// ViewModel for the Admin Dashboard.
/// Consumes [ICivicRepository] and exposes reactive state for all 3 tabs.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required ICivicRepository repository})
      : _repository = repository {
    _initialize();
  }

  final ICivicRepository _repository;
  StreamSubscription<List<IncidentReport>>? _subscription;

  // ── Raw data ───────────────────────────────────────────────────────────────
  List<IncidentReport> _allReports = [];

  // ── Filter state ───────────────────────────────────────────────────────────
  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;
  String _searchQuery = '';
  String? _districtFilter;

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  String? _updatingId; // ID of the row currently being status-updated

  // ── Sort state ─────────────────────────────────────────────────────────────
  int _sortColumnIndex = 6; // timestamp column
  bool _sortAscending = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get updatingId => _updatingId;
  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;
  String get searchQuery => _searchQuery;
  String? get districtFilter => _districtFilter;
  int get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;

  /// All reports without any filter — used by MapTab.
  List<IncidentReport> get allReports => List.unmodifiable(_allReports);

  /// Computed stats from all reports (no filter applied).
  DashboardStats get stats => DashboardStats.fromReports(_allReports);

  /// Filtered + sorted reports for the data table.
  List<IncidentReport> get filteredReports {
    var result = _allReports.where((r) {
      final matchesStatus =
          _statusFilter == null || r.status == _statusFilter;
      final matchesCategory =
          _categoryFilter == null || r.category == _categoryFilter;
      final matchesDistrict =
          _districtFilter == null || r.district == _districtFilter;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.reporterName.toLowerCase().contains(q) ||
          r.district.toLowerCase().contains(q) ||
          r.category.displayName.toLowerCase().contains(q);
      return matchesStatus && matchesCategory && matchesDistrict && matchesSearch;
    }).toList();

    result.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 1: // district
          cmp = a.district.compareTo(b.district);
        case 2: // category
          cmp = a.category.displayName.compareTo(b.category.displayName);
        case 3: // title
          cmp = a.title.compareTo(b.title);
        case 4: // status
          cmp = a.status.displayName.compareTo(b.status.displayName);
        case 5: // reporter
          cmp = a.reporterName.compareTo(b.reporterName);
        case 6: // timestamp (default)
          cmp = a.timestamp.compareTo(b.timestamp);
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return result;
  }

  /// Unique districts present in all reports.
  List<String> get availableDistricts =>
      _allReports.map((r) => r.district).toSet().toList()..sort();

  bool get hasActiveFilters =>
      _statusFilter != null ||
      _categoryFilter != null ||
      _districtFilter != null ||
      _searchQuery.isNotEmpty;

  // ── Commands ───────────────────────────────────────────────────────────────

  void setStatusFilter(IncidentStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(IncidentCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setDistrictFilter(String? district) {
    _districtFilter = district;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSort(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _categoryFilter = null;
    _districtFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Updates a single report's status via repository.
  /// Optimistic update: immediately reflects in UI, then syncs via stream.
  Future<void> updateStatus(String id, IncidentStatus newStatus) async {
    _updatingId = id;
    notifyListeners();
    try {
      await _repository.updateReportStatus(id, newStatus);
    } catch (e) {
      _error = 'Failed to update status: $e';
    } finally {
      _updatingId = null;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allReports = await _repository.fetchAllReports();
    } catch (e) {
      _error = 'Failed to load reports: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _initialize() {
    _subscription = _repository.watchReports().listen(
      (reports) {
        _allReports = reports;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
    // Trigger initial load
    _repository.fetchAllReports().then((reports) {
      _allReports = reports;
      _isLoading = false;
      notifyListeners();
    }).catchError((Object e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
