import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class PendingReport {
  final String id;
  final String userId;
  final String disease;
  final String symptoms;
  final Uint8List? photoBytes;
  final double latitude;
  final double longitude;
  final String? locationName;
  final bool isAnonymous;

  const PendingReport({
    required this.id,
    required this.userId,
    required this.disease,
    required this.symptoms,
    this.photoBytes,
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.isAnonymous,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'disease': disease,
    'symptoms': symptoms,
    'photo': photoBytes == null ? null : base64Encode(photoBytes!),
    'latitude': latitude,
    'longitude': longitude,
    'locationName': locationName,
    'isAnonymous': isAnonymous,
  };

  factory PendingReport.fromJson(Map<String, dynamic> j) => PendingReport(
    id: j['id'] as String,
    userId: j['userId'] as String,
    disease: j['disease'] as String,
    symptoms: j['symptoms'] as String,
    photoBytes: j['photo'] == null ? null : base64Decode(j['photo'] as String),
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    locationName: j['locationName'] as String?,
    isAnonymous: j['isAnonymous'] as bool? ?? false,
  );
}

class PendingReportQueue {
  static const _key = 'pending_reports_v1';
  static const maxPerUser = 5; // keeps the stored data small

  Future<List<PendingReport>> _all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PendingReport.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<PendingReport> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((p) => p.toJson()).toList()));
  }

  Future<List<PendingReport>> forUser(String userId) async =>
      (await _all()).where((p) => p.userId == userId).toList();

  /// Returns false when this user already has too many unsent reports.
  Future<bool> add(PendingReport report) async {
    final items = await _all();
    if (items.where((p) => p.userId == report.userId).length >= maxPerUser) {
      return false;
    }
    items.add(report);
    await _save(items);
    return true;
  }

  Future<void> remove(String id) async {
    final items = await _all();
    items.removeWhere((p) => p.id == id);
    await _save(items);
  }
}