import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../scenes/scene_theme.dart';
import '../theme/app_tokens.dart';
import '../timer/timer_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _durationMin = widget.initialDurationMin;
  }

  void _selectPreset(int minutes) {
    setState(() => _durationMin = minutes);
  }

  void _selectScene(SceneTheme theme) {
    setState(() => _theme = theme);
  }

  /// Starts the countdown with the currently selected duration and hands off
  /// to the placeholder running screen. Start is a one-line call into
  /// [TimerController]'s existing public API — this screen never reaches
  /// into `lib/timer/` internals.
  void _handleStart() {
    context.read<TimerController>().start(_durationMin);
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

  /// 3-column grid of the five duration presets.
  Widget _buildDurationGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: _presets.map(_buildPresetCard).toList(),
    );
  }

  /// A single preset card: number + unit, with a 3px accent selection ring
  /// drawn as a `Positioned.fill` `IgnorePointer` overlay when this preset is
  /// the current selection (per UI-SPEC's selection-ring contract).
  Widget _buildPresetCard(int minutes) {
    final selected = minutes == _durationMin;
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
          if (selected) _buildSelectionRing(minutes),
        ],
      ),
    );
  }

  Widget _buildSelectionRing(int minutes) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          key: ValueKey('preset-ring-$minutes'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
            border: Border.all(color: AppTokens.accent, width: 3),
          ),
        ),
      ),
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
                Text('· $_durationMin min', style: AppTokens.startSuffix),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
