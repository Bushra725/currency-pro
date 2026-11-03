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
import 'trip_detail_page.dart';
import 'trip_helpers.dart';

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

void openTripDetail(BuildContext context, String tripId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TripDetailPage(tripId: tripId),
    ),
  );
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.5, height: 1.2, color: p.textSecondary),
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
                  labelText: l10n.budgetInDestination,
                  suffixText: _local,
                  helperText: _home == _local
                      ? null
                      : l10n.homeEquivalent(
                          homeAmount == null
                              ? '—'
                              : settings.format(homeAmount),
                          _home,
                        ),
                  helperMaxLines: 2,
                  helperStyle: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: p.textSecondary,
                  ),
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

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final TripsProvider trips = context.read<TripsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final TripTotals totals = TripTotals.of(trip, rates);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('open-trip-${trip.id}'),
                  onTap: () => openTripDetail(context, trip.id),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
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
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _stat(
                                p,
                                l10n.totalBudget,
                                '${settings.format(totals.budgetLocal)} ${totals.budgetCode}',
                                p.textPrimary,
                                note: totals.budgetCode == trip.homeCurrency
                                    ? null
                                    : homeNote(
                                        l10n,
                                        settings,
                                        totals.budgetHome,
                                        trip.homeCurrency,
                                      ),
                              ),
                            ),
                            Expanded(
                              child: _stat(
                                p,
                                l10n.spent,
                                '${settings.format(totals.spentLocal)} ${trip.localCurrency}',
                                p.primary,
                                note: trip.localCurrency == trip.homeCurrency
                                    ? null
                                    : homeNote(
                                        l10n,
                                        settings,
                                        totals.spentHome,
                                        trip.homeCurrency,
                                      ),
                              ),
                            ),
                            Expanded(
                              child: _stat(
                                p,
                                l10n.remaining,
                                '${settings.format(totals.remaining)} ${totals.budgetCode}',
                                totals.remaining >= 0 ? p.up : p.down,
                                note: totals.budgetCode == trip.homeCurrency
                                    ? null
                                    : homeNote(
                                        l10n,
                                        settings,
                                        totals.remainingHome,
                                        trip.homeCurrency,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totals.ratio,
                            minHeight: 6,
                            backgroundColor: p.surfaceAlt,
                            color: totals.ratio > 0.9 ? p.down : p.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: <Widget>[
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18, color: p.textSecondary),
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
                        trip.completed
                            ? l10n.markOngoing
                            : l10n.markCompleted,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(l10n.deleteTrip),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, color: p.textSecondary),
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
}
