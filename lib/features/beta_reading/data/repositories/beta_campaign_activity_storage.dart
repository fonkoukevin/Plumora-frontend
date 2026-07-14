import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste localement la derniere fois que l'utilisateur a lu un chapitre
/// ou commente sur chaque campagne, pour trier la Bibliotheque Beta par
/// activite recente (le backend n'expose pas ce timestamp par utilisateur).
class BetaCampaignActivityStorage {
  const BetaCampaignActivityStorage() : _storage = const FlutterSecureStorage();

  const BetaCampaignActivityStorage.withStorage(this._storage);

  static const String _storageKey = 'plumora_beta_campaign_last_activity';

  final FlutterSecureStorage _storage;

  Future<Map<String, DateTime>> readAll() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) {
      return <String, DateTime>{};
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (campaignId, value) =>
            MapEntry(campaignId, DateTime.parse(value as String)),
      );
    } catch (_) {
      return <String, DateTime>{};
    }
  }

  Future<void> touch(String campaignId) async {
    if (campaignId.isEmpty) {
      return;
    }

    final all = await readAll();
    all[campaignId] = DateTime.now();
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(
        all.map((id, timestamp) => MapEntry(id, timestamp.toIso8601String())),
      ),
    );
  }
}
