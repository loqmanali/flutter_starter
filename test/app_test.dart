import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/app.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_starter/core/navigation/app_router.dart';
import 'package:flutter_starter/core/navigation/auth_session.dart';
import 'package:flutter_starter/core/navigation/route_builders.dart';
import 'package:flutter_starter/core/navigation/route_paths.dart';
import 'package:flutter_starter/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter_starter/features/home/presentation/home_screen.dart';
import 'package:flutter_starter/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_kit/storage_kit.dart';

import 'core/di/di_graph_test.dart' show FakeStorageAdapter;

/// Boots the real [App] — not a screen pumped in isolation under its own
/// `MaterialApp` — under a single `UncontrolledProviderScope`, exactly as
/// `bootstrap()` does.
///
/// What this covers: the force-logout path end to end through the real
/// router. api_kit's `AuthInterceptor` calls `onLogout` on an unrecoverable
/// 401, and `bootstrap()` wires that to `signOut()`. Before that wiring
/// existed, a forced logout cleared storage but left `authSessionProvider`
/// reporting signed-in, stranding the user on protected screens until they
/// killed the app. Every other test pumps one screen directly, so this is
/// the only one that exercises session state driving real navigation.
///
/// What this does NOT cover, deliberately stated so nobody assumes otherwise:
/// it cannot catch `bootstrap()` regressing to `runApp(ProviderScope(...))`
/// instead of `UncontrolledProviderScope(container: container, ...)`. That is
/// the actual container-desync hazard — `onLogout`'s closure would hold a
/// container the widget tree never reads — but no widget test can see it,
/// because tests construct their own scope and never call `bootstrap()`.
/// Verified by mutation: wrapping [App]'s subtree in a nested `ProviderScope`
/// does not fail this test, and correctly so — Riverpod delegates reads to
/// the root container for providers a child scope doesn't override, so a
/// nested scope is transparent rather than dangerous. The guard against the
/// real hazard is the doc comment on [App] plus review of `bootstrap()`.
void main() {
  // Shared by every test below: boots the real [App] under a single real
  // container, seeding a signed-in or signed-out session up front.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required bool signedIn,
  }) async {
    // Seed the access token (or don't) before AppStorage initializes, so
    // AuthSessionNotifier.build() (which reads the sync-cached token) sees
    // the intended session from the very first read — same as a real cold
    // start with (or without) a previously-persisted token.
    final adapter = FakeStorageAdapter();
    if (signedIn) {
      await adapter.setString(StorageKeys.accessToken, 'seeded-access-token');
    }
    await AppStorage.initializeWithAdapter(adapter);
    addTearDown(AppStorage.resetForTesting);

    final container = ProviderContainer(
      overrides: [appStorageProvider.overrideWithValue(AppStorage.instance)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const App()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('signing out redirects from the home screen to sign-in', (
    tester,
  ) async {
    final container = await pumpApp(tester, signedIn: true);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);

    // The exact closure bootstrap() wires to api_kit's onLogout.
    await container.read(authSessionProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  // Regression coverage for a notification tap: buildNotifyConfig's
  // onTapRoute closure (wired in app_bootstrap.dart) calls exactly
  // `container.read(goRouterProvider).go(route)` with the `route` value
  // taken verbatim from the push payload — an unauthenticated, unvalidated
  // string. These two tests drive that identical call so a regression in
  // AuthGuard or the router's errorBuilder is caught here rather than only
  // discovered by a crafted push payload in the wild.
  testWidgets('a notification tap naming a protected route while signed out is '
      'redirected to sign-in instead of rendering it', (tester) async {
    final container = await pumpApp(tester, signedIn: false);

    expect(find.byType(SignInScreen), findsOneWidget);

    container.read(goRouterProvider).go(RoutePaths.settings);
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets(
    'a notification tap naming a nonexistent route renders NotFoundScreen '
    'instead of throwing',
    (tester) async {
      final container = await pumpApp(tester, signedIn: true);

      expect(find.byType(HomeScreen), findsOneWidget);

      container.read(goRouterProvider).go('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
    },
  );
}
