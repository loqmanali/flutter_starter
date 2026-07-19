import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/di/infrastructure_providers.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // AppStorage only caches the access token synchronously (see
    // getAccessTokenSync); the theme mode has no such cache, so the stored
    // value is restored asynchronously after the default first frame.
    unawaited(_restore());
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final stored = await ref.read(appStorageProvider).getThemeMode();
    final mode = _parse(stored);
    if (mode != state) state = mode;
  }

  Future<void> set(ThemeMode mode) async {
    await ref.read(appStorageProvider).saveThemeMode(mode.name);
    state = mode;
  }

  static ThemeMode _parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
