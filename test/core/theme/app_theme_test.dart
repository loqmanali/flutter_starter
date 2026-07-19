import 'package:flutter/material.dart';
import 'package:flutter_starter/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widget_kit/widget_kit.dart';

void main() {
  group('AppTheme', () {
    test('light and dark carry the WidgetKitTheme extension', () {
      expect(AppTheme.light().extension<WidgetKitTheme>(), isNotNull);
      expect(AppTheme.dark().extension<WidgetKitTheme>(), isNotNull);
    });

    test('brightness differs between the two', () {
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
    });

    test('both use Material 3', () {
      expect(AppTheme.light().useMaterial3, isTrue);
      expect(AppTheme.dark().useMaterial3, isTrue);
    });

    test('light: Material input/button radii and button height match the '
        'registered WidgetKitTheme', () {
      _expectSizingMatchesExtension(AppTheme.light());
    });

    test('dark: Material input/button radii and button height match the '
        'registered WidgetKitTheme', () {
      _expectSizingMatchesExtension(AppTheme.dark());
    });
  });
}

/// Asserts that the radius and button height `widget_kit` widgets resolve
/// (via the registered [WidgetKitTheme]) match what's configured on the
/// stock Material [InputDecorationTheme] / [FilledButtonThemeData] in
/// [theme]. If these drift apart, a `widget_kit` input/button and a stock
/// `TextField`/`FilledButton` render different corners or heights on the
/// same screen.
void _expectSizingMatchesExtension(ThemeData theme) {
  final WidgetKitTheme? widgetKitTheme = theme.extension<WidgetKitTheme>();
  expect(widgetKitTheme, isNotNull);

  final double? inputRadius = _radiusOf(theme.inputDecorationTheme.border);
  final double? buttonRadius = _radiusOf(
    theme.filledButtonTheme.style?.shape?.resolve(<WidgetState>{}),
  );
  final double? buttonHeight = theme.filledButtonTheme.style?.minimumSize
      ?.resolve(<WidgetState>{})
      ?.height;

  expect(
    inputRadius,
    widgetKitTheme!.inputBorderRadius,
    reason:
        'InputDecorationTheme radius must match WidgetKitTheme.inputBorderRadius',
  );
  expect(
    buttonRadius,
    widgetKitTheme.buttonBorderRadius,
    reason:
        'FilledButtonThemeData radius must match WidgetKitTheme.buttonBorderRadius',
  );
  expect(
    buttonHeight,
    widgetKitTheme.buttonHeight,
    reason:
        'FilledButtonThemeData minimumSize height must match WidgetKitTheme.buttonHeight',
  );
}

/// Extracts the corner radius from a [ShapeBorder], if it carries a uniform
/// [BorderRadius].
double? _radiusOf(ShapeBorder? shape) {
  final BorderRadiusGeometry? borderRadius = switch (shape) {
    final OutlineInputBorder s => s.borderRadius,
    final RoundedRectangleBorder s => s.borderRadius,
    _ => null,
  };
  if (borderRadius is BorderRadius) {
    return borderRadius.topLeft.x;
  }
  return null;
}
