import 'package:latlong2/latlong.dart';

/// Centre of the ~1 km grid cell that contains this point.
LatLng areaCenter(double lat, double lng) => LatLng(
  (lat * 100).floor() / 100 + 0.005,
  (lng * 100).floor() / 100 + 0.005,
);

/// Unique key for the grid cell, used to group cases.
String areaKey(double lat, double lng) =>
    '${(lat * 100).floor()}_${(lng * 100).floor()}';