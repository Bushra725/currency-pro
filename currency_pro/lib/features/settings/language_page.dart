import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/section_card.dart';
import '../../state/settings_provider.dart';

/// Language picker. Default is the device language; the user can override.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final String selected = settings.localeCode;

    return Scaffold(
      appBar: AppBar(title: ScreenTitle(l10n.selectLanguage)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        itemCount: AppLocales.options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final LocaleOption option = AppLocales.options[index];
          final bool isSelected = option.code == selected;
          return SectionCard(
            onTap: () => settings.setLocaleCode(option.code),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            borderColor: isSelected ? p.primary : p.outline,
            child: RadioListTile<String>(
              value: option.code,
              groupValue: selected,
              onChanged: (String? v) {
                if (v != null) settings.setLocaleCode(v);
              },
              title: Text(
                option.isSystem ? l10n.systemDefault : option.nativeName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              subtitle: Text(
                option.isSystem ? l10n.systemDefaultSub : option.englishName,
                style: TextStyle(fontSize: 12, color: p.textSecondary),
              ),
              activeColor: p.primary,
            ),
          );
        },
      ),
    );
  }
}
