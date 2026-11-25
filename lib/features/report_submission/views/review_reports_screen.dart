import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../models/outbreak_report.dart';
import '../viewmodel/report_viewmodel.dart';

class ReviewReportsScreen extends StatelessWidget {
  const ReviewReportsScreen({super.key});

  Future<void> _review(BuildContext context, OutbreakReport report, bool approve) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve report?' : 'Reject report?'),
        content: TextField(
          controller: reasonController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: approve ? 'Reason (optional)' : 'Reason (required)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!approve && reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final officerId = context.read<AuthViewModel>().currentUser?.id ?? 'unknown';
    await context.read<ReportViewModel>().reviewReport(
      reportId: report.id,
      officerId: officerId,
      approve: approve,
      reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<ReportViewModel>().pendingReports;

    return Scaffold(
      appBar: AppBar(title: Text('Pending Reports (${pending.length})')),
      body: pending.isEmpty
          ? const Center(child: Text('No reports waiting for review'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pending.length,
        itemBuilder: (context, i) {
          final r = pending[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.disease,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(r.symptoms),
                  const SizedBox(height: 8),
                  Text(r.locationName ??
                      '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}'),
                  Text('Reported by: ${r.userId}'
                      '${r.isAnonymous ? ' (anonymous on public feed)' : ''}'),
                  Text('Time: ${r.createdAt}'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _review(context, r, false),
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _review(context, r, true),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}