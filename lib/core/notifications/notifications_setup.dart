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
/// intentionally minimal — this is wiring only, not a notification
/// display/UX feature.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

// notify_kit v1.1.5 fixed a bug where `NotifyKit.init()` latched its
// private `_initialized` flag to `true` before awaiting the fallible
// `_local.init(...)`/`_fcm.init(...)` calls, so a first call that threw
// permanently wedged every later call into a silent no-op ("init() already
// called — ignoring") with no error signal. It now only latches on genuine
// success, and a concurrent second call awaits the same in-flight attempt
// instead of racing it.
//
// `bootstrap()` still calls `NotifyKit.init()` exactly once, inside a
// try/catch that only logs (see app_bootstrap.dart). With the fix, device
// registration or resume/retry logic added later can safely call
// `NotifyKit.init()` again to genuinely retry after a failed first attempt,
// per `NotifyKit.registerDevice()`'s own doc comment ("call this after
// login/profile changes").
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
      id: 'app_default_channel',
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
