// lib/domain/enums/incident_category.dart
// Defines the taxonomy of civic infrastructure incidents that citizens can report.

enum IncidentCategory {
  pothole,
  waterLeak,
  structuralLightFailure,
  drainageBlockage,
  roadDamage;

  /// Human-readable label for display in UI widgets.
  String get displayName => switch (this) {
        IncidentCategory.pothole => 'Pothole',
        IncidentCategory.waterLeak => 'Water Leak',
        IncidentCategory.structuralLightFailure => 'Light Failure',
        IncidentCategory.drainageBlockage => 'Drainage Blockage',
        IncidentCategory.roadDamage => 'Road Damage',
      };

  /// Emoji shorthand for compact UI representations (map markers, chips, etc.).
  String get emoji => switch (this) {
        IncidentCategory.pothole => '🕳️',
        IncidentCategory.waterLeak => '💧',
        IncidentCategory.structuralLightFailure => '💡',
        IncidentCategory.drainageBlockage => '🚧',
        IncidentCategory.roadDamage => '🛣️',
      };

  /// Serialise to a Firestore-safe string value.
  String get firestoreValue => name;

  /// Deserialise from a Firestore string value.
  static IncidentCategory fromFirestoreValue(String value) {
    return IncidentCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IncidentCategory.pothole,
    );
  }
}
