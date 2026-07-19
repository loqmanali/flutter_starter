import 'package:flutter/material.dart';
import 'package:flutter_starter/core/localization/l10n/app_localizations.dart';

part 'l10n/l10n_forwarders.g.dart';

/// Ergonomic access to localized strings inside widgets.
extension LocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;
}

/// The locales this app ships. Keep in step with the `.arb` files.
const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ar')];
