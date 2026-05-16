import 'api_client.dart';

/// API surface for Yudisium announcements / overview flows on mobile.
///
/// Endpoints (see services/src/routes/yudisiums.route.js):
///   GET /yudisiums/announcements — public list of past-deadline events
///                                  with appointed/finalized participants.
class YudisiumApiService {
  static final YudisiumApiService _instance = YudisiumApiService._internal();
  factory YudisiumApiService() => _instance;
  YudisiumApiService._internal();

  final ApiClient _api = ApiClient();

  /// GET /announcements — yudisium events whose registration window has
  /// closed, each with the list of appointed / finalized participants.
  Future<List<Map<String, dynamic>>> getYudisiumAnnouncements() async {
    final res = await _api.get('/yudisiums/announcements');
    return _unwrapList(res);
  }

  List<Map<String, dynamic>> _unwrapList(dynamic res) {
    final raw = res is List
        ? res
        : res is Map<String, dynamic>
            ? (res['data'] ?? res['items'] ?? const [])
            : const [];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
}
