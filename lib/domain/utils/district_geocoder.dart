import 'package:civic_voice/data/repositories/mock_civic_data_repository.dart';

class AccraDistrictGeocoder {
  /// Finds the closest district by calculating Euclidean distance to the 55 seed reports.
  /// Falls back to 'Ayawaso Central' if no matching coordinates exist.
  static String getDistrict(double latitude, double longitude) {
    double minDistance = double.maxFinite;
    String closestDistrict = 'Ayawaso Central';

    for (final report in MockCivicDataRepository.seedData) {
      final double latDiff = report.latitude - latitude;
      final double lngDiff = report.longitude - longitude;
      final double distance = latDiff * latDiff + lngDiff * lngDiff;
      if (distance < minDistance) {
        minDistance = distance;
        closestDistrict = report.district;
      }
    }
    return closestDistrict;
  }
}
