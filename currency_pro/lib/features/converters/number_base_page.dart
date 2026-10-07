import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/section_card.dart';

/// Decimal ↔ binary ↔ octal ↔ hexadecimal, plus an arbitrary base 2–36.
class NumberBasePage extends StatefulWidget {
  const NumberBasePage({super.key});

  @override
  State<NumberBasePage> createState() => _NumberBasePageState();
}

class _NumberBasePageState extends State<NumberBasePage> {
  final TextEditingController _input = TextEditingController(text: '255');
  int _inputBase = 10;
  int _customBase = 36;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  int? get _value {
    final String text = _input.text.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;
    return int.tryParse(text, radix: _inputBase);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final int? value = _value;
    _error = (_input.text.trim().isNotEmpty && value == null)
        ? l10n.invalidBaseNumber('$_inputBase')
        : null;

    return Scaffold(
      appBar: AppBar(title: ScreenTitle(l10n.numberBase)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    FieldLabel(l10n.inputBase, width: 104),
                    const Spacer(),
                    AppDropdown<int>(
                      value: _inputBase,
                      entries: <AppDropdownEntry<int>>[
                        AppDropdownEntry<int>(value: 2, label: l10n.binaryBase),
                        AppDropdownEntry<int>(value: 8, label: l10n.octalBase),
                        AppDropdownEntry<int>(value: 10, label: l10n.decimalBase),
                        AppDropdownEntry<int>(value: 16, label: l10n.hexBase),
                      ],
                      onChanged: (int v) => setState(() => _inputBase = v),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _input,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.valueLabel,
                    errorText: _error,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            color: p.primary.withOpacity(0.12),
            borderColor: p.primary.withOpacity(0.5),
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _row(p, l10n.binary, value?.toRadixString(2), first: true),
                _row(p, l10n.octal, value?.toRadixString(8)),
                _row(p, l10n.decimalWord, value?.toString()),
                _row(p, l10n.hexadecimal, value?.toRadixString(16).toUpperCase()),
                _row(p, l10n.baseN('$_customBase'),
                    value?.toRadixString(_customBase).toUpperCase()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    FieldLabel(l10n.customBase, width: 104),
                    const Spacer(),
                    Text(
                      '$_customBase',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _customBase.toDouble(),
                  min: 2,
                  max: 36,
                  divisions: 34,
                  onChanged: (double v) =>
                      setState(() => _customBase = v.round()),
                ),
              ],
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(height: 12),
            SectionLabel(l10n.bitView),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value.toRadixString(2).padLeft(
                          ((value.toRadixString(2).length + 7) ~/ 8) * 8,
                          '0',
                        ),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      letterSpacing: 2,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.bitSummary(
                      '${value.toRadixString(2).length}',
                      '${_bytes(value)}',
                    ),
                    style:
                        TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static int _bytes(int value) => ((value.toRadixString(2).length + 7) ~/ 8);

  Widget _row(AppPalette p, String label, String? value,
      {bool first = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: p.outline.withOpacity(0.5))),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
