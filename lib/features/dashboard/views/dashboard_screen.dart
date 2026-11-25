import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../../report_submission/viewmodel/report_viewmodel.dart';
import '../../report_submission/views/audit_log_screen.dart';
import '../../report_submission/views/report_form_screen.dart';
import '../../report_submission/views/review_reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final reportVm = context.watch<ReportViewModel>();

    final approved = reportVm.approvedReports;
    final pendingCount = reportVm.pendingReports.length;

    // Approved cases per disease
    final perDisease = <String, int>{};
    for (final r in approved) {
      perDisease[r.disease] = (perDisease[r.disease] ?? 0) + 1;
    }

    final isOfficer = user?.role == UserRole.healthOfficer;
    final isAdmin = user?.role == UserRole.admin;
    final isPublic = user?.role == UserRole.public;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthViewModel>().logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome, ${user?.name ?? 'Guest'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Row(
            children: [
              _StatCard(label: 'Verified cases', value: '${approved.length}', color: AppColors.danger),
              const SizedBox(width: 12),
              _StatCard(label: 'Pending review', value: '$pendingCount', color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Verified cases by disease',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (perDisease.isEmpty)
            const Text('No verified cases yet')
          else
            ...perDisease.entries.map((e) => Card(
              child: ListTile(title: Text(e.key), trailing: Text('${e.value}')),
            )),

          if (isOfficer || isAdmin) ...[
            const SizedBox(height: 24),
            if (isOfficer)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReviewReportsScreen())),
                icon: const Icon(Icons.fact_check),
                label: Text('Review pending reports ($pendingCount)'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuditLogScreen())),
              icon: const Icon(Icons.history),
              label: const Text('View audit trail'),
            ),
          ],
        ],
      ),
      floatingActionButton: isPublic
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportFormScreen())),
        icon: const Icon(Icons.add_alert),
        label: const Text('Report'),
      )
          : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}