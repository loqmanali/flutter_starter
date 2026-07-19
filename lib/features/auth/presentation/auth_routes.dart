import 'package:flutter_starter/core/navigation/route_paths.dart';
import 'package:flutter_starter/features/auth/presentation/sign_in_screen.dart';
import 'package:go_router/go_router.dart';

/// This feature's contribution to the router. Composed in `app_router.dart`.
final List<RouteBase> authRoutes = <RouteBase>[
  GoRoute(
    path: RoutePaths.signIn,
    name: RoutePaths.signIn,
    builder: (context, state) => const SignInScreen(),
  ),
];
