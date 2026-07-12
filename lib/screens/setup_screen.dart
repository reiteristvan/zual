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

  /// The maximum width the setup content column is allowed to occupy. The
  /// whole design was tuned to the `design/README.md` reference frame (402px
  /// wide, phone-class); left unbounded, the two grids stretch to the full
  /// screen width on tablets, so the grid CELLS grow while their fixed-size
  /// interior content (preset fonts, scene thumbnail) does not — producing
  /// oversized preset squares with tiny text and scene artwork that fills only
  /// a fraction of the card. Capping the column to a phone-class width and
  /// centering it keeps every cell — and therefore its interior balance —
  /// phone-proportioned on tablets. Chosen slightly above the reference frame
  /// so no real phone (which are all narrower) is ever affected; only
  /// genuinely wide screens (tablets) are reined in.
  static const double _maxContentWidth = 440;

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
        child: LayoutBuilder(
          builder: (context, bodyConstraints) {
            // Cap the content column to a phone-class width and center it, so
            // grid cells stay phone-proportioned on tablets (see
            // [_maxContentWidth]). On phones this is a no-op (the screen is
            // narrower than the cap, so [layoutWidth] == the full width).
            final layoutWidth = bodyConstraints.maxWidth < _maxContentWidth
                ? bodyConstraints.maxWidth
                : _maxContentWidth;
            final contentWidth = layoutWidth - 44;
            final footerHeight = _measureFooterHeight(context);

            // Baseline header top padding per the design formula: scales
            // down on short viewports (min 24, design default 52).
            final baselineHeaderTop = (MediaQuery.sizeOf(context).height * 0.055)
                .clamp(24.0, 52.0);
            final baselineHeaderHeight =
                baselineHeaderTop + 8 + _headerContentHeight(context, layoutWidth - 48);
            final baselineScrollRegionHeight =
                bodyConstraints.maxHeight - baselineHeaderHeight - footerHeight;

            final gap = (baselineScrollRegionHeight * 0.03).clamp(12.0, 26.0);
            final durationAspectRatio = _computeDurationAspectRatio(
              context: context,
              availableHeight: baselineScrollRegionHeight,
              contentWidth: contentWidth,
            );
            final sceneAspectRatio = _computeSceneAspectRatio(
              context: context,
              availableHeight: baselineScrollRegionHeight,
              contentWidth: contentWidth,
              gap: gap,
              durationAspectRatio: durationAspectRatio,
            );

            // The scroll region's true required height given the ratios
            // just chosen (which are themselves already capped so no card
            // content overflows its cell). If this still exceeds what the
            // baseline header leaves available -- which can happen once
            // real font metrics are accounted for -- shrink the header
            // further (down to a hard floor) rather than let the
            // SingleChildScrollView safety net absorb an avoidable
            // shortfall.
            final requiredScrollRegionHeight = _requiredScrollRegionHeight(
              context: context,
              contentWidth: contentWidth,
              gap: gap,
              durationAspectRatio: durationAspectRatio,
              sceneAspectRatio: sceneAspectRatio,
            );
            final shortfall =
                requiredScrollRegionHeight - baselineScrollRegionHeight;
            final headerTopPadding = shortfall > 0
                ? (baselineHeaderTop - shortfall).clamp(16.0, 52.0)
                : baselineHeaderTop;

            return Center(
              child: SizedBox(
                width: layoutWidth,
                height: bodyConstraints.maxHeight,
                child: Column(
                  children: [
                    _buildHeader(headerTopPadding),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('setup-scroll'),
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('How long?'),
                            _buildDurationGrid(durationAspectRatio),
                            if (_showCustom) _buildCustomStepperRow(),
                            SizedBox(height: gap),
                            _buildSectionLabel('Pick a scene'),
                            SceneGrid(
                              selected: _theme,
                              onSelect: _selectScene,
                              childAspectRatio: sceneAspectRatio,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Fixed header: wordmark + tagline, centered per UI-SPEC (`text-align:
  /// center` in the Layout A reference markup). [topPadding] scales down on
  /// short viewports (min 24, design default 52, occasionally shrunk
  /// further down to 16 when [build] finds the scroll region still short on
  /// space after accounting for real font metrics) to reclaim height for
  /// the scroll region below.
  Widget _buildHeader(double topPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 8),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Zual', style: AppTokens.wordmark),
          SizedBox(height: 4),
          Text('a gentle timer for little ones', style: AppTokens.tagline),
        ],
      ),
    );
  }

  /// The header's own content height (wordmark + 4px gap + tagline),
  /// excluding its padding -- used to predict the header's total footprint
  /// before it is built, so [build] can decide whether to shrink its top
  /// padding further. Measures the tagline with the header's real available
  /// width (screen width minus its 24+24 horizontal padding): the tagline
  /// string is wide enough to wrap to two lines on narrow screens, and an
  /// unconstrained measurement would silently under-count that.
  double _headerContentHeight(BuildContext context, double headerContentWidth) {
    return _measureTextHeight(
          context,
          'Zual',
          AppTokens.wordmark,
          maxWidth: headerContentWidth,
        ) +
        4 +
        _measureTextHeight(
          context,
          'a gentle timer for little ones',
          AppTokens.tagline,
          maxWidth: headerContentWidth,
        );
  }

  /// Estimates the footer's total height (padding + the Start button's own
  /// padding + label row), used to predict how much vertical space remains
  /// for the header + scroll region.
  double _measureFooterHeight(BuildContext context) {
    final labelHeight = _measureTextHeight(
      context,
      'Start',
      AppTokens.startLabelStyle,
    );
    final suffixHeight = _measureTextHeight(
      context,
      '· 999 min',
      AppTokens.startSuffix,
    );
    final rowHeight = labelHeight > suffixHeight ? labelHeight : suffixHeight;
    // Padding.fromLTRB(22,14,22,26) vertical (14+26=40) + PressableSurface
    // padding.all(20) vertical (40) + row content.
    return 40 + 40 + rowHeight;
  }

  /// The scroll region's true required height for the given [gap],
  /// [durationAspectRatio], and [sceneAspectRatio] -- i.e. the same
  /// fixed-cost budget [_computeSceneAspectRatio] uses internally, plus the
  /// scene grid's actual height at the ratio that was ultimately chosen.
  double _requiredScrollRegionHeight({
    required BuildContext context,
    required double contentWidth,
    required double gap,
    required double durationAspectRatio,
    required double sceneAspectRatio,
  }) {
    final fixedCost = _fixedCostAboveScene(
      context: context,
      contentWidth: contentWidth,
      gap: gap,
      durationAspectRatio: durationAspectRatio,
    );
    final sceneCellWidth = (contentWidth - 12) / 2;
    final sceneGridHeight = 2 * (sceneCellWidth / sceneAspectRatio) + 12;
    return fixedCost + sceneGridHeight;
  }

  /// The scroll region's fixed vertical cost above the scene grid: scroll
  /// padding, both section labels, the duration grid, the responsive gap,
  /// and (when shown) the custom stepper row.
  double _fixedCostAboveScene({
    required BuildContext context,
    required double contentWidth,
    required double gap,
    required double durationAspectRatio,
  }) {
    final durationCellWidth = (contentWidth - 24) / 3;
    final durationGridHeight =
        2 * (durationCellWidth / durationAspectRatio) + 12;

    final sectionLabelHeight =
        _measureTextHeight(context, 'Hg', AppTokens.sectionLabel) + 14;

    var fixedCost =
        12 + // scroll padding top
        4 + // scroll padding bottom
        (sectionLabelHeight * 2) + // "How long?" + "Pick a scene" labels
        durationGridHeight +
        gap;

    if (_showCustom) {
      fixedCost += _measureStepperRowHeight(context);
    }
    return fixedCost;
  }

  /// The exact scene-card labels, mirrored from `SceneGrid._labels` (kept as
  /// a duplicate literal list here rather than exposing new public API on
  /// [SceneGrid], per this plan's directive not to touch its theme->label
  /// mapping). Used only to measure the worst-case wrapped label height for
  /// the fit-to-space scene aspect ratio below.
  static const List<String> _sceneLabelsForMeasurement = [
    'Shrinking disc',
    'Night to sunrise',
    'Walking home',
    'Car on a road',
  ];

  /// Computes the "How long?" duration grid's `childAspectRatio`: the
  /// design's height-based default (1.1 tall / 1.2 short), reduced further
  /// only if the actual rendered cell content (worst case: the "Custom" /
  /// "set your own" pair, which can wrap on narrow cells) would otherwise
  /// overflow the cell. Uses real [TextPainter] measurement rather than a
  /// guessed constant so this tracks the bundled fonts' real metrics and any
  /// text wrap, on-device as well as in tests.
  double _computeDurationAspectRatio({
    required BuildContext context,
    required double availableHeight,
    required double contentWidth,
  }) {
    final baseRatio = availableHeight >= 640 ? 1.1 : 1.2;
    final cellWidth = (contentWidth - 24) / 3;
    final interiorWidth = cellWidth - 12; // horizontal padding 6 * 2
    if (cellWidth <= 0 || interiorWidth <= 0) return baseRatio;

    final presetHeight =
        _measureTextHeight(
          context,
          '30',
          AppTokens.presetNumber,
          maxWidth: interiorWidth,
        ) +
        _measureTextHeight(
          context,
          'min',
          AppTokens.presetUnit,
          maxWidth: interiorWidth,
        );
    final customHeight =
        _measureTextHeight(
          context,
          'Custom',
          AppTokens.customLabel,
          maxWidth: interiorWidth,
        ) +
        _measureTextHeight(
          context,
          'set your own',
          AppTokens.customSublabel,
          maxWidth: interiorWidth,
        );
    final contentHeight =
        (presetHeight > customHeight ? presetHeight : customHeight) +
        32; // vertical padding 16 * 2

    if (contentHeight <= 0) return baseRatio;
    final maxSafeRatio = cellWidth / contentHeight;
    return baseRatio < maxSafeRatio ? baseRatio : maxSafeRatio;
  }

  /// Computes a fit-to-space `childAspectRatio` for [SceneGrid] so the scene
  /// picker consumes only the vertical space left over after the duration
  /// grid, both section labels, the responsive gap, and (when shown) the
  /// custom stepper row. The design's preferred range is `[1.35, 2.4]` —
  /// 1.35 keeps scene cards no taller than the design's default; 2.4
  /// prevents ultra-flat cards on tiny screens, where the
  /// `SingleChildScrollView` safety net then absorbs any residual overflow —
  /// but the result is further capped so the actual rendered card content
  /// (thumbnail + label, including any label line-wrap on narrow cells)
  /// never overflows the cell, even if that means going below 1.35.
  double _computeSceneAspectRatio({
    required BuildContext context,
    required double availableHeight,
    required double contentWidth,
    required double gap,
    required double durationAspectRatio,
  }) {
    final fixedCost = _fixedCostAboveScene(
      context: context,
      contentWidth: contentWidth,
      gap: gap,
      durationAspectRatio: durationAspectRatio,
    );

    final sceneCellWidth = (contentWidth - 12) / 2;
    final maxSafeSceneRatio = _maxSafeSceneAspectRatio(
      context,
      sceneCellWidth,
    );

    final availableForScene = availableHeight - fixedCost;
    final perCellHeight = (availableForScene - 12) / 2;
    final fitRatio = perCellHeight <= 0
        ? 2.4
        : (sceneCellWidth / perCellHeight).clamp(1.35, 2.4);

    return fitRatio > maxSafeSceneRatio ? maxSafeSceneRatio : fitRatio;
  }

  /// The largest `childAspectRatio` [sceneCellWidth] can use without the
  /// tallest scene card's thumbnail + label content (label measured with
  /// real wrapping at this cell's interior width) overflowing the cell.
  double _maxSafeSceneAspectRatio(BuildContext context, double sceneCellWidth) {
    final interiorWidth = sceneCellWidth - 20; // padding 10 * 2 (all sides)
    if (sceneCellWidth <= 0 || interiorWidth <= 0) return 1.35;

    var maxLabelHeight = 0.0;
    for (final label in _sceneLabelsForMeasurement) {
      final height = _measureTextHeight(
        context,
        label,
        AppTokens.sceneCardLabel,
        maxWidth: interiorWidth,
      );
      if (height > maxLabelHeight) maxLabelHeight = height;
    }

    // thumbnail (74) + gap (8) + label + padding (10 * 2).
    final contentHeight = 74 + 8 + maxLabelHeight + 20;
    if (contentHeight <= 0) return 1.35;
    return sceneCellWidth / contentHeight;
  }

  /// Measures the rendered height of [text] in [style] using the current
  /// text scaling (and, when [maxWidth] is given, the real line-wrap that
  /// would occur at that width), so the fit-to-space calculations above
  /// track real font metrics and wrapping instead of guessed constants.
  ///
  /// Merges [style] onto the ambient [DefaultTextStyle] first, exactly as
  /// the real `Text` widget does internally — every `Text` in this screen
  /// only sets a subset of `TextStyle` fields (fontFamily/size/weight/
  /// color), so unset fields such as `height` are inherited from the
  /// Material theme's default text style (Material 3 sets a non-1.0 height
  /// multiplier). Measuring with the bare [style] alone under-counts the
  /// real rendered line height and silently mispredicts wrapping.
  double _measureTextHeight(
    BuildContext context,
    String text,
    TextStyle style, {
    double? maxWidth,
  }) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final painter = TextPainter(
      text: TextSpan(text: text, style: effectiveStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth ?? double.infinity);
    return painter.height;
  }

  /// Estimates the custom stepper row's total block height (margin +
  /// padding + row), used only when `_showCustom` is true.
  double _measureStepperRowHeight(BuildContext context) {
    final textColumnHeight =
        _measureTextHeight(context, '99', AppTokens.stepperValue) +
        _measureTextHeight(context, 'minutes', AppTokens.stepperUnit);
    final rowHeight = textColumnHeight > 48 ? textColumnHeight : 48.0;
    return 14 + 28 + rowHeight; // margin-top(14) + padding(14+14) + row
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
  /// [aspectRatio] is adaptive per available height (1.1 on tall screens,
  /// 1.2 on short ones) to reclaim vertical space without changing the
  /// design on normal/tall devices.
  Widget _buildDurationGrid(double aspectRatio) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: aspectRatio,
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
