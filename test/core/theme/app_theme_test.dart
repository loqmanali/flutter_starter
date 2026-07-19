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
  });
}
