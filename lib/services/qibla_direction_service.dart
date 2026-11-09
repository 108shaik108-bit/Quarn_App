import 'dart:math' as math;

class QiblaDirectionService {
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  /// Returns the initial great-circle bearing from the given coordinates
  /// to the Kaaba, measured clockwise from true north (0°–360°).
  static double bearingFrom(double latitude, double longitude) {
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final deltaLongitude = _toRadians(kaabaLongitude - longitude);

    final y = math.sin(deltaLongitude) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLongitude);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  static double distanceKmFrom(double latitude, double longitude) {
    const earthRadiusKm = 6371.0;
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final deltaLat = lat2 - lat1;
    final deltaLon = _toRadians(kaabaLongitude - longitude);

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(deltaLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
