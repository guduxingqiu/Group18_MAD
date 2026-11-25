import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/health_facility.dart';

class ClinicViewModel extends ChangeNotifier {
  List<HealthFacility> facilities = [];
  bool isLoading = false;
  bool isDemoData = false;
  String? errorMessage;

  // Public Overpass servers. If one is slow or busy, the next is tried.
  static const _servers = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  Future<void> load(double lat, double lng) async {
    isLoading = true;
    isDemoData = false;
    errorMessage = null;
    notifyListeners();

    try {
      var results = await _fetch(lat, lng, 5000);
      if (results.isEmpty) results = await _fetch(lat, lng, 15000);

      results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      facilities = results.take(10).toList();
    } catch (e) {
      debugPrint('Clinic lookup failed: $e');
      // Live service unreachable: show clearly labelled demo data
      facilities = _demoData(lat, lng);
      isDemoData = true;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<List<HealthFacility>> _fetch(double lat, double lng, int radius) async {
    // Lighter query: exact match, node/way/relation shorthand, small result limit
    final query = '[out:json][timeout:10];'
        'nwr["amenity"~"^(hospital|clinic)\$"](around:$radius,$lat,$lng);'
        'out center 30;';

    Object? lastError;
    for (final url in _servers) {
      try {
        final res = await Dio().post(
          url,
          data: {'data': query},
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: {'User-Agent': 'WhatTheHealth-StudentProject/1.0'},
            sendTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
          ),
        );
        final data = res.data is String ? jsonDecode(res.data as String) : res.data;
        return _parse(data, lat, lng);
      } catch (e) {
        lastError = e;
        debugPrint('Overpass failed at $url: $e');
      }
    }
    throw lastError ?? Exception('No server responded');
  }

  List<HealthFacility> _parse(dynamic data, double lat, double lng) {
    final elements = (data['elements'] as List).cast<Map<String, dynamic>>();
    final list = <HealthFacility>[];

    for (final e in elements) {
      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final name = tags['name'] as String?;
      if (name == null || name.isEmpty) continue;

      final fLat = (e['lat'] ?? e['center']?['lat']) as num?;
      final fLng = (e['lon'] ?? e['center']?['lon']) as num?;
      if (fLat == null || fLng == null) continue;

      list.add(HealthFacility(
        name: name,
        type: (tags['amenity'] as String?) ?? 'clinic',
        latitude: fLat.toDouble(),
        longitude: fLng.toDouble(),
        distanceMeters: Geolocator.distanceBetween(
            lat, lng, fLat.toDouble(), fLng.toDouble()),
        phone: (tags['phone'] ?? tags['contact:phone']) as String?,
      ));
    }
    return list;
  }

  // Placeholder places near the user, ONLY so the screen can be demonstrated
  // when the live service is down. They are not real facilities.
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