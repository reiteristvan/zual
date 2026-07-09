import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/chime_player.dart';
import '../scenes/scene_theme.dart';
import '../settings/setup_preferences.dart';
import '../theme/app_tokens.dart';
import '../timer/timer_controller.dart';
import '../widgets/hold_repeat_button.dart';
import '../widgets/pressable_surface.dart';
import '../widgets/scene_grid.dart';
import 'running_screen.dart';

/// The parent-facing home screen: pick a countdown duration and a scene,
/// then tap Start to launch the timer.
///
/// This plan implements the duration-preset + Start slice (SETUP-01,
/// SETUP-04) and the scene picker (SETUP-03). The custom stepper (Plan 03)
/// extends this screen further, and PERSIST-01 (Plan 04) seeds
/// [initialDurationMin]/[initialTheme] from persisted values and persists the
/// selection again on Start.
class SetupScreen extends StatefulWidget {
  SetupScreen({
    super.key,
    ChimePlayer? chimePlayer,
    ValueNotifier<bool>? soundOn,
    this.initialDurationMin = 5,
    this.initialTheme = SceneTheme.disc,
  }) : chimePlayer = chimePlayer ?? const NoopChimePlayer(),
       soundOn = soundOn ?? ValueNotifier<bool>(true);

  /// Plays the completion chime; forwarded to the [RunningScreen] pushed by
  /// [_handleStart] (Phase 4, so Plan 04-05 can fire it on
  /// `TimerPhase.done`).
  final ChimePlayer chimePlayer;

  /// The shared mute preference; forwarded to the [RunningScreen] pushed by
  /// [_handleStart] so the Parent Controls sheet's mute toggle and the
  /// chime trigger share one source of truth (D-01/D-02).
  final ValueNotifier<bool> soundOn;

  /// The duration (in minutes) pre-selected when this screen first mounts.
  /// Defaults to 5 per D-09's first-launch default; `main()` passes in a
  /// value preloaded from [SetupPreferences.load] instead of this literal
  /// default (PERSIST-01).
  final int initialDurationMin;

  /// The scene theme pre-selected when this screen first mounts. Defaults to
  /// [SceneTheme.disc] per D-09's first-launch default; `main()` passes in a
  /// value preloaded from [SetupPreferences.load] instead of this literal
  /// default (PERSIST-01).
  final SceneTheme initialTheme;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  /// The five fixed preset durations (in minutes) offered on this screen.
  static const List<int> _presets = [1, 5, 10, 15, 30];

  late int _durationMin;

  /// The currently selected scene theme, seeded from [widget.initialTheme]
  /// (PERSIST-01) in [initState].
  late SceneTheme _theme;

  /// Whether the Custom stepper row is currently revealed. Selecting any
  /// numeric preset hides it; selecting "Custom" reveals it. The duration
  /// grid itself never reflows when this toggles (UI-SPEC).
  bool _showCustom = false;

  /// The custom duration in minutes, always kept inside 1..120 by
  /// [_setCustomMin] regardless of the stepper buttons' disable state
  /// (V5 Input Validation, threat T-02-01). Defaults to 3 per UI-SPEC's
  /// `customMin: 3` default the first time the Custom row is shown, and is
  /// not reset by toggling the row closed/open within the same session.
  int _customMin = 3;

  @override
  void initState() {
    super.initState();
    _durationMin = widget.initialDurationMin;
    _theme = widget.initialTheme;
  }

  void _selectPreset(int minutes) {
    setState(() {
      _durationMin = minutes;
      _showCustom = false;
    });
  }

  void _selectCustom() {
    setState(() => _showCustom = true);
  }

  /// The sole write path for [_customMin]. Clamping here — independent of
  /// whichever button the caller thinks is disabled — is the V5 control:
  /// no code path (including a bug in the disable logic, or the stepper's
  /// accelerated repeat overshooting) can push the value outside 1..120.
  void _setCustomMin(int v) {
    _customMin = v.clamp(1, 120);
  }

  void _selectScene(SceneTheme theme) {
    setState(() => _theme = theme);
  }

  /// The duration (in minutes) that Start and the footer label use: the
  /// custom value while the Custom row is open, otherwise the selected
  /// preset.
  int get _selectedMinutes => _showCustom ? _customMin : _durationMin;

  /// Starts the countdown with the currently selected duration and hands off
  /// to [RunningScreen]. Start is a one-line call into [TimerController]'s
  /// existing public API — this screen never reaches into `lib/timer/`
  /// internals.
  ///
  /// Also persists the current selection via [SetupPreferences.persistIfPreset]
  /// (PERSIST-01, D-10): theme is always written; duration is written only
  /// when a preset (not Custom) is the live selection. This is
  /// fire-and-forget — navigation must not wait on it, and a persistence
  /// failure must fail silently (defaults are restored next launch instead)
  /// rather than block or crash the Start flow.
  void _handleStart() {
    context.read<TimerController>().start(_selectedMinutes);
    unawaited(
      SetupPreferences.persistIfPreset(
        showCustom: _showCustom,
        durationMin: _durationMin,
        theme: _theme,
      ).catchError((_) {}),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RunningScreen(
          theme: _theme,
          chimePlayer: widget.chimePlayer,
          soundOn: widget.soundOn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('How long?'),
                    _buildDurationGrid(),
                    if (_showCustom) _buildCustomStepperRow(),
                    const SizedBox(height: 26),
                    _buildSectionLabel('Pick a scene'),
                    SceneGrid(selected: _theme, onSelect: _selectScene),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Fixed header: wordmark + tagline, centered per UI-SPEC (`text-align:
  /// center` in the Layout A reference markup).
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 52, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Zual', style: AppTokens.wordmark),
          SizedBox(height: 4),
          Text('a gentle timer for little ones', style: AppTokens.tagline),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 0, 14),
      child: Text(label, style: AppTokens.sectionLabel),
    );
  }

