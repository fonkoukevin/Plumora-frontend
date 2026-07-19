import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/core/theme/plumora_theme.dart';
import 'package:plumora_app/features/writing/presentation/widgets/continue_on_web_card.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncher extends UrlLauncherPlatform {
  String? lastLaunchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return true;
  }
}

void main() {
  group('ContinueOnWebCard.isRelevant', () {
    final originalPlatform = debugDefaultTargetPlatformOverride;

    tearDown(() {
      debugDefaultTargetPlatformOverride = originalPlatform;
    });

    test('is shown on native Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(ContinueOnWebCard.isRelevant, isTrue);
    });

    test('is shown on native iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(ContinueOnWebCard.isRelevant, isTrue);
    });

    test('is hidden on desktop platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(ContinueOnWebCard.isRelevant, isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(ContinueOnWebCard.isRelevant, isFalse);
    });
  });

  testWidgets(
    'tapping "Continuer sur le web" opens the manuscript on the web app, '
    'without any token in the URL',
    (tester) async {
      final fakeLauncher = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fakeLauncher;

      await tester.pumpWidget(
        MaterialApp(
          theme: PlumoraTheme.light,
          home: const Scaffold(
            body: ContinueOnWebCard(manuscriptId: 'book-42'),
          ),
        ),
      );

      expect(
        find.text('Écrivez plus confortablement sur ordinateur'),
        findsOneWidget,
      );
      expect(find.text('Continuer sur le web'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('continue_on_web_button')));
      await tester.pumpAndSettle();

      expect(fakeLauncher.lastLaunchedUrl, isNotNull);
      final launchedUri = Uri.parse(fakeLauncher.lastLaunchedUrl!);
      expect(launchedUri.path, '/author/manuscripts/book-42');
      expect(launchedUri.toString(), isNot(contains('token')));
      expect(launchedUri.toString(), isNot(contains('jwt')));
    },
  );
}
