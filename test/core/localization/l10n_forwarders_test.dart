import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_starter/core/localization/l10n/app_localizations.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('L10n exposes exactly one accessor per ARB message key', () {
    final arb =
        jsonDecode(
              File('lib/core/localization/l10n/app_en.arb').readAsStringSync(),
            )
            as Map<String, dynamic>;
    // `@@locale` and every `@key` metadata entry start with `@`; only the
    // rest are real message keys that should have a forwarder.
    final messageKeyCount = arb.keys
        .where((key) => !key.startsWith('@'))
        .length;

    final generated = File(
      'lib/core/localization/l10n/l10n_forwarders.g.dart',
    ).readAsStringSync();
    final accessorCount = RegExp(r'=> _tr\.').allMatches(generated).length;

    expect(
      accessorCount,
      messageKeyCount,
      reason:
          'l10n_forwarders.g.dart is out of sync with app_en.arb '
          '($accessorCount accessors, $messageKeyCount ARB keys). '
          'Run `dart run tool/update_l10n.dart` to regenerate.',
    );
  });

  testWidgets('L10n resolves after init and reflects the active locale', (
    tester,
  ) async {
    Future<void> pumpIn(Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              L10n.init(context);
              return Text(context.l10n.signIn);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpIn(const Locale('en'));
    expect(L10n.signIn, 'Sign in');
    expect(L10n.isEnglish, isTrue);

    await pumpIn(const Locale('ar'));
    expect(L10n.signIn, 'تسجيل الدخول');
    expect(L10n.isArabic, isTrue);
  });
}
