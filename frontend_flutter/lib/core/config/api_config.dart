import 'package:flutter/foundation.dart';

/// Provides the API endpoint for the current runtime environment.
///
/// Override the default with `--dart-define=API_BASE_URL=https://example.com/api`.
/// Android emulators use `10.0.2.2` to reach a backend running on the host.
class ApiConfig {
  ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _desktopAndWebBaseUrl = 'http://127.0.0.1:5168/api';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:5168/api';

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    // Use the real Wi-Fi IP address for both physical phones and desktop
    return _desktopAndWebBaseUrl;
  }
}
