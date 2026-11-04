import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/flag_avatar.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/trip.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/trips_provider.dart';
import 'expense_sheet.dart';
import 'trip_csv.dart';

/// Icons used next to expense categories on every travel screen.
const Map<ExpenseCategory, IconData> kExpenseIcons =
    <ExpenseCategory, IconData>{
  ExpenseCategory.food: Icons.restaurant,
  ExpenseCategory.transport: Icons.directions_bus,
  ExpenseCategory.hotel: Icons.hotel,
  ExpenseCategory.shopping: Icons.shopping_bag_outlined,
  ExpenseCategory.sightseeing: Icons.camera_alt_outlined,
  ExpenseCategory.other: Icons.more_horiz,
};

/// Stable slice colours for the category pie chart.
const Map<ExpenseCategory, Color> kExpenseColors = <ExpenseCategory, Color>{
  ExpenseCategory.food: Color(0xFF2BBBAD),
  ExpenseCategory.transport: Color(0xFF5B7CFA),
  ExpenseCategory.hotel: Color(0xFF7C6CFF),
  ExpenseCategory.shopping: Color(0xFFE8A838),
  ExpenseCategory.sightseeing: Color(0xFF4CAF82),
  ExpenseCategory.other: Color(0xFF8A94A6),
};

/// Budget, spent and remaining amounts for a trip, in destination currency.
class TripTotals {
  const TripTotals({
    required this.budgetLocal,
    required this.budgetCode,
    required this.spentLocal,
    required this.remaining,
    this.budgetHome,
    this.spentHome,
    this.remainingHome,
  });

  final double budgetLocal;
  final String budgetCode;
  final double spentLocal;
  final double remaining;
  final double? budgetHome;
  final double? spentHome;
  final double? remainingHome;

  double get ratio {
    if (budgetLocal <= 0) return 0;
    return (spentLocal / budgetLocal).clamp(0.0, 1.0);
  }

  factory TripTotals.of(Trip trip, RatesProvider rates) {
    final double? legacyLocal = trip.budgetInLocal
        ? null
        : rates.convert(trip.budget, trip.homeCurrency, trip.localCurrency);
    final bool inDestination = trip.budgetInLocal || legacyLocal != null;
    final double budgetLocal =
        trip.budgetInLocal ? trip.budget : (legacyLocal ?? trip.budget);
    final String budgetCode =
        inDestination ? trip.localCurrency : trip.homeCurrency;
    final double? spentHome = rates.convert(
      trip.spentLocal,
      trip.localCurrency,
      trip.homeCurrency,
    );
    final double remaining = inDestination
        ? budgetLocal - trip.spentLocal
        : trip.budget - (spentHome ?? 0);
    final double? budgetHome = budgetCode == trip.homeCurrency
        ? budgetLocal
        : rates.convert(budgetLocal, budgetCode, trip.homeCurrency);
    final double? remainingHome = budgetCode == trip.homeCurrency
        ? remaining
        : rates.convert(remaining, budgetCode, trip.homeCurrency);
    return TripTotals(
      budgetLocal: budgetLocal,
      budgetCode: budgetCode,
      spentLocal: trip.spentLocal,
      remaining: remaining,
      budgetHome: budgetHome,
      spentHome: spentHome,
      remainingHome: remainingHome,
    );
  }
}

String categoryLabel(L10n l10n, ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.food:
      return l10n.catFood;
    case ExpenseCategory.transport:
      return l10n.catTransport;
    case ExpenseCategory.hotel:
      return l10n.catHotel;
    case ExpenseCategory.shopping:
      return l10n.catShopping;
    case ExpenseCategory.sightseeing:
      return l10n.catSightseeing;
    case ExpenseCategory.other:
      return l10n.catOther;
  }
}

String expenseTitle(L10n l10n, ExpenseDraft draft) {
  final String text = draft.title.trim();
  if (text.isEmpty) return categoryLabel(l10n, draft.category);
  return text;
}

String? homeNote(
  L10n l10n,
  SettingsProvider settings,
  double? amount,
  String code,
) {
  if (amount == null) return null;
  return l10n.homeEquivalent(settings.format(amount), code);
}

