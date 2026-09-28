import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/section_card.dart';

/// Exact age in years / months / days, plus totals and the next birthday.
class AgeCalculatorPage extends StatefulWidget {
  const AgeCalculatorPage({super.key});

  @override
  State<AgeCalculatorPage> createState() => _AgeCalculatorPageState();
}

class _AgeCalculatorPageState extends State<AgeCalculatorPage> {
  DateTime _birth = DateTime(1995, 6, 15);
  DateTime _on = DateTime.now();

  Future<void> _pick({required bool birth}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birth ? _birth : _on,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked == null) return;
    setState(() {
      if (birth) {
        _birth = picked;
      } else {
        _on = picked;
      }
    });
  }

  /// Calendar-correct years / months / days between the two dates.
  ({int years, int months, int days}) get _exact {
    DateTime from = _birth;
    final DateTime to = _on;
    if (from.isAfter(to)) return (years: 0, months: 0, days: 0);

    int years = to.year - from.year;
    int months = to.month - from.month;
    int days = to.day - from.day;

    if (days < 0) {
      months -= 1;
      final DateTime previousMonth = DateTime(to.year, to.month, 0);
      days += previousMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    return (years: years, months: months, days: days);
  }

  DateTime get _nextBirthday {
    DateTime next = DateTime(_on.year, _birth.month, _birth.day);
    if (!next.isAfter(_on)) {
      next = DateTime(_on.year + 1, _birth.month, _birth.day);
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final ({int years, int months, int days}) age = _exact;
    final Duration span = _on.difference(_birth);
    final int totalDays = span.inDays;
    final DateTime next = _nextBirthday;
    final int daysToBirthday = next.difference(_on).inDays;

    return Scaffold(
      appBar: AppBar(title: const Text('AGE CALCULATOR')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              children: <Widget>[
                _dateRow(p, 'Date of birth', _birth,
                    () => _pick(birth: true), Icons.cake_outlined),
                const SizedBox(height: 12),
                _dateRow(p, 'Age at date', _on, () => _pick(birth: false),
                    Icons.event_outlined),
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
                  'Your age is',
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _big(p, '${age.years}', 'years'),
                    _big(p, '${age.months}', 'months'),
                    _big(p, '${age.days}', 'days'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionLabel('Totals'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _row(p, 'Total months',
                    Fmt.amount((totalDays / 30.4375), decimals: 0),
                    first: true),
                _row(p, 'Total weeks',
                    Fmt.amount(totalDays / 7, decimals: 0)),
                _row(p, 'Total days', Fmt.amount(totalDays.toDouble(),
                    decimals: 0)),
                _row(p, 'Total hours',
                    Fmt.amount(span.inHours.toDouble(), decimals: 0)),
                _row(p, 'Total minutes',
                    Fmt.amount(span.inMinutes.toDouble(), decimals: 0)),
                _row(p, 'Total seconds',
                    Fmt.amount(span.inSeconds.toDouble(), decimals: 0)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.celebration_outlined, size: 22, color: p.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Next birthday',
                        style: TextStyle(
                            fontSize: 11.5, color: p.textSecondary),
                      ),
                      Text(
                        '${Fmt.weekday(next)}, ${Fmt.date(next)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  daysToBirthday == 0
                      ? 'Today!'
                      : '$daysToBirthday days',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.pets, size: 20, color: p.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Born on a ${Fmt.weekday(_birth)} · '
                    'you have lived through roughly '
                    '${(totalDays / 365.2425).floor()} full years.',
                    style:
                        TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateRow(AppPalette p, String label, DateTime value,
      VoidCallback onTap, IconData icon) {
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
                border: Border.all(color: p.outline),
              ),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 17, color: p.primary),
                  const SizedBox(width: 8),
                  Text(
                    Fmt.date(value),
                    style: TextStyle(
                      fontSize: 13.5,
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

  Widget _big(AppPalette p, String value, String label) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: p.primary,
          ),
        ),
        Text(label,
            style: TextStyle(fontSize: 11, color: p.textSecondary)),
      ],
    );
  }

  Widget _row(AppPalette p, String label, String value,
      {bool first = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: p.outline.withOpacity(0.5))),
      ),
      child: Row(
        children: <Widget>[
          Text(label,
              style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
