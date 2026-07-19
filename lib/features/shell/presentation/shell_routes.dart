import 'package:flutter_starter/core/navigation/route_paths.dart';
import 'package:flutter_starter/features/home/presentation/home_screen.dart';
import 'package:flutter_starter/features/settings/presentation/settings_screen.dart';
import 'package:flutter_starter/features/shell/presentation/shell_screen.dart';
import 'package:go_router/go_router.dart';

final List<RouteBase> shellRoutes = <RouteBase>[
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        ShellScreen(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: RoutePaths.home,
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: RoutePaths.settings,
            name: RoutePaths.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  ),
];
