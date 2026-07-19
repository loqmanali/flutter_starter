import 'package:flutter_starter/core/navigation/route_paths.dart';

/// Decides redirects from session state alone — pure, so it is unit-tested
/// without a router, a widget tree, or Riverpod.
abstract final class AuthGuard {
  /// Returns the path to redirect to, or `null` to stay put.
  static String? redirect(bool isSignedIn, String location) {
    final isPublic = RoutePaths.public.any(
      (path) => location == path || location.startsWith('$path/'),
    );

    if (!isSignedIn && !isPublic) return RoutePaths.signIn;
    if (isSignedIn && isPublic) return RoutePaths.home;
    return null;
  }
}
