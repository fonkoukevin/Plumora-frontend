import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/home/presentation/landing_screen.dart';

void main() {
  Future<void> pumpLanding(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: PlumoraTheme.light, home: const LandingScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('landing page stays responsive on a compact screen', (
    tester,
  ) async {
    await pumpLanding(tester, size: const Size(360, 800));

    expect(find.byKey(const ValueKey('landing_cover_stack')), findsOneWidget);
    expect(find.text('Rejoindre gratuitement'), findsOneWidget);
    expect(
      tester.getTopRight(find.byKey(const ValueKey('landing_login_button'))).dx,
      closeTo(336, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('landing calls to action and books react to mouse hover', (
    tester,
  ) async {
    await pumpLanding(tester, size: const Size(1440, 1000));

    expect(
      tester.getTopRight(find.byKey(const ValueKey('landing_login_button'))).dx,
      closeTo(1416, 1),
    );

    final primaryCta = find.byKey(const ValueKey('landing_primary_cta'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(primaryCta));
    await tester.pump(const Duration(milliseconds: 240));

    final ctaScale = tester.widget<AnimatedScale>(
      find.descendant(of: primaryCta, matching: find.byType(AnimatedScale)),
    );
    expect(ctaScale.scale, greaterThan(1));

    final covers = find.byKey(const ValueKey('landing_cover_stack'));
    await mouse.moveTo(tester.getCenter(covers));
    await tester.pump(const Duration(milliseconds: 300));

    final promptOpacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Découvrir ces histoires'),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(promptOpacity.opacity, 1);
  });
}
