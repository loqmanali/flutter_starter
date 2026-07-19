import 'package:api_kit/api_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_starter/core/navigation/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_kit/storage_kit.dart';

import '../di/di_graph_test.dart' show FakeStorageAdapter;
import '../network/app_token_storage_test.dart' show FailingWriteStorageAdapter;

/// Fails only the refresh-token write; the access token and `isLoggedIn`
/// persist normally. Real Sanctum-style backends return the same string
/// for both tokens, so two concurrent writes of identical content to
/// different keys can glitch independently — this proves that glitch alone
/// must not sink an otherwise-fine sign-in.
class RefreshTokenOnlyFailsStorageAdapter extends FakeStorageAdapter {
  @override
  Future<bool> setString(String key, String value) async {
    if (key == StorageKeys.refreshToken) return false;
    return super.setString(key, value);
  }
}

/// Fails only the access-token write — the one write [AuthSession] actually
/// depends on ([AuthSessionNotifier.build] reads only the access token).
class AccessTokenFailsStorageAdapter extends FakeStorageAdapter {
  @override
  Future<bool> setString(String key, String value) async {
    if (key == StorageKeys.accessToken) return false;
    return super.setString(key, value);
  }
}

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

    test(
      'flips the session on when only the refresh-token write fails',
      () async {
        await AppStorage.initializeWithAdapter(
          RefreshTokenOnlyFailsStorageAdapter(),
        );
        addTearDown(AppStorage.resetForTesting);

        final container = ProviderContainer(
          overrides: [
            appStorageProvider.overrideWithValue(AppStorage.instance),
          ],
        );
        addTearDown(container.dispose);

        // The access token — the only thing isSignedIn depends on — persisted
        // fine, so the aggregate failure of the unrelated refresh-token write
        // must not be treated as a failed sign-in.
        await container
            .read(authSessionProvider.notifier)
            .onAuthenticated(accessToken: 'a-token', refreshToken: 'r-token');

        expect(container.read(authSessionProvider).isSignedIn, isTrue);
      },
    );

    test('throws a CacheFailure and leaves the session signed out when the '
        'access-token write fails', () async {
      await AppStorage.initializeWithAdapter(AccessTokenFailsStorageAdapter());
      addTearDown(AppStorage.resetForTesting);

      final container = ProviderContainer(
        overrides: [appStorageProvider.overrideWithValue(AppStorage.instance)],
      );
      addTearDown(container.dispose);

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
