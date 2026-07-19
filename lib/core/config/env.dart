import 'package:logging_kit/logging_kit.dart';

/// Thrown when compile-time configuration is missing or inconsistent.
///
/// Surfaced by [bootstrap] as [AppInitializationErrorScreen] rather than a
/// white screen.
class EnvException implements Exception {
  const EnvException(this.message);

  final String message;

  @override
  String toString() => 'EnvException: $message';
}

/// Compile-time environment, supplied by `--dart-define-from-file`.
///
/// There is no bundled `.env` asset: anything in an asset is readable by
/// unzipping the APK.
abstract final class Env {
  static const String flavor = String.fromEnvironment('BUILD_ENV');
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String appName = String.fromEnvironment('APP_NAME');
  static const bool logEnabled = bool.fromEnvironment('LOG_ENABLED');
  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'info',
  );

  /// Validates configuration and applies it to [AppLogger].
  ///
  /// Throws [EnvException] if the running entrypoint disagrees with the
  /// compiled flavor, or if a required key is absent.
  static void load({required String expectedFlavor}) {
    if (flavor != expectedFlavor) {
      throw EnvException(
        'BUILD_ENV is "$flavor" but this entrypoint expects "$expectedFlavor". '
        'Launch with: flow flavor run $expectedFlavor',
      );
    }
    if (baseUrl.isEmpty) {
      throw const EnvException('BASE_URL is required and was empty.');
    }
    if (!baseUrl.startsWith('https://') && !baseUrl.startsWith('http://')) {
      throw const EnvException(
        'BASE_URL must be an absolute URL, got "$baseUrl".',
      );
    }
    if (appName.isEmpty) {
      throw const EnvException('APP_NAME is required and was empty.');
    }

    AppLogger.setEnabled(logEnabled);
    AppLogger.setLevel(_parseLevel(logLevel));
    AppLogger.setTag(appName);
  }

  static AppLogLevel _parseLevel(String value) => switch (value.toLowerCase()) {
    'debug' => AppLogLevel.debug,
    'warning' => AppLogLevel.warning,
    'error' => AppLogLevel.error,
    'none' => AppLogLevel.none,
    _ => AppLogLevel.info,
  };
}
