import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/audit_log.dart';
import '../models/outbreak_report.dart';
import 'package:dio/dio.dart';

class ReportViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  // Mock storage. Replace with the real backend later.
  final List<OutbreakReport> _reports = [];
  final List<AuditLog> _auditLogs = [];

  // Form state
  String? selectedDisease;
  bool isAnonymous = false;
  Uint8List? photoBytes;
  String? photoPath;
  double? latitude;
  double? longitude;
  String? locationName;

  bool isLocating = false;
  bool isSubmitting = false;
  String? errorMessage;

  List<OutbreakReport> get reports => List.unmodifiable(_reports);
  List<AuditLog> get auditLogs => List.unmodifiable(_auditLogs);
  List<OutbreakReport> get pendingReports =>
      _reports.where((r) => r.status == ReportStatus.pending).toList();

  List<OutbreakReport> get approvedReports =>
      _reports.where((r) => r.status == ReportStatus.approved).toList();

  Future<void> reviewReport({
    required String reportId,
    required String officerId,
    required bool approve,
    String? reason,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return;

    _reports[index] = _reports[index].copyWith(
      status: approve ? ReportStatus.approved : ReportStatus.rejected,
    );

    // Audit trail: who, what, when and why
    _auditLogs.add(AuditLog(
      id: 'a${_auditLogs.length + 1}',
      reportId: reportId,
      action: approve ? 'approved' : 'rejected',
      performedBy: officerId,
      reason: reason,
      timestamp: DateTime.now(),
    ));

    notifyListeners();
  }

  void setDisease(String? value) {
    selectedDisease = value;
    notifyListeners();
  }

  void setAnonymous(bool value) {
    isAnonymous = value;
    notifyListeners();
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 70);
      if (file == null) return;
      photoBytes = await file.readAsBytes();
      photoPath = file.path;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Could not load the photo';
      notifyListeners();
    }
  }

  void removePhoto() {
    photoBytes = null;
    photoPath = null;
    notifyListeners();
  }
  Future<String?> _lookupPlaceName(double lat, double lng) async {
    try {
      final res = await Dio().get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'accept-language': 'en',
        },
        options: Options(
          headers: {'User-Agent': 'WhatTheHealth-StudentProject/1.0'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final name = res.data['display_name'] as String?;
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}

    return null; // the form shows coordinates instead
  }

  Future<void> fetchLocation() async {
    isLocating = true;
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
        throw Exception('Location permission was denied');
      }
      final pos = await Geolocator.getCurrentPosition();
      latitude = pos.latitude;
      longitude = pos.longitude;
      locationName = await _lookupPlaceName(pos.latitude, pos.longitude);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    isLocating = false;
    notifyListeners();
  }

  Future<bool> submitReport({
    required String userId,
    required String symptoms,
  }) async {
    if (selectedDisease == null || latitude == null || longitude == null) {
      errorMessage = 'Please choose a disease and get your location';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // pretend network delay

    final id = 'r${_reports.length + 1}';
    final now = DateTime.now();

    _reports.add(OutbreakReport(
      id: id,
      userId: userId, // always stored, even when anonymous
      disease: selectedDisease!,
      symptoms: symptoms,
      photoPath: photoPath,
      photoBytes: photoBytes,
      latitude: latitude!,
      longitude: longitude!,
      locationName: locationName,
      isAnonymous: isAnonymous,
      createdAt: now,
    ));

    // Audit trail entry for every submission
    _auditLogs.add(AuditLog(
      id: 'a${_auditLogs.length + 1}',
      reportId: id,
      action: 'submitted',
      performedBy: userId,
      timestamp: now,
    ));

    _resetForm();
    isSubmitting = false;
    notifyListeners();
    return true;
  }

  void _resetForm() {
    selectedDisease = null;
    isAnonymous = false;
    photoBytes = null;
    photoPath = null;
    latitude = null;
    longitude = null;
    locationName = null;
  }
}