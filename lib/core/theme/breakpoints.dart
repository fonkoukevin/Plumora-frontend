/// Shared width thresholds for screens that need their own `LayoutBuilder`
/// beyond what `MainShell`/`AdminShell` already provide (sidebar vs. bottom
/// nav at [large]). Existing screens with their own already-tested
/// thresholds are left as-is — this is for new/fixed responsive layouts
/// going forward, not a mandate to renumber working code.
abstract final class Breakpoints {
  /// Phone.
  static const double compact = 600;

  /// Large phone / small tablet.
  static const double medium = 760;

  /// Tablet / narrow desktop window.
  static const double expanded = 900;

  /// Desktop — matches `MainShell`/`AdminShell`'s own chrome breakpoint.
  static const double large = 1024;

  /// Wide desktop — matches `FigmaScreen`'s default `maxWidth`.
  static const double wide = 1280;
}
