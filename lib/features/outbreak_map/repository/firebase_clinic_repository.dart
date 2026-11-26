import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/health_facility.dart';
import 'clinic_repository.dart';

class FirebaseClinicRepository implements ClinicRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<HealthFacility>> findNearby(double lat, double lng) async {
    // The list is small, so load it all and measure the distance on the phone.
    final snap = await _db.collection('facilities').get();
    final list = <HealthFacility>[];

    for (final doc in snap.docs) {
      final d = doc.data();
      final name = d['name'] as String?;
      final fLat = d['latitude'];
      final fLng = d['longitude'];
      if (name == null || fLat is! num || fLng is! num) continue; // skip bad entries

      list.add(HealthFacility(
        name: name,
        type: (d['type'] as String?) ?? 'clinic',
        latitude: fLat.toDouble(),
        longitude: fLng.toDouble(),
        distanceMeters: Geolocator.distanceBetween(
            lat, lng, fLat.toDouble(), fLng.toDouble()),
        phone: d['phone'] as String?,
      ));
    }
    return list;
  }
}