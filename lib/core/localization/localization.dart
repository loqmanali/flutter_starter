import 'package:flutter/material.dart';
import 'package:flutter_starter/core/localization/l10n/app_localizations.dart';

part 'l10n/l10n_forwarders.g.dart';

/// Ergonomic access to localized strings inside widgets.
///
/// `isArabic` deliberately isn't here: `localization_kit`'s
/// `LocalizationContextX` already defines it, and declaring the same member
/// on two extensions in scope is an `ambiguous_extension_member_access`
/// compile error. Use the kit's `context.isArabic` instead.
extension LocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  TextDirection get textDirection =>
      Localizations.localeOf(this).languageCode == 'ar'
      ? TextDirection.rtl
      : TextDirection.ltr;
}

/// The locales this app ships. Keep in step with the `.arb` files.
const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ar')];
