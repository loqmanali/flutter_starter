import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/navigation/auth_guard.dart';
import 'package:flutter_starter/core/navigation/auth_session.dart';
import 'package:flutter_starter/core/navigation/route_builders.dart';
import 'package:flutter_starter/core/navigation/route_paths.dart';
import 'package:flutter_starter/features/auth/presentation/auth_routes.dart';
import 'package:flutter_starter/features/shell/presentation/shell_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:logging_kit/logging_kit.dart';

/// Routes are composed from per-feature lists rather than one growing file.
final goRouterProvider = Provider<GoRouter>((ref) {
  final listenable = AuthSessionListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: RoutePaths.home,
    refreshListenable: listenable,
    errorBuilder: (context, state) {
      AppLogger.error('go_router failed to resolve ${state.uri}', state.error);
      return const NotFoundScreen();
    },
    redirect: (context, state) => AuthGuard.redirect(
      ref.read(authSessionProvider).isSignedIn,
      state.matchedLocation,
    ),
    routes: [...authRoutes, ...shellRoutes],
  );
});
