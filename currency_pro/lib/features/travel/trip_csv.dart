import '../../core/l10n/l10n.dart';
import '../../data/models/trip.dart';

/// A spreadsheet export of one trip: budget summary, every expense, and
/// category totals. Amounts use a dot decimal and no thousands separator.
String buildTripCsv({
  required Trip trip,
  required L10n l10n,
  required String Function(ExpenseCategory category) categoryLabel,
  required double budgetAmount,
  required String budgetCurrency,
  required double remainingAmount,
  double? budgetHome,
  double? spentHome,
  double? remainingHome,
  double? Function(double amount)? toHome,
}) {
  final String homeAmount =
      '${l10n.amountLabel} (${l10n.homeCurrency})';
  final List<Expense> expenses = List<Expense>.of(trip.expenses)
    ..sort((Expense a, Expense b) {
      final int byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.title.compareTo(b.title);
    });

  final List<String> rows = <String>[
    _row(<String>[
      l10n.tripName,
      l10n.homeCurrency,
      l10n.localCurrency,
      l10n.budgetLabel,
      l10n.currency,
      l10n.startDate,
      l10n.endDate,
      l10n.daysLabel,
      l10n.statusLabel,
      l10n.spent,
      l10n.amountLeft,
      '${l10n.budgetLabel} (${l10n.homeCurrency})',
      '${l10n.spent} (${l10n.homeCurrency})',
      '${l10n.amountLeft} (${l10n.homeCurrency})',
    ]),
    _row(<String>[
      trip.name,
      trip.homeCurrency,
      trip.localCurrency,
      _num(budgetAmount),
      budgetCurrency,
      _day(trip.startDate),
      _day(trip.endDate),
      '${trip.days}',
      trip.completed ? l10n.tripCompleted : l10n.ongoing,
      _num(trip.spentLocal),
      _num(remainingAmount),
      _opt(budgetHome),
      _opt(spentHome),
      _opt(remainingHome),
    ]),
    '',
    _row(<String>[
      l10n.dateLabel,
      l10n.expenseTitle,
      l10n.expenseNote,
      l10n.category,
      l10n.amountLabel,
      l10n.currency,
      homeAmount,
    ]),
    for (final Expense expense in expenses)
      _row(<String>[
        _dateTime(expense.date),
        expense.title,
        expense.note,
        categoryLabel(expense.category),
        _num(expense.amount),
        trip.localCurrency,
        _opt(toHome?.call(expense.amount)),
      ]),
    '',
    _row(<String>[
      l10n.category,
      l10n.amountLabel,
      l10n.currency,
      homeAmount,
    ]),
    for (final ExpenseCategory category in ExpenseCategory.values)
      if (trip.byCategory[category] != null)
        _row(<String>[
          categoryLabel(category),
          _num(trip.byCategory[category]!),
          trip.localCurrency,
          _opt(toHome?.call(trip.byCategory[category]!)),
        ]),
  ];
  return rows.join('\r\n');
}

/// A file name that keeps the trip title and stays safe on device storage.
String tripCsvFileName(String name) {
  final String cleaned = name
      .replaceAll(RegExp(r'[\\/:*?"<>|\r\n]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final String base = cleaned.isEmpty ? 'trip' : cleaned;
  final String clipped = base.length > 80 ? base.substring(0, 80).trim() : base;
  return '$clipped.csv';
}

String _row(List<String> fields) => fields.map(_field).join(',');

String _field(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _num(double value) {
  if (value.isNaN || value.isInfinite) return '';
  return value.toStringAsFixed(2);
}

String _opt(double? value) => value == null ? '' : _num(value);

String _day(DateTime value) {
  final DateTime local = value.toLocal();
  return '${_two(local.year, 4)}-${_two(local.month, 2)}-${_two(local.day, 2)}';
}

String _dateTime(DateTime value) {
  final DateTime local = value.toLocal();
  return '${_day(local)} ${_two(local.hour, 2)}:${_two(local.minute, 2)}';
}

String _two(int value, int width) => value.toString().padLeft(width, '0');
