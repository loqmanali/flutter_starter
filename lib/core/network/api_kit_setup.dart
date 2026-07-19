import 'package:api_kit/api_kit.dart';
import 'package:flutter_starter/core/config/env.dart';
import 'package:flutter_starter/core/network/app_token_storage.dart';
import 'package:logging_kit/logging_kit.dart';
import 'package:storage_kit/storage_kit.dart';

/// Configures api_kit once, before any client is constructed.
///
/// Token refresh is **not** enabled here — no `onRefreshToken` is passed to
/// [ApiKitRuntime.use]. With no refresh callback configured,
/// `AuthInterceptor` reacts to a `401` on a non-skip-listed path by clearing
/// stored tokens and calling `onLogout` directly (no retry, no crash) — see
/// `api_kit`'s `auth_interceptor.dart`.
///
/// A project that wants refresh must pass an `onRefreshToken` callback that
/// both hits the refresh endpoint *and persists the new token pair itself*
/// (e.g. via `AppTokenStorage.saveTokens`). `AuthInterceptor` does not do
/// this for you: after a successful refresh it only retries the failed
/// request, trusting `onRequest` to re-read the token from storage. Skip the
/// persist step and the retried request re-attaches the stale token, which
/// loops straight into another `401`.
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
