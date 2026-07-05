import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/domain/utils/district_geocoder.dart';

void main() {
  group('AccraDistrictGeocoder Tests', () {
    test('returns exact district for seed data coordinates', () {
      // cv_001 coordinates (5.5717, -0.2107) -> Ayawaso Central
      final district1 = AccraDistrictGeocoder.getDistrict(5.5717, -0.2107);
      expect(district1, equals('Ayawaso Central'));

      // cv_022 coordinates (5.5812, -0.1812) -> Korle Klottey
      final district2 = AccraDistrictGeocoder.getDistrict(5.5812, -0.1812);
      expect(district2, equals('Korle Klottey'));

      // cv_010 coordinates (5.6793, -0.1702) -> Ga East
      final district3 = AccraDistrictGeocoder.getDistrict(5.6793, -0.1702);
      expect(district3, equals('Ga East'));
    });

    test('returns closest district for coordinates near the seed data', () {
      // Coordinate very close to cv_001 (5.5717, -0.2107)
      final district = AccraDistrictGeocoder.getDistrict(5.5716, -0.2108);
      expect(district, equals('Ayawaso Central'));
    });
  });
}
