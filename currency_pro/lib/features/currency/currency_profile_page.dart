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
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import 'currency_picker.dart';

/// Reference card for a single currency: ISO data, symbol, subunit and its
/// current value against the user's base currency.
class CurrencyProfilePage extends StatefulWidget {
  const CurrencyProfilePage({super.key});

  @override
  State<CurrencyProfilePage> createState() => _CurrencyProfilePageState();
}

class _CurrencyProfilePageState extends State<CurrencyProfilePage> {
  String _code = 'USD';

  @override
  void initState() {
    super.initState();
    _code = context.read<SettingsProvider>().toCode;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    final Currency c = CurrencyLookup.of(_code);
    final Currency base = CurrencyLookup.of(settings.baseCode);
    final double? rate = rates.pairRate(c.code, base.code);
    final double? inverse = rates.pairRate(base.code, c.code);

    final int index =
        CurrencyLookup.fiat.indexWhere((Currency x) => x.code == _code);

    return Scaffold(
      drawer: const AppDrawer(current: Routes.profile),
      appBar: RateAppBar(title: 'Currency Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final Currency? picked =
                          await CurrencyPicker.show(context);
                      if (picked != null) setState(() => _code = picked.code);
                    },
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search, size: 19, color: p.textSecondary),
                        const SizedBox(width: 10),
                        FlagAvatar(c, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${c.code} — ${c.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                  onPressed: index <= 0
                      ? null
                      : () => setState(
                          () => _code = CurrencyLookup.fiat[index - 1].code),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  onPressed: index < 0 || index >= CurrencyLookup.fiat.length - 1
                      ? null
                      : () => setState(
                          () => _code = CurrencyLookup.fiat[index + 1].code),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            color: p.primary.withOpacity(0.12),
            borderColor: p.primary.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    FlagAvatar(c, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${c.name} (${c.code})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rate == null
                      ? 'Rate unavailable'
                      : '1 ${c.code} = ${Fmt.smart(rate, maxDecimals: 6)} ${base.code}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.primary,
                  ),
                ),
                if (inverse != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '1 ${base.code} = ${Fmt.smart(inverse, maxDecimals: 6)} ${c.code}',
                      style:
                          TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionLabel('Profile'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _row(p, 'ISO 4217 code', c.code, first: true),
                _row(p, 'Currency name', c.name),
                _row(p, 'Country / region', c.country.isEmpty ? '—' : c.country),
                _row(p, 'Symbol', c.symbol.isEmpty ? '—' : c.symbol),
                _row(p, 'Subunit', c.subunit),
                _row(p, 'Decimal digits', '${c.decimals}'),
                _row(
                  p,
                  'Asset class',
                  c.isFiat
                      ? 'Fiat currency'
                      : (c.isMetal ? 'Precious metal' : 'Cryptocurrency'),
                ),
                if (c.flag.isNotEmpty) _row(p, 'Flag', c.flag),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 17, color: p.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Rates are mid-market reference values from '
                    '${rates.provider}. Banks and exchanges add their own '
                    'spread — use Exchange Rate Adjustment to model it.',
                    style:
                        TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppPalette p, String label, String value,
      {bool first = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: p.outline.withOpacity(0.5))),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: p.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
