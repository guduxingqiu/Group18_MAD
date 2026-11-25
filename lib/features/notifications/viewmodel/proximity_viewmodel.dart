import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/area_utils.dart';
import '../../report_submission/models/outbreak_report.dart';
import 'local_notification_service.dart';

class ProximityViewModel extends ChangeNotifier {
  static const double redZoneMeters = 1000;

  Timer? _timer;
  List<OutbreakReport> Function()? _getCases;
  Set<String> _insideKeys = {};

  bool isChecking = false;
  bool hasChecked = false;
  bool isInRedZone = false;
  int nearbyCaseCount = 0;
  double? nearestMeters;
  String? errorMessage;
  DateTime? lastChecked;

  Future<void> startMonitoring(List<OutbreakReport> Function() getCases) async {
    _getCases = getCases;
    await LocalNotificationService.init();
    await check();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => check());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> check() async {
    if (isChecking || _getCases == null) return;
    isChecking = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are turned off');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is needed for Red Zone alerts');
      }

      final pos = await Geolocator.getCurrentPosition();

      // Group verified cases by area, so we never use exact positions.
      final groups = <String, List<OutbreakReport>>{};
      for (final r in _getCases!()) {
        groups.putIfAbsent(areaKey(r.latitude, r.longitude), () => []).add(r);
      }

      final inside = <String>{};
      int caseCount = 0;
      double? nearest;

      groups.forEach((key, list) {
        final c = areaCenter(list.first.latitude, list.first.longitude);
        final d = Geolocator.distanceBetween(
            pos.latitude, pos.longitude, c.latitude, c.longitude);
        if (nearest == null || d < nearest!) nearest = d;
        if (d <= redZoneMeters) {
          inside.add(key);
          caseCount += list.length;
        }
      });

      // Notify only when the user ENTERS a new red zone (no repeated spam)
      final entered = inside.difference(_insideKeys);
      if (entered.isNotEmpty) {
        await LocalNotificationService.showRedZoneAlert(
            '$caseCount verified case(s) reported within 1 km of your location. '
                'Take precautions and avoid stagnant water or crowded areas.');
      }

      _insideKeys = inside;
      isInRedZone = inside.isNotEmpty;
      nearbyCaseCount = caseCount;
      nearestMeters = nearest;
      lastChecked = DateTime.now();
      hasChecked = true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    isChecking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}