  /// 3-column grid of the five duration presets plus the "Custom" cell.
  /// Fixed at 6 cells regardless of [_showCustom] — the grid itself never
  /// reflows; the stepper row is a separate widget rendered below it.
  Widget _buildDurationGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [..._presets.map(_buildPresetCard), _buildCustomCard()],
    );
  }

  /// A single preset card: number + unit, with a 3px accent selection ring
  /// drawn as a `Positioned.fill` `IgnorePointer` overlay when this preset is
  /// the current selection (per UI-SPEC's selection-ring contract). Never
  /// shows as selected while the Custom row is open — selection belongs to
  /// exactly one of the six cells at a time.
  Widget _buildPresetCard(int minutes) {
    final selected = !_showCustom && minutes == _durationMin;
    return Stack(
      children: [
        PressableSurface(
          onTap: () => _selectPreset(minutes),
          color: AppTokens.cardSurface,
          pressedColor: AppTokens.pressed,
          borderRadius: AppTokens.buttonRadius,
          boxShadow: AppTokens.cardShadow,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$minutes', style: AppTokens.presetNumber),
              Text('min', style: AppTokens.presetUnit),
            ],
          ),
        ),
        if (selected) _buildSelectionRing(ValueKey('preset-ring-$minutes')),
      ],
    );
  }

  /// The sixth grid cell: "Custom" / "set your own". Selecting it reveals
  /// the stepper row and moves the selection ring here (SETUP-02).
  Widget _buildCustomCard() {
    return Stack(
      children: [
        PressableSurface(
          onTap: _selectCustom,
          color: AppTokens.cardSurface,
          pressedColor: AppTokens.pressed,
          borderRadius: AppTokens.buttonRadius,
          boxShadow: AppTokens.cardShadow,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Custom', style: AppTokens.customLabel),
              Text('set your own', style: AppTokens.customSublabel),
            ],
          ),
        ),
        if (_showCustom) _buildSelectionRing(const ValueKey('custom-ring')),
      ],
    );
  }

  Widget _buildSelectionRing(Key key) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          key: key,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
            border: Border.all(color: AppTokens.accent, width: 3),
          ),
        ),
      ),
    );
  }

  /// The revealed Custom stepper row: "−" / value+unit / "+", per UI-SPEC's
  /// Custom stepper spacing (14px padding, 14px top margin, 20px internal
  /// gap). Rendered below the grid so the grid itself never reflows.
  Widget _buildCustomStepperRow() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.cardSurface,
        borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepperButton(
            key: const ValueKey('stepper-minus'),
            glyph: '−',
            enabled: _customMin > 1,
            onStep: () => setState(() => _setCustomMin(_customMin - 1)),
          ),
          const SizedBox(width: 20),
          _buildStepperValue(),
          const SizedBox(width: 20),
          _buildStepperButton(
            key: const ValueKey('stepper-plus'),
            glyph: '+',
            enabled: _customMin < 120,
            onStep: () => setState(() => _setCustomMin(_customMin + 1)),
          ),
        ],
      ),
    );
  }

  /// A single 48px circular stepper button. Disabled buttons render at
  /// ~35% opacity on both fill and glyph and do not respond to tap/hold —
  /// `enabled: false` on [HoldRepeatButton] both drives the visual dimming
  /// here and excludes the button from tap handling.
  Widget _buildStepperButton({
    required Key key,
    required String glyph,
    required bool enabled,
    required VoidCallback onStep,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: HoldRepeatButton(
        key: key,
        enabled: enabled,
        onStep: onStep,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppTokens.stepperFill,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(glyph, style: AppTokens.stepperGlyph),
        ),
      ),
    );
  }

  Widget _buildStepperValue() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$_customMin',
          key: const ValueKey('stepper-value'),
          style: AppTokens.stepperValue,
        ),
        Text('minutes', style: AppTokens.stepperUnit),
      ],
    );
  }

  /// Fixed footer: the Start button, showing the currently selected
  /// duration as two text runs ("Start" + "· {N} min") per UI-SPEC. Uses
  /// [PressableSurface] rather than `ElevatedButton` so the pressed fill
  /// matches the UI-SPEC's exact `#6E9A68` (Android has no hover — the
  /// design's `hover` state is treated as the pressed state).
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
      child: Container(
        decoration: const BoxDecoration(boxShadow: AppTokens.startShadow),
        child: SizedBox(
          width: double.infinity,
          child: PressableSurface(
            key: const ValueKey('start-button'),
            onTap: _handleStart,
            color: AppTokens.accent,
            pressedColor: AppTokens.accentPressed,
            borderRadius: AppTokens.startRadius,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Start', style: AppTokens.startLabelStyle),
                const SizedBox(width: 6),
                Text('· $_selectedMinutes min', style: AppTokens.startSuffix),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
