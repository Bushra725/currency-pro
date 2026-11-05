import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../theme/app_palette.dart';
import 'ads_service.dart';

/// In-feed native ad. iOS uses a custom factory whose MediaView is framed
/// at 200×336 pt before AdMob validates video size. If that factory is
/// missing, the Google medium template (also ≥120 pt) is the fallback.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({
    super.key,
    this.height,
  });

  final double? height;

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;
  bool _retriedSample = false;
  bool _retriedMedium = false;

  static bool get _ios =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  NativeTemplateStyle _mediumStyle(AppPalette p) {
    return NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: p.surface,
      cornerRadius: 14,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: p.onPrimary,
        backgroundColor: p.primary,
        style: NativeTemplateFontStyle.bold,
        size: 13,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: p.textPrimary,
        style: NativeTemplateFontStyle.bold,
        size: 14,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: p.textSecondary,
        size: 12,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: p.textSecondary,
        size: 11,
      ),
    );
  }

  void _load({bool useIosFactory = true}) {
    if (!mounted || !AdsService.isSupported) return;
    final AdsService ads = context.read<AdsService>();
    if (ads.adsMuted || !ads.sdkReady) return;

    _ad?.dispose();
    _ad = null;
    _loaded = false;

    final AppPalette p = context.palette;
    final bool factory = _ios && useIosFactory;
    final NativeAdListener listener = NativeAdListener(
      onAdLoaded: (Ad ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() {
          _loaded = true;
          _failed = false;
        });
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        debugPrint('Native ad failed: $error');
        ad.dispose();
        if (identical(_ad, ad)) _ad = null;
        if (!mounted) return;
        if (factory && !_retriedMedium) {
          _retriedMedium = true;
          _load(useIosFactory: false);
          return;
        }
        if (error.code == 3) {
          context.read<AdsService>().retryWithSampleAds();
        }
        setState(() => _failed = true);
      },
    );
    final NativeAd ad = NativeAd(
      adUnitId: AdsService.nativeAdUnitId,
      factoryId: factory ? 'native_media' : null,
      request: const AdRequest(),
      listener: listener,
      nativeTemplateStyle: factory ? null : _mediumStyle(p),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AdsService ads = context.watch<AdsService>();
    if (!AdsService.isSupported || ads.adsMuted) {
      return const SizedBox.shrink();
    }
    if (ads.sdkReady && _ad == null && !_failed && !_loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    if (ads.usingSampleAds && _failed && !_retriedSample) {
      _retriedSample = true;
      _failed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(useIosFactory: !_retriedMedium);
      });
    }
    if (_failed || _ad == null || !_loaded) {
      return const SizedBox.shrink();
    }

    final double height = widget.height ?? AppConfig.nativeAdCardHeight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
