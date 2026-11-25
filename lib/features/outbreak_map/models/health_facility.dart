class HealthFacility {
  final String name;
  final String type; // 'hospital' or 'clinic'
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final String? phone;

  const HealthFacility({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.phone,
  });
}