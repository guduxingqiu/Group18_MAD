import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/audit_log.dart';
import '../models/outbreak_report.dart';
import '../repository/report_repository.dart';
import '../../../core/database/pending_report_queue.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportRepository _repo;

  ReportViewModel(this._repo) {
    loadAll();
  }

  final ImagePicker _picker = ImagePicker();

  // Data cached from the repository
  List<OutbreakReport> _reports = [];
  List<AuditLog> _auditLogs = [];
  List<OutbreakReport> _approved = [];
  Map<String, int> get approvedByDisease {
    final counts = <String, int>{};
    for (final r in _approved) {
      counts[r.disease] = (counts[r.disease] ?? 0) + 1;
    }
    return counts;
  }

  // Form state
  final PendingReportQueue _queue = PendingReportQueue();
  String? _userId;
  int pendingCount = 0;
  bool isSyncing = false;
  bool lastSubmitQueued = false;
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
  List<OutbreakReport> get approvedReports => _approved;

  /// Call after login or register.
  Future<void> onLogin(String userId) async {
    _userId = userId;
    await _refreshPendingCount();
    await syncPending();
    await loadAll();
  }

  Future<void> _refreshPendingCount() async {
    pendingCount = _userId == null ? 0 : (await _queue.forUser(_userId!)).length;
    notifyListeners();
  }

  /// Sends reports that were saved while offline.
  Future<void> syncPending() async {
    final uid = _userId;
    if (uid == null || isSyncing) return;

    isSyncing = true;
    notifyListeners();

    var sent = 0;
    try {
      for (final item in await _queue.forUser(uid)) {
        try {
          await _repo.submitReport(
            reportId: item.id,
            userId: item.userId,
            disease: item.disease,
            symptoms: item.symptoms,
            photoBytes: item.photoBytes,
            latitude: item.latitude,
            longitude: item.longitude,
            locationName: item.locationName,
            isAnonymous: item.isAnonymous,
          );
          await _queue.remove(item.id);
          sent++;
        } on ReportOfflineException {
          break; // still offline, try again later
        } on ReportException catch (e) {
          errorMessage = e.message; // keep it queued and try the next one
        }
      }
    } catch (_) {
      // ignore unexpected storage errors; the reports stay queued
    }

    isSyncing = false;
    await _refreshPendingCount();
    if (sent > 0) await loadAll();
  }

  void _finishSubmit() {
    _resetForm();
    isSubmitting = false;
    notifyListeners();
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

  Future<void> loadAll() async {
    try {
      _reports = await _repo.fetchReports();
      _approved = await _repo.fetchApprovedCases();
      _auditLogs = await _repo.fetchAuditLogs();
      errorMessage = null;
    } on ReportException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not load reports';
    }
    notifyListeners();
  }

  /// Call on logout so the next person on this device never sees old data.
  void clear() {
    _userId = null;
    pendingCount = 0;
    _reports = [];
    _approved = [];
    _auditLogs = [];
    errorMessage = null;
    notifyListeners();
  }

  Future<void> reviewReport({
    required String reportId,
    required String officerId,
    required bool approve,
    String? reason,
  }) async {
    try {
      await _repo.reviewReport(
        reportId: reportId,
        officerId: officerId,
        approve: approve,
        reason: reason,
      );
      await loadAll();
    } on ReportException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Could not update the report';
      notifyListeners();
    }
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
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
      );
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
    lastSubmitQueued = false;
    notifyListeners();

    final id = _repo.newReportId(); // created first so a retry uses the same ID

    try {
      await _repo.submitReport(
        reportId: id,
        userId: userId,
        disease: selectedDisease!,
        symptoms: symptoms,
        photoPath: photoPath,
        photoBytes: photoBytes,
        latitude: latitude!,
        longitude: longitude!,
        locationName: locationName,
        isAnonymous: isAnonymous,
      );
      await loadAll();
      _finishSubmit();
      syncPending(); // we are online, so also send older unsent reports
      return true;
    } on ReportOfflineException {
      final saved = await _queue.add(PendingReport(
        id: id,
        userId: userId,
        disease: selectedDisease!,
        symptoms: symptoms,
        photoBytes: photoBytes,
        latitude: latitude!,
        longitude: longitude!,
        locationName: locationName,
        isAnonymous: isAnonymous,
      ));
      if (!saved) {
        errorMessage =
        'You have too many unsent reports. Connect to the internet so they can be sent first.';
        isSubmitting = false;
        notifyListeners();
        return false;
      }
      lastSubmitQueued = true;
      await _refreshPendingCount();
      _finishSubmit();
      return true;
    } on ReportException catch (e) {
      errorMessage = e.message;
      isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Could not submit the report. Please try again.';
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}