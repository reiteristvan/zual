import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../scenes/scene_theme.dart';
import '../theme/app_tokens.dart';
import '../timer/timer_controller.dart';
import '../widgets/hold_repeat_button.dart';
import '../widgets/scene_grid.dart';
import 'placeholder_running_screen.dart';

/// The parent-facing home screen: pick a countdown duration and a scene,
/// then tap Start to launch the timer.
///
/// This plan implements the duration-preset + Start slice (SETUP-01,
/// SETUP-04) and the scene picker (SETUP-03). The custom stepper (Plan 03)
/// and persisted last-used defaults (Plan 04) extend this screen further
/// without replacing it.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, this.initialDurationMin = 5});

  /// The duration (in minutes) pre-selected when this screen first mounts.
  /// Defaults to 5 per D-09's first-launch default; Plan 04 passes in a
  /// persisted value instead of this literal default.
  final int initialDurationMin;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  /// The five fixed preset durations (in minutes) offered on this screen.
  static const List<int> _presets = [1, 5, 10, 15, 30];

  late int _durationMin;

  /// The currently selected scene theme. Defaults to [SceneTheme.disc] per
  /// D-09's first-launch default; Plan 04 will pass in a persisted value
  /// instead of this literal default.
  SceneTheme _theme = SceneTheme.disc;

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
  /// to the placeholder running screen. Start is a one-line call into
  /// [TimerController]'s existing public API — this screen never reaches
  /// into `lib/timer/` internals.
  void _handleStart() {
    context.read<TimerController>().start(_selectedMinutes);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlaceholderRunningScreen()),
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

  /// Fixed header: wordmark + tagline.
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    return GestureDetector(
      onTap: () => _selectPreset(minutes),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTokens.cardSurface,
              borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
              boxShadow: AppTokens.cardShadow,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            alignment: Alignment.center,
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
      ),
    );
  }

  /// The sixth grid cell: "Custom" / "set your own". Selecting it reveals
  /// the stepper row and moves the selection ring here (SETUP-02).
  Widget _buildCustomCard() {
    return GestureDetector(
      onTap: _selectCustom,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTokens.cardSurface,
              borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
              boxShadow: AppTokens.cardShadow,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            alignment: Alignment.center,
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
      ),
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
  /// duration as two text runs ("Start" + "· {N} min") per UI-SPEC.
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
      child: Container(
        decoration: const BoxDecoration(boxShadow: AppTokens.startShadow),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const ValueKey('start-button'),
            onPressed: _handleStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.accent,
              padding: const EdgeInsets.all(20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.startRadius),
              ),
            ),
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
