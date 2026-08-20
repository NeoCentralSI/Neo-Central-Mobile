import '../models/api_exception.dart';

typedef JsonMap = Map<String, dynamic>;

JsonMap requireJsonMap(dynamic value, {String context = 'data'}) {
  if (value is! Map) {
    throw ApiContractException('$context harus berupa objek JSON.');
  }
  return Map<String, dynamic>.from(value);
}

List<dynamic> requireJsonList(dynamic value, {String context = 'data'}) {
  if (value is! List) {
    throw ApiContractException('$context harus berupa array JSON.');
  }
  return value;
}

extension JsonContractReader on JsonMap {
  String requireString(String key, {String? context}) {
    final value = this[key];
    if (value is String && value.isNotEmpty) return value;
    throw ApiContractException(
      '${context ?? 'data'}.$key harus berupa string.',
    );
  }

  String? optionalString(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is String) return value;
    throw ApiContractException('data.$key harus berupa string atau null.');
  }

  bool requireBool(String key, {String? context}) {
    final value = this[key];
    if (value is bool) return value;
    throw ApiContractException(
      '${context ?? 'data'}.$key harus berupa boolean.',
    );
  }

  bool optionalBool(String key, {bool fallback = false}) {
    final value = this[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    throw ApiContractException('data.$key harus berupa boolean atau null.');
  }

  int requireInt(String key, {String? context}) {
    final value = this[key];
    if (value is int) return value;
    throw ApiContractException(
      '${context ?? 'data'}.$key harus berupa integer.',
    );
  }

  int? optionalInt(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is int) return value;
    throw ApiContractException('data.$key harus berupa integer atau null.');
  }

  num requireNum(String key, {String? context}) {
    final value = this[key];
    if (value is num) return value;
    throw ApiContractException('${context ?? 'data'}.$key harus berupa angka.');
  }

  num? optionalNum(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is num) return value;
    throw ApiContractException('data.$key harus berupa angka atau null.');
  }

  DateTime requireDateTime(String key, {String? context}) {
    final raw = requireString(key, context: context);
    final value = DateTime.tryParse(raw);
    if (value != null) return value;
    throw ApiContractException(
      '${context ?? 'data'}.$key bukan tanggal ISO-8601.',
    );
  }

  DateTime? optionalDateTime(String key) {
    final raw = optionalString(key);
    if (raw == null || raw.isEmpty) return null;
    final value = DateTime.tryParse(raw);
    if (value != null) return value;
    throw ApiContractException('data.$key bukan tanggal ISO-8601.');
  }

  JsonMap requireMap(String key, {String? context}) =>
      requireJsonMap(this[key], context: '${context ?? 'data'}.$key');

  JsonMap? optionalMap(String key) {
    final value = this[key];
    if (value == null) return null;
    return requireJsonMap(value, context: 'data.$key');
  }

  List<dynamic> requireList(String key, {String? context}) =>
      requireJsonList(this[key], context: '${context ?? 'data'}.$key');

  List<dynamic> optionalList(String key) {
    final value = this[key];
    if (value == null) return const [];
    return requireJsonList(value, context: 'data.$key');
  }
}
