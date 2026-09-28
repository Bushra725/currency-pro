import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/section_card.dart';

/// Days between two dates, and date ± a number of days.
class DateDifferencePage extends StatefulWidget {
  const DateDifferencePage({super.key});

  @override
  State<DateDifferencePage> createState() => _DateDifferencePageState();
}

class _DateDifferencePageState extends State<DateDifferencePage> {
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  bool _includeEndDay = false;

  DateTime _addBase = DateTime.now();
  int _addDays = 90;

  Future<void> _pick(void Function(DateTime) apply, DateTime initial) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null) setState(() => apply(picked));
  }

  int get _days {
    final int raw = DateTime(_end.year, _end.month, _end.day)
        .difference(DateTime(_start.year, _start.month, _start.day))
        .inDays;
    return _includeEndDay ? raw + 1 : raw;
  }

  int get _weekdays {
    int count = 0;
    DateTime cursor = DateTime(_start.year, _start.month, _start.day);
    final DateTime stop = DateTime(_end.year, _end.month, _end.day);
    while (cursor.isBefore(stop) || (_includeEndDay && !cursor.isAfter(stop))) {
      if (cursor.weekday <= DateTime.friday) count++;
      cursor = cursor.add(const Duration(days: 1));
      if (count > 100000) break;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final int days = _days;
    final DateTime result = _addBase.add(Duration(days: _addDays));

    return Scaffold(
      appBar: AppBar(title: const Text('DATE DIFFERENCE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionLabel('Days between two dates', padding: EdgeInsets.zero),
          SectionCard(
            child: Column(
              children: <Widget>[
                _dateRow(p, 'From', _start,
                    () => _pick((DateTime d) => _start = d, _start)),
                const SizedBox(height: 12),
                _dateRow(p, 'To', _end,
                    () => _pick((DateTime d) => _end = d, _end)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _includeEndDay,
                  onChanged: (bool v) => setState(() => _includeEndDay = v),
                  title: Text(
                    'Include the end day',
                    style: TextStyle(fontSize: 13, color: p.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            color: p.primary.withOpacity(0.12),
            borderColor: p.primary.withOpacity(0.5),
            child: Column(
              children: <Widget>[
                Text(
                  '${days.abs()}',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                ),
                Text(
                  days.abs() == 1 ? 'day' : 'days',
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
                Divider(height: 22, color: p.outline),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _mini(p, Fmt.amount(days / 7, decimals: 1), 'weeks'),
                    _mini(p, Fmt.amount(days / 30.4375, decimals: 1),
                        'months'),
                    _mini(p, Fmt.amount(days / 365.2425, decimals: 2),
                        'years'),
                    _mini(p, '$_weekdays', 'weekdays'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionLabel('Add or subtract days', padding: EdgeInsets.zero),
          SectionCard(
            child: Column(
              children: <Widget>[
                _dateRow(p, 'Start date', _addBase,
                    () => _pick((DateTime d) => _addBase = d, _addBase)),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    const FieldLabel('Days', width: 120),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      onPressed: () => setState(() => _addDays--),
                    ),
                    Expanded(
                      child: Text(
                        '${_addDays >= 0 ? '+' : ''}$_addDays',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: p.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      onPressed: () => setState(() => _addDays++),
                    ),
                  ],
                ),
                Slider(
                  value: _addDays.toDouble().clamp(-365.0, 365.0),
                  min: -365,
                  max: 365,
                  divisions: 146,
                  onChanged: (double v) =>
                      setState(() => _addDays = v.round()),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '${Fmt.weekday(result)}, ${Fmt.date(result)}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateRow(
      AppPalette p, String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: <Widget>[
          FieldLabel(label, width: 120),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '${Fmt.weekday(value)}, ${Fmt.date(value)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_calendar_outlined,
                      size: 16, color: p.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mini(AppPalette p, String value, String label) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        Text(label,
            style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
      ],
    );
  }
}
