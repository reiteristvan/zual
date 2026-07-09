import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/chime_player.dart';
import '../scenes/scene_registry.dart';
import '../scenes/scene_theme.dart';
import '../settings/setup_preferences.dart';
import '../theme/app_tokens.dart';
import '../timer/timer_controller.dart';
import '../timer/timer_phase.dart';

/// The 850ms hidden long-press threshold (CTRL-01, `04-UI-SPEC.md` §Sheet
/// Contract's locked `LongPressGestureRecognizer(duration:)` value). Factored
/// out to its own constructor function so [RawGestureDetector]'s
/// `GestureRecognizerFactoryWithHandlers` can take it as a tear-off.
LongPressGestureRecognizer _buildParentControlsRecognizer() =>
    LongPressGestureRecognizer(duration: const Duration(milliseconds: 850));

/// The real child-facing running screen (replaces [PlaceholderRunningScreen]
/// as Start's navigation destination): hosts the animated scene for
/// [theme] via [sceneFor], full-bleed behind the composition root's parent
/// controls gate.
///
/// Composition-root responsibilities live here, never inside a scene
/// (SCENE-05): the hidden long-press -> Parent Controls sheet gate replaces
/// the Phase 3 scaffolding's visible back `IconButton` outright (deleted,
/// not kept as a fallback).
///
/// [PlaceholderRunningScreen]: package:zual/screens/placeholder_running_screen.dart
class RunningScreen extends StatefulWidget {
  const RunningScreen({
    super.key,
    required this.theme,
    required this.chimePlayer,
    required this.soundOn,
  });

  /// The scene theme selected on Setup, threaded through to [sceneFor].
  final SceneTheme theme;

  /// Plays the completion chime once `TimerPhase.done` is reached (wired in
  /// Plan 04-05); injected so widget tests never touch a real platform
  /// channel (mirrors [ScreenWake]'s interface-wraps-a-plugin shape).
  final ChimePlayer chimePlayer;

  /// The shared mute preference. Read by the Parent Controls sheet's mute
  /// toggle and by the chime trigger (Plan 04-05) so both share one source
  /// of truth (D-01/D-02).
  final ValueNotifier<bool> soundOn;

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  /// Guards *both* exit paths (the Parent Controls sheet's End timer button
  /// and the auto-pop-on-done post-frame callback) so at most one of them
  /// ever calls `Navigator.pop()`. `build` (and therefore the auto-pop
  /// check) re-runs on every [TimerController] notification while phase
  /// stays [TimerPhase.done], and `mounted` alone does not become `false`
  /// synchronously on `pop()` -- a sheet-driven exit can race an
  /// already-scheduled auto-pop callback and both would otherwise fire.
  bool _leftScreen = false;

  /// Pops exactly once, regardless of which exit path (Parent Controls'
  /// End timer or auto-pop-on-done) reaches it first.
  void _leaveOnce() {
    if (_leftScreen) return;
    _leftScreen = true;
    Navigator.of(context).pop();
  }

  /// Auto-returns to Setup once the controller reaches [TimerPhase.done],
  /// scheduled via a post-frame callback since navigating away is not safe
  /// to do synchronously from inside `build`.
  void _maybeAutoPopWhenDone(TimerPhase phase) {
    if (phase != TimerPhase.done || _leftScreen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _leaveOnce();
    });
  }

  /// Opens the Parent Controls sheet (CTRL-01/CTRL-02), triggered by a
  /// silent ~850ms long-press anywhere on the screen (D-08). Blurred via
  /// [BackdropFilter] since [showModalBottomSheet]'s `barrierColor` alone
  /// only paints a flat scrim, not a blur (`04-RESEARCH.md` Pattern 2).
  void _openParentControls() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppTokens.scrim,
      builder: (sheetContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: _ParentControlsSheet(
          soundOn: widget.soundOn,
          onEndTimer: _leaveOnce,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimerController>();
    _maybeAutoPopWhenDone(controller.phase);
    final gestureEnabled = controller.phase != TimerPhase.done;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: gestureEnabled
                  ? <Type, GestureRecognizerFactory>{
                      LongPressGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            LongPressGestureRecognizer
                          >(
                            _buildParentControlsRecognizer,
                            (recognizer) =>
                                recognizer.onLongPress = _openParentControls,
                          ),
                    }
                  : const <Type, GestureRecognizerFactory>{},
              child: sceneFor(widget.theme),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Parent Controls bottom sheet content: grab handle, header (title +
/// mute icon), Pause/Resume, End timer, and Keep watching -- per
/// `04-UI-SPEC.md`'s Parent Controls Sheet Contract layout order.
class _ParentControlsSheet extends StatelessWidget {
  const _ParentControlsSheet({required this.soundOn, required this.onEndTimer});

  final ValueNotifier<bool> soundOn;

  /// Called after this sheet pops itself, so [_RunningScreenState._leaveOnce]
  /// can then pop the now-topmost [RunningScreen] route -- a single
  /// `Navigator.pop()` from inside the sheet would only dismiss the sheet
  /// itself, since it is pushed on top of [RunningScreen] on the same
  /// Navigator stack.
  final VoidCallback onEndTimer;

  void _toggleSound() {
    soundOn.value = !soundOn.value;
    unawaited(SetupPreferences.persistSoundOn(soundOn.value));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimerController>();
    final isRunning = controller.phase == TimerPhase.running;

    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: AppTokens.sheetShadow,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGrabHandle(),
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildPrimaryButton(context, isRunning),
              const SizedBox(height: 12),
              _buildEndTimerButton(context),
              const SizedBox(height: 18),
              _buildKeepWatchingButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrabHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTokens.grabHandle,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Parent controls',
          style: TextStyle(
            fontFamily: AppTokens.fontQuicksand,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTokens.ink,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: soundOn,
          builder: (context, soundOnValue, _) {
            return Semantics(
              label: soundOnValue ? 'Mute sound' : 'Unmute sound',
              button: true,
              child: IconButton(
                onPressed: _toggleSound,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                icon: Icon(
                  soundOnValue ? Icons.volume_up : Icons.volume_off,
                  color: AppTokens.inkSoft,
                  size: 22,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context, bool isRunning) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final ctrl = context.read<TimerController>();
          isRunning ? ctrl.pause() : ctrl.resume();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.accent,
          foregroundColor: AppTokens.startLabel,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          isRunning ? 'Pause' : 'Resume',
          style: const TextStyle(
            fontFamily: AppTokens.fontQuicksand,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEndTimerButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<TimerController>().endTimer();
          Navigator.of(context).pop();
          onEndTimer();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.destructive,
          foregroundColor: AppTokens.startLabel,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: const Text(
          'End timer',
          style: TextStyle(
            fontFamily: AppTokens.fontQuicksand,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildKeepWatchingButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text(
        'Keep watching',
        style: TextStyle(
          fontFamily: AppTokens.fontQuicksand,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTokens.ink,
        ),
      ),
    );
  }
}
