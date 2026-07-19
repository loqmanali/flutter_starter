import 'package:flutter/foundation.dart';
import 'package:logging_kit/logging_kit.dart';
import 'package:notify_kit/notify_kit.dart';

/// FCM requires the background handler to be a top-level function in the app.
///
/// Background isolates start with fresh statics, so nothing configured in
/// `bootstrap()` (the DI container, storage, logging tag) is available here —
/// including `AppLogger`'s level. `AppLogger` defaults to
/// [AppLogLevel.info], and only `Env.load()` (main isolate, inside
/// `bootstrap()`) ever raises it; this isolate never runs that, so
/// `AppLogger.debug(...)` here would be a guaranteed no-op in every build.
/// Use [debugPrint] instead — it needs no prior configuration, which is
/// exactly why notify_kit's own background handler uses it too. Kept
/// intentionally minimal — Task 10 is wiring only, not a notification
/// display/UX feature.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

// KNOWN UPSTREAM BUG in notify_kit (vendored, read-only — cannot be fixed
// here): `NotifyKit.init()` sets its private `_initialized` flag to `true`
// BEFORE awaiting `_local.init(...)` and `_fcm.init(...)` — the two calls
// that can actually throw. If the first call to `NotifyKit.init()` throws
// partway through, every later call to it silently no-ops forever
// ("init() already called — ignoring"): the subscriptions never got
// created, and there is no error signal to react to.
//
// Harmless as wired today — `bootstrap()` calls `NotifyKit.init()` exactly
// once, inside a try/catch that only logs and never retries (see
// app_bootstrap.dart). But it poisons the retry-after-failure pattern that
// `NotifyKit.registerDevice()`'s own doc comment recommends ("call this
// after login/profile changes"): a second `NotifyKit.init()` call made to
// recover from a first failed one will not actually initialize anything.
// Anyone adding device registration or resume/retry logic here must not
// assume calling `NotifyKit.init()` again can repair a failed first call.
//
/// Builds the notify_kit configuration.
///
/// [onTapRoute] receives the `route` value from a notification payload; the
/// caller decides how to navigate, keeping this file free of router imports.
///
/// Env.baseUrl gates on whether a backend is configured, not on whether
/// Firebase config (google-services.json / GoogleService-Info.plist) is
/// present — the two are unrelated, so this is deliberately NOT exposed as a
/// "should we init push" gate (and is also why there is no
/// `notificationsEnabled` helper). See notifications_setup_test.dart and the
/// try/catch around NotifyKit.init in app_bootstrap.dart, which is the real
/// guard: it already survives Firebase.initializeApp() failing.
NotifyConfig buildNotifyConfig({
  required void Function(String route) onTapRoute,
}) {
  return NotifyConfig(
    androidChannel: const AndroidChannelConfig(
      id: 'flutter_starter_default',
      name: 'General',
      icon: '@mipmap/ic_launcher',
      description: 'General notifications',
    ),
    requestPermissionOnInit: true,
    onTap: (message, source) {
      final route = message.data['route'];
      if (route is String && route.isNotEmpty) onTapRoute(route);
    },
    onError: (context, error, stackTrace) =>
        AppLogger.error('notify_kit error: $context', error, stackTrace),
  );
}
