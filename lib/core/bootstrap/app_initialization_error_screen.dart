import 'package:flutter/material.dart';
import 'package:widget_kit/widget_kit.dart';

/// Shown when [bootstrap] fails before the app can start.
///
/// Deliberately depends on nothing that bootstrap configures — no theme, no
/// localization, no providers — because any of those may be why we are here.
class AppInitializationErrorScreen extends StatelessWidget {
  const AppInitializationErrorScreen({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(WidgetKitTokens.spaceLg),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: WidgetKitTokens.spaceMd),
                const Text(
                  'Startup failed',
                  style: TextStyle(
                    fontSize: WidgetKitTokens.fontHeading,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: WidgetKitTokens.spaceXs),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
