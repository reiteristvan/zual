import 'package:flutter/material.dart';

/// A tappable surface that swaps its fill to [pressedColor] while held, per
/// the UI-SPEC's pressed/touch-feedback contract (`#FFF7E9` for
/// preset/Custom/scene cards, `#6E9A68` for Start — Android has no hover, so
/// the design's `hover` state is treated as the pressed state here).
///
/// Shared by the Setup screen's preset/Custom/Start surfaces and
/// `SceneCard` so pressed-state tracking (via `onTapDown`/`onTapCancel`/
/// `onTapUp`) lives in exactly one place rather than being duplicated per
/// call site — any future change to the pressed-state contract (timing,
/// color, tap-vs-long-press interaction) only has to be made here.
class PressableSurface extends StatefulWidget {
  const PressableSurface({
    super.key,
    required this.onTap,
    required this.color,
    required this.pressedColor,
    required this.borderRadius,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.boxShadow,
    this.alignment = Alignment.center,
  });

  final VoidCallback onTap;
  final Color color;
  final Color pressedColor;
  final double borderRadius;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow>? boxShadow;

  /// How [child] is aligned within the surface. Defaults to
  /// [Alignment.center] to match the Setup screen's preset/Custom/Start
  /// surfaces; callers whose child should fill the surface unshifted (e.g.
  /// `SceneCard`, which lays out a full-width thumbnail + label column) may
  /// pass `null`.
  final AlignmentGeometry? alignment;

  @override
  State<PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<PressableSurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: Container(
        padding: widget.padding,
        alignment: widget.alignment,
        decoration: BoxDecoration(
          color: _pressed ? widget.pressedColor : widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.boxShadow,
        ),
        child: widget.child,
      ),
    );
  }
}
