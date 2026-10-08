import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/notifications/alert_notifications.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/flag_avatar.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../core/widgets/section_card.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../data/models/rate_alert.dart';
import '../../routes.dart';
import '../../state/alerts_provider.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import '../currency/currency_picker.dart';

/// Watch a pair and get told when it reaches your target.
class RateAlertPage extends StatefulWidget {
  const RateAlertPage({super.key});

  @override
  State<RateAlertPage> createState() => _RateAlertPageState();
}

class _RateAlertPageState extends State<RateAlertPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
  }

  Future<void> _evaluate() async {
    final RatesProvider rates = context.read<RatesProvider>();
    final AlertsProvider alerts = context.read<AlertsProvider>();
    final List<RateAlert> fired = await alerts.evaluate(rates.pairRate);
    if (fired.isEmpty || !mounted) return;
    await AlertNotifications.showFired(fired, rates.pairRate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fired.length == 1
              ? L10n.read(context).pairReached(
                  '${fired.first.from}/${fired.first.to}',
                )
              : L10n.read(context).alertsReached('${fired.length}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final AlertsProvider alerts = context.watch<AlertsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    return Scaffold(
      drawer: const AppDrawer(current: Routes.alerts),
      appBar: RateAppBar(
        title: l10n.rateAlert,
        actions: <Widget>[
          IconButton(
            tooltip: l10n.checkNow,
            icon: const Icon(Icons.done_all, size: 20),
            onPressed: _evaluate,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: FilledButton.icon(
              onPressed: _createAlert,
              icon: const Icon(Icons.add_alert_outlined, size: 18),
              label: Text(l10n.addNewAlert),
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
                  child: _counter(p, Icons.schedule, '${alerts.pending.length}',
                      l10n.pending, p.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _counter(p, Icons.check_circle_outline,
                      '${alerts.achieved.length}', l10n.achieved, p.up),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: alerts.all.isEmpty
                ? EmptyState(
                    icon: Icons.notifications_none,
                    title: l10n.noAlertsTitle,
                    message: l10n.noAlertsBody,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: alerts.all.length,
                    itemBuilder: (BuildContext context, int index) {
                      final RateAlert a = alerts.all[index];
                      return _alertCard(p, a, rates, alerts);
                    },
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
          Text(label,
              style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
        ],
      ),
    );
  }

  Widget _alertCard(
    AppPalette p,
    RateAlert a,
    RatesProvider rates,
    AlertsProvider alerts,
  ) {
    final L10n l10n = L10n.of(context);
    final Currency from = CurrencyLookup.of(a.from);
    final Currency to = CurrencyLookup.of(a.to);
    final double? current = rates.pairRate(a.from, a.to);
    final double progress = current == null ? 0 : a.progress(current);
    final double? remaining =
        current == null ? null : (a.targetRate - current).abs();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                FlagAvatar(from, size: 22),
                const SizedBox(width: 4),
                Text(
                  a.from,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child:
                      Icon(Icons.arrow_forward, size: 13, color: p.textSecondary),
                ),
                FlagAvatar(to, size: 22),
                const SizedBox(width: 4),
                Text(
                  a.to,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (a.isAchieved ? p.up : p.primary).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    a.isAchieved ? l10n.achieved : l10n.inProgress,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: a.isAchieved ? p.up : p.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: p.textSecondary),
                  onPressed: () => alerts.remove(a.id),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _stat(p, l10n.registered, Fmt.smart(a.startRate, maxDecimals: 6),
                    p.textSecondary),
                _stat(
                  p,
                  a.direction == AlertDirection.above
                      ? l10n.targetUp
                      : l10n.targetDown,
                  Fmt.smart(a.targetRate, maxDecimals: 6),
                  p.primary,
                  sub: Fmt.percent(a.targetDeltaPercent, decimals: 2),
                ),
                _stat(
                  p,
                  l10n.nowLabel,
                  current == null ? '—' : Fmt.smart(current, maxDecimals: 6),
                  p.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: p.surfaceAlt,
                color: a.isAchieved ? p.up : p.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.isAchieved
                  ? l10n.reachedOn(Fmt.dateTime(a.achievedAt!))
                  : remaining == null
                      ? l10n.waitingForRate
                      : l10n.amountToGo(
                          Fmt.smart(remaining, maxDecimals: 6),
                          a.to,
                          (progress * 100).toStringAsFixed(0),
                        ),
              style: TextStyle(fontSize: 11, color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(AppPalette p, String label, String value, Color color,
      {String? sub}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (sub != null)
            Text(sub,
                style: TextStyle(fontSize: 10, color: p.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _createAlert() async {
    final SettingsProvider settings = context.read<SettingsProvider>();
    final RatesProvider rates = context.read<RatesProvider>();

    String from = settings.fromCode;
    String to = settings.toCode;
    AlertDirection direction = AlertDirection.above;
    double percent = 5;
    final TextEditingController target = TextEditingController();
    final TextEditingController percentField = TextEditingController(text: '5');

    double? currentRate() => rates.pairRate(from, to);

    void writeTarget() {
      final double? live = currentRate();
      if (live == null || live <= 0 || percent <= 0) return;
      final double next = RateAlert.targetForPercent(live, percent, direction);
      if (next <= 0) return;
      target.text = Fmt.smart(next, maxDecimals: 6, grouping: false);
    }

    writeTarget();

    final bool? created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheet) {
            final AppPalette p = context.palette;
            final L10n l10n = L10n.read(context);
            final double? live = currentRate();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.newRateAlert,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final Currency? picked =
                                await CurrencyPicker.show(context);
                            if (picked != null) {
                              setSheet(() {
                                from = picked.code;
                                writeTarget();
                              });
                            }
                          },
                          child: Text(from),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.east, size: 16, color: p.primary),
                      ),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final Currency? picked =
                                await CurrencyPicker.show(context);
                            if (picked != null) {
                              setSheet(() {
                                to = picked.code;
                                writeTarget();
                              });
                            }
                          },
                          child: Text(to),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    live == null
                        ? l10n.noLiveRate
                        : l10n.currentPair(
                            from,
                            Fmt.smart(live, maxDecimals: 6),
                            to,
                          ),
                    style:
                        TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AlertDirection>(
                    segments: <ButtonSegment<AlertDirection>>[
                      ButtonSegment<AlertDirection>(
                        value: AlertDirection.above,
                        label: Text(l10n.risesTo),
                        icon: const Icon(Icons.trending_up, size: 16),
                      ),
                      ButtonSegment<AlertDirection>(
                        value: AlertDirection.below,
                        label: Text(l10n.fallsTo),
                        icon: const Icon(Icons.trending_down, size: 16),
                      ),
                    ],
                    selected: <AlertDirection>{direction},
                    onSelectionChanged: (Set<AlertDirection> value) =>
                        setSheet(() {
                      direction = value.first;
                      writeTarget();
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.alertPercent,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <double>[1, 2, 5, 10, 15, 25].map((double value) {
                      final bool selected = (percent - value).abs() < 0.001;
                      return ChoiceChip(
                        label: Text('${Fmt.smart(value, grouping: false)}%'),
                        selected: selected,
                        onSelected: (_) => setSheet(() {
                          percent = value;
                          percentField.text =
                              Fmt.smart(value, grouping: false);
                          writeTarget();
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: percentField,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.alertPercent,
                      suffixText: '%',
                    ),
                    onChanged: (String text) {
                      final double? value = Fmt.parse(text);
                      if (value == null || value <= 0) return;
                      setSheet(() {
                        percent = value;
                        writeTarget();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: target,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.targetRate,
                      suffixText: to,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(l10n.createAlert),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );

    final double? targetValue = Fmt.parse(target.text);
    target.dispose();
    percentField.dispose();

    if (created != true || targetValue == null || !mounted) return;

    final bool allowed = await AlertNotifications.ensurePermission();
    if (!mounted) return;
    await context.read<SettingsProvider>().setNotificationsEnabled(allowed);

    await context.read<AlertsProvider>().add(
          RateAlert(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            from: from,
            to: to,
            startRate: rates.pairRate(from, to) ?? targetValue,
            targetRate: targetValue,
            direction: direction,
            createdAt: DateTime.now(),
          ),
        );

    if (!mounted) return;
    await _evaluate();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allowed
              ? L10n.read(context).alertAddedNotify
              : L10n.read(context).alertAddedSilent,
        ),
      ),
    );
  }
}
