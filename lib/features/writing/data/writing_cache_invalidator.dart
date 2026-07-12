import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../beta_reading/data/repositories/beta_reading_repository.dart';
import '../../catalog/data/repositories/catalog_repository.dart';

/// Invalidates every cached provider that could show a stale snapshot of a
/// book after it is published, edited, archived, or has its chapters
/// changed -- so the Discover catalog ("Oeuvres Plumora") and any
/// beta-reading screens (open campaigns, this book's campaigns) refresh with
/// the latest title, cover, and content.
void invalidateBookPublicationCaches(WidgetRef ref, String bookId) {
  ref.invalidate(catalogBooksProvider);
  ref.invalidate(plumoraCatalogBooksProvider);
  ref.invalidate(latestCatalogBooksProvider);
  ref.invalidate(popularCatalogBooksProvider);
  ref.invalidate(catalogSearchProvider);

  ref.invalidate(betaOpenCampaignsProvider);
  ref.invalidate(betaCampaignProvider);
  ref.invalidate(betaSharedChaptersProvider);

  if (bookId.isNotEmpty) {
    ref.invalidate(catalogBookDetailProvider(bookId));
    ref.invalidate(betaCampaignsForBookProvider(bookId));
  }
}
