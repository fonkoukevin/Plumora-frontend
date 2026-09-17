import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Flutter's test runner automatically wraps every test in this directory
/// (and subdirectories) with this function - see
/// https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html.
///
/// Without this, `GoogleFonts.*` calls (used throughout the app, e.g.
/// author_dashboard_screen.dart's `GoogleFonts.playfairDisplay`) try to
/// fetch font files over the network the first time they run. That fetch
/// races the test's own `pumpAndSettle()`/`pump()` calls instead of being
/// tied to them, which is a well-known source of intermittent, unrelated
/// widget-test failures - especially in CI, where network access can be
/// slow or restricted. `allowRuntimeFetching = false` makes GoogleFonts
/// fall back to the bundled/system font synchronously instead, which is
/// deterministic and removes that whole class of flakiness.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
