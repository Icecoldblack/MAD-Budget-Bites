/// Turns a whole number of minor units into a price string, e.g. 650 -> "6.50".
String formatMinor(int minor) {
  final sign = minor < 0 ? '-' : '';
  final value = minor.abs();
  final major = value ~/ 100;
  final cents = (value % 100).toString().padLeft(2, '0');
  return '$sign$major.$cents';
}
