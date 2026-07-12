import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste localement les identifiants (invitations, campagnes...) que le
/// beta-lecteur a deja vus, sous une cle donnee.
class BetaSeenIdsStorage {
  const BetaSeenIdsStorage(this._storageKey)
    : _storage = const FlutterSecureStorage();

  const BetaSeenIdsStorage.withStorage(this._storageKey, this._storage);

  final String _storageKey;
  final FlutterSecureStorage _storage;

  Future<Set<String>> readSeenIds() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) {
      return <String>{};
    }

    return raw.split(',').where((id) => id.isNotEmpty).toSet();
  }

  Future<void> markSeen(Iterable<String> ids) async {
    final newIds = ids.where((id) => id.isNotEmpty);
    if (newIds.isEmpty) {
      return;
    }

    final seenIds = await readSeenIds();
    seenIds.addAll(newIds);
    await _storage.write(key: _storageKey, value: seenIds.join(','));
  }
}
