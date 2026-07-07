/// Shared theme identity for Zual's four scene visualizations.
///
/// A single enum keeps the Setup screen's scene picker, persistence (Plan
/// 04's last-used-theme restore), and Phase 3's real scene renderers in sync
/// without any of them depending on one another's internal representation.
enum SceneTheme {
  /// A disc that shrinks as time passes, cycling green -> yellow -> red.
  disc,

  /// A night sky that brightens into sunrise as time passes.
  sunrise,

  /// A character walking home along a path toward a house.
  walk,

  /// A car driving along a road toward a destination.
  car,
}
