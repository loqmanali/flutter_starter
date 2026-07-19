import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/app.dart';
import 'package:flutter_starter/core/bootstrap/app_initialization_error_screen.dart';
import 'package:flutter_starter/core/config/env.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_starter/core/navigation/auth_session.dart';
import 'package:flutter_starter/core/network/api_kit_setup.dart';
import 'package:flutter_starter/features/settings/presentation/theme_mode_provider.dart';
import 'package:localization_kit/localization_kit.dart';
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

  // Seed themeModeProvider's initial state instead of restoring it after the
  // first frame: read the persisted mode now, while nothing has rendered
  // yet, so build() (below) never has to reconcile away a wrong guess. See
  // theme_mode_provider.dart for why a post-frame restore is wrong.
  final initialThemeMode = ThemeModeNotifier.parse(
    await AppStorage.instance.getThemeMode(),
  );

  final container = ProviderContainer(
    overrides: [
      appStorageProvider.overrideWithValue(AppStorage.instance),
      themeModeProvider.overrideWith(() => ThemeModeNotifier(initialThemeMode)),
    ],
  );

  LocalizationKitRuntime.use(
    storage: _StorageBackedLocalization(AppStorage.instance),
    // Both ARB locales this app ships (see supportedLocales), not just the
    // kit's English-only default — otherwise a language picker built from
    // availableLanguagesProvider would silently drop Arabic despite it
    // being fully translated.
    defaultLanguages: const [
      LanguageModel(code: 'en', name: 'English', isoCode: 'en'),
      LanguageModel(code: 'ar', name: 'العربية', isoCode: 'ar'),
    ],
    defaultIsoCode: 'en',
    defaultApiCode: 'en',
  );
  // Restores the persisted locale before the first frame — without this,
  // languageProvider never reads storage and always starts at the runtime
  // default, so a saved Arabic choice would silently reset on every launch.
  await container.read(languageProvider.notifier).initialize();

  configureApiKit(
    storage: AppStorage.instance,
    onLogout: () => container.read(authSessionProvider.notifier).signOut(),
    languageCode: () async => await AppStorage.instance.getLocale() ?? 'en',
  );

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}

/// Persists the chosen language through AppStorage so locale and tokens share
/// one backend.
class _StorageBackedLocalization implements LocalizationStorageAdapter {
  const _StorageBackedLocalization(this._storage);

  final AppStorage _storage;

  @override
  Future<String?> getLocaleCode() => _storage.getLocale();

  @override
  Future<void> setLocaleCode(String isoCode) async {
    await _storage.saveLocale(isoCode);
  }

  @override
  Future<String?> getLanguageCode() => _storage.getLocale();

  @override
  Future<void> setLanguageCode(String apiCode) async {
    await _storage.saveLocale(apiCode);
  }
}
