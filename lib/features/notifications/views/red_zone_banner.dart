import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../report_submission/viewmodel/report_viewmodel.dart';
import '../viewmodel/proximity_viewmodel.dart';

class RedZoneBanner extends StatefulWidget {
  const RedZoneBanner({super.key});

  @override
  State<RedZoneBanner> createState() => _RedZoneBannerState();
}

class _RedZoneBannerState extends State<RedZoneBanner> {
  late final ProximityViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<ProximityViewModel>();
    final reportVm = context.read<ReportViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.startMonitoring(() => reportVm.approvedReports);
    });
  }

  @override
  void dispose() {
    _vm.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProximityViewModel>();

    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (vm.errorMessage != null) {
      color = Colors.grey;
      icon = Icons.location_off;
      title = 'Red Zone check unavailable';
      subtitle = vm.errorMessage!;
    } else if (!vm.hasChecked) {
      color = Colors.grey;
      icon = Icons.location_searching;
      title = 'Checking your area...';
      subtitle = 'Looking for verified outbreaks near you';
    } else if (vm.isInRedZone) {
      color = AppColors.danger;
      icon = Icons.warning_amber_rounded;
      title = 'Red Zone: you are near an outbreak';
      subtitle = '${vm.nearbyCaseCount} verified case(s) within 1 km. '
          'Avoid stagnant water and crowded places.';
    } else {
      color = AppColors.safe;
      icon = Icons.check_circle_outline;
      title = 'No verified outbreak within 1 km';
      subtitle = vm.nearestMeters == null
          ? 'No verified cases reported yet'
          : 'Nearest outbreak area is about '
          '${(vm.nearestMeters! / 1000).toStringAsFixed(1)} km away';
    }

    return Card(
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle),
                ],
              ),
            ),
            vm.isChecking
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
              tooltip: 'Check now',
              icon: const Icon(Icons.refresh),
              onPressed: vm.check,
            ),
          ],
        ),
      ),
    );
  }
}