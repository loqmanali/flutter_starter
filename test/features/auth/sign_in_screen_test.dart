import 'package:api_kit/api_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/localization/l10n/app_localizations.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:flutter_starter/features/auth/data/auth_repository.dart';
import 'package:flutter_starter/features/auth/presentation/auth_providers.dart';
import 'package:flutter_starter/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAuthRepository implements AuthRepository {
  @override
  Future<AuthTokens> signIn({
    required String email,
    required String password,
  }) async => throw const AuthFailure(message: 'Bad credentials');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FailingAuthRepository()),
        ],
        child: MaterialApp(
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
              return const SignInScreen();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows validation errors when submitted empty', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('sign_in_submit')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsNWidgets(2));
  });

  testWidgets('surfaces a Failure message in a snack bar', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('sign_in_email')),
      'user@example.com',
    );
    await tester.enterText(find.byKey(const Key('sign_in_password')), 'secret');
    await tester.tap(find.byKey(const Key('sign_in_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Bad credentials'), findsOneWidget);
  });
}
