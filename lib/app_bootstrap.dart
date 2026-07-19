import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/app.dart';
import 'package:flutter_starter/core/bootstrap/app_initialization_error_screen.dart';
import 'package:flutter_starter/core/config/env.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_starter/core/network/api_kit_setup.dart';
import 'package:logging_kit/logging_kit.dart';
import 'package:storage_kit/storage_kit.dart';

/// The single startup sequence, shared by every flavored entrypoint.
///
/// Later tasks extend this: storage init (Task 3), api_kit (Task 6),
/// notify_kit and force_update_gate (Task 10).
Future<void> bootstrap(String flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Env.load(expectedFlavor: flavor);
  } on EnvException catch (error) {
    runApp(AppInitializationErrorScreen(message: error.message));
    return;
  }

  AppLogger.info('Booting ${Env.appName} (${Env.flavor})');

  await AppStorage.initialize();

  configureApiKit(
    storage: AppStorage.instance,
    onLogout: () async => AppStorage.instance.clearAuthData(),
    languageCode: () async => await AppStorage.instance.getLocale() ?? 'en',
  );

  runApp(
    ProviderScope(
      overrides: [appStorageProvider.overrideWithValue(AppStorage.instance)],
      child: const App(),
    ),
  );
}
