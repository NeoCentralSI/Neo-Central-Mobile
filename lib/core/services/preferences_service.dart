import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static const String _keyDefaultHome = 'default_home_route';

  /// Saves the default home route.
  /// Options: 'tugas_akhir' (default), 'internship'
  Future<void> setDefaultHome(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultHome, route);
  }

  /// Gets the default home route.
  Future<String> getDefaultHome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultHome) ?? 'tugas_akhir';
  }
}
