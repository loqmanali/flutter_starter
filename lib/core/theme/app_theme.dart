import 'package:flutter/material.dart';
import 'package:flutter_starter/core/theme/app_tokens.dart';
import 'package:widget_kit/widget_kit.dart';

/// Light and dark [ThemeData], both registering [WidgetKitTheme] so that kit
/// widgets resolve their styling from the app rather than their fallback.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: const <ThemeExtension<dynamic>>[WidgetKitTheme.fallback],
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WidgetKitTokens.radiusMd),
        ),
        constraints: const BoxConstraints(
          minHeight: WidgetKitTokens.inputHeight,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(WidgetKitTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WidgetKitTokens.radiusMd),
          ),
        ),
      ),
    );
  }
}
