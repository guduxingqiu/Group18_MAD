import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../models/health_facility.dart';
import '../viewmodel/clinic_viewmodel.dart';
import '../repository/clinic_repository.dart';

class ClinicListScreen extends StatelessWidget {
  final double latitude;
  final double longitude;

  const ClinicListScreen({super.key, required this.latitude, required this.longitude});

  String _formatDistance(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';

  Future<void> _openDirections(HealthFacility f) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${f.latitude},${f.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
      ClinicViewModel(ctx.read<ClinicRepository>())..load(latitude, longitude),
      child: Scaffold(
        appBar: AppBar(title: const Text('Nearby Clinics & Hospitals')),
        body: Consumer<ClinicViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vm.errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => vm.load(latitude, longitude),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (vm.facilities.isEmpty) {
              return const Center(child: Text('No clinics found nearby'));
            }

            return Column(
              children: [
                if (vm.isDemoData)
                  Container(
                    width: double.infinity,
                    color: AppColors.danger.withValues(alpha: 0.12),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Live clinic data is unavailable. These are DEMO places, '
                                'not real facilities.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => vm.load(latitude, longitude),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  color: AppColors.warning.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'This list is for convenience only and is not medical advice. '
                        'In an emergency, call 999.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: vm.facilities.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final f = vm.facilities[i];
                      return ListTile(
                        leading: Icon(
                          f.type == 'hospital' ? Icons.local_hospital : Icons.medical_services,
                          color: AppColors.primary,
                        ),
                        title: Text(f.name),
                        subtitle: Text(
                            '${f.type == 'hospital' ? 'Hospital' : 'Clinic'}  •  ${_formatDistance(f.distanceMeters)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (f.phone != null)
                              IconButton(
                                tooltip: 'Call',
                                icon: const Icon(Icons.call),
                                onPressed: () => _call(f.phone!),
                              ),
                            IconButton(
                              tooltip: 'Directions',
                              icon: const Icon(Icons.directions),
                              onPressed: () => _openDirections(f),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}