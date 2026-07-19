import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';

/// Owns [ThemeMode]. Starts synchronously at whatever [_initial] is
/// constructed with — [ThemeMode.system] by default, or the persisted value
/// when `bootstrap()` overrides this provider with a seeded instance.
///
/// There is deliberately no async "restore" here: `build()` used to return
/// `ThemeMode.system` and fire off a background read of storage that
/// reconciled state after the first frame. That flashed the wrong mode on
/// every cold launch (system resolves against platform brightness, so a
/// user who chose dark saw a real light frame) and raced with [set] — a
/// manual choice made while the restore was still in flight could be
/// silently overwritten by the stale persisted value once it landed.
/// Seeding the initial state before `runApp` (see `bootstrap()`) removes
/// both bugs at once: there is no in-flight future for [set] to race with.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeModeNotifier([this._initial = ThemeMode.system]);

  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;

  Future<void> set(ThemeMode mode) async {
    await ref.read(appStorageProvider).saveThemeMode(mode.name);
    state = mode;
  }

  /// Parses a persisted [AppStorage.getThemeMode] value, defaulting to
  /// [ThemeMode.system] for `null`/unrecognized values.
  static ThemeMode parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
