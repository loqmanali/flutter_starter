import 'package:flutter/material.dart';

/// Colour values owned by this app.
///
/// [seed] is the brand colour this app is identified by — it drives the
/// Material [ColorScheme] via [ColorScheme.fromSeed]. Change it to rebrand.
///
/// [success], [warning], [danger], and [info] are semantic/status colours,
/// not brand identity. They are intentionally unreferenced in this starter
/// kit: this file is the palette a cloned project reaches for once it
/// starts wiring up status UI (success banners, warning chips, error
/// states, info callouts), so do not prune them as dead code.
///
/// Spacing, radius, font sizes, and breakpoints are NOT redefined here —
/// they come from `WidgetKitTokens` and `WidgetKitBreakpoints` so that app
/// code and kit widgets agree on one scale.
abstract final class AppTokens {
  static const Color seed = Color(0xFF2563EB);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);
}