String? homeAmount(
  L10n l10n,
  SettingsProvider settings,
  RatesProvider rates,
  double amount,
  String from,
  String home,
) {
  if (from == home) return null;
  final double? converted = rates.convert(amount, from, home);
  if (converted == null) return null;
  return l10n.approxAmount(settings.format(converted), home);
}

Future<ExpenseDraft?> showExpenseSheet(
  BuildContext context, {
  required String currency,
  Expense? existing,
}) {
  return showModalBottomSheet<ExpenseDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ExpenseSheet(currency: currency, existing: existing),
  );
}

Future<void> addTripExpense(BuildContext context, Trip trip) async {
  final L10n l10n = L10n.read(context);
  final ExpenseDraft? draft = await showExpenseSheet(
    context,
    currency: trip.localCurrency,
  );
  if (draft == null || !context.mounted) return;
  await context.read<TripsProvider>().addExpense(
        trip.id,
        Expense(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: expenseTitle(l10n, draft),
          note: draft.note.trim(),
          amount: draft.amount,
          category: draft.category,
          date: draft.date,
        ),
      );
}

Future<void> editTripExpense(
  BuildContext context,
  Trip trip,
  Expense expense,
) async {
  final L10n l10n = L10n.read(context);
  final ExpenseDraft? draft = await showExpenseSheet(
    context,
    currency: trip.localCurrency,
    existing: expense,
  );
  if (draft == null || !context.mounted) return;
  await context.read<TripsProvider>().updateExpense(
        trip.id,
        Expense(
          id: expense.id,
          title: expenseTitle(l10n, draft),
          note: draft.note.trim(),
          amount: draft.amount,
          category: draft.category,
          date: draft.date,
        ),
      );
}

Future<void> shareTripCsv(BuildContext context, Trip trip) async {
  final L10n l10n = L10n.read(context);
  final RatesProvider rates = context.read<RatesProvider>();
  final TripTotals totals = TripTotals.of(trip, rates);
  final String csv = buildTripCsv(
    trip: trip,
    l10n: l10n,
    categoryLabel: (ExpenseCategory item) => categoryLabel(l10n, item),
    budgetAmount: totals.budgetLocal,
    budgetCurrency: totals.budgetCode,
    remainingAmount: totals.remaining,
    budgetHome: totals.budgetHome,
    spentHome: totals.spentHome,
    remainingHome: totals.remainingHome,
    toHome: (double amount) => rates.convert(
      amount,
      trip.localCurrency,
      trip.homeCurrency,
    ),
  );

  try {
    final Directory dir =
        await Directory.systemTemp.createTemp('currency_pro_csv');
    final String fileName = tripCsvFileName(trip.name);
    final File file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString('\uFEFF$csv', flush: true);
    if (!context.mounted) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Rect? origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.shareXFiles(
      <XFile>[XFile(file.path, mimeType: 'text/csv', name: fileName)],
      subject: trip.name,
      sharePositionOrigin: origin,
      fileNameOverrides: <String>[fileName],
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.exportFailed)),
    );
  }
}

/// Full-width country-currency row used on the new-trip sheet.
class TripCurrencyPicker extends StatelessWidget {
  const TripCurrencyPicker({
    super.key,
    required this.label,
    required this.code,
    required this.onTap,
  });

  final String label;
  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Material(
      color: p.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary,
                  ),
                ),
              ),
              FlagAvatar(CurrencyLookup.of(code), size: 22),
              const SizedBox(width: 6),
              Text(
                code,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              Icon(Icons.expand_more, size: 18, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Destination amount with a smaller home-currency conversion underneath.
class TripAmountBlock extends StatelessWidget {
  const TripAmountBlock({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.note,
  });

  final String label;
  final String value;
  final Color color;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              note!,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: p.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TripExportButton extends StatelessWidget {
  const TripExportButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('export-csv'),
      onPressed: onPressed,
      icon: const Icon(Icons.ios_share, size: 18),
      label: Text(L10n.of(context).exportCsv),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
      ),
    );
  }
}
