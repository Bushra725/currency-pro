import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fired.length == 1
              ? '${fired.first.from}/${fired.first.to} reached its target'
              : '${fired.length} alerts reached their target',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final AlertsProvider alerts = context.watch<AlertsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    return Scaffold(
      drawer: const AppDrawer(current: Routes.alerts),
      appBar: RateAppBar(
        title: 'Rate Alert',
        actions: <Widget>[
          IconButton(
            tooltip: 'Check now',
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
              label: const Text('ADD NEW ALERT'),
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
                      'Pending', p.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _counter(p, Icons.check_circle_outline,
                      '${alerts.achieved.length}', 'Achieved', p.up),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: alerts.all.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_none,
                    title: 'No alerts yet',
                    message: 'Add a target rate and the app will mark it as '
                        'achieved once the market gets there.',
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
                    a.isAchieved ? 'Achieved' : 'In progress',
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
                _stat(p, 'Registered', Fmt.smart(a.startRate, maxDecimals: 6),
                    p.textSecondary),
                _stat(
                  p,
                  'Target ${a.direction == AlertDirection.above ? '↑' : '↓'}',
                  Fmt.smart(a.targetRate, maxDecimals: 6),
                  p.primary,
                  sub: Fmt.percent(a.targetDeltaPercent, decimals: 2),
                ),
                _stat(
                  p,
                  'Now',
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
                  ? 'Reached on ${Fmt.dateTime(a.achievedAt!)}'
                  : remaining == null
                      ? 'Waiting for a live rate'
                      : '${Fmt.smart(remaining, maxDecimals: 6)} ${a.to} '
                          'to go · ${(progress * 100).toStringAsFixed(0)}%',
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
    final TextEditingController target = TextEditingController();

    double? currentRate() => rates.pairRate(from, to);
    target.text = Fmt.smart(currentRate() ?? 1, maxDecimals: 6, grouping: false);

    final bool? created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheet) {
            final AppPalette p = context.palette;
            final double? live = currentRate();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'New rate alert',
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
                              setSheet(() => from = picked.code);
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
                              setSheet(() => to = picked.code);
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
                        ? 'No live rate for this pair yet'
                        : 'Current: 1 $from = ${Fmt.smart(live, maxDecimals: 6)} $to',
                    style:
                        TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AlertDirection>(
                    segments: const <ButtonSegment<AlertDirection>>[
                      ButtonSegment<AlertDirection>(
                        value: AlertDirection.above,
                        label: Text('Rises to'),
                        icon: Icon(Icons.trending_up, size: 16),
                      ),
                      ButtonSegment<AlertDirection>(
                        value: AlertDirection.below,
                        label: Text('Falls to'),
                        icon: Icon(Icons.trending_down, size: 16),
                      ),
                    ],
                    selected: <AlertDirection>{direction},
                    onSelectionChanged: (Set<AlertDirection> value) =>
                        setSheet(() => direction = value.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: target,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Target rate',
                      suffixText: to,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('CREATE ALERT'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final double? targetValue = Fmt.parse(target.text);
    target.dispose();

    if (created != true || targetValue == null || !mounted) return;

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert added')),
    );
  }
}
