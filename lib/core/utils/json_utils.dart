/// Null-safe, type-tolerant JSON readers. Backends are not always consistent
/// (numbers as strings, missing keys), so every model parses through these.
abstract final class Json {
  static String string(Object? value, [String fallback = '']) =>
      value == null ? fallback : value.toString();

  static String? stringOrNull(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int integer(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
    }
    return fallback;
  }

  static int? integerOrNull(Object? value) =>
      value == null ? null : integer(value);

  static double decimal(Object? value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? decimalOrNull(Object? value) =>
      value == null ? null : decimal(value);

  static bool boolean(Object? value, [bool fallback = false]) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return fallback;
  }

  static DateTime? date(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static Map<String, dynamic> map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static Map<String, dynamic>? mapOrNull(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static List<T> list<T>(
    Object? value,
    T Function(Map<String, dynamic> json) parse,
  ) {
    if (value is! List) return <T>[];
    return value
        .whereType<Map>()
        .map((item) => parse(Map<String, dynamic>.from(item)))
        .toList();
  }

  static List<String> stringList(Object? value) => value is List
      ? value.where((e) => e != null).map((e) => e.toString()).toList()
      : <String>[];

  static Map<String, String> stringMap(Object? value) => value is Map
      ? value.map((key, val) => MapEntry(key.toString(), val?.toString() ?? ''))
      : <String, String>{};

  /// IDs are strings inside the app; the API expects numeric IDs in bodies.
  static Object id(String value) => int.tryParse(value) ?? value;
}
