import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_starter/core/localization/localization.dart';
import 'package:flutter_starter/core/navigation/auth_session.dart';
import 'package:flutter_starter/features/settings/presentation/theme_mode_provider.dart';
import 'package:localization_kit/localization_kit.dart';
import 'package:widget_kit/widget_kit.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static String _labelFor(ThemeMode mode) => switch (mode) {
    ThemeMode.system => L10n.themeModeSystem,
    ThemeMode.light => L10n.themeModeLight,
    ThemeMode.dark => L10n.themeModeDark,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isArabic = ref.watch(isArabicProvider);

    return Scaffold(
      appBar: AppBar(title: Text(L10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(WidgetKitTokens.spaceMd),
        children: [
          ListTile(
            title: Text(L10n.language),
            trailing: Switch(
              value: isArabic,
              onChanged: (wantArabic) {
                final isoCode = wantArabic ? 'ar' : 'en';
                ref
                    .read(languageProvider.notifier)
                    .changeLocale(isoCode: isoCode, apiCode: isoCode);
              },
            ),
          ),
          const Divider(),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (selected) {
              if (selected != null) {
                ref.read(themeModeProvider.notifier).set(selected);
              }
            },
            child: Column(
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    title: Text(_labelFor(mode)),
                    value: mode,
                  ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(L10n.signOut),
            leading: const Icon(Icons.logout),
            onTap: () => ref.read(authSessionProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
