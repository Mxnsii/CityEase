import 'package:latlong2/latlong.dart';

class GeoUtils {
  static const Distance distance = Distance();
  
  static double calculateDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    return distance.as(LengthUnit.Meter, LatLng(lat1, lng1), LatLng(lat2, lng2)) / 1000.0;
  }
  
  static int calculateCommuteMinutes(double distanceKm, {double avgSpeedKmh = 30.0}) {
    if (distanceKm == 0) return 0;
    return ((distanceKm / avgSpeedKmh) * 60).round();
  }
}
