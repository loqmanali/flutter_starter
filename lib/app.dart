import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/config/env.dart';
import 'package:flutter_starter/core/localization/l10n/app_localizations.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:flutter_starter/core/navigation/app_router.dart';
import 'package:flutter_starter/core/theme/app_theme.dart';
import 'package:flutter_starter/features/settings/presentation/theme_mode_provider.dart';
import 'package:localization_kit/localization_kit.dart';

/// The app's single widget tree, built under the [UncontrolledProviderScope]
/// that `bootstrap()` already created. No `ProviderScope`/`ProviderContainer`
/// here — a second one would desync from the container `onLogout` writes to.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);

    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(goRouterProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        L10n.init(context);
        return Directionality(
          textDirection: context.textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
