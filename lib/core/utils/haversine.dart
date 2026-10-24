import 'dart:math';

/// Menghitung jarak antara dua koordinat menggunakan rumus Haversine.
/// Identik dengan fungsi calculateDistance() di matching.js.
double calculateDistanceKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const double r = 6371.0; // Radius bumi dalam km
  final double dLat = (lat2 - lat1) * (pi / 180);
  final double dLng = (lng2 - lng1) * (pi / 180);
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * (pi / 180)) *
          cos(lat2 * (pi / 180)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  final double distance = r * c;
  // Bulatkan ke 1 desimal (sesuai matching.js)
  return (distance * 10).roundToDouble() / 10;
}
