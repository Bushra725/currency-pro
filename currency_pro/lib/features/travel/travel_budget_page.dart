import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

/// Plan a trip budget in your home currency and log spending in the local one.
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
                  child: _counter(
                    p,
                    Icons.schedule,
                    '${trips.ongoing.length}',
                    l10n.ongoing,
                    p.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _counter(
                    p,
                    Icons.check_circle_outline,
                    '${trips.completed.length}',
                    l10n.tripCompleted,
                    p.up,
                  ),
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

  Widget _counter(
    AppPalette p,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
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
          Text(label, style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
        ],
      ),
    );
  }

  static Future<void> _newTrip(BuildContext context) async {
    final L10n l10n = L10n.read(context);
    final SettingsProvider settings = context.read<SettingsProvider>();
    final _TripDraft? draft = await showModalBottomSheet<_TripDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) => _NewTripSheet(
        l10n: l10n,
        home: settings.fromCode,
        local: settings.toCode,
      ),
    );

    if (draft == null || !context.mounted) return;
    final String tripName = draft.name.trim().isEmpty
        ? l10n.tripTo(draft.local)
        : draft.name.trim();
    final double budgetValue = Fmt.parse(draft.budget) ?? 0;

    await context.read<TripsProvider>().add(
      Trip(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: tripName,
        homeCurrency: draft.home,
        localCurrency: draft.local,
        budget: budgetValue,
        startDate: draft.range.start,
        endDate: draft.range.end,
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

    final double spentHome =
        rates.convert(trip.spentLocal, trip.localCurrency, trip.homeCurrency) ??
        0;
    final double ratio = trip.budget <= 0
        ? 0
        : (spentHome / trip.budget).clamp(0.0, 1.0);
    final double remaining = trip.budget - spentHome;
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
                        style: TextStyle(fontSize: 11, color: p.textSecondary),
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
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
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
                    '${settings.format(trip.budget)} ${trip.homeCurrency}',
                    p.textPrimary,
                  ),
                ),
                Expanded(
                  child: _stat(
                    p,
                    l10n.spent,
                    '${settings.format(trip.spentLocal)} ${trip.localCurrency}',
                    p.primary,
                  ),
                ),
                Expanded(
                  child: _stat(
                    p,
                    l10n.amountLeft,
                    '${settings.format(remaining)} ${trip.homeCurrency}',
                    remaining >= 0 ? p.up : p.down,
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
                children: byCategory.entries.map((
                  MapEntry<ExpenseCategory, double> e,
                ) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                          '${_categoryLabel(l10n, e.key)} ${Fmt.smart(e.value)}',
                          style: TextStyle(fontSize: 11, color: p.textPrimary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
                    label: Text(l10n.itemsCount('${trip.expenses.length}')),
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

  Widget _stat(AppPalette p, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _addExpense(BuildContext context, Trip trip) async {
    final L10n l10n = L10n.read(context);
    final _ExpenseDraft? draft = await showModalBottomSheet<_ExpenseDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) =>
          _ExpenseSheet(l10n: l10n, currency: trip.localCurrency),
    );

    if (draft == null || !context.mounted) return;
    final double? value = Fmt.parse(draft.amount);
    if (value == null || !value.isFinite) return;
    final String text = draft.title.trim().isEmpty
        ? _categoryLabel(l10n, draft.category)
        : draft.title.trim();

    await context.read<TripsProvider>().addExpense(
      trip.id,
      Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: text,
        amount: value,
        category: draft.category,
        date: DateTime.now(),
      ),
    );
  }

  Future<void> _showExpenses(BuildContext context, Trip trip) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        final L10n l10n = L10n.read(sheetContext);
        final AppPalette p = sheetContext.palette;
        return Consumer<TripsProvider>(
          builder: (BuildContext context, TripsProvider provider, _) {
            final Trip? live = provider.byId(trip.id);
            final List<Expense> items = live?.expenses ?? <Expense>[];
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double cap = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : MediaQuery.sizeOf(context).height * 0.85;
                return SizedBox(
                  height: cap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(height: 16),
                      Text(
                        l10n.tripExpenses(trip.name),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: items.isEmpty
                            ? EmptyState(
                                icon: Icons.receipt_long,
                                title: l10n.nothingLogged,
                              )
                            : ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: p.outline.withOpacity(0.5),
                                ),
                                itemBuilder: (BuildContext context, int index) {
                                  final Expense e = items[index];
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(_icons[e.category], size: 20),
                                    title: Text(e.title),
                                    subtitle: Text(
                                      '${_categoryLabel(l10n, e.category)} · ${Fmt.date(e.date)}',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          '${Fmt.smart(e.amount)} '
                                          '${trip.localCurrency}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: p.primary,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                          onPressed: () => provider
                                              .removeExpense(trip.id, e.id),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TripDraft {
  const _TripDraft({
    required this.name,
    required this.budget,
    required this.home,
    required this.local,
    required this.range,
  });

  final String name;
  final String budget;
  final String home;
  final String local;
  final DateTimeRange range;
}

/// Owns the text fields for the life of the route. Disposing them when the
/// sheet future returns throws, because the pop animation still has the
/// fields mounted.
class _NewTripSheet extends StatefulWidget {
  const _NewTripSheet({
    required this.l10n,
    required this.home,
    required this.local,
  });

  final L10n l10n;
  final String home;
  final String local;

  @override
  State<_NewTripSheet> createState() => _NewTripSheetState();
}

class _NewTripSheetState extends State<_NewTripSheet> {
  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _budget = TextEditingController(
    text: '1000',
  );
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

  @override
  Widget build(BuildContext context) {
    final L10n l10n = widget.l10n;
    final AppPalette p = context.palette;
    return _SheetScroll(
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
                    if (picked != null && mounted) {
                      setState(() => _home = picked.code);
                    }
                  },
                  child: Text(l10n.homeCode(_home)),
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
                    if (picked != null && mounted) {
                      setState(() => _local = picked.code);
                    }
                  },
                  child: Text(l10n.localCode(_local)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.budgetLabel,
              suffixText: _home,
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
              if (picked != null && mounted) setState(() => _range = picked);
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text('${Fmt.date(_range.start)} → ${Fmt.date(_range.end)}'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _TripDraft(
                name: _name.text,
                budget: _budget.text,
                home: _home,
                local: _local,
                range: _range,
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(l10n.createTrip),
          ),
        ],
      ),
    );
  }
}

class _ExpenseDraft {
  const _ExpenseDraft({
    required this.title,
    required this.amount,
    required this.category,
  });

  final String title;
  final String amount;
  final ExpenseCategory category;
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.l10n, required this.currency});

  final L10n l10n;
  final String currency;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _title = TextEditingController();
  late final TextEditingController _amount = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.food;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L10n l10n = widget.l10n;
    final AppPalette p = context.palette;
    return _SheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.addExpense,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: l10n.whatFor),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.amountLabel,
              suffixText: widget.currency,
            ),
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
            onPressed: () => Navigator.of(context).pop(
              _ExpenseDraft(
                title: _title.text,
                amount: _amount.text,
                category: _category,
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(l10n.saveExpense),
          ),
        ],
      ),
    );
  }
}

/// Keeps a bottom sheet inside the space left above the keyboard.
class _SheetScroll extends StatelessWidget {
  const _SheetScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: child,
        ),
      ),
    );
  }
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
