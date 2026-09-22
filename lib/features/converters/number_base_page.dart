import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
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
    final int? value = _value;
    _error = (_input.text.trim().isNotEmpty && value == null)
        ? 'Not a valid base-$_inputBase number'
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('NUMBER BASE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const FieldLabel('Input base', width: 104),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _inputBase,
                      underline: const SizedBox.shrink(),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem<int>(value: 2, child: Text('Binary (2)')),
                        DropdownMenuItem<int>(value: 8, child: Text('Octal (8)')),
                        DropdownMenuItem<int>(
                            value: 10, child: Text('Decimal (10)')),
                        DropdownMenuItem<int>(
                            value: 16, child: Text('Hexadecimal (16)')),
                      ],
                      onChanged: (int? v) =>
                          setState(() => _inputBase = v ?? 10),
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
                    labelText: 'Value',
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
                _row(p, 'Binary', value?.toRadixString(2), first: true),
                _row(p, 'Octal', value?.toRadixString(8)),
                _row(p, 'Decimal', value?.toString()),
                _row(p, 'Hexadecimal', value?.toRadixString(16).toUpperCase()),
                _row(p, 'Base $_customBase',
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
                    const FieldLabel('Custom base', width: 104),
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
            SectionLabel('Bit view'),
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
                    '${value.toRadixString(2).length} significant bits · '
                    'fits in ${_bytes(value)} byte(s)',
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
