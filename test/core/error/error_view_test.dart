import 'package:api_kit/api_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_starter/core/error/error_view.dart';
import 'package:flutter_starter/core/localization/l10n/app_localizations.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpError(WidgetTester tester, Object error) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
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
            return ErrorView(error: error);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ErrorView.messageFor', () {
    test('returns a Failure\'s message directly', () {
      expect(
        ErrorView.messageFor(const ServerFailure(message: 'Server exploded')),
        'Server exploded',
      );
    });
  });

  group('ErrorView', () {
    testWidgets('renders a Failure\'s message', (tester) async {
      await pumpError(tester, const ServerFailure(message: 'Server exploded'));

      expect(find.text('Server exploded'), findsOneWidget);
    });

    testWidgets('renders the generic message for a non-Failure error', (
      tester,
    ) async {
      await pumpError(tester, Exception('boom'));

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
