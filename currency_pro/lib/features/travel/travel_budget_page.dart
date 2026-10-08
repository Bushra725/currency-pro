import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/currency.dart';
import '../../data/models/trip.dart';
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/trips_provider.dart';
import '../currency/currency_picker.dart';
import 'trip_csv.dart';

/// Plan a trip budget in the destination currency and log spending there.
class TravelBudgetPage extends StatelessWidget {
  const TravelBudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final TripsProvider trips = context.watch<TripsProvider>();

    return Scaffold(
      drawer: const AppDrawer(current: Routes.travel),
      appBar: RateAppBar(title: l10n.travelBudget),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: FilledButton.icon(
              onPressed: () => _newTrip(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addNewTrip),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _counter(p, Icons.schedule,
                      '${trips.ongoing.length}', l10n.ongoing, p.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _counter(p, Icons.check_circle_outline,
                      '${trips.completed.length}', l10n.tripCompleted, p.up),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: trips.all.isEmpty
                ? EmptyState(
                    icon: Icons.luggage_outlined,
                    title: l10n.noTripsYet,
                    message: l10n.noTripsMessage,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: trips.all.length,
                    itemBuilder: (BuildContext context, int index) =>
                        _TripCard(trip: trips.all[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _counter(AppPalette p, IconData icon, String value, String label,
      Color color) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
        ],
      ),
    );
  }

  static Future<void> _newTrip(BuildContext context) async {
    final L10n l10n = L10n.read(context);
    final SettingsProvider settings = context.read<SettingsProvider>();
    final _DraftTrip? draft = await showModalBottomSheet<_DraftTrip>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NewTripSheet(
        home: settings.fromCode,
        local: settings.toCode,
      ),
    );

    if (draft == null || !context.mounted) return;

    final String tripName = draft.name.trim().isEmpty
        ? l10n.tripTo(draft.local)
        : draft.name.trim();
    await context.read<TripsProvider>().add(
          Trip(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: tripName,
            homeCurrency: draft.home,
            localCurrency: draft.local,
            budget: draft.budget,
            budgetInLocal: true,
            startDate: draft.range.start,
            endDate: draft.range.end,
          ),
        );
  }
}

class _DraftTrip {
  const _DraftTrip({
    required this.name,
    required this.home,
    required this.local,
    required this.budget,
    required this.range,
  });

  final String name;
  final String home;
  final String local;
  final double budget;
  final DateTimeRange range;
}

class _NewTripSheet extends StatefulWidget {
  const _NewTripSheet({required this.home, required this.local});

  final String home;
  final String local;

