import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_starter/core/localization/l10n/app_localizations.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:flutter_starter/features/settings/presentation/settings_screen.dart';
import 'package:flutter_starter/features/settings/presentation/theme_mode_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization_kit/localization_kit.dart';
import 'package:storage_kit/storage_kit.dart';

import '../../core/di/di_graph_test.dart' show FakeStorageAdapter;

// Exercises the two callbacks this screen wires up by hand rather than by
// copying the task brief verbatim — LanguageNotifier.changeLocale (not the
// brief's nonexistent changeLanguage) and RadioGroup (not the deprecated
// RadioListTile.groupValue/onChanged) — so a regression in either wiring
// fails a test instead of only showing up on a device.
void main() {
  setUp(() async {
    await AppStorage.initializeWithAdapter(FakeStorageAdapter());
    addTearDown(AppStorage.resetForTesting);
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [appStorageProvider.overrideWithValue(AppStorage.instance)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              L10n.init(context);
              return const SettingsScreen();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('toggling the language switch flips locale to Arabic', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    expect(container.read(languageProvider).locale, const Locale('en'));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(container.read(languageProvider).locale, const Locale('ar'));
  });

  testWidgets('selecting a theme radio persists the choice', (tester) async {
    final container = await pumpScreen(tester);

    await tester.tap(find.widgetWithText(RadioListTile<ThemeMode>, 'dark'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(await AppStorage.instance.getThemeMode(), 'dark');
  });
}
