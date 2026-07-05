import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/data/models/incident_report.dart';
import 'package:civic_voice/data/repositories/mock_civic_data_repository.dart';
import 'package:civic_voice/domain/enums/incident_category.dart';
import 'package:civic_voice/domain/enums/incident_status.dart';
import 'package:civic_voice/ui/features/admin_dashboard/view_models/dashboard_view_model.dart';

void main() {
  group('DashboardViewModel', () {
    late MockCivicDataRepository repository;
    late DashboardViewModel vm;

    setUp(() {
      repository = MockCivicDataRepository();
      vm = DashboardViewModel(repository: repository);
    });

    tearDown(() {
      vm.dispose();
      repository.dispose();
    });

    test('loads all 55 reports on initialization', () async {
      // Allow the async initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      expect(vm.allReports.length, equals(55));
      expect(vm.isLoading, isFalse);
    });

    test('stats total matches report count', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      expect(vm.stats.total, equals(vm.allReports.length));
    });

    test('status filter reduces filteredReports', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      vm.setStatusFilter(IncidentStatus.submitted);
      final filtered = vm.filteredReports;
      expect(filtered.every((r) => r.status == IncidentStatus.submitted), isTrue);
    });

    test('category filter reduces filteredReports', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      vm.setCategoryFilter(IncidentCategory.pothole);
      final filtered = vm.filteredReports;
      expect(filtered.every((r) => r.category == IncidentCategory.pothole), isTrue);
    });

    test('search query filters by title', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      // Use a known word from seed data
      vm.setSearchQuery('pothole');
      final filtered = vm.filteredReports;
      for (final r in filtered) {
        final matches = r.title.toLowerCase().contains('pothole') ||
            r.description.toLowerCase().contains('pothole') ||
            r.category.displayName.toLowerCase().contains('pothole');
        expect(matches, isTrue, reason: 'Report ${r.id} did not match "pothole"');
      }
    });

    test('clearFilters resets all filters', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      vm.setStatusFilter(IncidentStatus.resolved);
      vm.setCategoryFilter(IncidentCategory.waterLeak);
      vm.setSearchQuery('test');
      vm.clearFilters();
      expect(vm.statusFilter, isNull);
      expect(vm.categoryFilter, isNull);
      expect(vm.searchQuery, isEmpty);
      expect(vm.hasActiveFilters, isFalse);
    });

    test('combined filters (status + category) produce intersection', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      vm.setStatusFilter(IncidentStatus.dispatched);
      vm.setCategoryFilter(IncidentCategory.pothole);
      final filtered = vm.filteredReports;
      for (final r in filtered) {
        expect(r.status, equals(IncidentStatus.dispatched));
        expect(r.category, equals(IncidentCategory.pothole));
      }
    });

    test('updateStatus changes report status reactively', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      final report = vm.allReports.firstWhere(
        (r) => r.status == IncidentStatus.submitted,
      );
      await vm.updateStatus(report.id, IncidentStatus.reviewed);
      await Future.delayed(const Duration(milliseconds: 50));
      final updated = vm.allReports.firstWhere((r) => r.id == report.id);
      expect(updated.status, equals(IncidentStatus.reviewed));
    });

    test('DashboardStats.fromReports computes correct counts', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      final stats = vm.stats;
      final manualTotal = stats.submitted + stats.reviewed +
          stats.dispatched + stats.resolved;
      expect(manualTotal, equals(stats.total));
    });

    test('sort by district ascending orders alphabetically', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      vm.setSort(1, true);
      final filtered = vm.filteredReports;
      for (int i = 1; i < filtered.length; i++) {
        expect(
          filtered[i - 1].district.compareTo(filtered[i].district),
          lessThanOrEqualTo(0),
        );
      }
    });

    test('availableDistricts returns 6 unique districts', () async {
      await Future.delayed(const Duration(milliseconds: 100));
      expect(vm.availableDistricts.length, equals(6));
    });
  });

  group('DashboardStats', () {
    test('fromReports produces correct byStatus map', () {
      final reports = [
        _mockReport(status: IncidentStatus.submitted),
        _mockReport(status: IncidentStatus.submitted),
        _mockReport(status: IncidentStatus.resolved),
      ];
      final stats = DashboardStats.fromReports(reports);
      expect(stats.submitted, equals(2));
      expect(stats.resolved, equals(1));
      expect(stats.reviewed, equals(0));
      expect(stats.total, equals(3));
    });

    test('resolvedThisWeek only counts recent resolutions', () {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 30));
      final recent = now.subtract(const Duration(days: 3));
      final reports = [
        _mockReport(status: IncidentStatus.resolved, timestamp: old),
        _mockReport(status: IncidentStatus.resolved, timestamp: recent),
        _mockReport(status: IncidentStatus.submitted, timestamp: recent),
      ];
      final stats = DashboardStats.fromReports(reports);
      expect(stats.resolvedThisWeek, equals(1));
    });
  });
}

IncidentReport _mockReport({
  IncidentStatus status = IncidentStatus.submitted,
  IncidentCategory category = IncidentCategory.pothole,
  DateTime? timestamp,
}) {
  return IncidentReport(
    id: 'test_${DateTime.now().microsecondsSinceEpoch}',
    category: category,
    title: 'Test Report',
    description: 'Test description for unit testing purposes.',
    latitude: 5.6037,
    longitude: -0.1870,
    imageUrl: 'https://picsum.photos/seed/test/400/300',
    status: status,
    timestamp: timestamp ?? DateTime.now(),
    reporterName: 'Test User',
    district: 'Ayawaso Central',
  );
}
