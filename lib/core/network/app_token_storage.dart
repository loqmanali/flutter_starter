import 'package:api_kit/api_kit.dart';
import 'package:logging_kit/logging_kit.dart';
import 'package:storage_kit/storage_kit.dart';

/// Bridges api_kit's [AuthTokenStorageAdapter] contract onto storage_kit's
/// [AppStorage], which already owns the token keys.
class AppTokenStorage implements AuthTokenStorageAdapter {
  const AppTokenStorage(this._storage);

  final AppStorage _storage;

  @override
  Future<String?> getAccessToken() => _storage.getAccessToken();

  @override
  Future<String?> getRefreshToken() => _storage.getRefreshToken();

  /// Invariant: write tokens only through this method (or
  /// [AppStorage.saveAccessToken]) — never via
  /// `AppStorage.instance.setString(StorageKeys.accessToken, ...)` directly.
  /// Only [AppStorage.saveAuthTokens]/`saveAccessToken` also update
  /// [AppStorage.getAccessTokenSync]'s in-memory cache. `AuthSessionNotifier.
  /// build()` reads that cache synchronously, but only once, when the
  /// notifier is first constructed — go_router's auth-gate redirect then just
  /// reads the resulting cached `isSignedIn` from `authSessionProvider`. That
  /// one-time read must see a value written earlier in the same process
  /// (`AppStorage.initialize()` pre-warms it at cold start), so bypassing
  /// this path desyncs the cache from persisted storage and silently breaks
  /// the auth gate.
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final wasSaved = await _storage.saveAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    if (!wasSaved) {
      // The adapters underneath AppStorage (SharedPrefsAdapter, HiveAdapter)
      // catch every exception internally and return false instead of
      // throwing — this warning is the only failure signal that exists.
      // storage_kit rolls its in-memory access-token cache back to the
      // previous value when the write fails (it no longer sets the cache
      // ahead of the write), so this doesn't desync `getAccessTokenSync()`
      // from what's persisted — it's just a diagnostic for an otherwise
      // silent storage failure.
      AppLogger.warning(
        'AppTokenStorage.saveTokens: AppStorage.saveAuthTokens failed to '
        'persist the new access/refresh token pair.',
      );
    }
  }

  // Clears persisted storage only — it does not flip `authSessionProvider`.
  // `AuthInterceptor` calls this directly on an unrecoverable 401, then calls
  // `onLogout`, which `bootstrap()` wires to
  // `authSessionProvider.notifier.signOut()` for that reason: without it,
  // the router's redirect keeps reading a stale `isSignedIn: true`.
  @override
  Future<void> clearAuthData() async {
    final wasCleared = await _storage.clearAuthData();
    if (!wasCleared) {
      AppLogger.warning(
        'AppTokenStorage.clearAuthData: AppStorage.clearAuthData failed to '
        'remove one or more persisted auth keys.',
      );
    }
  }
}
