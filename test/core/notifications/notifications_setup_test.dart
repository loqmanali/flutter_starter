import 'package:flutter_starter/core/notifications/notifications_setup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notify_kit/notify_kit.dart';

void main() {
  group('buildNotifyConfig', () {
    test('declares an Android channel with a stable id', () {
      final config = buildNotifyConfig(onTapRoute: (_) {});

      expect(config.androidChannel.id, 'app_default_channel');
      expect(config.androidChannel.name.isNotEmpty, isTrue);
      expect(config.androidChannel.icon.isNotEmpty, isTrue);
    });

    test('requests permission on init', () {
      expect(
        buildNotifyConfig(onTapRoute: (_) {}).requestPermissionOnInit,
        isTrue,
      );
    });

    test('routes a tap payload that carries a route key', () {
      String? routed;
      final config = buildNotifyConfig(onTapRoute: (route) => routed = route);

      config.onTap!(
        const NotifyMessage(data: {'route': '/settings'}),
        NotifyTapSource.background,
      );

      expect(routed, '/settings');
    });

    test('ignores a tap payload with no route key', () {
      String? routed;
      final config = buildNotifyConfig(onTapRoute: (route) => routed = route);

      config.onTap!(const NotifyMessage(data: {}), NotifyTapSource.background);

      expect(routed, isNull);
    });
  });
}
