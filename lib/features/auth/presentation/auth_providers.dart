import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_starter/core/navigation/auth_session.dart';
import 'package:flutter_starter/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(publicApiClientProvider)),
);

/// Action notifier: `AsyncValue<void>` tracks one submission.
///
/// The UI watches `.isLoading` for the button and `ref.listen`s for the error;
/// success is signalled by the session flipping, which the router observes.
class SignInController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue<void>.data(null);

  Future<void> submit({required String email, required String password}) async {
    if (state.isLoading) return; // de-dupe rapid taps

    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(() async {
      final tokens = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      await ref
          .read(authSessionProvider.notifier)
          .onAuthenticated(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
          );
    });
  }
}

final signInControllerProvider =
    NotifierProvider<SignInController, AsyncValue<void>>(SignInController.new);
