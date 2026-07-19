import 'package:api_kit/api_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';

/// Whether a usable session exists. Deliberately minimal — profile data
/// belongs to the auth feature, not to routing.
@immutable
class AuthSession {
  const AuthSession({required this.isSignedIn});

  const AuthSession.signedOut() : isSignedIn = false;

  final bool isSignedIn;

  @override
  bool operator ==(Object other) =>
      other is AuthSession && other.isSignedIn == isSignedIn;

  @override
  int get hashCode => isSignedIn.hashCode;
}

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() {
    final storage = ref.watch(appStorageProvider);
    // Sync read of the cached token: the router's redirect runs synchronously
    // and cannot await, so the token must already be in memory. AppStorage
    // caches it during initialize(), which bootstrap awaits.
    final token = storage.getAccessTokenSync();
    return AuthSession(isSignedIn: token != null && token.isNotEmpty);
  }

  /// Persists a token pair and flips the session on.
  ///
  /// [build] gates [isSignedIn] on the access token alone, so that's the
  /// only write this verifies. `saveAuthTokens` bundles three independent
  /// writes (access token, `isLoggedIn` flag, refresh token) into one
  /// aggregate bool; a failure of the other two has no effect on whether
  /// this session is usable and must not fail a sign-in that actually
  /// worked. So instead of trusting that aggregate, this reads the access
  /// token back from storage and compares it to what was just sent.
  ///
  /// Reads it with the async accessor, not [AppStorage.getAccessTokenSync]:
  /// storage_kit rolls the sync cache back to its previous value when the
  /// write fails, but this method verifies the thing that actually matters
  /// — what's on disk — rather than trusting an in-memory mirror of it.
  ///
  /// Throwing here (before flipping [state]) surfaces the failure through
  /// the same `AsyncValue.guard` that already wraps [onAuthenticated]'s
  /// caller, so a sign-in whose token can't be persisted is treated as a
  /// failed sign-in rather than a silent desync that only bites on the
  /// next cold start.
  Future<void> onAuthenticated({
    required String accessToken,
    required String refreshToken,
  }) async {
    final storage = ref.read(appStorageProvider);
    // ponytail: saveAuthTokens's return value is intentionally ignored here
    // — the check below is on the access token it wrote, not its aggregate
    // bool (a failed refresh-token write shouldn't fail an otherwise-good
    // sign-in). See the note below for why the persisted read below is what
    // actually matters, independent of how storage_kit's cache behaves.
    await storage.saveAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    final persistedAccessToken = await storage.getAccessToken();
    if (persistedAccessToken != accessToken) {
      // NOTE: storage_kit rolls AppStorage's in-memory `_cachedAccessToken`
      // back to its previous value when the write fails, so
      // `getAccessTokenSync()` no longer reports a token that never
      // persisted. This check doesn't depend on that either way — it reads
      // the persisted value directly, which is ground truth regardless of
      // how the cache behaves. This provider's state (still signed out
      // below) remains the source of truth for the rest of the app.
      throw const CacheFailure(
        message:
            'Sign-in succeeded but the session could not be saved. '
            'Please try again.',
      );
    }
    state = const AuthSession(isSignedIn: true);
  }

  Future<void> signOut() async {
    await ref.read(appStorageProvider).clearAuthData();
    state = const AuthSession.signedOut();
  }
}

final authSessionProvider = NotifierProvider<AuthSessionNotifier, AuthSession>(
  AuthSessionNotifier.new,
);

/// Bridges the provider onto go_router's `refreshListenable`, which predates
/// Riverpod and only understands [Listenable].
class AuthSessionListenable extends ChangeNotifier {
  AuthSessionListenable(this._ref) {
    _subscription = _ref.listen<AuthSession>(
      authSessionProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthSession> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
