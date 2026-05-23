import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookCoverCacheProvider =
    NotifierProvider<BookCoverCache, Map<String, Uint8List>>(
      BookCoverCache.new,
    );

final bookCoverBytesProvider = Provider.family<Uint8List?, String>((
  ref,
  bookId,
) {
  return ref.watch(bookCoverCacheProvider)[bookId.trim()];
});

class BookCoverCache extends Notifier<Map<String, Uint8List>> {
  @override
  Map<String, Uint8List> build() => const {};

  void put(String bookId, Uint8List bytes) {
    final normalizedBookId = bookId.trim();
    if (normalizedBookId.isEmpty) {
      return;
    }

    state = {...state, normalizedBookId: bytes};
  }

  void remove(String bookId) {
    final normalizedBookId = bookId.trim();
    if (normalizedBookId.isEmpty || !state.containsKey(normalizedBookId)) {
      return;
    }

    state = {
      for (final entry in state.entries)
        if (entry.key != normalizedBookId) entry.key: entry.value,
    };
  }
}
