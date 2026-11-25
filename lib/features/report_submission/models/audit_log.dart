class AuditLog {
  final String id;
  final String reportId;
  final String action; // submitted / approved / rejected
  final String performedBy; // user id (always the real id, even for anonymous reports)
  final String? reason;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.reportId,
    required this.action,
    required this.performedBy,
    this.reason,
    required this.timestamp,
  });
}