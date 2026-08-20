import 'api_exception.dart';

/// Standard `{ success, data, message, details }` response from the backend.
class ApiEnvelope<T> {
  final bool success;
  final T data;
  final String? message;
  final Object? details;

  const ApiEnvelope({
    required this.success,
    required this.data,
    this.message,
    this.details,
  });

  factory ApiEnvelope.decode(
    dynamic value,
    T Function(dynamic value) decodeData,
  ) {
    if (value is! Map) {
      throw const ApiContractException('Respons API harus berupa objek JSON.');
    }

    final json = Map<String, dynamic>.from(value);
    final success = json['success'];
    if (success is! bool) {
      throw const ApiContractException(
        'Respons API tidak memiliki field success bertipe boolean.',
      );
    }
    if (!success) {
      throw ApiContractException(
        json['message']?.toString() ??
            'Respons API menyatakan permintaan gagal.',
        details: json['details'],
      );
    }
    if (!json.containsKey('data')) {
      throw const ApiContractException(
        'Respons API sukses tidak memiliki field data.',
      );
    }

    try {
      return ApiEnvelope<T>(
        success: true,
        data: decodeData(json['data']),
        message: json['message']?.toString(),
        details: json['details'],
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiContractException(
        'Field data pada respons API tidak sesuai kontrak.',
        details: error,
      );
    }
  }
}
