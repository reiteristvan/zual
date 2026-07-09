import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/chime_player.dart';
import '../scenes/scene_registry.dart';
import '../scenes/scene_theme.dart';
import '../theme/app_tokens.dart';
import '../timer/timer_controller.dart';
import '../timer/timer_phase.dart';

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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimerController>();
    _maybeAutoPopWhenDone(controller.phase);

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Stack(
        children: [Positioned.fill(child: sceneFor(widget.theme))],
      ),
    );
  }
}
