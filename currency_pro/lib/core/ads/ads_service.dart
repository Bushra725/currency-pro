import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../app_config.dart';
import '../../data/services/prefs_service.dart';

/// Loads every AdMob format used in the published app.
class AdsService extends ChangeNotifier {
  AdsService(this._prefs) {
    final int until = _prefs.getInt(PrefsService.kAdsFreeUntil) ?? 0;
    if (until > 0) {
      _adsFreeUntil = DateTime.fromMillisecondsSinceEpoch(until);
    }
  }

  final PrefsService _prefs;

  BannerAd? _banner;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  RewardedInterstitialAd? _rewardedInterstitial;
  AppOpenAd? _appOpen;

  bool _loadingBanner = false;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  bool _loadingRewardedInterstitial = false;
  bool _loadingAppOpen = false;
  bool _showingFullscreen = false;
  bool _initialized = false;
  bool _failed = false;
  bool _enabled = false;
  int _featureExits = 0;
  DateTime? _lastFullscreenAt;
  DateTime? _lastAppOpenAt;
  DateTime? _adsFreeUntil;
  DateTime? _backgroundedAt;

  bool _sampleFallback = false;
  int _lastBannerWidth = 320;

  BannerAd? get banner => adsMuted ? null : _banner;
  bool get isReady => banner != null;
  bool get failed => _failed;
  bool get isLoadingBanner => _loadingBanner;
  bool get interstitialReady => _interstitial != null;
  bool get rewardedReady => _rewarded != null;
  bool get usingSampleAds => _sampleFallback;

  bool get adsMuted {
    final DateTime? until = _adsFreeUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _adsFreeUntil = null;
    return false;
  }

