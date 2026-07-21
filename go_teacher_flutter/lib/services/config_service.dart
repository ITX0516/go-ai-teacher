import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _keyBaseUrl = 'backend_base_url';
  static const String _defaultBaseUrl = 'http://192.168.1.25:8080';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get baseUrl {
    return _prefs.getString(_keyBaseUrl) ?? _defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_keyBaseUrl, url);
  }

  Future<void> resetToDefault() async {
    await _prefs.setString(_keyBaseUrl, _defaultBaseUrl);
  }
}