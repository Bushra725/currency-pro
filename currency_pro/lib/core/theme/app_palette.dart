import 'package:flutter/material.dart';

/// A complete, hand-tuned colour set for one app theme.
///
/// Every screen paints from this object rather than from raw `Colors.*`
/// constants, so adding a new theme is a matter of adding one entry to
/// `theme_catalog.dart` — nothing else has to change.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.id,
    required this.name,
    required this.city,
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.keyFace,
    required this.keyFaceAlt,
    required this.keyText,
    required this.equalsKey,
    required this.up,
    required this.down,
  });

  final String id;
  final String name;
  final String city;
  final Brightness brightness;

  /// Main brand colour — headers, active chips, highlighted amounts.
  final Color primary;
  final Color onPrimary;

  /// Secondary highlight used for links and selected rows.
  final Color accent;

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;

  /// Calculator keypad colours.
  final Color keyFace;
  final Color keyFaceAlt;
  final Color keyText;
  final Color equalsKey;

  /// Rate movement colours.
  final Color up;
  final Color down;

  bool get isDark => brightness == Brightness.dark;

  Color get shadow => isDark ? Colors.black54 : Colors.black12;

  Color get scrim => isDark
      ? Colors.white.withOpacity(0.06)
      : Colors.black.withOpacity(0.04);

  // ---------------------------------------------------------------------
  // Derived design tokens
  //
  // These are computed from the colours above so a new theme still only has
  // to define the base set. They give the UI soft, borderless surfaces
  // instead of the hairline strokes the first version used.
  // ---------------------------------------------------------------------

  /// Barely-there separator. Used only where a rule genuinely helps
  /// scanning; most surfaces now rely on spacing and fill instead.
  Color get hairline => outline.withOpacity(isDark ? 0.45 : 0.55);

  /// A panel that should read as lifted above [surface].
  Color get surfaceHigh => isDark
      ? Color.lerp(surface, Colors.white, 0.05) ?? surface
      : Color.lerp(surface, Colors.black, 0.02) ?? surface;

  /// Tinted wash used behind highlighted values and hero panels.
  Color get primaryWash => primary.withOpacity(isDark ? 0.14 : 0.10);

  /// Stronger tint for selected chips and active rows.
  Color get primarySoft => primary.withOpacity(isDark ? 0.22 : 0.16);

  /// Coloured halo behind the logo and primary buttons.
  Color get glow => primary.withOpacity(isDark ? 0.30 : 0.22);

  /// Soft drop shadow for cards. Deliberately wide and low-opacity so it
  /// reads as depth rather than as an outline.
  List<BoxShadow> get cardShadow => <BoxShadow>[
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.35)
              : Colors.black.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Tighter shadow for keypad keys and small controls.
  List<BoxShadow> get keyShadow => <BoxShadow>[
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.28)
              : Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Background gradient used by the splash, onboarding and hero panels.
  List<Color> get heroGradient => <Color>[
        Color.lerp(background, primary, isDark ? 0.10 : 0.07) ?? background,
        background,
        Color.lerp(background, accent, isDark ? 0.07 : 0.05) ?? background,
      ];

  /// Gradient used on the brand mark and primary call-to-action.
  List<Color> get brandGradient => <Color>[primary, accent];

  @override
  AppPalette copyWith({
    String? id,
    String? name,
    String? city,
    Brightness? brightness,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? keyFace,
    Color? keyFaceAlt,
    Color? keyText,
    Color? equalsKey,
    Color? up,
    Color? down,
  }) {
    return AppPalette(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      keyFace: keyFace ?? this.keyFace,
      keyFaceAlt: keyFaceAlt ?? this.keyFaceAlt,
      keyText: keyText ?? this.keyText,
      equalsKey: equalsKey ?? this.equalsKey,
      up: up ?? this.up,
      down: down ?? this.down,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppPalette(
      id: t < 0.5 ? id : other.id,
      name: t < 0.5 ? name : other.name,
      city: t < 0.5 ? city : other.city,
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      accent: c(accent, other.accent),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      outline: c(outline, other.outline),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      keyFace: c(keyFace, other.keyFace),
      keyFaceAlt: c(keyFaceAlt, other.keyFaceAlt),
      keyText: c(keyText, other.keyText),
      equalsKey: c(equalsKey, other.equalsKey),
      up: c(up, other.up),
      down: c(down, other.down),
    );
  }
}

/// `context.palette` shorthand used throughout the UI.
extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? kFallbackPalette;
}

/// Used only if a screen is built outside the themed subtree (tests, etc.).
const AppPalette kFallbackPalette = AppPalette(
  id: 'fallback',
  name: 'Amber Night',
  city: 'Default',
  brightness: Brightness.dark,
  primary: Color(0xFFFFB020),
  onPrimary: Color(0xFF1A1206),
  accent: Color(0xFFFF8A3D),
  background: Color(0xFF0E1013),
  surface: Color(0xFF16191F),
  surfaceAlt: Color(0xFF1F242C),
  outline: Color(0xFF2C323C),
  textPrimary: Color(0xFFF2F4F7),
  textSecondary: Color(0xFF9AA3B2),
  keyFace: Color(0xFF1C2027),
  keyFaceAlt: Color(0xFF262C35),
  keyText: Color(0xFFF2F4F7),
  equalsKey: Color(0xFFE5484D),
  up: Color(0xFF3DD68C),
  down: Color(0xFFE5484D),
);
