import '../models/health_facility.dart';

abstract class ClinicRepository {
  /// Returns facilities near the point (any order, distance filled in).
  Future<List<HealthFacility>> findNearby(double lat, double lng);
}