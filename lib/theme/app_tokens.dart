import 'package:flutter/material.dart';

/// Design-token constants transcribed verbatim from
/// `.planning/phases/02-setup-screen/02-UI-SPEC.md` and `design/README.md`.
///
/// Centralizing these as static consts (rather than scattering hex literals
/// across widgets) keeps the Setup/placeholder-running screens pixel-accurate
/// to the design spec and gives later plans a single place to update.
///
/// Fonts: Baloo 2 (700) for the wordmark only; Quicksand (400/500/600/700)
/// for every other text style. Both are bundled as local `.ttf` assets under
/// `assets/fonts/` and declared in `pubspec.yaml`'s `flutter: fonts:` section
/// — no `google_fonts` runtime fetch, the app renders text fully offline.
abstract class AppTokens {
  /// Wordmark-only display font.
  static const String fontBaloo = 'Baloo 2';

  /// Every other text style's font.
  static const String fontQuicksand = 'Quicksand';

  // Colors
  /// Dominant (60%) app/screen background — Setup and placeholder Running
  /// screen alike, for visual continuity.
  static const Color bg = Color(0xFFF6EBDD);

  /// Secondary (30%) card surface — preset buttons, Custom button, scene
  /// cards.
  static const Color cardSurface = Color(0xFFFFFCF6);

  /// Secondary-alt surface — Custom stepper minus/plus circular buttons.
  static const Color stepperFill = Color(0xFFF1E6D3);

  /// Accent (10%) — Start button fill, 3px selection ring, disc preview.
  static const Color accent = Color(0xFF7FA87A);

  /// Start button pressed/touch-feedback state.
  static const Color accentPressed = Color(0xFF6E9A68);

  /// Primary text ink.
  static const Color ink = Color(0xFF4B4038);

  /// Secondary/soft text ink (units, sublabels, tagline).
  static const Color inkSoft = Color(0xFF93826F);

  /// Pressed/touch feedback for preset, Custom, and scene-card buttons.
  static const Color pressed = Color(0xFFFFF7E9);

  /// Start button label color.
  static const Color startLabel = Color(0xFFFFFDF7);

  /// Parent Controls sheet fill (`design/README.md` §G).
  static const Color sheetBg = Color(0xFFFBF4E8);

  /// End timer button fill — the first genuine destructive-action use of
  /// this hex (`04-UI-SPEC.md` Color table).
  static const Color destructive = Color(0xFFE0805F);

  /// End timer button pressed/touch-feedback state.
  static const Color destructivePressed = Color(0xFFD06E4C);

  /// Full-screen scrim behind the Parent Controls sheet:
  /// `rgba(40,32,26,0.42)`.
  static const Color scrim = Color(0x6B28201A);

  /// "All done" pill surface: `rgba(255,253,247,0.94)`.
  static const Color pillSurface = Color(0xF0FFFDF7);

  /// Parent Controls sheet grab handle: `rgba(75,64,56,0.2)`.
  static const Color grabHandle = Color(0x334B4038);

  // Radii
  /// Preset/Custom button and Start button corner radius baseline.
  static const double buttonRadius = 22;

  /// Card corner radius (scene cards, per UI-SPEC).
  static const double cardRadius = 26;

  /// Start button corner radius.
  static const double startRadius = 26;

  /// Scene mini-preview corner radius.
  static const double sceneThumbRadius = 16;

  // Shadows
  /// Start button drop shadow: `0 8px 20px rgba(127,168,122,0.4)`.
  static const List<BoxShadow> startShadow = [
    BoxShadow(
      color: Color(0x667FA87A),
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
  ];

  /// Card drop shadow: `0 2px 6px rgba(75,64,56,0.05)`.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D4B4038),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  /// Parent Controls sheet drop shadow: `0 -10px 40px rgba(0,0,0,0.25)`.
  static const List<BoxShadow> sheetShadow = [
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, -10),
      blurRadius: 40,
    ),
  ];

  // Text styles
  /// Wordmark "Zual" — 36/700, Baloo 2 (the only Baloo 2 usage in the app).
  static const TextStyle wordmark = TextStyle(
    fontFamily: fontBaloo,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: accent,
    letterSpacing: 0.5,
    height: 1.0,
  );

  /// Tagline "a gentle timer for little ones" — 13/500, soft ink.
  static const TextStyle tagline = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: inkSoft,
  );

  /// Section label ("How long?" / "Pick a scene") — 16/700, ink.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  /// Preset button number (e.g. "5") — 30/700, ink.
  static const TextStyle presetNumber = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.05,
  );

  /// Preset button unit ("min") — 12/600, soft ink.
  static const TextStyle presetUnit = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: inkSoft,
  );

  /// Scene card label (e.g. "Shrinking disc") — 13/700, ink, left-aligned.
  static const TextStyle sceneCardLabel = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  /// Start label ("Start") — 21/700, start label color.
  static const TextStyle startLabelStyle = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: startLabel,
  );

  /// Start suffix ("· {N} min") — 15/600, start label color @0.85 opacity.
  static const TextStyle startSuffix = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xD9FFFDF7), // startLabel @ ~0.85 opacity
  );

  /// "Custom" button label — 19/700, ink.
  static const TextStyle customLabel = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.05,
  );

  /// "Custom" button sublabel ("set your own") — 11/600, soft ink.
  static const TextStyle customSublabel = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: inkSoft,
  );

  /// Custom stepper glyphs ("−"/"+") — 26/700, ink.
  static const TextStyle stepperGlyph = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.0,
  );

  /// Custom stepper value (e.g. "12") — 36/700, ink.
  static const TextStyle stepperValue = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.0,
  );

  /// Custom stepper unit ("minutes") — 12/600, soft ink. Same values as
  /// [presetUnit] today (both are "small soft-ink unit captions" per
  /// UI-SPEC); kept as its own named token since the two roles are free to
  /// diverge later without one accidentally changing the other.
  static const TextStyle stepperUnit = TextStyle(
    fontFamily: fontQuicksand,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: inkSoft,
  );
}
