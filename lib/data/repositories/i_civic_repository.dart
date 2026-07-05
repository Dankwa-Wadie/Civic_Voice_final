// lib/data/repositories/i_civic_repository.dart
// Abstract contract (interface) for all civic data repositories.
//
// Firestore Collection: civic_reports/{reportId}
// Fields:
//   id           (String)     — document ID, duplicated as a field for query convenience
//   category     (String)     — serialised IncidentCategory enum name
//   title        (String)     — short incident title
//   description  (String)     — detailed reporter-supplied description
//   latitude     (Number)     — WGS-84 latitude, decimal degrees
//   longitude    (Number)     — WGS-84 longitude, decimal degrees
//   imageUrl     (String)     — publicly accessible photo URL
//   status       (String)     — serialised IncidentStatus enum name
//   timestamp    (Timestamp)  — Firestore Timestamp of report submission
//   reporterName (String)     — full name of the reporting citizen
//   district     (String)     — administrative district name

import 'package:civic_voice/data/models/incident_report.dart';
import 'package:civic_voice/domain/enums/incident_status.dart';

/// Abstract repository interface for CivicVoice incident data.
///
/// Concrete implementations:
///  - [MockCivicDataRepository]  — in-memory seed data for development/testing.
///  - [FirebaseFirestoreRepository] — production Cloud Firestore backend (Phase 2).
abstract class ICivicRepository {
  /// Returns a snapshot list of all incident reports currently in the data store.
  Future<List<IncidentReport>> fetchAllReports();

  /// Returns the incident report with the given [id], or `null` if not found.
  Future<IncidentReport?> fetchReportById(String id);

  /// Updates the [status] of the report identified by [id].
  ///
  /// Throws [ArgumentError] if no report with [id] exists.
  Future<void> updateReportStatus(String id, IncidentStatus status);

  /// Persists [report] to the data store and returns the assigned document ID.
  ///
  /// For mock implementations the ID is a locally-generated UUID.
  /// For Firestore implementations the ID is the auto-generated document ID.
  Future<String> submitReport(IncidentReport report);

  /// Returns a [Stream] that emits the full list of incident reports whenever
  /// the underlying data changes.  The stream must emit the current state
  /// immediately upon subscription.
  Stream<List<IncidentReport>> watchReports();
}
