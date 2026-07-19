import 'package:logging_kit/logging_kit.dart';
import 'package:notify_kit/notify_kit.dart';

/// FCM requires the background handler to be a top-level function in the app.
///
/// Background isolates start with fresh statics, so nothing configured in
/// `bootstrap()` (the DI container, storage, logging tag) is available here.
/// Kept intentionally minimal — Task 10 is wiring only, not a notification
/// display/UX feature.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(RemoteMessage message) async {
  AppLogger.debug('Background message: ${message.messageId}');
}

/// Builds the notify_kit configuration.
///
/// [onTapRoute] receives the `route` value from a notification payload; the
/// caller decides how to navigate, keeping this file free of router imports.
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

/// Env.baseUrl gates on whether a backend is configured, not on whether
/// Firebase config (google-services.json / GoogleService-Info.plist) is
/// present — the two are unrelated, so this is deliberately NOT exposed as a
/// "should we init push" gate. See notifications_setup_test.dart and the
/// try/catch around NotifyKit.init in app_bootstrap.dart, which is the real
/// guard: it already survives Firebase.initializeApp() failing.
