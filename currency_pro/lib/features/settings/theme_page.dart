import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/theme_catalog.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/section_card.dart';
import '../../state/settings_provider.dart';

/// Theme picker with a live preview of the calculator face.
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  late String _selected = context.read<SettingsProvider>().themeId;

  @override
  Widget build(BuildContext context) {
    final AppPalette current = context.palette;
    final L10n l10n = L10n.of(context);
    final AppPalette preview = ThemeCatalog.byId(_selected);

    return Scaffold(
      appBar: AppBar(title: ScreenTitle(l10n.selectTheme.toUpperCase())),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: _preview(preview),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              itemCount: ThemeCatalog.all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final AppPalette theme = ThemeCatalog.all[index];
                final bool selected = theme.id == _selected;

                return SectionCard(
                  onTap: () => setState(() => _selected = theme.id),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  borderColor:
                      selected ? current.primary : current.outline,
                  child: Row(
                    children: <Widget>[
                      Radio<String>(
                        value: theme.id,
                        groupValue: _selected,
                        onChanged: (String? v) =>
                            setState(() => _selected = v ?? _selected),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${theme.city} — ${theme.name}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: current.textPrimary,
                              ),
                            ),
                            Text(
                              theme.isDark ? l10n.dark : l10n.light,
                              style: TextStyle(
                                fontSize: 11,
                                color: current.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _swatch(theme.primary),
                      _swatch(theme.accent),
                      _swatch(theme.background),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await context
                            .read<SettingsProvider>()
                            .setTheme(_selected);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.apply),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatch(Color color) => Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.only(left: 5),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
        ),
      );

  /// Miniature of the converter screen painted in the highlighted theme.
  Widget _preview(AppPalette t) {
    Widget key(String label, {Color? face, Color? text, int flex = 1}) =>
        Expanded(
          flex: flex,
          child: Container(
            height: 22,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: face ?? t.keyFace,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: text ?? t.keyText,
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: t.primary.withOpacity(t.isDark ? 0.18 : 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  '1,234.56',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'USD → KRW',
                  style: TextStyle(fontSize: 11, color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(children: <Widget>[
            key('COPY', face: t.keyFaceAlt),
            key('SEND', face: t.keyFaceAlt),
            key('CLR', face: t.keyFaceAlt),
            key('DEL', face: t.keyFaceAlt),
          ]),
          Row(children: <Widget>[
            key('7'),
            key('8'),
            key('9'),
            key('÷', face: t.keyFaceAlt, text: t.primary),
          ]),
          Row(children: <Widget>[
            key('4'),
            key('5'),
            key('6'),
            key('×', face: t.keyFaceAlt, text: t.primary),
          ]),
          Row(children: <Widget>[
            key('0'),
            key('.'),
            key('±'),
            key('=', face: t.equalsKey, text: Colors.white),
          ]),
        ],
      ),
    );
  }
}
