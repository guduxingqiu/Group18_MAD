import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../report_submission/models/outbreak_report.dart';
import '../../report_submission/viewmodel/report_viewmodel.dart';

class OutbreakMapScreen extends StatelessWidget {
  const OutbreakMapScreen({super.key});

  // Fallback centre when there are no verified cases yet. Change it to your campus.
  static const _defaultCenter = LatLng(2.29, 111.83);

  // Snap a report to the centre of a ~1 km grid cell (0.01 degrees).
  static LatLng _areaCenter(OutbreakReport r) => LatLng(
    (r.latitude * 100).floor() / 100 + 0.005,
    (r.longitude * 100).floor() / 100 + 0.005,
  );

  static Map<String, List<OutbreakReport>> _groupByArea(List<OutbreakReport> cases) {
    final map = <String, List<OutbreakReport>>{};
    for (final r in cases) {
      final key = '${(r.latitude * 100).floor()}_${(r.longitude * 100).floor()}';
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  void _showAreaDetails(BuildContext context, List<OutbreakReport> reports) {
    final counts = <String, int>{};
    for (final r in reports) {
      counts[r.disease] = (counts[r.disease] ?? 0) + 1;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${reports.length} verified case(s) in this area',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final e in counts.entries) Text('${e.key}: ${e.value}'),
            const SizedBox(height: 8),
            const Text('Exact locations are hidden to protect privacy.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showExactDetails(BuildContext context, OutbreakReport r) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.disease,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(r.locationName ??
                '${r.latitude.toStringAsFixed(5)}, ${r.longitude.toStringAsFixed(5)}'),
            Text('Reported by: ${r.userId}'),
            Text('Time: ${r.createdAt.toLocal()}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().currentUser?.role;
    final isOfficer = role == UserRole.healthOfficer; // only officers see exact points
    final cases = context.watch<ReportViewModel>().approvedReports;
    final areas = _groupByArea(cases);

    final center = cases.isEmpty
        ? _defaultCenter
        : (isOfficer
        ? LatLng(cases.first.latitude, cases.first.longitude)
        : _areaCenter(cases.first));

    return Scaffold(
      appBar: AppBar(title: Text('Outbreak Map (${cases.length} verified)')),
      body: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // Replace with your applicationId from android/app/build.gradle.kts
            userAgentPackageName: 'my.uts.wth.what_the_health',
          ),
          CircleLayer(
            circles: isOfficer
                ? [
              for (final r in cases)
                CircleMarker(
                  point: LatLng(r.latitude, r.longitude),
                  radius: 1000,
                  useRadiusInMeter: true,
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderColor: AppColors.danger,
                  borderStrokeWidth: 2,
                ),
            ]
                : [
              for (final group in areas.values)
                CircleMarker(
                  point: _areaCenter(group.first),
                  radius: 1000,
                  useRadiusInMeter: true,
                  color: AppColors.danger.withValues(alpha: 0.2),
                  borderColor: AppColors.danger,
                  borderStrokeWidth: 2,
                ),
            ],
          ),
          MarkerLayer(
            markers: isOfficer
                ? [
              for (final r in cases)
                Marker(
                  point: LatLng(r.latitude, r.longitude),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showExactDetails(context, r),
                    child: const Icon(Icons.location_on,
                        color: AppColors.danger, size: 44),
                  ),
                ),
            ]
                : [
              for (final group in areas.values)
                Marker(
                  point: _areaCenter(group.first),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showAreaDetails(context, group),
                    child: CircleAvatar(
                      backgroundColor: AppColors.danger,
                      child: Text('${group.length}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}