import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_starter/core/localization/l10n/app_localizations.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
