import 'package:api_kit/api_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_starter/core/navigation/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_kit/storage_kit.dart';

import '../di/di_graph_test.dart' show FakeStorageAdapter;
import '../network/app_token_storage_test.dart' show FailingWriteStorageAdapter;

void main() {
  group('AuthSessionNotifier.onAuthenticated', () {
    test('flips the session on when the token write succeeds', () async {
      await AppStorage.initializeWithAdapter(FakeStorageAdapter());
      addTearDown(AppStorage.resetForTesting);

      final container = ProviderContainer(
        overrides: [appStorageProvider.overrideWithValue(AppStorage.instance)],
      );
      addTearDown(container.dispose);

      await container
          .read(authSessionProvider.notifier)
          .onAuthenticated(accessToken: 'a-token', refreshToken: 'r-token');

      expect(container.read(authSessionProvider).isSignedIn, isTrue);
    });

    test('throws a CacheFailure and leaves the session signed out when the '
        'token write fails', () async {
      await AppStorage.initializeWithAdapter(FailingWriteStorageAdapter());
      addTearDown(AppStorage.resetForTesting);

      final container = ProviderContainer(
        overrides: [appStorageProvider.overrideWithValue(AppStorage.instance)],
      );
      addTearDown(container.dispose);

      // Sanity check: the session starts signed out, so the assertion
      // below actually proves the failed write left it unchanged rather
      // than merely never having been true.
      expect(container.read(authSessionProvider).isSignedIn, isFalse);

      await expectLater(
        container
            .read(authSessionProvider.notifier)
            .onAuthenticated(accessToken: 'a-token', refreshToken: 'r-token'),
        throwsA(isA<CacheFailure>()),
      );

      expect(container.read(authSessionProvider).isSignedIn, isFalse);
    });
  });
}
