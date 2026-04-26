class AppNormalizers {
  const AppNormalizers._();

  static String compactWhitespace(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  static String titleCase(String value) {
    final cleaned = compactWhitespace(value);
    if (cleaned.isEmpty) return '';

    return cleaned
        .split(' ')
        .map((word) {
          if (word.length == 1) return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static String category(String value) {
    return compactWhitespace(value).toUpperCase();
  }

  static String brand(String value) {
    return titleCase(value);
  }

  static String color(String value) {
    return titleCase(value);
  }

  static List<String> colors(List<String> values) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in values) {
      final normalized = color(raw);
      if (normalized.isEmpty) continue;

      final key = normalized.toLowerCase();
      if (seen.contains(key)) continue;

      seen.add(key);
      cleaned.add(normalized);
    }

    return cleaned;
  }

  static List<String> categories(List<String> values) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in values) {
      final normalized = category(raw);
      if (normalized.isEmpty) continue;
      if (seen.contains(normalized)) continue;

      seen.add(normalized);
      cleaned.add(normalized);
    }

    cleaned.sort();
    return cleaned;
  }

  static List<String> brands(List<String> values) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in values) {
      final normalized = brand(raw);
      if (normalized.isEmpty) continue;

      final key = normalized.toLowerCase();
      if (seen.contains(key)) continue;

      seen.add(key);
      cleaned.add(normalized);
    }

    cleaned.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cleaned;
  }

  static String paymentType(String value) {
    return compactWhitespace(value).toLowerCase();
  }
}