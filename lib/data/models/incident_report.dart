import 'package:flutter/foundation.dart';
import 'package:civic_voice/domain/enums/incident_category.dart';
import 'package:civic_voice/domain/enums/incident_status.dart';

/// An immutable value object representing a single civic incident report.
///
/// Serialises to/from a Firestore document map via [toMap] / [fromMap].
class IncidentReport {
  const IncidentReport({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.status,
    required this.timestamp,
    required this.reporterName,
    required this.district,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Fields
  // ──────────────────────────────────────────────────────────────────────────

  /// Unique document identifier (Firestore document ID).
  final String id;

  /// Classification of the infrastructure issue.
  final IncidentCategory category;

  /// Short title describing the incident.
  final String title;

  /// Detailed description provided by the reporter.
  final String description;

  /// WGS-84 latitude of the incident location.
  final double latitude;

  /// WGS-84 longitude of the incident location.
  final double longitude;

  /// Publicly accessible image URL (e.g., Firebase Storage / Picsum seed URL).
  final String imageUrl;

  /// Publicly accessible list of image URLs for multiple photo uploads.
  final List<String> imageUrls;

  /// Current lifecycle status of the incident.
  final IncidentStatus status;

  /// UTC timestamp of when the report was submitted.
  final DateTime timestamp;

  /// Full name of the citizen who submitted the report.
  final String reporterName;

  /// Administrative district in which the incident was reported.
  final String district;

  // ──────────────────────────────────────────────────────────────────────────
  // CopyWith
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a new [IncidentReport] with the given fields replaced.
  IncidentReport copyWith({
    String? id,
    IncidentCategory? category,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? imageUrls,
    IncidentStatus? status,
    DateTime? timestamp,
    String? reporterName,
    String? district,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      reporterName: reporterName ?? this.reporterName,
      district: district ?? this.district,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Firestore Serialisation
  // ──────────────────────────────────────────────────────────────────────────

  /// Converts this [IncidentReport] to a [Map] suitable for Firestore writes.
  ///
  /// Note: [timestamp] is stored as milliseconds-since-epoch so it is
  /// compatible with both Firestore Timestamps and JSON encoders.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.firestoreValue,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'status': status.firestoreValue,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reporterName': reporterName,
      'district': district,
    };
  }

  /// Constructs an [IncidentReport] from a Firestore document [map].
  ///
  /// Handles both [int] millisecond timestamps and ISO-8601 [String] timestamps
  /// for resilience across different serialisation strategies.
  factory IncidentReport.fromMap(Map<String, dynamic> map) {
    final DateTime parsedTimestamp;
    final dynamic rawTimestamp = map['timestamp'];
    if (rawTimestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.parse(rawTimestamp);
    } else if (rawTimestamp != null &&
        rawTimestamp.runtimeType.toString() == 'Timestamp') {
      parsedTimestamp = (rawTimestamp as dynamic).toDate() as DateTime;
    } else {
      parsedTimestamp = DateTime.now();
    }

    final String singleUrl = map['imageUrl'] as String? ?? '';
    final List<String> urls = (map['imageUrls'] as List?)?.map((e) => e as String).toList() ??
        (singleUrl.isNotEmpty ? [singleUrl] : []);

    return IncidentReport(
      id: map['id'] as String? ?? '',
      category: IncidentCategory.fromFirestoreValue(
          map['category'] as String? ?? 'pothole'),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: singleUrl,
      imageUrls: urls,
      status: IncidentStatus.fromFirestoreValue(
          map['status'] as String? ?? 'submitted'),
      timestamp: parsedTimestamp,
      reporterName: map['reporterName'] as String? ?? '',
      district: map['district'] as String? ?? '',
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Equality & Hashing
  // ──────────────────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IncidentReport) return false;
    return id == other.id &&
        category == other.category &&
        title == other.title &&
        description == other.description &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        imageUrl == other.imageUrl &&
        listEquals(imageUrls, other.imageUrls) &&
        status == other.status &&
        timestamp == other.timestamp &&
        reporterName == other.reporterName &&
        district == other.district;
  }

  @override
  int get hashCode => Object.hash(
        id,
        category,
        title,
        description,
        latitude,
        longitude,
        imageUrl,
        Object.hashAll(imageUrls),
        status,
        timestamp,
        reporterName,
        district,
      );

  @override
  String toString() {
    return 'IncidentReport('
        'id: $id, '
        'category: ${category.displayName}, '
        'title: $title, '
        'status: ${status.displayName}, '
        'district: $district, '
        'reporter: $reporterName, '
        'timestamp: $timestamp'
        ')';
  }
}
