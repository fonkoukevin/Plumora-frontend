import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/plumora_colors.dart';

/// Subtle nudge shown in the native mobile author space, pointing authors at
/// the larger web writing experience for a given manuscript.
///
/// Never rendered on Flutter Web itself (there is no "web" to switch to),
/// and the link never carries a JWT or any secret — it is a plain, public
/// URL. If the browser isn't already signed in, the author simply logs in
/// again there; that's an accepted limitation for the MVP.
class ContinueOnWebCard extends StatelessWidget {
  const ContinueOnWebCard({required this.manuscriptId, super.key});

  final String manuscriptId;

  /// Only native Android/iOS apps benefit from this nudge — on Flutter Web
  /// the visitor is already on the web, and desktop already gets the large
  /// layout directly.
  static bool get isRelevant =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Uri get _webUri => Uri.parse(
    '${AppConfig.webBaseUrl}'
    '${AppRoutes.continueOnWebAuthorPath(manuscriptId)}',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.cards,
        border: Border.all(color: context.colors.border, width: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.laptop_mac_outlined,
              color: context.colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Écrivez plus confortablement sur ordinateur',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Retrouvez votre manuscrit et les outils Plumo dans un '
                  "espace d'écriture plus large et plus complet.",
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const ValueKey('continue_on_web_button'),
                  onPressed: () =>
                      launchUrl(_webUri, mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: const Text('Continuer sur le web'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
