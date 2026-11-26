import 'dart:typed_data';
import '../models/audit_log.dart';
import '../models/outbreak_report.dart';

class ReportException implements Exception {
  final String message;
  const ReportException(this.message);
}

/// Thrown when the report could not be sent because there is no connection.
class ReportOfflineException extends ReportException {
  const ReportOfflineException() : super('No internet connection');
}

abstract class ReportRepository {
  Future<List<OutbreakReport>> fetchReports();
  Future<List<AuditLog>> fetchAuditLogs();

  /// Verified cases for the map, dashboard and Red Zone check.
  /// Officers get exact reports; everyone else gets area-level cases only.
  Future<List<OutbreakReport>> fetchApprovedCases();

  /// A new ID that can be created offline and reused when retrying.
  String newReportId();

  /// Sends a report. Passing the same [reportId] again is safe: a retry never
  /// creates a duplicate.
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
  });

  /// Approve or reject, and record the audit entry (who, what, when, why).
  Future<void> reviewReport({
    required String reportId,
    required String officerId,
    required bool approve,
    String? reason,
  });
}