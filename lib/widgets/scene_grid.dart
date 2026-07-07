import 'package:flutter/material.dart';

import '../scenes/scene_preview.dart';
import '../scenes/scene_theme.dart';
import '../theme/app_tokens.dart';
import 'pressable_surface.dart';

/// A single selectable scene card: a static mini-preview above a
/// left-aligned label, with the shared 3px accent selection ring when
/// [selected].
///
/// Depends only on the [ScenePreviewPainter] abstraction (D-06) — never on a
/// concrete painter type (e.g. `DiscPreviewPainter`) by name, so Phase 3 can
/// swap in the real scene-at-progress-0 renderer without touching this file.
///
/// Delegates pressed/touch-feedback tracking (swap fill to `#FFF7E9` while
/// held, per the UI-SPEC's pressed-state contract — Android has no hover,
/// so the design's `hover` state is treated as the pressed state here) to
/// the shared [PressableSurface], rather than tracking `_pressed` itself,
/// so the Setup screen's preset/Custom/Start surfaces and this card share
/// exactly one implementation of that contract.
class SceneCard extends StatelessWidget {
  const SceneCard({
    super.key,
    required this.preview,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// The painter drawing this card's static preview.
  final ScenePreviewPainter preview;

  /// The exact scene-card copy, e.g. "Shrinking disc".
  final String label;

  /// Whether this card is the current single selection.
  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PressableSurface(
          onTap: onTap,
          color: AppTokens.cardSurface,
          pressedColor: AppTokens.pressed,
          borderRadius: AppTokens.cardRadius,
          boxShadow: AppTokens.cardShadow,
          padding: const EdgeInsets.all(10),
          alignment: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppTokens.sceneThumbRadius,
                ),
                child: SizedBox(
                  height: 74,
                  width: double.infinity,
                  child: CustomPaint(painter: preview),
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: AppTokens.sceneCardLabel),
            ],
          ),
        ),
        if (selected) _buildSelectionRing(),
      ],
    );
  }

  Widget _buildSelectionRing() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          key: ValueKey('scene-ring-${label.toLowerCase()}'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppTokens.accent, width: 3),
          ),
        ),
      ),
    );
  }
}

/// The 2x2 grid of the four scene-selection cards.
///
/// Owns the theme->label and theme->painter mappings (the one place allowed
/// to reference concrete painter types by name, per D-06) and hands each
/// [SceneCard] only the painter it needs.
class SceneGrid extends StatelessWidget {
  const SceneGrid({super.key, required this.selected, required this.onSelect});

  /// The currently selected theme.
  final SceneTheme selected;

  /// Invoked with the newly tapped theme; the caller owns selection state.
  final ValueChanged<SceneTheme> onSelect;

  /// Exact scene-card copy, verbatim from `02-UI-SPEC.md`.
  static const Map<SceneTheme, String> _labels = {
    SceneTheme.disc: 'Shrinking disc',
    SceneTheme.sunrise: 'Night to sunrise',
    SceneTheme.walk: 'Walking home',
    SceneTheme.car: 'Car on a road',
  };

  static const Map<SceneTheme, ScenePreviewPainter> _painters = {
    SceneTheme.disc: DiscPreviewPainter(),
    SceneTheme.sunrise: SunrisePreviewPainter(),
    SceneTheme.walk: WalkPreviewPainter(),
    SceneTheme.car: CarPreviewPainter(),
  };

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: SceneTheme.values.map((theme) {
        return SceneCard(
          preview: _painters[theme]!,
          label: _labels[theme]!,
          selected: theme == selected,
          onTap: () => onSelect(theme),
        );
      }).toList(),
    );
  }
}
