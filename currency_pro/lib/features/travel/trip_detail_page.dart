import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/trip.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/trips_provider.dart';
import 'trip_helpers.dart';

/// Dedicated screen for one trip: budget totals, expenses, categories, days.
class TripDetailPage extends StatelessWidget {
  const TripDetailPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final Trip? trip = context.watch<TripsProvider>().byId(tripId);
    if (trip == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();
    final TripsProvider trips = context.read<TripsProvider>();
    final TripTotals totals = TripTotals.of(trip, rates);

    return Scaffold(
      key: const Key('trip-detail'),
      appBar: RateAppBar(
        title: trip.name,
        showUpdated: false,
        showRefresh: false,
        actions: <Widget>[
          IconButton(
            tooltip: l10n.exportCsv,
            icon: const Icon(Icons.ios_share, size: 20),
            onPressed: () => shareTripCsv(context, trip),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: p.textSecondary),
            onSelected: (String value) {
              if (value == 'done') {
                trips.toggleCompleted(trip.id);
              } else if (value == 'delete') {
                trips.remove(trip.id);
              } else if (value == 'export') {
                shareTripCsv(context, trip);
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'export',
                child: Text(l10n.exportCsv),
              ),
              PopupMenuItem<String>(
                value: 'done',
                child: Text(
                  trip.completed ? l10n.markOngoing : l10n.markCompleted,
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(l10n.deleteTrip),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          Text(
            '${Fmt.date(trip.startDate)} → ${Fmt.date(trip.endDate)} · '
            '${l10n.daysCount(trip.days)}',
            style: TextStyle(fontSize: 12, color: p.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.homeCurrency}: ${trip.homeCurrency}',
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          Text(
            '${l10n.localCurrency}: ${trip.localCurrency}',
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          _SummaryCard(trip: trip, totals: totals),
          const SizedBox(height: 10),
          TripExportButton(onPressed: () => shareTripCsv(context, trip)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totals.ratio,
              minHeight: 8,
              backgroundColor: p.surfaceAlt,
              color: totals.ratio > 0.9 ? p.down : p.primary,
            ),
          ),
          const SizedBox(height: 18),
          _ExpensesSection(trip: trip),
          const SizedBox(height: 18),
          _CategoriesSection(trip: trip, spent: totals.spentLocal),
          const SizedBox(height: 18),
          _DailySection(trip: trip),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.trip, required this.totals});

  final Trip trip;
  final TripTotals totals;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final SettingsProvider settings = context.watch<SettingsProvider>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TripAmountBlock(
            label: l10n.totalBudget,
            value:
                '${settings.format(totals.budgetLocal)} ${totals.budgetCode}',
            color: p.textPrimary,
            note: totals.budgetCode == trip.homeCurrency
                ? null
                : homeNote(
                    l10n,
                    settings,
                    totals.budgetHome,
                    trip.homeCurrency,
                  ),
          ),
          TripAmountBlock(
            label: l10n.spent,
            value:
                '${settings.format(totals.spentLocal)} ${trip.localCurrency}',
            color: p.primary,
            note: trip.localCurrency == trip.homeCurrency
                ? null
                : homeNote(
                    l10n,
                    settings,
                    totals.spentHome,
                    trip.homeCurrency,
                  ),
          ),
          TripAmountBlock(
            label: l10n.remaining,
            value:
                '${settings.format(totals.remaining)} ${totals.budgetCode}',
            color: totals.remaining >= 0 ? p.up : p.down,
            note: totals.budgetCode == trip.homeCurrency
                ? null
                : homeNote(
                    l10n,
                    settings,
                    totals.remainingHome,
                    trip.homeCurrency,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesSection extends StatelessWidget {
  const _ExpensesSection({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final List<Expense> ordered = List<Expense>.of(trip.expenses)
      ..sort((Expense a, Expense b) => b.date.compareTo(a.date));

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.expensesSection,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const Key('add-expense'),
            onPressed: () => addTripExpense(context, trip),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addExpense),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          if (ordered.isEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              l10n.noExpensesYet,
              style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            ),
          ] else
            for (final Expense expense in ordered)
              _ExpenseTile(trip: trip, expense: expense),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.trip, required this.expense});

  final Trip trip;
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final String note = expense.note.trim();
    final String details = note.isEmpty
        ? '${categoryLabel(l10n, expense.category)} · ${Fmt.date(expense.date)}'
        : '${categoryLabel(l10n, expense.category)} · ${Fmt.date(expense.date)}\n$note';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            kExpenseIcons[expense.category] ?? Icons.more_horiz,
            size: 20,
            color: kExpenseColors[expense.category] ?? p.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  expense.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  details,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${Fmt.smart(expense.amount)} ${trip.localCurrency}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: p.primary,
            ),
          ),
          IconButton(
            key: ValueKey<String>('expense-edit-${expense.id}'),
            tooltip: l10n.editExpense,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => editTripExpense(context, trip, expense),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => context
                .read<TripsProvider>()
                .removeExpense(trip.id, expense.id),
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({required this.trip, required this.spent});

  final Trip trip;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final List<MapEntry<ExpenseCategory, double>> categories =
        trip.byCategory.entries.toList()
          ..sort((MapEntry<ExpenseCategory, double> a,
                  MapEntry<ExpenseCategory, double> b) =>
              b.value.compareTo(a.value));

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.expenseCategories,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: _CategoryPie(
              slices: categories,
              total: spent,
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Text(
              l10n.nothingLogged,
              style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            )
          else
            for (final MapEntry<ExpenseCategory, double> entry in categories)
              _CategoryRow(
                trip: trip,
                entry: entry,
                spent: spent,
                settings: settings,
                rates: rates,
              ),
        ],
      ),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.slices, required this.total});

  final List<MapEntry<ExpenseCategory, double>> slices;
  final double total;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    return SizedBox(
      key: const Key('category-pie'),
      width: 176,
      height: 176,
      child: CustomPaint(
        painter: _PiePainter(
          slices: slices,
          total: total,
          track: p.surfaceAlt,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                settings.format(total),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              Text(
                L10n.of(context).spent,
                style: TextStyle(fontSize: 10.5, color: p.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter({
    required this.slices,
    required this.total,
    required this.track,
  });

  final List<MapEntry<ExpenseCategory, double>> slices;
  final double total;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2 - 6;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;

    paint.color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);

    if (total <= 0 || slices.isEmpty) return;

    double start = -math.pi / 2;
    for (final MapEntry<ExpenseCategory, double> slice in slices) {
      final double sweep = (slice.value / total) * math.pi * 2;
      paint.color = kExpenseColors[slice.key] ?? track;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.slices != slices;
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.trip,
    required this.entry,
    required this.spent,
    required this.settings,
    required this.rates,
  });

  final Trip trip;
  final MapEntry<ExpenseCategory, double> entry;
  final double spent;
  final SettingsProvider settings;
  final RatesProvider rates;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final double share = spent <= 0 ? 0 : entry.value / spent;
    final Color color = kExpenseColors[entry.key] ?? p.primary;
    final String? home = homeAmount(
      l10n,
      settings,
      rates,
      entry.value,
      trip.localCurrency,
      trip.homeCurrency,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Icon(kExpenseIcons[entry.key] ?? Icons.more_horiz,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${categoryLabel(l10n, entry.key)} · '
                        '${(share * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${settings.format(entry.value)} ${trip.localCurrency}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: p.surfaceAlt,
                    color: color,
                  ),
                ),
                if (home != null)
                  Text(
                    home,
                    style: TextStyle(fontSize: 10, color: p.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySection extends StatelessWidget {
  const _DailySection({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final Map<DateTime, List<Expense>> byDay = trip.byDay;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.dailySpending,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (byDay.isEmpty)
            Text(
              l10n.nothingLogged,
              style: TextStyle(fontSize: 12.5, color: p.textSecondary),
            )
          else
            for (final MapEntry<DateTime, List<Expense>> entry in byDay.entries)
              _DayBlock(
                trip: trip,
                day: entry.key,
                expenses: entry.value,
                settings: settings,
                rates: rates,
              ),
        ],
      ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.trip,
    required this.day,
    required this.expenses,
    required this.settings,
    required this.rates,
  });

  final Trip trip;
  final DateTime day;
  final List<Expense> expenses;
  final SettingsProvider settings;
  final RatesProvider rates;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final double total = expenses.fold<double>(
      0,
      (double sum, Expense expense) => sum + expense.amount,
    );
    final String? home = homeAmount(
      l10n,
      settings,
      rates,
      total,
      trip.localCurrency,
      trip.homeCurrency,
    );
    final List<Expense> ordered = List<Expense>.of(expenses)
      ..sort((Expense a, Expense b) => b.date.compareTo(a.date));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  Fmt.date(day),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${settings.format(total)} ${trip.localCurrency}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: p.primary,
                    ),
                  ),
                  if (home != null)
                    Text(
                      home,
                      style: TextStyle(fontSize: 10, color: p.textSecondary),
                    ),
                ],
              ),
            ],
          ),
          for (final Expense expense in ordered)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: <Widget>[
                  Icon(
                    kExpenseIcons[expense.category] ?? Icons.more_horiz,
                    size: 14,
                    color: kExpenseColors[expense.category] ?? p.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expense.title,
                      style: TextStyle(fontSize: 12, color: p.textPrimary),
                    ),
                  ),
                  Text(
                    '${Fmt.smart(expense.amount)} ${trip.localCurrency}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
