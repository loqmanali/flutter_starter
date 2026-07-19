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

    test(
      'light: Material input/button radii match the registered WidgetKitTheme',
      () {
        _expectRadiiMatchExtension(AppTheme.light());
      },
    );

    test(
      'dark: Material input/button radii match the registered WidgetKitTheme',
      () {
        _expectRadiiMatchExtension(AppTheme.dark());
      },
    );
  });
}

/// Asserts that the radius `widget_kit` widgets resolve (via the registered
/// [WidgetKitTheme]) is the same radius configured on the stock Material
/// [InputDecorationTheme] / [FilledButtonThemeData] in [theme]. If these
/// drift apart, a `widget_kit` input/button and a stock `TextField`/
/// `FilledButton` render different corner radii on the same screen.
void _expectRadiiMatchExtension(ThemeData theme) {
  final WidgetKitTheme? widgetKitTheme = theme.extension<WidgetKitTheme>();
  expect(widgetKitTheme, isNotNull);

  final double? inputRadius = _radiusOf(theme.inputDecorationTheme.border);
  final double? buttonRadius = _radiusOf(
    theme.filledButtonTheme.style?.shape?.resolve(<WidgetState>{}),
  );

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
