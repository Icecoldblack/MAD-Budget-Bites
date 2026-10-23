/// Turns a whole number of minor units into a price string, e.g. 650 -> "6.50".
String formatMinor(int minor) {
  final sign = minor < 0 ? '-' : '';
  final value = minor.abs();
  final major = value ~/ 100;
  final cents = (value % 100).toString().padLeft(2, '0');
  return '$sign$major.$cents';
}

/// Turns a typed price into minor units, e.g. "6.50" -> 650 and "6" -> 600.
/// Returns null if the text is not a number, is negative, or has more
/// than 2 decimal places.
int? parseMinor(String text) {
  final trimmed = text.trim();
  final value = double.tryParse(trimmed);
  if (value == null || value < 0) {
    return null;
  }

  final parts = trimmed.split('.');
  if (parts.length == 2 && parts[1].length > 2) {
    return null;
  }

  return (value * 100).round();
}
