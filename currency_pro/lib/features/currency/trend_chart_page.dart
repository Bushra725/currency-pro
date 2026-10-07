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

/// Historical rate chart with 10D … 2Y ranges and a day-by-day table.
class TrendChartPage extends StatefulWidget {
  const TrendChartPage({super.key});

  @override
  State<TrendChartPage> createState() => _TrendChartPageState();
}

class _TrendChartPageState extends State<TrendChartPage> {
  final HistoryApi _api = HistoryApi();

  List<RatePoint> _points = <RatePoint>[];
  ChartRange _range = ChartRange.all[3]; // 6M
  bool _loading = false;
  _ChartError? _error;
  String _from = 'USD';
  String _to = 'GBP';

  @override
  void initState() {
    super.initState();
    final SettingsProvider settings = context.read<SettingsProvider>();
    _from = settings.fromCode;
    _to = settings.toCode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final HistorySeries result =
          await _api.series(_from, _to, _range.days);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.failed) {
          _points = <RatePoint>[];
          _error = _ChartError.network;
        } else if (result.points.length < 2) {
          _points = <RatePoint>[];
          // An empty series is either a pair with no published history, or
          // a response that came back with nothing. Neither case shows the
          // request, the status code, or the query string.
          _error = _api.supports(_from, _to)
              ? _ChartError.network
              : _ChartError.unsupportedPair;
        } else {
          _points = result.points;
          _error = null;
        }
      });
    } catch (_) {
      debugPrint('Trend chart load failed for $_from/$_to');
      if (!mounted) return;
      setState(() {
        _points = <RatePoint>[];
        _loading = false;
        _error = _ChartError.network;
      });
    }
  }

  Future<void> _pick({required bool isFrom}) async {
    final Currency? picked = await CurrencyPicker.show(
      context,
      title: isFrom
          ? L10n.read(context).chartBase
          : L10n.read(context).chartTarget,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked.code;
      } else {
        _to = picked.code;
      }
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();

    final double? live = rates.pairRate(_from, _to);
    final double? first = _points.isEmpty ? null : _points.first.value;
    final double? last = _points.isEmpty ? null : _points.last.value;
    final double? changePct = (first == null || last == null || first == 0)
        ? null
        : (last - first) / first * 100;

    return Scaffold(
      drawer: const AppDrawer(current: Routes.charts),
      appBar: RateAppBar(
        title: l10n.trendCharts,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 20),
            tooltip: l10n.swapPair,
            onPressed: () {
              setState(() {
                final String old = _from;
                _from = _to;
                _to = old;
              });
              _load();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _pairButton(p, _from, isFrom: true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16, color: p.primary),
              ),
              Expanded(child: _pairButton(p, _to, isFrom: false)),
            ],
          ),
          const SizedBox(height: 12),
          _rangeSelector(p),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  live == null
                      ? '1 $_from = —'
                      : '1 $_from = ${Fmt.smart(live, maxDecimals: 6)} $_to',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (changePct != null)
                  Row(
                    children: <Widget>[
                      Icon(
                        changePct >= 0
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 18,
                        color: changePct >= 0 ? p.up : p.down,
                      ),
                      Text(
                        '${Fmt.percent(changePct)} · ${_range.label}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: changePct >= 0 ? p.up : p.down,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                if (_loading)
                  SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(color: p.primary),
                    ),
                  )
                else if (_error != null)
                  SizedBox(
                    height: 220,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                            if (_error == _ChartError.network) ...<Widget>[
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 17),
                                label: Text(l10n.retry),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  TrendChart(
                    points: _points,
                    labelBuilder: (RatePoint point) =>
                        '${Fmt.date(point.date)}   1 $_from = '
                        '${Fmt.smart(point.value, maxDecimals: 6)} $_to',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_points.length > 1) _table(p),
        ],
      ),
    );
  }

  Widget _pairButton(AppPalette p, String code, {required bool isFrom}) {
    final Currency c = CurrencyLookup.of(code);
    return InkWell(
      onTap: () => _pick(isFrom: isFrom),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.primary.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.primary.withOpacity(0.5)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    c.code,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                  ),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: p.textSecondary),
                  ),
                ],
              ),
            ),
            FlagAvatar(c, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _rangeSelector(AppPalette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: ChartRange.all.map((ChartRange r) {
          final bool selected = r.label == _range.label;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _range = r);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? p.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? p.onPrimary : p.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _table(AppPalette p) {
    final L10n l10n = L10n.of(context);
    final List<RatePoint> rows = _points.reversed.take(14).toList();

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(l10n.colDate, style: _head(p)),
                ),
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
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary),
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
}

/// Why the chart has nothing to draw. Kept separate from the message text so
/// the wording stays translatable and no exception detail can reach the UI.
enum _ChartError { network, unsupportedPair }
