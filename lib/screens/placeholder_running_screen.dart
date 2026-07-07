import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_tokens.dart';
import '../timer/timer_controller.dart';
import '../timer/timer_phase.dart';

/// Minimal, inert Start-destination stand-in (D-01..D-04).
///
/// Phase 3 replaces this entire body with the real Shrinking Disc scene;
/// Phase 4 layers real Parent Controls on top. Deliberately unpolished: a
/// single flat accent circle shrinking with progress, a plain back control,
/// and an auto-return on completion — no color zones, no long-press, no
/// pause/resume (D-03).
class PlaceholderRunningScreen extends StatefulWidget {
  const PlaceholderRunningScreen({super.key});

  @override
  State<PlaceholderRunningScreen> createState() => _PlaceholderRunningScreenState();
}

class _PlaceholderRunningScreenState extends State<PlaceholderRunningScreen> {
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

  /// Back control per D-02: end the timer and return to Setup immediately,
  /// with no confirmation dialog. This is not the real Phase 4 Parent
  /// Controls UX (no long-press, no bottom sheet) — it exists only so the
  /// screen is usable/testable before Phase 4 lands.
  void _handleBack() {
    context.read<TimerController>().endTimer();
    _leaveOnce();
  }

  /// Auto-returns to Setup once the controller reaches [TimerPhase.done]
  /// (D-04), scheduled via a post-frame callback since navigating away is
  /// not safe to do synchronously from inside `build`.
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

    final remaining = (1 - controller.progress).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Stack(
        children: [
          Center(
            child: Transform.scale(
              scale: remaining,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  color: AppTokens.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
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
