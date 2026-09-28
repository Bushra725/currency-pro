import 'package:flutter/material.dart';

import '../../data/models/currency.dart';
import '../theme/app_palette.dart';

/// Shows a country flag emoji for fiat currencies and a coloured badge for
/// metals and crypto (which have no flag).
class FlagAvatar extends StatelessWidget {
  const FlagAvatar(this.currency, {super.key, this.size = 26});

  final Currency currency;
  final double size;

  static const Map<String, Color> _assetColors = <String, Color>{
    'XAU': Color(0xFFD4AF37),
    'XAG': Color(0xFFB8BFC6),
    'XPT': Color(0xFF9FB1BD),
    'XPD': Color(0xFFA8A29E),
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF7B7BE8),
    'USDT': Color(0xFF26A17B),
    'BNB': Color(0xFFF3BA2F),
    'SOL': Color(0xFF14F195),
    'XRP': Color(0xFF7A7A7A),
  };

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final String flag = currency.flag;

    if (flag.isNotEmpty) {
      return SizedBox(
        width: size * 1.35,
        height: size,
        child: Center(
          child: Text(flag, style: TextStyle(fontSize: size * 0.95)),
        ),
      );
    }

    final Color badge = _assetColors[currency.code] ?? p.primary;
    final String glyph = currency.code.length >= 2
        ? currency.code.substring(currency.code.length - 2)
        : currency.code;

    return Container(
      width: size * 1.35,
      height: size,
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Filled badge — no ring, matching the rest of the borderless UI.
          gradient: LinearGradient(
            colors: <Color>[
              badge.withOpacity(0.30),
              badge.withOpacity(0.16),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          currency.code == 'BTC' ? '₿' : glyph,
          style: TextStyle(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            color: badge,
          ),
        ),
      ),
    );
  }
}