  Duration get adsFreeRemaining {
    final DateTime? until = _adsFreeUntil;
    if (until == null) return Duration.zero;
    final Duration left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// After a live-unit no-fill (sideloaded / new app), Google sample units
  /// keep the slots filled. Live units are always tried first.
  static bool _forceSample = false;

  static bool get _android => defaultTargetPlatform == TargetPlatform.android;

  static String get bannerAdUnitId {
    if (_forceSample) return AppConfig.testBannerAdUnitId;
    return _android
        ? AppConfig.androidBannerAdUnitId
        : AppConfig.iosBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (_forceSample) return AppConfig.testInterstitialAdUnitId;
    return _android
        ? AppConfig.androidInterstitialAdUnitId
        : AppConfig.iosInterstitialAdUnitId;
  }

  static String get rewardedAdUnitId {
    if (_forceSample) return AppConfig.testRewardedAdUnitId;
    return _android
        ? AppConfig.androidRewardedAdUnitId
        : AppConfig.iosRewardedAdUnitId;
  }

  static String get rewardedInterstitialAdUnitId {
    if (_forceSample) return AppConfig.testRewardedInterstitialAdUnitId;
    return _android
        ? AppConfig.androidRewardedInterstitialAdUnitId
        : AppConfig.iosRewardedInterstitialAdUnitId;
  }

  static String get nativeAdUnitId {
    if (_forceSample) return AppConfig.testNativeAdUnitId;
    return _android
        ? AppConfig.androidNativeAdUnitId
        : AppConfig.iosNativeAdUnitId;
  }

  static String get appOpenAdUnitId {
    if (_forceSample) return AppConfig.testAppOpenAdUnitId;
    return _android
        ? AppConfig.androidAppOpenAdUnitId
        : AppConfig.iosAppOpenAdUnitId;
  }

  Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    _initialized = true;
    try {
      // Test-device IDs must be registered before SDK init, otherwise
      // production units return Error 3 (no fill) on a sideloaded APK.
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: AppConfig.adMobTestDeviceIds,
        ),
      );
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('Mobile Ads failed to initialize: $e');
      _failed = true;
      notifyListeners();
    }
  }

  Future<void> enableReturnAds() async {
    if (!isSupported) return;
    _enabled = true;
    unawaited(_requestConsent());
    loadInterstitial();
    loadRewarded();
    loadRewardedInterstitial();
    loadAppOpen();
  }

  Future<void> _requestConsent() async {
    try {
      final Completer<void> done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            if (await ConsentInformation.instance.isConsentFormAvailable()) {
              ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
                if (!done.isCompleted) done.complete();
              });
            } else if (!done.isCompleted) {
              done.complete();
            }
          } catch (_) {
            if (!done.isCompleted) done.complete();
          }
        },
        (FormError error) {
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () {},
      );
    } catch (e) {
      debugPrint('UMP consent skipped: $e');
    }
  }

  Future<void> loadBanner({required int width}) async {
    if (!isSupported || adsMuted || _loadingBanner || _banner != null) return;
    if (width <= 0) return;
    _lastBannerWidth = width;
    _loadingBanner = true;
    _failed = false;

    AdSize size = AdSize.banner;
    try {
      final AdSize? adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        width,
      );
      if (adaptive != null) size = adaptive;
    } catch (_) {
      size = AdSize.banner;
    }

    final BannerAd ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _banner = ad as BannerAd;
          _loadingBanner = false;
          _failed = false;
          notifyListeners();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
          _banner = null;
          _loadingBanner = false;
          if (_handleNoFill(error, 'Banner')) return;
          _failed = true;
          notifyListeners();
        },
      ),
    );

    try {
      ad.load();
    } catch (e) {
      debugPrint('Banner load threw: $e');
      ad.dispose();
      _loadingBanner = false;
      _failed = true;
      notifyListeners();
    }
  }

  bool _handleNoFill(LoadAdError error, String label) {
    if (error.code != 3 || _forceSample) return false;
    debugPrint('$label no-fill on live units; loading Google sample ads');
    retryWithSampleAds();
    return true;
  }

  void retryWithSampleAds() {
    if (_forceSample && _sampleFallback) return;
    _forceSample = true;
    _sampleFallback = true;
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      loadBanner(width: _lastBannerWidth);
      loadInterstitial();
      loadRewarded();
      loadRewardedInterstitial();
      loadAppOpen();
    });
  }

  Future<void> loadInterstitial() async {
    if (!isSupported || !_enabled || adsMuted) return;
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Interstitial failed: $error');
          _interstitial = null;
          _loadingInterstitial = false;
          _handleNoFill(error, 'Interstitial');
        },
      ),
    );
  }

  Future<void> loadRewarded() async {
    if (!isSupported || !_enabled || _loadingRewarded || _rewarded != null) {
      return;
    }
    _loadingRewarded = true;
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded failed: $error');
          _rewarded = null;
          _loadingRewarded = false;
          if (!_handleNoFill(error, 'Rewarded')) notifyListeners();
        },
      ),
    );
  }

  Future<void> loadRewardedInterstitial() async {
    if (!isSupported || !_enabled || adsMuted) return;
    if (_loadingRewardedInterstitial || _rewardedInterstitial != null) return;
    _loadingRewardedInterstitial = true;
    await RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitial = ad;
          _loadingRewardedInterstitial = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded interstitial failed: $error');
          _rewardedInterstitial = null;
          _loadingRewardedInterstitial = false;
          _handleNoFill(error, 'Rewarded interstitial');
        },
      ),
    );
  }

  Future<void> loadAppOpen() async {
    if (!isSupported || !_enabled || adsMuted) return;
    if (_loadingAppOpen || _appOpen != null) return;
    _loadingAppOpen = true;
    await AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpen = ad;
          _loadingAppOpen = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('App open failed: $error');
          _appOpen = null;
          _loadingAppOpen = false;
          _handleNoFill(error, 'App open');
        },
      ),
    );
  }

  void markBackgrounded() {
    _backgroundedAt = DateTime.now();
  }

  /// Full-screen ad after leaving a calculator / converter / tool.
  Future<void> showAfterReturningFromFeature() async {
    if (!_enabled || adsMuted || _showingFullscreen) return;
    if (!_canShowFullscreen(AppConfig.interstitialGap)) {
      loadInterstitial();
      loadRewardedInterstitial();
      return;
    }

    _featureExits++;
    if (_featureExits == 1) {
      loadInterstitial();
      loadRewardedInterstitial();
      return;
    }
    final bool preferRewardedInterstitial = _featureExits % 3 == 0;
    if (preferRewardedInterstitial && _rewardedInterstitial != null) {
      await _showRewardedInterstitial();
      return;
    }
    await _showInterstitial();
  }

  Future<void> showAppOpenIfEligible() async {
    if (!_enabled || adsMuted || _showingFullscreen) return;
    final DateTime? backgrounded = _backgroundedAt;
    _backgroundedAt = null;
    if (backgrounded == null) return;
    if (DateTime.now().difference(backgrounded) < const Duration(seconds: 8)) {
      return;
    }
    if (!_canShowFullscreen(AppConfig.appOpenGap, last: _lastAppOpenAt)) {
      loadAppOpen();
      return;
    }
    final AppOpenAd? ad = _appOpen;
    if (ad == null) {
      loadAppOpen();
      return;
    }

    _showingFullscreen = true;
    _lastAppOpenAt = DateTime.now();
    _lastFullscreenAt = _lastAppOpenAt;
    _appOpen = null;

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (AppOpenAd ad) {
        ad.dispose();
        _showingFullscreen = false;
        loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
        debugPrint('App open show failed: $error');
        ad.dispose();
        _showingFullscreen = false;
        loadAppOpen();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('App open show threw: $e');
      ad.dispose();
      _showingFullscreen = false;
      loadAppOpen();
    }
  }

  /// Watch a rewarded video to hide ads for [AppConfig.rewardedAdFree].
  Future<bool> watchToHideAds() async {
    if (!isSupported) return false;
    RewardedAd? ad = _rewarded;
    if (ad == null) {
      await loadRewarded();
      ad = _rewarded;
    }
    if (ad == null) return false;

    final Completer<bool> earned = Completer<bool>();
    _rewarded = null;
    _showingFullscreen = true;

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _showingFullscreen = false;
        loadRewarded();
        if (!earned.isCompleted) earned.complete(false);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('Rewarded show failed: $error');
        ad.dispose();
        _showingFullscreen = false;
        loadRewarded();
        if (!earned.isCompleted) earned.complete(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          if (!earned.isCompleted) earned.complete(true);
        },
      );
    } catch (e) {
      debugPrint('Rewarded show threw: $e');
      ad.dispose();
      _showingFullscreen = false;
      loadRewarded();
      return false;
    }

    final bool ok = await earned.future;
    if (ok) await _muteAds();
    return ok;
  }

  Future<void> _showInterstitial() async {
    final InterstitialAd? ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return;
    }

    _showingFullscreen = true;
    _lastFullscreenAt = DateTime.now();
    _interstitial = null;

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _showingFullscreen = false;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('Interstitial show failed: $error');
        ad.dispose();
        _showingFullscreen = false;
        loadInterstitial();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('Interstitial show threw: $e');
      ad.dispose();
      _showingFullscreen = false;
      loadInterstitial();
    }
  }

  Future<void> _showRewardedInterstitial() async {
    final RewardedInterstitialAd? ad = _rewardedInterstitial;
    if (ad == null) {
      await _showInterstitial();
      return;
    }

    _showingFullscreen = true;
    _lastFullscreenAt = DateTime.now();
    _rewardedInterstitial = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedInterstitialAd>(
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        ad.dispose();
        _showingFullscreen = false;
        loadRewardedInterstitial();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedInterstitialAd ad, AdError error) {
        debugPrint('Rewarded interstitial show failed: $error');
        ad.dispose();
        _showingFullscreen = false;
        loadRewardedInterstitial();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {},
      );
    } catch (e) {
      debugPrint('Rewarded interstitial show threw: $e');
      ad.dispose();
      _showingFullscreen = false;
      loadRewardedInterstitial();
    }
  }

  bool _canShowFullscreen(Duration gap, {DateTime? last}) {
    final DateTime? stamp = last ?? _lastFullscreenAt;
    if (stamp == null) return true;
    return DateTime.now().difference(stamp) >= gap;
  }

  Future<void> _muteAds() async {
    _adsFreeUntil = DateTime.now().add(AppConfig.rewardedAdFree);
    await _prefs.setInt(
      PrefsService.kAdsFreeUntil,
      _adsFreeUntil!.millisecondsSinceEpoch,
    );
    _banner?.dispose();
    _banner = null;
    _interstitial?.dispose();
    _interstitial = null;
    _rewardedInterstitial?.dispose();
    _rewardedInterstitial = null;
    _appOpen?.dispose();
    _appOpen = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _banner?.dispose();
    _banner = null;
    _interstitial?.dispose();
    _interstitial = null;
    _rewarded?.dispose();
    _rewarded = null;
    _rewardedInterstitial?.dispose();
    _rewardedInterstitial = null;
    _appOpen?.dispose();
    _appOpen = null;
    super.dispose();
  }
}
