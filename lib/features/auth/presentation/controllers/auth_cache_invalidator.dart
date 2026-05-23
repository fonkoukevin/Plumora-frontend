import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../ai/data/repositories/ai_repository.dart';
import '../../../beta_reading/data/repositories/beta_reading_repository.dart';
import '../../../book/data/repositories/book_cover_cache.dart';
import '../../../book/data/repositories/book_repository.dart';
import '../../../book/data/repositories/chapter_repository.dart';
import '../../../notification/data/repositories/notification_repository.dart';
import '../../../reading/data/repositories/favorite_repository.dart';
import '../../../reading/data/repositories/reading_repository.dart';
import '../../../reading/data/repositories/review_repository.dart';

void invalidateUserScopedCaches(Ref ref) {
  ref.invalidate(authRepositoryProvider);
  ref.invalidate(authApiServiceProvider);
  ref.invalidate(dioProvider);

  ref.invalidate(bookCoverCacheProvider);
  ref.invalidate(myBooksProvider);
  ref.invalidate(authorBookProvider);
  ref.invalidate(bookChaptersProvider);
  ref.invalidate(chapterProvider);

  ref.invalidate(myReadingProgressProvider);
  ref.invalidate(readingProgressProvider);
  ref.invalidate(readableBookProvider);
  ref.invalidate(myFavoritesProvider);
  ref.invalidate(favoriteStatusProvider);
  ref.invalidate(myReviewsProvider);
  ref.invalidate(myReviewForBookProvider);

  ref.invalidate(betaInvitationsProvider);
  ref.invalidate(betaCampaignsForBookProvider);
  ref.invalidate(betaCampaignProvider);
  ref.invalidate(betaSharedChaptersProvider);
  ref.invalidate(betaCommentsForBookProvider);
  ref.invalidate(betaCommentsForCampaignProvider);

  ref.invalidate(myNotificationsProvider);
  ref.invalidate(unreadNotificationsCountProvider);
  ref.invalidate(aiRecommendationRequestsProvider);
}
