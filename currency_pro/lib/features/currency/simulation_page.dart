import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/flag_avatar.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/trend_chart.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../data/models/rate_snapshot.dart';
import '../../data/services/history_api.dart';
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import 'currency_picker.dart';

/// "What if the rate moved by X%?" — plus historical rates for the pair.
class SimulationPage extends StatefulWidget {
  const SimulationPage({super.key, this.historyApi});

  /// Injected in tests. The live screen creates its own [HistoryApi].
  final HistoryApi? historyApi;

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  final TextEditingController _amount = TextEditingController(text: '1000');
  late final HistoryApi _api;
  late final bool _ownsApi;
  double _shiftPercent = 0;
  String _from = 'USD';
  String _to = 'EUR';
  ChartRange _range = ChartRange.short.first;
  List<RatePoint> _points = <RatePoint>[];
  bool _loading = false;
  _ChartError? _error;
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    final SettingsProvider s = context.read<SettingsProvider>();
    _from = s.fromCode;
    _to = s.toCode;
    _ownsApi = widget.historyApi == null;
    _api = widget.historyApi ?? HistoryApi();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _amount.dispose();
    if (_ownsApi) _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final int id = ++_loadId;
    final String from = _from;
    final String to = _to;
    final int days = _range.days;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      HistorySeries result = await _api.series(from, to, days);
      if ((result.failed || result.points.length < 2) && id == _loadId) {
        result = await _api.series(from, to, days);
      }
      if (!mounted || id != _loadId) return;
      setState(() {
        _loading = false;
        if (result.points.length >= 2) {
          _points = result.points;
          _error = null;
        } else if (result.failed) {
          _points = <RatePoint>[];
          _error = _ChartError.network;
        } else {
          _points = <RatePoint>[];
          _error = _ChartError.unsupportedPair;
        }
      });
    } catch (_) {
      if (!mounted || id != _loadId) return;
      setState(() {
        _points = <RatePoint>[];
        _loading = false;
        _error = _ChartError.network;
      });
    }
  }

  void _setRange(ChartRange range) {
    if (range.label == _range.label) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    final double amount = Fmt.parse(_amount.text) ?? 0;
    final double? liveRate = rates.pairRate(_from, _to);
    final double? simulatedRate =
        liveRate == null ? null : liveRate * (1 + _shiftPercent / 100);

    final double? liveValue = liveRate == null ? null : amount * liveRate;
    final double? simulatedValue =
        simulatedRate == null ? null : amount * simulatedRate;
    final double? difference = (liveValue == null || simulatedValue == null)
        ? null
        : simulatedValue - liveValue;

    return Scaffold(
      drawer: const AppDrawer(current: Routes.simulation),
      appBar: RateAppBar(title: l10n.simulation),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: <Widget>[
                Expanded(child: _picker(p, _from, isFrom: true)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    icon: Icon(Icons.swap_horiz, color: p.primary),
                    onPressed: () {
                      setState(() {
                        final String old = _from;
                        _from = _to;
                        _to = old;
                      });
                      _load();
                    },
                  ),
                ),
                Expanded(child: _picker(p, _to, isFrom: false)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _rangeChips(p),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              key: const Key('sim-scroll'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
              children: <Widget>[
                _chartCard(p, l10n),
                const SizedBox(height: 12),
                SectionCard(
                  child: Row(
                    children: <Widget>[
                      FieldLabel(l10n.amountLabel, width: 84),
                      Expanded(
                        child: TextField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.right,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _from,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          FieldLabel(l10n.rateChange, width: 104),
                          const Spacer(),
                          Text(
                            Fmt.percent(_shiftPercent, decimals: 2),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _shiftPercent >= 0 ? p.up : p.down,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _shiftPercent,
                        min: -25,
                        max: 25,
                        divisions: 200,
                        onChanged: (double v) =>
                            setState(() => _shiftPercent = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('-25%',
                              style: TextStyle(
                                  fontSize: 11, color: p.textSecondary)),
                          TextButton(
                            onPressed: () => setState(() => _shiftPercent = 0),
                            child: Text(l10n.reset),
                          ),
                          Text('+25%',
                              style: TextStyle(
                                  fontSize: 11, color: p.textSecondary)),
                        ],
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
                      _resultRow(
                          p,
                          l10n.liveRate,
                          liveRate == null
                              ? '—'
                              : Fmt.smart(liveRate, maxDecimals: 6)),
                      const SizedBox(height: 8),
                      _resultRow(
                        p,
                        l10n.simulatedRate,
                        simulatedRate == null
                            ? '—'
                            : Fmt.smart(simulatedRate, maxDecimals: 6),
                        highlight: true,
                      ),
                      Divider(height: 22, color: p.outline),
                      _resultRow(
                        p,
                        l10n.youGetNow,
                        liveValue == null
                            ? '—'
                            : '${settings.format(liveValue)} $_to',
                      ),
                      const SizedBox(height: 8),
                      _resultRow(
                        p,
                        l10n.youWouldGet,
                        simulatedValue == null
                            ? '—'
                            : '${settings.format(simulatedValue)} $_to',
                        highlight: true,
                      ),
                      const SizedBox(height: 8),
                      _resultRow(
                        p,
                        l10n.difference,
                        difference == null
                            ? '—'
                            : '${difference >= 0 ? '+' : ''}'
                                '${settings.format(difference)} $_to',
                        color: difference == null
                            ? null
                            : (difference >= 0 ? p.up : p.down),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _historyTable(p, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeChips(AppPalette p) {
    return Wrap(
      spacing: 8,
      children: ChartRange.short.map((ChartRange range) {
        final bool selected = range.label == _range.label;
        return ChoiceChip(
          key: Key('sim-range-${range.label}'),
          label: Text(range.label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => _setRange(range),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? p.onPrimary : p.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  Widget _chartCard(AppPalette p, L10n l10n) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '1 $_from → $_to · ${_range.label}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(color: p.primary),
                    const SizedBox(height: 16),
                    Text(
                      l10n.chartChecking,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SizedBox(
              height: 200,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        _error == _ChartError.network
                            ? Icons.wifi_off_rounded
                            : Icons.show_chart_rounded,
                        size: 34,
                        color: p.textSecondary.withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error == _ChartError.network
                            ? l10n.chartLoadFailed
                            : l10n.chartNoHistory,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: Text(l10n.retry),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            TrendChart(
              key: const Key('sim-chart'),
              points: _points,
              height: 200,
              labelBuilder: (RatePoint point) =>
                  '${Fmt.date(point.date)}   1 $_from = '
                  '${Fmt.smart(point.value, maxDecimals: 6)} $_to',
            ),
        ],
      ),
    );
  }

  Widget _historyTable(AppPalette p, L10n l10n) {
    final List<RatePoint> rows = _points.reversed.toList();
    return SectionCard(
      key: const Key('sim-history-table'),
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.historicalRates,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
            ),
            child: Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text(l10n.colDate, style: _head(p))),
                Expanded(
                  flex: 3,
                  child: Text(l10n.colRate,
                      textAlign: TextAlign.right, style: _head(p)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(l10n.colChange,
                      textAlign: TextAlign.right, style: _head(p)),
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.chartNoHistory,
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
              ),
            )
          else
            ...List<Widget>.generate(rows.length, (int i) {
              final RatePoint row = rows[i];
              final RatePoint? prev = i + 1 < rows.length ? rows[i + 1] : null;
              final double? delta = prev == null || prev.value == 0
                  ? null
                  : (row.value - prev.value) / prev.value * 100;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: p.outline.withOpacity(0.5)),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        Fmt.date(row.date),
                        style:
                            TextStyle(fontSize: 11.5, color: p.textSecondary),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        Fmt.smart(row.value, maxDecimals: 6),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        delta == null ? '—' : Fmt.percent(delta),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: delta == null
                              ? p.textSecondary
                              : (delta >= 0 ? p.up : p.down),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  TextStyle _head(AppPalette p) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: p.textSecondary,
      );

  Widget _resultRow(
    AppPalette p,
    String label,
    String value, {
    bool highlight = false,
    Color? color,
  }) {
    return Row(
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 17 : 14,
            fontWeight: FontWeight.w800,
            color: color ?? (highlight ? p.primary : p.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _picker(AppPalette p, String code, {required bool isFrom}) {
    final Currency c = CurrencyLookup.of(code);
    return InkWell(
      onTap: () async {
        final Currency? picked = await CurrencyPicker.show(context);
        if (picked == null) return;
        setState(() {
          if (isFrom) {
            _from = picked.code;
          } else {
            _to = picked.code;
          }
        });
        await _load();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            FlagAvatar(c, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                c.code,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
            ),
            Icon(Icons.expand_more, size: 18, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}

enum _ChartError { network, unsupportedPair }
