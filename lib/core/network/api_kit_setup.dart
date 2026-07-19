import 'package:api_kit/api_kit.dart';
import 'package:flutter_starter/core/config/env.dart';
import 'package:flutter_starter/core/network/app_token_storage.dart';
import 'package:logging_kit/logging_kit.dart';
import 'package:storage_kit/storage_kit.dart';

/// Configures api_kit once, before any client is constructed.
///
/// The refresh flow is wired even though Sanctum-style backends do not issue
/// refresh tokens: the interceptor's concurrency-safe queue already exists,
/// and switching it on later should not mean re-reading the interceptor.
/// Return `null` from [refreshAccessToken] to force a logout.
void configureApiKit({
  required AppStorage storage,
  required Future<void> Function() onLogout,
  required Future<String> Function() languageCode,
  String? appVersion,
}) {
  ApiKitRuntime.use(
    baseUrl: Env.baseUrl,
    timeout: const Duration(seconds: 30),
    tokenStorage: AppTokenStorage(storage),
    onLogout: onLogout,
    languageCodeProvider: languageCode,
    appVersion: appVersion,
    enablePrettyLogger: Env.logEnabled,
    logPrint: (object) => AppLogger.debug(object.toString()),
  );
}
