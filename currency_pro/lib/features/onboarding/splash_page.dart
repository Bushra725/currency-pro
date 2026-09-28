import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/brand_logo.dart';

/// Branded splash shown after the native launch screen.
///
/// Deliberately stroke-free: the whole screen is one painted gradient with a
/// glow behind the coin. There are no borders, dividers or container edges
/// anywhere, so no hairline can show up between sections.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _coinSpin;
  late final Animation<double> _coinSettle;
  late final Animation<double> _haloFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleRise;
  late final Animation<double> _taglineFade;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    );

    _coinSpin = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _coinSettle = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _haloFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.75, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.68, curve: Curves.easeOut),
    );
    _titleRise = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.34, 0.68, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.46, 0.80, curve: Curves.easeOut),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 1.0, curve: Curves.easeInOut),
    );

    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 1850), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return DecoratedBox(
      // Full-bleed: this paints edge to edge, including behind the status and
      // navigation bars, so there is no seam anywhere on screen.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.heroGradient,
          stops: const <double>[0.0, 0.55, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Soft ambient wash behind the mark.
              Align(
                alignment: const Alignment(0, -0.32),
                child: Opacity(
                  opacity: _haloFade.value * 0.9,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          p.glow,
                          p.primary.withOpacity(0.06),
                          p.primary.withOpacity(0),
                        ],
                        stops: const <double>[0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 5),
                    Transform.scale(
                      scale: _coinSettle.value * _coinSpin.value,
                      child: const BrandLogo(size: 132, radius: 28),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: _titleFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleRise.value),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) => LinearGradient(
                            colors: <Color>[p.textPrimary, p.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            AppConfig.appName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Text(
                        'Live rates · Bitcoin · Gold · Silver',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w500,
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(flex: 5),
                    Opacity(
                      opacity: _haloFade.value,
                      child: _ProgressBar(palette: p, value: _progress.value),
                    ),
                    const SizedBox(height: 44),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Slim determinate bar. A rounded fill, not a rule.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.palette, required this.value});

  final AppPalette palette;
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 4,
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: palette.textSecondary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: palette.brandGradient),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
