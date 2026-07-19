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
  Future<void> onAuthenticated({
    required String accessToken,
    required String refreshToken,
  }) async {
    await ref
        .read(appStorageProvider)
        .saveAuthTokens(accessToken: accessToken, refreshToken: refreshToken);
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
