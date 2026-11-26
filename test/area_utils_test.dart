import 'package:flutter_test/flutter_test.dart';
import 'package:what_the_health/core/utils/area_utils.dart';

void main() {
  test('areaCenter snaps to the middle of a 0.01 degree cell', () {
    final c = areaCenter(2.2964682, 111.8917884);
    expect(c.latitude, closeTo(2.295, 1e-9));
    expect(c.longitude, closeTo(111.895, 1e-9));
  });

  test('nearby points share the same area key', () {
    expect(areaKey(2.2961, 111.8911), areaKey(2.2999, 111.8999));
  });

  test('points in different cells have different keys', () {
    expect(areaKey(2.2961, 111.8911), isNot(areaKey(2.3061, 111.8911)));
  });
}