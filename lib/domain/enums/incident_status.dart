// lib/domain/enums/incident_status.dart
// Defines the lifecycle states of a civic incident report.

enum IncidentStatus {
  submitted,
  reviewed,
  dispatched,
  resolved;

  /// Human-readable label for display in UI widgets.
  String get displayName => switch (this) {
        IncidentStatus.submitted => 'Submitted',
        IncidentStatus.reviewed => 'Reviewed',
        IncidentStatus.dispatched => 'Dispatched',
        IncidentStatus.resolved => 'Resolved',
      };

  /// Returns the valid next statuses for the workflow lifecycle.
  /// Used by the admin dashboard to constrain status transition dropdowns.
  List<IncidentStatus> get nextStatuses => switch (this) {
        IncidentStatus.submitted => [
            IncidentStatus.reviewed,
            IncidentStatus.dispatched
          ],
        IncidentStatus.reviewed => [
            IncidentStatus.dispatched,
            IncidentStatus.resolved
          ],
        IncidentStatus.dispatched => [IncidentStatus.resolved],
        IncidentStatus.resolved => [],
      };

  /// Whether this status represents a terminal (end) state.
  bool get isTerminal => this == IncidentStatus.resolved;

  /// Serialise to a Firestore-safe string value.
  String get firestoreValue => name;

  /// Deserialise from a Firestore string value.
  static IncidentStatus fromFirestoreValue(String value) {
    return IncidentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IncidentStatus.submitted,
    );
  }
}
