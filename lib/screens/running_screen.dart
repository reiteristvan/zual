import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../scenes/scene_registry.dart';
import '../scenes/scene_theme.dart';
import '../theme/app_tokens.dart';
import '../timer/timer_controller.dart';
import '../timer/timer_phase.dart';

/// The real child-facing running screen (replaces [PlaceholderRunningScreen]
/// as Start's navigation destination): hosts the animated scene for
/// [theme] via [sceneFor], full-bleed behind the composition root's back
/// affordance.
///
/// Composition-root responsibilities live here, never inside a scene
/// (SCENE-05): the back IconButton and auto-pop-on-done are ported
/// verbatim from `placeholder_running_screen.dart`. Phase 4 replaces the
/// visible back button with the hidden long-press Parent Controls gate --
/// that affordance must stay on this screen, not migrate into a scene.
///
/// [PlaceholderRunningScreen]: package:zual/screens/placeholder_running_screen.dart
class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key, required this.theme});

  /// The scene theme selected on Setup, threaded through to [sceneFor].
  final SceneTheme theme;

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  /// Guards *both* exit paths (manual back tap and the auto-pop-on-done
  /// post-frame callback) so at most one of them ever calls
  /// `Navigator.pop()`. `build` (and therefore the auto-pop check) re-runs
  /// on every [TimerController] notification while phase stays
  /// [TimerPhase.done], and `mounted` alone does not become `false`
  /// synchronously on `pop()` -- a manual back tap can race an
  /// already-scheduled auto-pop callback and both would otherwise fire.
  bool _leftScreen = false;

  /// Pops exactly once, regardless of which exit path (manual back or
  /// auto-pop-on-done) reaches it first.
  void _leaveOnce() {
    if (_leftScreen) return;
    _leftScreen = true;
    Navigator.of(context).pop();
  }

  /// Back control: end the timer and return to Setup immediately, with no
  /// confirmation dialog. Phase 4 replaces the visible affordance with the
  /// hidden long-press Parent Controls sheet; this stays the exit path
  /// until then.
  void _handleBack() {
    context.read<TimerController>().endTimer();
    _leaveOnce();
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimerController>();
    _maybeAutoPopWhenDone(controller.phase);

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Stack(
        children: [
          Positioned.fill(child: sceneFor(widget.theme)),
          Positioned(
            top: 8,
            left: 8,
            child: Semantics(
              label: 'End timer and return to setup',
              button: true,
              child: IconButton(
                onPressed: _handleBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                icon: const Icon(Icons.arrow_back, color: AppTokens.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
