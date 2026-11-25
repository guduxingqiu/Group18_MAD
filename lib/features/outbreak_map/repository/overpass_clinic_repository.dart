import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/health_facility.dart';
import 'clinic_repository.dart';

class OverpassClinicRepository implements ClinicRepository {
  static const _servers = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  @override
  Future<List<HealthFacility>> findNearby(double lat, double lng) async {
    var results = await _fetch(lat, lng, 5000);
    if (results.isEmpty) results = await _fetch(lat, lng, 15000);
    return results;
  }

  Future<List<HealthFacility>> _fetch(double lat, double lng, int radius) async {
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
}