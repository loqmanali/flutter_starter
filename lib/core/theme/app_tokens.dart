import 'package:flutter/material.dart';

/// Brand colour values owned by this app.
///
/// Spacing, radius, font sizes, and breakpoints are NOT redefined here —
/// they come from `WidgetKitTokens` and `WidgetKitBreakpoints` so that app
/// code and kit widgets agree on one scale. Change the seed to rebrand.
abstract final class AppTokens {
  static const Color seed = Color(0xFF2563EB);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);
}
