import 'package:flutter_test/flutter_test.dart';

import 'package:budget_bites/utils/money.dart';

void main() {
  test('formatMinor turns minor units into a price', () {
    expect(formatMinor(650), '6.50');
    expect(formatMinor(1050), '10.50');
    expect(formatMinor(5), '0.05');
    expect(formatMinor(0), '0.00');
    expect(formatMinor(-100), '-1.00');
  });

  test('parseMinor turns a typed price into minor units', () {
    expect(parseMinor('6.50'), 650);
    expect(parseMinor('6.5'), 650);
    expect(parseMinor('6'), 600);
    expect(parseMinor('0'), 0);
    expect(parseMinor(' 4.50 '), 450);
    expect(parseMinor('0.29'), 29);
  });

  test('parseMinor rejects bad prices', () {
    expect(parseMinor(''), isNull);
    expect(parseMinor('abc'), isNull);
    expect(parseMinor('-1'), isNull);
    expect(parseMinor('6.505'), isNull);
  });
}
