import 'package:flutter/material.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:go_router/go_router.dart';
import 'package:navigation_kit/navigation_kit.dart';

/// Hosts the bottom nav over a [StatefulNavigationShell] so each branch keeps
/// its own navigation stack.
class ShellScreen extends StatelessWidget {
  const ShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationKitBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          IconNavigationItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: L10n.home,
          ),
          IconNavigationItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: L10n.settings,
          ),
        ],
      ),
    );
  }
}
