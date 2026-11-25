import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/report_viewmodel.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<ReportViewModel>().auditLogs.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Trail')),
      body: logs.isEmpty
          ? const Center(child: Text('No activity yet'))
          : ListView.separated(
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final l = logs[i];
          return ListTile(
            leading: Icon(switch (l.action) {
              'approved' => Icons.check_circle,
              'rejected' => Icons.cancel,
              _ => Icons.upload_file,
            }),
            title: Text('Report ${l.reportId} ${l.action}'),
            subtitle: Text('By ${l.performedBy}  •  ${l.timestamp}'
                '${l.reason != null ? '\nReason: ${l.reason}' : ''}'),
            isThreeLine: l.reason != null,
          );
        },
      ),
    );
  }
}