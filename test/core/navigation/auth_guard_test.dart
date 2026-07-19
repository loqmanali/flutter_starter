import 'package:flutter_starter/core/navigation/auth_guard.dart';
import 'package:flutter_starter/core/navigation/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthGuard.redirect', () {
    test('sends a signed-out user off a protected path to sign-in', () {
      expect(AuthGuard.redirect(false, RoutePaths.home), RoutePaths.signIn);
    });

    test('leaves a signed-out user on the sign-in path alone', () {
      expect(AuthGuard.redirect(false, RoutePaths.signIn), isNull);
    });

    test('sends a signed-in user off the sign-in path to home', () {
      expect(AuthGuard.redirect(true, RoutePaths.signIn), RoutePaths.home);
    });

    test('leaves a signed-in user on a protected path alone', () {
      expect(AuthGuard.redirect(true, RoutePaths.settings), isNull);
    });

    test('guards nested protected paths, not just exact matches', () {
      expect(
        AuthGuard.redirect(false, '${RoutePaths.settings}/language'),
        RoutePaths.signIn,
      );
    });
  });
}
