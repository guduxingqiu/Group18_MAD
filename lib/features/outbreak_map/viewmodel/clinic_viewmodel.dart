import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/health_facility.dart';
import '../repository/clinic_repository.dart';

class ClinicViewModel extends ChangeNotifier {
  final ClinicRepository _repo;
  ClinicViewModel(this._repo);

  List<HealthFacility> facilities = [];
  bool isLoading = false;
  bool isDemoData = false;
  String? errorMessage;

  Future<void> load(double lat, double lng) async {
    isLoading = true;
    isDemoData = false;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await _repo.findNearby(lat, lng);
      results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      facilities = results.take(10).toList();
    } catch (e) {
      debugPrint('Clinic lookup failed: $e');
      errorMessage = 'Could not load nearby clinics. Please try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  // Placeholder places, ONLY so the screen can be demonstrated when the live
  // service is down. They are not real facilities.
  List<HealthFacility> _demoData(double lat, double lng) {
    HealthFacility make(String name, String type, double dLat, double dLng) =>
        HealthFacility(
          name: name,
          type: type,
          latitude: lat + dLat,
          longitude: lng + dLng,
          distanceMeters:
          Geolocator.distanceBetween(lat, lng, lat + dLat, lng + dLng),
        );

    return [
      make('Demo Clinic A', 'clinic', 0.004, 0.003),
      make('Demo Hospital B', 'hospital', -0.008, 0.006),
      make('Demo Clinic C', 'clinic', 0.012, -0.010),
    ]..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  }
}