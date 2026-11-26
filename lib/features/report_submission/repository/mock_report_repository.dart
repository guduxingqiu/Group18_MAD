import 'dart:typed_data';
import '../models/audit_log.dart';
import '../models/outbreak_report.dart';
import 'report_repository.dart';

class MockReportRepository implements ReportRepository {
  final List<OutbreakReport> _reports = [];
  final List<AuditLog> _logs = [];

  @override
  Future<List<OutbreakReport>> fetchReports() async => List.of(_reports);

  @override
  Future<List<AuditLog>> fetchAuditLogs() async => List.of(_logs);

  @override
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
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // pretend network delay

    final now = DateTime.now();
    final report = OutbreakReport(
      id: 'r${_reports.length + 1}',
      userId: userId, // always stored, even when anonymous
      disease: disease,
      symptoms: symptoms,
      photoPath: photoPath,
      photoBytes: photoBytes,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      isAnonymous: isAnonymous,
      createdAt: now,
    );
    _reports.add(report);

    _logs.add(AuditLog(
      id: 'a${_logs.length + 1}',
      reportId: report.id,
      action: 'submitted',
      performedBy: userId,
      timestamp: now,
    ));
    return report;
  }

  @override
  Future<void> reviewReport({
    required String reportId,
    required String officerId,
    required bool approve,
    String? reason,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Report not found');

    _reports[index] = _reports[index].copyWith(
      status: approve ? ReportStatus.approved : ReportStatus.rejected,
    );

    _logs.add(AuditLog(
      id: 'a${_logs.length + 1}',
      reportId: reportId,
      action: approve ? 'approved' : 'rejected',
      performedBy: officerId,
      reason: reason,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<List<OutbreakReport>> fetchApprovedCases() async =>
      _reports.where((r) => r.status == ReportStatus.approved).toList();
}