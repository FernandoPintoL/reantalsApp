import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UrlConfigProvider with ChangeNotifier {
  static const String _useOnlineUrlKey = 'use_online_url';

  bool _useOnlineUrl = true;
  String? _baseUrlLocal;
  String? _baseUrlOnline;
  String? _baseUrlImageOnline;
  String? _baseUrlImageLocal;
  String? _baseUrlSocketLocal;
  String? _baseUrlSocketOnline;

  UrlConfigProvider() {
    _baseUrlLocal = dotenv.env['BASE_LOCAL_URL'] ?? '';
    _baseUrlOnline = dotenv.env['BASE_PROD_URL'] ?? '';
    _baseUrlImageLocal = dotenv.env['BASE_LOCAL_URL_IMAGE'] ?? '';
    _baseUrlImageOnline = dotenv.env['BASE_PROD_URL_IMAGE'] ?? '';
    _baseUrlSocketLocal = dotenv.env['BASE_LOCAL_URL_SOCKET'] ?? '';
    _baseUrlSocketOnline = dotenv.env['BASE_PROD_URL_SOCKET'] ?? '';

    // Set default URL mode based on APP_ENV
    final appEnv = dotenv.env['APP_ENV'] ?? 'local';
    _useOnlineUrl = appEnv != 'local';

    _loadPreference();
  }

  bool get useOnlineUrl => _useOnlineUrl;
  String get currentBaseUrl => _useOnlineUrl ? (_baseUrlOnline ?? '') : (_baseUrlLocal ?? '');
  String get currentBaseUrlImage => _useOnlineUrl ? (_baseUrlImageOnline ?? '') : (_baseUrlImageLocal ?? '');
  String get currentBaseUrlSocket => _useOnlineUrl ? (_baseUrlSocketOnline ?? '') : (_baseUrlSocketLocal ?? '');
  String get baseUrlLocal => _baseUrlLocal ?? '';
  String get baseUrlOnline => _baseUrlOnline ?? '';
  String get baseUrlImageLocal => _baseUrlImageLocal ?? '';
  String get baseUrlImageOnline => _baseUrlImageOnline ?? '';
  String get baseUrlSocketLocal => _baseUrlSocketLocal ?? '';
  String get baseUrlSocketOnline => _baseUrlSocketOnline ?? '';

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Only use saved preference if APP_ENV is not explicitly set
    final appEnv = dotenv.env['APP_ENV'];
    if (appEnv == null || appEnv.isEmpty) {
      _useOnlineUrl = prefs.getBool(_useOnlineUrlKey) ?? true;
    } else {
      // APP_ENV takes precedence over saved preferences
      _useOnlineUrl = appEnv != 'local';
      // Update the saved preference to match APP_ENV
      await prefs.setBool(_useOnlineUrlKey, _useOnlineUrl);
    }
    notifyListeners();
  }

  Future<void> setUseOnlineUrl(bool value) async {
    if (_useOnlineUrl == value) return;

    // Check if APP_ENV is explicitly set
    final appEnv = dotenv.env['APP_ENV'];
    if (appEnv != null && appEnv.isNotEmpty) {
      // If APP_ENV is set, only allow changing if it matches the requested mode
      bool shouldBeOnline = appEnv != 'local';
      if (value != shouldBeOnline) {
        print('Warning: Cannot change URL mode when APP_ENV is set. Current APP_ENV: $appEnv');
        return;
      }
    }

    _useOnlineUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useOnlineUrlKey, value);
    notifyListeners();
  }

  Future<void> toggleUrlMode() async {
    await setUseOnlineUrl(!_useOnlineUrl);
  }
}
