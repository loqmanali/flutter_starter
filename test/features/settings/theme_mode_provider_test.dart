import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_starter/features/settings/presentation/theme_mode_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_kit/storage_kit.dart';

import '../../core/di/di_graph_test.dart' show FakeStorageAdapter;

void main() {
  setUp(() async {
    await AppStorage.initializeWithAdapter(FakeStorageAdapter());
    addTearDown(AppStorage.resetForTesting);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [appStorageProvider.overrideWithValue(AppStorage.instance)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults to system when nothing is stored', () {
    expect(makeContainer().read(themeModeProvider), ThemeMode.system);
  });

  test('set() updates state and persists the choice', () async {
    final container = makeContainer();

    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(await AppStorage.instance.getThemeMode(), 'dark');
  });

  test('a fresh container restores the persisted choice', () async {
    await AppStorage.instance.saveThemeMode('light');

    final container = makeContainer();
    container.read(themeModeProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
