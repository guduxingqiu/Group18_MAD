enum ReportStatus { pending, approved, rejected }

class OutbreakReport {
  final String id;
  final String userId;
  final String disease;
  final String symptoms;
  final String? photoPath;
  final double latitude;
  final double longitude;
  final String? locationName;
  final bool isAnonymous;
  final ReportStatus status;
  final DateTime createdAt;

  const OutbreakReport({
    required this.id,
    required this.userId,
    required this.disease,
    required this.symptoms,
    this.photoPath,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.isAnonymous = false,
    this.status = ReportStatus.pending,
    required this.createdAt,
  });

  factory OutbreakReport.fromJson(Map<String, dynamic> json) => OutbreakReport(
    id: json['id'] as String,
    userId: json['userId'] as String,
    disease: json['disease'] as String,
    symptoms: json['symptoms'] as String,
    photoPath: json['photoPath'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    locationName: json['locationName'] as String?,
    isAnonymous: json['isAnonymous'] as bool? ?? false,
    status: ReportStatus.values.firstWhere(
          (s) => s.name == json['status'],
      orElse: () => ReportStatus.pending,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'disease': disease,
    'symptoms': symptoms,
    'photoPath': photoPath,
    'latitude': latitude,
    'longitude': longitude,
    'locationName': locationName,
    'isAnonymous': isAnonymous,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  OutbreakReport copyWith({ReportStatus? status}) => OutbreakReport(
    id: id,
    userId: userId,
    disease: disease,
    symptoms: symptoms,
    photoPath: photoPath,
    latitude: latitude,
    longitude: longitude,
    locationName: locationName,
    isAnonymous: isAnonymous,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}