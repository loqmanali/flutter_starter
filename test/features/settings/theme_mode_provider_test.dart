import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';
import 'package:flutter_starter/features/settings/presentation/theme_mode_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_kit/storage_kit.dart';

import '../../core/di/di_graph_test.dart' show FakeStorageAdapter;

/// Simulates `SharedPrefsAdapter`'s real async round-trip (platform channel
/// + JSON decode), so a test can prove no frame ever observes a stale
/// [ThemeMode] while a read is "in flight" — there is nothing in flight by
/// the time the widget tree exists, because bootstrap() awaits this read
/// before `runApp`.
class DelayedStorageAdapter extends FakeStorageAdapter {
  @override
  Future<String?> getString(String key) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return super.getString(key);
  }
}

void main() {
  setUp(() async {
    await AppStorage.initializeWithAdapter(FakeStorageAdapter());
    addTearDown(AppStorage.resetForTesting);
  });

  ProviderContainer makeContainer({ThemeMode? seed}) {
    final container = ProviderContainer(
      overrides: [
        appStorageProvider.overrideWithValue(AppStorage.instance),
        if (seed != null)
          themeModeProvider.overrideWith(() => ThemeModeNotifier(seed)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults to system when nothing seeds the notifier', () {
    expect(makeContainer().read(themeModeProvider), ThemeMode.system);
  });

  test('set() updates state and persists the choice', () async {
    final container = makeContainer();

    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(await AppStorage.instance.getThemeMode(), 'dark');
  });

  test(
    'seeding from the persisted value (as bootstrap() does) starts the '
    'notifier there synchronously — no restore, so nothing to await',
    () async {
      await AppStorage.instance.saveThemeMode('light');

      // Mirrors bootstrap(): read storage BEFORE the container (and its
      // first read of themeModeProvider) exists.
      final seed = ThemeModeNotifier.parse(
        await AppStorage.instance.getThemeMode(),
      );
      final container = makeContainer(seed: seed);

      // No `await Future<void>.delayed(...)` bridge here, unlike the old
      // restore-based test — the very first synchronous read already
      // reflects the persisted value.
      expect(container.read(themeModeProvider), ThemeMode.light);
    },
  );

  test(
    'the notifier starts at the persisted value rather than system',
    () async {
      await AppStorage.instance.saveThemeMode('dark');
      final seed = ThemeModeNotifier.parse(
        await AppStorage.instance.getThemeMode(),
      );

      final container = makeContainer(seed: seed);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(container.read(themeModeProvider), isNot(ThemeMode.system));
    },
  );

  test('set() right after seeding is never overwritten — there is no in-flight '
      'restore future left to race with it', () async {
    await AppStorage.instance.saveThemeMode('dark');
    final seed = ThemeModeNotifier.parse(
      await AppStorage.instance.getThemeMode(),
    );
    final container = makeContainer(seed: seed);

    // A manual choice made immediately after construction.
    await container.read(themeModeProvider.notifier).set(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);

    // Flush any pending microtasks/timers. Structurally, build() no
    // longer starts any async work, so there is nothing left that could
    // later flip `state` back to the stale persisted 'dark' — this would
    // have failed under the old fire-and-forget `_restore()`.
    await Future<void>.delayed(Duration.zero);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets(
    'cold start under simulated storage latency never renders system before '
    'the persisted dark mode',
    (tester) async {
      // `DelayedStorageAdapter` awaits a real `Future.delayed`. Inside
      // `testWidgets` that would never complete: the body runs in a
      // fake-async zone where timers only fire when the test pumps, so
      // awaiting one before the first pump deadlocks the test.
      // `runAsync` runs this against the real clock instead — which also
      // mirrors bootstrap(), where the storage read happens before
      // `runApp` and therefore before any frame exists.
      final seed = await tester.runAsync(() async {
        await AppStorage.resetForTesting();
        await AppStorage.initializeWithAdapter(DelayedStorageAdapter());
        await AppStorage.instance.saveThemeMode('dark');
        return ThemeModeNotifier.parse(
          await AppStorage.instance.getThemeMode(),
        );
      });
      addTearDown(AppStorage.resetForTesting);

      // `runAsync` returns null if it was called in an invalid state. Without
      // this, a null seed would skip the override in `makeContainer` and the
      // test would pass for the wrong reason.
      expect(seed, ThemeMode.dark, reason: 'setup must observe persisted dark');

      final container = makeContainer(seed: seed);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            themeMode: container.read(themeModeProvider),
            home: const SizedBox.shrink(),
          ),
        ),
      );

      final observed = <ThemeMode>[];
      for (var frame = 0; frame < 5; frame++) {
        observed.add(container.read(themeModeProvider));
        await tester.pump(const Duration(milliseconds: 16));
      }

      debugPrint('theme mode observed across frames 0-4: $observed');
      expect(observed, everyElement(ThemeMode.dark));
      expect(observed, isNot(contains(ThemeMode.system)));
    },
  );
}
