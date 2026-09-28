import 'package:flutter/material.dart';

/// The CurrencyPro launcher mark, used in the splash, onboarding, drawer
/// and app bars so the in-app icon matches the home-screen icon.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 40,
    this.radius,
  });

  final double size;
  final double? radius;

  static const String assetPath = 'assets/icon/app_icon.png';

  @override
  Widget build(BuildContext context) {
    final double r = radius ?? size * 0.22;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}
