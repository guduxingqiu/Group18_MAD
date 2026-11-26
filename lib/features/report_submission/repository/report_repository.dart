import 'dart:typed_data';
import '../models/audit_log.dart';
import '../models/outbreak_report.dart';

class ReportException implements Exception {
  final String message;
  const ReportException(this.message);
}

abstract class ReportRepository {
  Future<List<OutbreakReport>> fetchReports();
  Future<List<AuditLog>> fetchAuditLogs();

  /// The repository also records the "submitted" audit entry.
  /// With a real backend the SERVER should write audit entries, so they can't be skipped or edited.
  Future<OutbreakReport> submitReport({
    required String userId,
    required String disease,
    required String symptoms,
    String? photoPath,
    Uint8List? photoBytes,
    required double latitude,
    required double longitude,
    String? locationName,
    required bool isAnonymous,
  });

  /// Approve or reject, and record the audit entry (who, what, when, why).
  Future<void> reviewReport({
    required String reportId,
    required String officerId,
    required bool approve,
    String? reason,
  });

  /// Verified cases for the map, dashboard and Red Zone check.
  /// Officers get exact reports; everyone else gets area-level cases only.
  Future<List<OutbreakReport>> fetchApprovedCases();
}