import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../theme/app_palette.dart';
import 'ads_service.dart';

/// Persistent bottom banner. The slot is always reserved so keypads and
/// lists never jump, and it sits *above* the system navigation bar.
class BottomAdSlot extends StatefulWidget {
  const BottomAdSlot({super.key});

  @override
  State<BottomAdSlot> createState() => _BottomAdSlotState();
}

class _BottomAdSlotState extends State<BottomAdSlot> {
  bool _requested = false;

  void _requestIfNeeded(int width) {
    if (_requested || width <= 0) return;
    _requested = true;
    final AdsService ads = context.read<AdsService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ads.loadBanner(width: width);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AdsService ads = context.watch<AdsService>();
    if (!AdsService.isSupported || ads.adsMuted) {
      return const SizedBox.shrink();
    }
    final AppPalette p = context.palette;
    final BannerAd? banner = ads.banner;
    final double height = banner != null
        ? banner.size.height
            .toDouble()
            .clamp(AppConfig.bannerAdSlotHeight, 120)
            .toDouble()
        : AppConfig.bannerAdSlotHeight;

    // Separated from the content by a soft shadow rather than a rule, so no
    // hairline runs across the bottom of the app.
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: p.isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              _requestIfNeeded(constraints.maxWidth.truncate());
              return SizedBox(
                height: height,
                width: double.infinity,
                child: ClipRect(
                  child: banner == null
                      ? _placeholder(p)
                      : AdWidget(key: ObjectKey(banner), ad: banner),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _placeholder(AppPalette p) {
    return Center(
      child: Text(
        'Advertisement',
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          color: p.textSecondary,
        ),
      ),
    );
  }
}
