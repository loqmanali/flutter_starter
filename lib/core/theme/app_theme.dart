import 'package:flutter/material.dart';
import 'package:flutter_starter/core/theme/app_tokens.dart';
import 'package:widget_kit/widget_kit.dart';

/// Light and dark [ThemeData], both registering [WidgetKitTheme] so that kit
/// widgets resolve their styling from the app rather than their fallback.
abstract final class AppTheme {
  /// The app's single corner-radius decision for stock Material inputs and
  /// buttons. The `WidgetKitTheme` registered below overrides its input and
  /// button radius fields from this same constant, so `widget_kit` widgets
  /// and stock `TextField`/`FilledButton` always render identical corners.
  /// Change this one line to change the app's corner radius.
  static const double _cornerRadius = WidgetKitTokens.radiusMd;

  /// The app's single button-height decision, for the same reason as
  /// [_cornerRadius]: `WidgetKitTheme.buttonHeight` and stock `FilledButton`'s
  /// `minimumSize` are bound to this one constant instead of each separately
  /// hardcoding `WidgetKitTokens.buttonHeight`, so they cannot drift apart.
  static const double _buttonHeight = WidgetKitTokens.buttonHeight;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.seed,
      brightness: brightness,
    );

    // The app's decisions layered on top of the kit's fallback — only the
    // fields this app actually opinionates on, everything else inherits.
    final widgetKitTheme = WidgetKitTheme.fallback.copyWith(
      inputBorderRadius: _cornerRadius,
      buttonBorderRadius: _cornerRadius,
      buttonHeight: _buttonHeight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[widgetKitTheme],
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cornerRadius),
        ),
        constraints: const BoxConstraints(
          minHeight: WidgetKitTokens.inputHeight,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(_buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cornerRadius),
          ),
        ),
      ),
    );
  }
}
