/// Every route path in the app. Path and name are the same string, so
/// `context.goNamed(RoutePaths.home)` and `context.go(RoutePaths.home)` agree.
abstract final class RoutePaths {
  static const String signIn = '/sign-in';
  static const String home = '/home';
  static const String settings = '/settings';

  /// Paths reachable without a session. Everything else is guarded.
  static const Set<String> public = <String>{signIn};
}