  @override
  State<_NewTripSheet> createState() => _NewTripSheetState();
}

class _NewTripSheetState extends State<_NewTripSheet> {
  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _budget =
      TextEditingController(text: '1000');
  late String _home = widget.home;
  late String _local = widget.local;
  late DateTimeRange _range = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 6)),
  );

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  Widget _countryChoice(AppPalette p, String label, String code) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10.5, color: p.textSecondary),
        ),
        Text(
          code,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final double? entered = Fmt.parse(_budget.text);
    final double? homeAmount = entered == null || _home == _local
        ? null
        : rates.convert(entered, _local, _home);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.newTrip,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.tripName,
                  hintText: l10n.tripNameHint,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final Currency? picked = await CurrencyPicker.show(
                          context,
                          title: l10n.homeCurrency,
                        );
                        if (picked != null) {
                          setState(() => _home = picked.code);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      child: _countryChoice(p, l10n.homeCurrency, _home),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final Currency? picked = await CurrencyPicker.show(
                          context,
                          title: l10n.localCurrency,
                        );
                        if (picked != null) {
                          setState(() => _local = picked.code);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      child: _countryChoice(p, l10n.localCurrency, _local),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('trip-budget'),
                controller: _budget,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.localCurrency,
                  suffixText: _local,
                ),
              ),
              if (homeAmount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    l10n.homeEquivalent(settings.format(homeAmount), _home),
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDateRange: _range,
                  );
                  if (picked != null) setState(() => _range = picked);
                },
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  '${Fmt.date(_range.start)} → ${Fmt.date(_range.end)}',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    _DraftTrip(
                      name: _name.text,
                      home: _home,
                      local: _local,
                      budget: Fmt.parse(_budget.text) ?? 0,
                      range: _range,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(l10n.createTrip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftExpense {
  const _DraftExpense({
    required this.title,
    required this.note,
    required this.amount,
    required this.category,
    required this.date,
  });

  final String title;
  final String note;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.currency, this.existing});

  final String currency;
  final Expense? existing;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  late final TextEditingController _amount = TextEditingController(
    text: widget.existing == null ? '' : Fmt.smart(widget.existing!.amount),
  );
  late ExpenseCategory _category =
      widget.existing?.category ?? ExpenseCategory.food;
  late DateTime _date = widget.existing?.date ?? DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day, 12);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final bool editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                editing ? l10n.editExpense : l10n.addExpense,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.whatFor),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('expense-note'),
                controller: _note,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.expenseNote,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('expense-amount'),
                controller: _amount,
                autofocus: !editing,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.amountLabel,
                  suffixText: widget.currency,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('expense-date'),
                onPressed: _pickDate,
                icon: const Icon(Icons.event, size: 18),
                label: Text('${l10n.spendingDate}: ${Fmt.date(_date)}'),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: ExpenseCategory.values.map((ExpenseCategory c) {
                  final bool selected = c == _category;
                  return ChoiceChip(
                    label: Text(_categoryLabel(l10n, c)),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = c),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      color: selected ? p.onPrimary : p.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final double? value = Fmt.parse(_amount.text);
                  if (value == null) return;
                  Navigator.of(context).pop(
                    _DraftExpense(
                      title: _title.text,
                      note: _note.text,
                      amount: value,
                      category: _category,
                      date: _date,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(l10n.saveExpense),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  static const Map<ExpenseCategory, IconData> _icons =
      <ExpenseCategory, IconData>{
    ExpenseCategory.food: Icons.restaurant,
    ExpenseCategory.transport: Icons.directions_bus,
    ExpenseCategory.hotel: Icons.hotel,
    ExpenseCategory.shopping: Icons.shopping_bag_outlined,
    ExpenseCategory.sightseeing: Icons.camera_alt_outlined,
    ExpenseCategory.other: Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final TripsProvider trips = context.read<TripsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();

    final double? legacyLocal = trip.budgetInLocal
        ? null
        : rates.convert(trip.budget, trip.homeCurrency, trip.localCurrency);
    final bool inDestination = trip.budgetInLocal || legacyLocal != null;
    final double budgetLocal =
        trip.budgetInLocal ? trip.budget : (legacyLocal ?? trip.budget);
    final String budgetCode =
        inDestination ? trip.localCurrency : trip.homeCurrency;
    final double? spentHome =
        rates.convert(trip.spentLocal, trip.localCurrency, trip.homeCurrency);
    final double remaining = inDestination
        ? budgetLocal - trip.spentLocal
        : trip.budget - (spentHome ?? 0);
    final String? spentNote = _homeNote(
      l10n,
      settings,
      trip.localCurrency == trip.homeCurrency ? null : spentHome,
      trip.homeCurrency,
    );
    final double? remainingHome = budgetCode == trip.homeCurrency
        ? null
        : rates.convert(remaining, budgetCode, trip.homeCurrency);
    final String? remainingNote =
        _homeNote(l10n, settings, remainingHome, trip.homeCurrency);
    final double ratio = budgetLocal <= 0
        ? 0
        : ((inDestination ? trip.spentLocal : (spentHome ?? 0)) / budgetLocal)
            .clamp(0.0, 1.0);
    final Map<ExpenseCategory, double> byCategory = trip.byCategory;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        trip.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        '${Fmt.date(trip.startDate)} → '
                        '${Fmt.date(trip.endDate)} · ${l10n.daysCount(trip.days)}',
                        style: TextStyle(
                            fontSize: 11, color: p.textSecondary),
                      ),
                      Text(
                        '${l10n.homeCurrency} ${trip.homeCurrency} · '
                        '${l10n.localCurrency} ${trip.localCurrency}',
                        style: TextStyle(
                            fontSize: 11, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: p.textSecondary),
                  onSelected: (String value) {
                    if (value == 'done') {
                      trips.toggleCompleted(trip.id);
                    } else if (value == 'delete') {
                      trips.remove(trip.id);
                    } else if (value == 'export') {
                      _export(context);
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
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _stat(
                    p,
                    l10n.budgetLabel,
                    '${settings.format(budgetLocal)} $budgetCode',
                    p.textPrimary,
                  ),
                ),
                Expanded(
                  child: _stat(
                    p,
                    l10n.spent,
                    '${settings.format(trip.spentLocal)} ${trip.localCurrency}',
                    p.primary,
                    note: spentNote,
                  ),
                ),
                Expanded(
                  child: _stat(
                    p,
                    l10n.amountLeft,
                    '${settings.format(remaining)} $budgetCode',
                    remaining >= 0 ? p.up : p.down,
                    note: remainingNote,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: p.surfaceAlt,
                color: ratio > 0.9 ? p.down : p.primary,
              ),
            ),
            if (byCategory.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: byCategory.entries.map(
                  (MapEntry<ExpenseCategory, double> e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(_icons[e.key], size: 13, color: p.primary),
                          const SizedBox(width: 5),
                          Text(
                            '${_categoryLabel(l10n, e.key)} '
                            '${Fmt.smart(e.value)} ${trip.localCurrency}',
                            style: TextStyle(
                              fontSize: 11,
                              color: p.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addExpense(context, trip),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.expenseBtn),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showExpenses(context, trip),
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: Text(
                      l10n.spendingOverview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(
    AppPalette p,
    String label,
    String value,
    Color color, {
    String? note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (note != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, height: 1.15, color: p.textSecondary),
          ),
        ],
      ],
    );
  }

  Future<void> _export(BuildContext context) async {
    final L10n l10n = L10n.read(context);
    final RatesProvider rates = context.read<RatesProvider>();
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

    final String csv = buildTripCsv(
      trip: trip,
      l10n: l10n,
      categoryLabel: (ExpenseCategory category) =>
          _categoryLabel(l10n, category),
      budgetAmount: budgetLocal,
      budgetCurrency: budgetCode,
      remainingAmount: remaining,
      budgetHome: budgetHome,
      spentHome: spentHome,
      remainingHome: remainingHome,
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

  Future<void> _addExpense(BuildContext context, Trip trip) async {
    final L10n l10n = L10n.read(context);
    final _DraftExpense? draft = await showModalBottomSheet<_DraftExpense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExpenseSheet(currency: trip.localCurrency),
    );

    if (draft == null || !context.mounted) return;

    await context.read<TripsProvider>().addExpense(
          trip.id,
          Expense(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: _expenseTitle(l10n, draft),
            note: draft.note.trim(),
            amount: draft.amount,
            category: draft.category,
            date: draft.date,
          ),
        );
  }

  Future<void> _editExpense(
    BuildContext context,
    Trip trip,
    Expense expense,
  ) async {
    final L10n l10n = L10n.read(context);
    final _DraftExpense? draft = await showModalBottomSheet<_DraftExpense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExpenseSheet(
        currency: trip.localCurrency,
        existing: expense,
      ),
    );

    if (draft == null || !context.mounted) return;

    await context.read<TripsProvider>().updateExpense(
          trip.id,
          Expense(
            id: expense.id,
            title: _expenseTitle(l10n, draft),
            note: draft.note.trim(),
            amount: draft.amount,
            category: draft.category,
            date: draft.date,
          ),
        );
  }

  Future<void> _showExpenses(BuildContext context, Trip trip) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return Consumer<TripsProvider>(
          builder: (BuildContext context, TripsProvider provider, _) {
            final Trip? live = provider.byId(trip.id);
            final Trip shown = live ?? trip;
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.92,
              child: _SpendingOverview(
                trip: shown,
                onEdit: (Expense expense) =>
                    _editExpense(context, shown, expense),
                onDelete: (Expense expense) =>
                    provider.removeExpense(shown.id, expense.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _SpendingOverview extends StatelessWidget {
  const _SpendingOverview({
    required this.trip,
    required this.onEdit,
    required this.onDelete,
  });

  final Trip trip;
  final ValueChanged<Expense> onEdit;
  final ValueChanged<Expense> onDelete;

  static const Map<ExpenseCategory, IconData> _icons =
      _TripCard._icons;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final double spent = trip.spentLocal;
    final double perDay = trip.days <= 0 ? spent : spent / trip.days;
    final String? spentHome = _homeAmount(
      l10n,
      settings,
      rates,
      spent,
      trip.localCurrency,
      trip.homeCurrency,
    );
    final String? perDayHome = _homeAmount(
      l10n,
      settings,
      rates,
      perDay,
      trip.localCurrency,
      trip.homeCurrency,
    );
    final List<MapEntry<ExpenseCategory, double>> categories =
        trip.byCategory.entries.toList()
          ..sort((MapEntry<ExpenseCategory, double> a,
                  MapEntry<ExpenseCategory, double> b) =>
              b.value.compareTo(a.value));
    final Map<DateTime, List<Expense>> byDay = <DateTime, List<Expense>>{};
    for (final Expense expense in trip.expenses) {
      final DateTime local = expense.date.toLocal();
      final DateTime day = DateTime(local.year, local.month, local.day);
      byDay.putIfAbsent(day, () => <Expense>[]).add(expense);
    }
    final List<DateTime> days = byDay.keys.toList()
      ..sort((DateTime a, DateTime b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        Text(
          l10n.spendingOverview,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          trip.name,
          style: TextStyle(fontSize: 12, color: p.textSecondary),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _figure(
                p,
                l10n.spent,
                settings.format(spent),
                trip.localCurrency,
                p.primary,
                spentHome,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _figure(
                p,
                l10n.perDay,
                settings.format(perDay),
                trip.localCurrency,
                p.textPrimary,
                perDayHome,
              ),
            ),
          ],
        ),
        if (categories.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          Text(
            l10n.category,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final MapEntry<ExpenseCategory, double> entry in categories)
            _categoryRow(p, l10n, settings, rates, entry, spent),
        ],
        const SizedBox(height: 18),
        Text(
          l10n.dailySpending,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (days.isEmpty)
          EmptyState(
            icon: Icons.receipt_long,
            title: l10n.nothingLogged,
          )
        else
          for (final DateTime day in days)
            _daySection(p, l10n, settings, rates, day, byDay[day]!),
      ],
    );
  }

  Widget _figure(
    AppPalette p,
    String label,
    String amount,
    String code,
    Color color,
    String? home,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
        const SizedBox(height: 2),
        Text(
          '$amount $code',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        if (home != null)
          Text(
            home,
            style: TextStyle(fontSize: 10, color: p.textSecondary),
          ),
      ],
    );
  }

  Widget _categoryRow(
    AppPalette p,
    L10n l10n,
    SettingsProvider settings,
    RatesProvider rates,
    MapEntry<ExpenseCategory, double> entry,
    double spent,
  ) {
    final double share = spent <= 0 ? 0 : entry.value / spent;
    final String? home = _homeAmount(
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
          Icon(_icons[entry.key], size: 16, color: p.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${_categoryLabel(l10n, entry.key)} · '
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
          ),
        ],
      ),
    );
  }

  Widget _daySection(
    AppPalette p,
    L10n l10n,
    SettingsProvider settings,
    RatesProvider rates,
    DateTime day,
    List<Expense> expenses,
  ) {
    final double total = expenses.fold<double>(
      0,
      (double sum, Expense expense) => sum + expense.amount,
    );
    final String? home = _homeAmount(
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
      padding: const EdgeInsets.only(bottom: 8),
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
          for (final Expense expense in ordered) _expenseTile(p, l10n, expense),
        ],
      ),
    );
  }

  Widget _expenseTile(AppPalette p, L10n l10n, Expense expense) {
    final String note = expense.note.trim();
    final String details = note.isEmpty
        ? _categoryLabel(l10n, expense.category)
        : '${_categoryLabel(l10n, expense.category)}\n$note';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(_icons[expense.category], size: 20, color: p.primary),
      title: Text(expense.title),
      subtitle: Text(
        details,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11),
      ),
      onTap: () => onEdit(expense),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
            onPressed: () => onEdit(expense),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => onDelete(expense),
          ),
        ],
      ),
    );
  }
}

String? _homeAmount(
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

String? _homeNote(
  L10n l10n,
  SettingsProvider settings,
  double? amount,
  String code,
) {
  if (amount == null) return null;
  return l10n.approxAmount(settings.format(amount), code);
}

String _expenseTitle(L10n l10n, _DraftExpense draft) {
  final String text = draft.title.trim();
  if (text.isEmpty) return _categoryLabel(l10n, draft.category);
  return text;
}

String _categoryLabel(L10n l10n, ExpenseCategory category) {
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
