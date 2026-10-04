import 'package:flutter/foundation.dart';

/// Provides the API endpoint for the current runtime environment.
///
/// Override the default with `--dart-define=API_BASE_URL=https://example.com/api`.
/// Android emulators use `10.0.2.2` to reach a backend running on the host.
/// Physical devices use the host machine's LAN IP address.
class ApiConfig {
  ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  // Desktop / Web (Chrome) — loopback works fine
  static const String _desktopAndWebBaseUrl = 'http://127.0.0.1:5168/api';

  // Android emulator — special alias that routes to host machine
  // static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:5168/api';

  // Physical Android / iOS device — using ADB reverse over USB cable
  static const String _physicalDeviceBaseUrl = 'http://127.0.0.1:5168/api';

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (kIsWeb) {
      return _desktopAndWebBaseUrl;
    }
    // On Android, check if running on emulator vs physical device
    // defaultTargetPlatform is Android for both, but emulator uses 10.0.2.2
    // We default to physical device IP — change to _androidEmulatorBaseUrl if using emulator
    return _physicalDeviceBaseUrl;
  }
}
