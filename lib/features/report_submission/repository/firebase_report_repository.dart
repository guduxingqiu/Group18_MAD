import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/area_utils.dart';
import '../models/audit_log.dart';
import '../models/outbreak_report.dart';
import 'report_repository.dart';
import 'dart:async';

class FirebaseReportRepository implements ReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Photos are stored inside the report document. Firestore allows 1 MiB per
  // document, and base64 adds about 33%, so keep the raw photo small.
  static const _maxPhotoBytes = 400 * 1024;
  static const _sendTimeout = Duration(seconds: 12);

  @override
  String newReportId() => _db.collection('reports').doc().id;

  Future<String> _role() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'none';
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['role'] as String?) ?? 'public';
  }

  ReportException _friendly(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const ReportException('You do not have permission to do that');
      case 'unavailable':
        return const ReportOfflineException();
      default:
        return ReportException('Server error (${e.code})');
    }
  }

  OutbreakReport _reportFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final photo = d['photoBase64'] as String?;
    return OutbreakReport(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      disease: d['disease'] as String? ?? '',
      symptoms: d['symptoms'] as String? ?? '',
      photoBytes: photo == null ? null : base64Decode(photo),
      latitude: (d['latitude'] as num).toDouble(),
      longitude: (d['longitude'] as num).toDouble(),
      locationName: d['locationName'] as String?,
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      status: ReportStatus.values.firstWhere(
            (s) => s.name == d['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<List<OutbreakReport>> fetchReports() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    try {
      final role = await _role();
      Query<Map<String, dynamic>> q = _db.collection('reports');
      // The rules only allow officers to read everything. Everyone else
      // may only query their own reports, so the query must say so.
      if (role != 'healthOfficer') q = q.where('userId', isEqualTo: uid);

      final snap = await q.get();
      final list = snap.docs.map(_reportFromDoc).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<List<OutbreakReport>> fetchApprovedCases() async {
    if (_auth.currentUser == null) return [];
    try {
      final role = await _role();

      if (role == 'healthOfficer') {
        final snap = await _db
            .collection('reports')
            .where('status', isEqualTo: 'approved')
            .get();
        return snap.docs.map(_reportFromDoc).toList();
      }

      // Public and admin: area-level cases only. No user ID, no exact position.
      final snap = await _db.collection('public_cases').get();
      return snap.docs.map((doc) {
        final d = doc.data();
        return OutbreakReport(
          id: doc.id,
          userId: '',
          disease: d['disease'] as String? ?? '',
          symptoms: '',
          latitude: (d['areaLat'] as num).toDouble(),
          longitude: (d['areaLng'] as num).toDouble(),
          status: ReportStatus.approved,
          createdAt: (d['approvedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<List<AuditLog>> fetchAuditLogs() async {
    if (_auth.currentUser == null) return [];
    try {
      final role = await _role();
      if (role != 'healthOfficer' && role != 'admin') return [];

      // Oldest first, because the audit screen reverses the list itself.
      final snap = await _db.collection('audit_logs').orderBy('timestamp').get();
      return snap.docs.map((doc) {
        final d = doc.data();
        return AuditLog(
          id: doc.id,
          reportId: d['reportId'] as String? ?? '',
          action: d['action'] as String? ?? '',
          performedBy: d['performedBy'] as String? ?? '',
          reason: d['reason'] as String?,
          timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<OutbreakReport> submitReport({
    String? reportId,
    required String userId,
    required String disease,
    required String symptoms,
    String? photoPath,
    Uint8List? photoBytes,
    required double latitude,
    required double longitude,
    String? locationName,
    required bool isAnonymous,
  }) async {
    if (photoBytes != null && photoBytes.length > _maxPhotoBytes) {
      throw const ReportException('The photo is too large. Please choose a smaller one.');
    }

    try {
      final reportRef = _db.collection('reports').doc(reportId ?? newReportId());
      final logRef = _db.collection('audit_logs').doc('submitted-${reportRef.id}');

      final result = OutbreakReport(
        id: reportRef.id,
        userId: userId,
        disease: disease,
        symptoms: symptoms,
        photoBytes: photoBytes,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        isAnonymous: isAnonymous,
        createdAt: DateTime.now(),
      );

      // Retry safety: an earlier attempt may have reached the server already.
      if (reportId != null) {
        final existing = await reportRef.get().timeout(_sendTimeout);
        if (existing.exists) return result;
      }

      final batch = _db.batch();
      batch.set(reportRef, {
        'userId': userId, // always stored, even when anonymous
        'disease': disease,
        'symptoms': symptoms,
        if (photoBytes != null) 'photoBase64': base64Encode(photoBytes),
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'isAnonymous': isAnonymous,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(logRef, {
        'reportId': reportRef.id,
        'action': 'submitted',
        'performedBy': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await batch.commit().timeout(_sendTimeout);

      return result;
    } on TimeoutException {
      throw const ReportOfflineException();
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<void> reviewReport({
    required String reportId,
    required String officerId,
    required bool approve,
    String? reason,
  }) async {
    try {
      final reportRef = _db.collection('reports').doc(reportId);
      final snap = await reportRef.get();
      final data = snap.data();
      if (data == null) throw const ReportException('Report not found');
      if (data['status'] != 'pending') {
        throw const ReportException('This report has already been reviewed');
      }

      final batch = _db.batch();

      batch.update(reportRef, {
        'status': approve ? 'approved' : 'rejected',
        'reviewedBy': officerId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      batch.set(_db.collection('audit_logs').doc(), {
        'reportId': reportId,
        'action': approve ? 'approved' : 'rejected',
        'performedBy': officerId,
        if (reason != null) 'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (approve) {
        // The public copy keeps only the centre of the ~1 km area.
        final lat = (data['latitude'] as num).toDouble();
        final lng = (data['longitude'] as num).toDouble();
        final c = areaCenter(lat, lng);
        batch.set(_db.collection('public_cases').doc(reportId), {
          'disease': data['disease'],
          'areaKey': areaKey(lat, lng),
          'areaLat': c.latitude,
          'areaLng': c.longitude,
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit().timeout(_sendTimeout);
    } on TimeoutException {
      throw const ReportException(
          'No connection. The decision may still be sent once you are online. Refresh to check.');
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }
  }
}