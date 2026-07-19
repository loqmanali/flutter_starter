import 'package:flutter_starter/core/network/app_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_kit/storage_kit.dart';

import '../di/di_graph_test.dart' show FakeStorageAdapter;

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
}
