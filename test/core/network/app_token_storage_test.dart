import 'package:flutter_starter/core/network/app_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging_kit/logging_kit.dart';
import 'package:storage_kit/storage_kit.dart';

import '../di/di_graph_test.dart' show FakeStorageAdapter;

/// A [FakeStorageAdapter] whose writes report failure without throwing —
/// mirrors how the real adapters (`SharedPrefsAdapter`, `HiveAdapter`) behave
/// when a write actually fails: they catch every exception internally and
/// return `false` rather than throw, so `false` is the only failure signal
/// that ever reaches [AppTokenStorage].
class FailingWriteStorageAdapter extends FakeStorageAdapter {
  @override
  Future<bool> setString(String key, String value) async => false;

  @override
  Future<bool> setBool(String key, bool value) async => false;

  @override
  Future<bool> remove(String key) async => false;
}

void main() {
  setUp(() async {
    await AppStorage.initializeWithAdapter(FakeStorageAdapter());
    addTearDown(AppStorage.resetForTesting);
  });

  group('AppTokenStorage', () {
    test('round-trips the token pair', () async {
      final storage = AppTokenStorage(AppStorage.instance);

      await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');

      expect(await storage.getAccessToken(), 'access');
      expect(await storage.getRefreshToken(), 'refresh');
    });

    test('clearAuthData removes both tokens', () async {
      final storage = AppTokenStorage(AppStorage.instance);
      await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');

      await storage.clearAuthData();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });

  group('AppTokenStorage failure warnings', () {
    test('saveTokens logs a warning when the underlying write fails', () async {
      // Swap the passing setUp() adapter for one whose writes fail.
      await AppStorage.resetForTesting();
      await AppStorage.initializeWithAdapter(FailingWriteStorageAdapter());
      addTearDown(AppStorage.resetForTesting);

      final capturedLevels = <AppLogLevel>[];
      final capturedMessages = <String>[];
      AppLogger.setEnabled(true);
      AppLogger.setLogHandler((level, message, error, stackTrace) {
        capturedLevels.add(level);
        capturedMessages.add(message);
      });
      addTearDown(AppLogger.reset);

      final storage = AppTokenStorage(AppStorage.instance);
      await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');

      expect(capturedLevels, contains(AppLogLevel.warning));
      expect(
        capturedMessages.any((message) => message.contains('saveTokens')),
        isTrue,
        reason: 'warning message should name the failed operation',
      );
    });

    test(
      'clearAuthData logs a warning when the underlying write fails',
      () async {
        await AppStorage.resetForTesting();
        await AppStorage.initializeWithAdapter(FailingWriteStorageAdapter());
        addTearDown(AppStorage.resetForTesting);

        final capturedLevels = <AppLogLevel>[];
        final capturedMessages = <String>[];
        AppLogger.setEnabled(true);
        AppLogger.setLogHandler((level, message, error, stackTrace) {
          capturedLevels.add(level);
          capturedMessages.add(message);
        });
        addTearDown(AppLogger.reset);

        final storage = AppTokenStorage(AppStorage.instance);
        await storage.clearAuthData();

        expect(capturedLevels, contains(AppLogLevel.warning));
        expect(
          capturedMessages.any((message) => message.contains('clearAuthData')),
          isTrue,
          reason: 'warning message should name the failed operation',
        );
      },
    );
  });
}
