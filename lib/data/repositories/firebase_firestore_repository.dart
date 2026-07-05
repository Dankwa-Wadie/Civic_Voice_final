// lib/data/repositories/firebase_firestore_repository.dart
// Firestore-backed implementation of ICivicRepository.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_voice/data/models/incident_report.dart';
import 'package:civic_voice/data/repositories/i_civic_repository.dart';
import 'package:civic_voice/domain/enums/incident_status.dart';

/// Phase-2 Firestore-backed implementation of [ICivicRepository].
class FirebaseFirestoreRepository implements ICivicRepository {
  final FirebaseFirestore _firestore;

  FirebaseFirestoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'civic_reports';

  // ──────────────────────────────────────────────────────────────────────────
  // Read operations
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<IncidentReport>> fetchAllReports() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => IncidentReport.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<IncidentReport?> fetchReportById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return IncidentReport.fromMap(doc.data()!);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Write operations
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> updateReportStatus(String id, IncidentStatus status) async {
    await _firestore
        .collection(_collection)
        .doc(id)
        .update({'status': status.firestoreValue});
  }

  @override
  Future<String> submitReport(IncidentReport report) async {
    final docRef = _firestore.collection(_collection).doc(report.id);
    final map = report.toMap();
    // Convert DateTime millisecond timestamp to Firestore Timestamp for rule compliance and db formatting
    map['timestamp'] = Timestamp.fromDate(report.timestamp);
    await docRef.set(map);
    return docRef.id;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Real-time stream
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<IncidentReport>> watchReports() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentReport.fromMap(doc.data()))
            .toList());
  }
}
