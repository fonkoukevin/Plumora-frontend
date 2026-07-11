import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plumora_app/core/routing/app_router.dart';
import 'package:plumora_app/features/ai/data/models/ai_models.dart';
import 'package:plumora_app/features/ai/data/services/ai_api_service.dart';
import 'package:plumora_app/features/auth/data/models/login_request.dart';
import 'package:plumora_app/features/auth/data/models/register_request.dart';
import 'package:plumora_app/features/auth/data/services/auth_api_service.dart';
import 'package:plumora_app/features/beta_reading/data/models/beta_campaign_model.dart';
import 'package:plumora_app/features/beta_reading/data/models/beta_comment_model.dart';
import 'package:plumora_app/features/beta_reading/data/services/beta_reading_api_service.dart';
import 'package:plumora_app/features/book/data/models/book_model.dart';
import 'package:plumora_app/features/book/data/models/chapter_model.dart';
import 'package:plumora_app/features/book/data/services/book_api_service.dart';
import 'package:plumora_app/features/book/data/services/chapter_api_service.dart';
import 'package:plumora_app/features/catalog/data/models/catalog_book_model.dart';
import 'package:plumora_app/features/catalog/data/services/catalog_api_service.dart';
import 'package:plumora_app/features/catalog/data/models/external_book_model.dart';
import 'package:plumora_app/features/catalog/data/services/external_book_api_service.dart';
import 'package:plumora_app/features/notification/data/services/notification_api_service.dart';
import 'package:plumora_app/features/reading/data/models/favorite_model.dart';
import 'package:plumora_app/features/reading/data/models/reading_progress_model.dart';
import 'package:plumora_app/features/reading/data/models/review_model.dart';
import 'package:plumora_app/features/reading/data/services/favorite_api_service.dart';
import 'package:plumora_app/features/reading/data/services/reading_api_service.dart';
import 'package:plumora_app/features/reading/data/services/review_api_service.dart';

void main() {
  group('GoRouter MVP routes', () {
    test('registers every implemented front route', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      final paths = _collectRoutePaths(router.configuration.routes);

      expect(
        paths,
        containsAll([
          AppRoutes.landing,
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.roleSelection,
          AppRoutes.home,
          AppRoutes.discover,
          AppRoutes.publicDomainCatalog,
          AppRoutes.publicDomainBookDetail,
          AppRoutes.catalogSearch,
          AppRoutes.catalogBookDetail,
          AppRoutes.mukemeRecommendation,
          AppRoutes.mukemeWriting,
          AppRoutes.write,
          AppRoutes.manuscripts,
          AppRoutes.editor,
          AppRoutes.createBook,
          AppRoutes.editBook,
          AppRoutes.authorBookDetail,
          AppRoutes.publishBook,
          AppRoutes.chapterEditor,
          AppRoutes.authorChapterDetail,
          AppRoutes.betaFeedback,
          AppRoutes.authorBetaComments,
          AppRoutes.authorBetaCampaigns,
          AppRoutes.authorBetaCampaignDetail,
          AppRoutes.betaInvitations,
          AppRoutes.betaChapters,
          AppRoutes.library,
          AppRoutes.libraryFavorites,
          AppRoutes.libraryReviews,
          AppRoutes.profile,
          AppRoutes.notifications,
          AppRoutes.reading,
          AppRoutes.betaReadChapter,
        ]),
      );
    });

    test('path helpers build concrete URLs from seed ids', () {
      expect(AppRoutes.authorBookDetailPath('book-1'), '/books/book-1/author');
      expect(
        AppRoutes.catalogSearchPath('nuit rouge'),
        '/discover/search?q=nuit+rouge',
      );
      expect(
        AppRoutes.publicDomainCatalogPath(
          search: 'Hugo',
          language: 'fr',
          topic: 'fiction',
        ),
        '/discover/public-domain?search=Hugo&language=fr&topic=fiction',
      );
      expect(
        AppRoutes.publicDomainBookDetailPath('123'),
        '/discover/public-domain/123',
      );
      expect(
        AppRoutes.catalogBookDetailPath('book-1'),
        '/catalog/books/book-1',
      );
      expect(AppRoutes.readingPath('book-1'), '/books/book-1/read');
      expect(
        AppRoutes.readingPath('book-1', chapterId: 'chapter-3'),
        '/books/book-1/read?chapterId=chapter-3',
      );
      expect(AppRoutes.editBookPath('book-1'), '/books/book-1/edit');
      expect(AppRoutes.chapterEditorPath('book-1'), '/books/book-1/editor');
      expect(AppRoutes.publishBookPath('book-1'), '/books/book-1/publish');
      expect(
        AppRoutes.authorChapterDetailPath('chapter-1', bookId: 'book-1'),
        '/chapters/chapter-1/author?bookId=book-1',
      );
      expect(
        AppRoutes.mukemeWritingPath(chapterId: 'chapter-1'),
        '/mukeme/writing?chapterId=chapter-1',
      );
      expect(
        AppRoutes.authorBetaCommentsPath('book-1'),
        '/books/book-1/beta-comments',
      );
      expect(
        AppRoutes.authorBetaCampaignsPath('book-1'),
        '/books/book-1/beta-campaigns',
      );
      expect(
        AppRoutes.authorBetaCampaignDetailPath('campaign-1', bookId: 'book-1'),
        '/beta/campaigns/campaign-1?bookId=book-1',
      );
      expect(
        AppRoutes.betaChaptersPath(
          'campaign-1',
          invitationId: 'invitation-1',
          bookId: 'book-1',
        ),
        '/beta/campaigns/campaign-1/chapters?invitationId=invitation-1&bookId=book-1',
      );
      expect(
        AppRoutes.betaReadChapterPath(
          'campaign-1',
          'chapter-1',
          invitationId: 'invitation-1',
          bookId: 'book-1',
        ),
        '/beta/campaigns/campaign-1/chapters/chapter-1/read?bookId=book-1&invitationId=invitation-1',
      );
    });
  });

  group('Reader model compatibility', () {
    test('reads flat reading progress book aliases from backend', () {
      final progress = ReadingProgressModel.fromJson({
        'bookId': 'book-91',
        'chapterId': 'chapter-2',
        'bookTitle': 'La Mer Sans Sommeil',
        'authorFirstName': 'Kevin',
        'authorLastName': 'Fonkou',
        'coverUrl': 'uploads/book-covers/cover.png',
        'progressPercentage': 25,
      });

      expect(progress.bookTitle, 'La Mer Sans Sommeil');
      expect(progress.authorName, 'Kevin Fonkou');
      expect(progress.progressPercent, 25);
      expect(progress.coverUrl, 'uploads/book-covers/cover.png');
    });

    test('reads flat favorite book title aliases from backend', () {
      final favorite = FavoriteModel.fromJson({
        'id': 'favorite-4',
        'bookId': 'book-42',
        'bookTitle': 'Les Chroniques d’Eldoria',
        'authorName': 'Sophie Martin',
        'coverUrl': 'uploads/book-covers/eldoria.png',
      });

      expect(favorite.book.id, 'book-42');
      expect(favorite.book.title, 'Les Chroniques d’Eldoria');
      expect(favorite.book.authorName, 'Sophie Martin');
      expect(favorite.book.coverUrl, 'uploads/book-covers/eldoria.png');
    });

    test('reads catalog author display names from backend', () {
      final book = CatalogBookModel.fromJson({
        'id': 'book-2701',
        'title': 'Moby Dick; Or, The Whale',
        'authorUsername': 'eli_reader',
        'authorDisplayName': 'Melville, Herman',
        'externalSource': 'GUTENDEX',
        'externalAuthors': ['Melville, Herman'],
      });

      expect(book.authorName, 'Melville, Herman');
      expect(book.externalSource, 'GUTENDEX');
      expect(book.isExternalImport, isTrue);

      final internalBook = CatalogBookModel.fromJson({
        'id': 'book-lumen',
        'title': 'Dernier Tram pour Lumen',
        'authorDisplayName': 'Bruno Kassel',
        'externalSource': null,
      });

      expect(internalBook.authorName, 'Bruno Kassel');
      expect(internalBook.isPlumoraOriginal, isTrue);
    });

    test('reads reviewer names from flat and nested backend aliases', () {
      final flat = ReviewModel.fromJson({
        'idReview': 'review-42',
        'idBook': 'book-42',
        'idUser': 'user-42',
        'reviewerFirstName': 'Clara',
        'reviewerLastName': 'Martin',
        'rating': 5,
        'comment': 'Super lecture.',
      });
      final nested = ReviewModel.fromJson({
        'id': 'review-43',
        'bookId': 'book-42',
        'userName': 'Lecteur Plumora',
        'rating': 4,
        'comment': 'Tres bon rythme.',
        'user': {'firstname': 'Sarah', 'lastname': 'Kouam'},
      });

      expect(flat.id, 'review-42');
      expect(flat.bookId, 'book-42');
      expect(flat.userId, 'user-42');
      expect(flat.userName, 'Clara Martin');
      expect(nested.userName, 'Sarah Kouam');
    });

    test('reads external review Gutendex aliases from backend', () {
      final review = ReviewModel.fromJson({
        'id': 'external-review-42',
        'externalId': '123',
        'userName': 'Lecteur externe',
        'rating': 5,
        'comment': 'Tres belle decouverte.',
      });

      expect(review.id, 'external-review-42');
      expect(review.bookId, '123');
      expect(review.userName, 'Lecteur externe');
    });
  });

  group('External book model compatibility', () {
    test(
      'reads nullable lists, formats and optional URLs from backend DTO',
      () {
        final page = ExternalBookPage.fromJson({
          'content': [
            {
              'externalId': '123',
              'source': 'GUTENDEX',
              'title': 'Les Miserables',
              'authors': ['Victor Hugo', null],
              'summary': 'Un roman social.',
              'subjects': ['French fiction'],
              'languages': ['fr'],
              'copyright': false,
              'mediaType': 'Text',
              'downloadCount': '42',
              'coverUrl': null,
              'readUrl': null,
              'formats': {'text/html': 'https://example.test/read.html'},
              'sourceUrl': 'https://www.gutenberg.org/ebooks/123',
              'imported': true,
              'internalBookId': 'book-3',
            },
          ],
          'page': 0,
          'size': 32,
          'totalElements': 100,
          'totalPages': 4,
          'first': true,
          'last': false,
        });

        final book = page.content.single;

        expect(page.totalPages, 4);
        expect(page.last, isFalse);
        expect(book.externalId, '123');
        expect(book.authorLabel, 'Victor Hugo');
        expect(book.coverUrl, isNull);
        expect(book.readUrl, isNull);
        expect(book.formats['text/html'], 'https://example.test/read.html');
        expect(book.downloadCount, 42);
        expect(book.imported, isTrue);
        expect(book.internalBookId, 'book-3');
        expect(book.canReadInPlumora, isTrue);
      },
    );
  });

  group('API contract services with seed data', () {
    test('call every MVP endpoint through Dio services', () async {
      final adapter = _SeedHttpClientAdapter(_seedResponses());
      final dio = Dio(BaseOptions(baseUrl: 'http://plumora.test/api/v1'))
        ..httpClientAdapter = adapter;

      final auth = AuthApiService(dio);
      final books = BookApiService(dio);
      final chapters = ChapterApiService(dio);
      final catalog = CatalogApiService(dio);
      final externalBooks = ExternalBookApiService(dio);
      final reading = ReadingApiService(dio);
      final favorites = FavoriteApiService(dio);
      final reviews = ReviewApiService(dio);
      final beta = BetaReadingApiService(dio);
      final ai = AiApiService(dio);
      final notifications = NotificationApiService(dio);

      final register = await auth.register(
        const RegisterRequest(
          firstname: 'Kevin',
          lastname: 'Fonkou',
          email: 'kevin@plumora.test',
          password: 'secret123',
        ),
      );
      final login = await auth.login(
        const LoginRequest(email: 'kevin@plumora.test', password: 'secret123'),
      );
      final authMe = await auth.authMe();
      final userMe = await auth.userMe();
      final roles = await auth.myRoles();
      final updatedRoles = await auth.updateMyRoles(['AUTHOR', 'READER']);

      expect(register.accessToken, 'seed-token');
      expect(login.user?.firstname, 'Kevin');
      expect(authMe.id, 'user-1');
      expect(userMe.email, 'kevin@plumora.test');
      expect(roles.map((role) => role.name), contains('AUTHOR'));
      expect(updatedRoles.map((role) => role.name), contains('READER'));

      final createdBook = await books.createBook(
        BookUpsertRequest(
          title: 'La Nuit Rouge',
          description: 'Thriller littéraire.',
          genre: 'Thriller',
          visibility: 'PRIVATE',
          coverImage: BookCoverUpload(
            fileName: 'nuit-rouge.jpg',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        ),
      );
      final myBooks = await books.myBooks();
      final book = await books.bookById('book-1');
      final updatedBook = await books.updateBook(
        'book-1',
        BookUpsertRequest(
          title: 'La Nuit Rouge corrigée',
          description: 'Résumé corrigé.',
          genre: 'Thriller',
          visibility: 'PUBLIC',
          coverImage: BookCoverUpload(
            fileName: 'nuit-rouge-v2.jpg',
            bytes: Uint8List.fromList([4, 5, 6]),
          ),
        ),
      );
      final publishedBook = await books.publishBook('book-1');
      final archivedBook = await books.archiveBook('book-1');

      expect(createdBook.id, 'book-1');
      expect(
        createdBook.coverUrl,
        'https://cdn.plumora.test/covers/nuit-rouge.jpg',
      );
      expect(myBooks, hasLength(2));
      expect(book.status, BookStatus.draft);
      expect(updatedBook.title, 'La Nuit Rouge corrigée');
      expect(
        updatedBook.coverUrl,
        'https://cdn.plumora.test/covers/nuit-rouge-v2.jpg',
      );
      expect(publishedBook.status, BookStatus.published);
      expect(archivedBook.status, BookStatus.archived);

      final createdChapter = await chapters.createChapter(
        'book-1',
        const ChapterUpsertRequest(
          title: 'Chapitre 1',
          content: 'Le début.',
          order: 1,
        ),
      );
      final bookChapters = await chapters.chaptersForBook('book-1');
      final chapter = await chapters.chapterById('chapter-1');
      final updatedChapter = await chapters.updateChapter(
        'chapter-1',
        const ChapterUpsertRequest(
          title: 'Chapitre 1 corrigé',
          content: 'Le début corrigé.',
          order: 1,
        ),
      );
      await chapters.deleteChapter('chapter-1');

      expect(createdChapter.bookId, 'book-1');
      expect(bookChapters, hasLength(1));
      expect(chapter.title, 'Chapitre 1');
      expect(updatedChapter.title, 'Chapitre 1 corrigé');

      final catalogBooks = await catalog.books();
      final latestBooks = await catalog.latest();
      final popularBooks = await catalog.popular();
      final searchBooks = await catalog.search('nuit');
      final catalogDetail = await catalog.bookDetail('book-1');
      final externalPage = await externalBooks.searchExternalBooks(
        search: 'Hugo',
        language: 'fr',
        page: 0,
      );
      final externalDetail = await externalBooks.getExternalBook('123');
      final importedExternalBook = await externalBooks.importGutendexBook(
        '123',
      );

      expect(catalogBooks.single.title, 'La Nuit Rouge');
      expect(catalogBooks.single.coverUrl, createdBook.coverUrl);
      expect(latestBooks.single.id, 'book-1');
      expect(popularBooks.single.id, 'book-1');
      expect(searchBooks.single.id, 'book-1');
      expect(catalogDetail.chapters.single.id, 'chapter-1');
      expect(externalPage.content.single.title, 'Les Miserables');
      expect(externalPage.content.single.imported, isFalse);
      expect(externalPage.last, isFalse);
      expect(externalDetail.formats, containsPair('text/html', 'https://read'));
      expect(externalDetail.internalBookId, isNull);
      expect(importedExternalBook.id, 'book-3');

      final readBook = await reading.readBook('book-1');
      final myProgress = await reading.myProgress();
      final progress = await reading.progress('book-1');
      final createdProgress = await reading.createProgress(
        'book-1',
        const ReadingProgressUpdateRequest(
          bookId: 'book-1',
          chapterId: 'chapter-1',
          progress: 0.25,
        ),
      );
      final updatedProgress = await reading.updateProgress(
        'book-1',
        const ReadingProgressUpdateRequest(
          bookId: 'book-1',
          chapterId: 'chapter-1',
          progress: 0.65,
        ),
      );
      final finishedProgress = await reading.finishProgress('book-1');

      expect(readBook.id, 'book-1');
      expect(readBook.coverUrl, createdBook.coverUrl);
      expect(myProgress.single.progressPercent, 35);
      expect(myProgress.single.coverUrl, createdBook.coverUrl);
      expect(progress.chapterId, 'chapter-1');
      expect(createdProgress.progressPercent, 25);
      expect(updatedProgress.progressPercent, 65);
      expect(finishedProgress.finished, isTrue);

      await favorites.addFavorite('book-1');
      await favorites.removeFavorite('book-1');
      final favoriteItems = await favorites.myFavorites();
      final isFavorite = await favorites.isFavorite('book-1');

      expect(favoriteItems.single.book.id, 'book-1');
      expect(favoriteItems.single.book.coverUrl, createdBook.coverUrl);
      expect(isFavorite, isTrue);

      final createdReview = await reviews.createReview(
        'book-1',
        const ReviewUpsertRequest(rating: 5, comment: 'Excellent.'),
      );
      final bookReviews = await reviews.reviewsForBook('book-1');
      final externalBookReviews = await reviews.reviewsForExternalBook('123');
      final createdExternalReview = await reviews.createExternalBookReview(
        '123',
        const ReviewUpsertRequest(
          rating: 5,
          comment: 'Lecture externe excellente.',
        ),
      );
      final myReviews = await reviews.myReviews();
      final updatedReview = await reviews.updateReview(
        'review-1',
        const ReviewUpsertRequest(rating: 4, comment: 'Très bon.'),
      );
      await reviews.deleteReview('review-1');

      expect(createdReview.bookId, 'book-1');
      expect(bookReviews, hasLength(2));
      expect(
        bookReviews.map((review) => review.userName),
        containsAll(['Lecteur Seed', 'Clara Martin']),
      );
      expect(externalBookReviews.single.bookId, '123');
      expect(createdExternalReview.bookId, '123');
      expect(myReviews.single.id, 'review-1');
      expect(updatedReview.rating, 4);

      final betaReaders = await beta.betaReaders();
      final invitations = await beta.myInvitations();
      final openCampaigns = await beta.openCampaigns();
      final campaign = await beta.createCampaign(
        'book-1',
        const BetaCampaignCreateRequest(
          title: 'Bêta La Nuit Rouge',
          instructions: 'Chercher les incohérences.',
        ),
      );
      final campaigns = await beta.campaignsForBook('book-1');
      final campaignDetail = await beta.campaignById('campaign-1');
      final closedCampaign = await beta.closeCampaign('campaign-1');
      final cancelledCampaign = await beta.cancelCampaign('campaign-1');
      final invitation = await beta.createInvitation(
        'campaign-1',
        const BetaInvitationCreateRequest(betaReaderId: 'user-2'),
      );
      final campaignInvitations = await beta.invitationsForCampaign(
        'campaign-1',
      );
      final sharedAfterUpdate = await beta.updateSharedChapters('campaign-1', [
        'chapter-1',
      ]);
      await beta.recordChapterView('campaign-1', 'chapter-1');
      final acceptedInvitation = await beta.acceptInvitation('invitation-1');
      final refusedInvitation = await beta.refuseInvitation('invitation-1');
      final sharedChapters = await beta.sharedChapters('campaign-1');
      final createdComment = await beta.createComment(
        const BetaCommentCreateRequest(
          bookId: 'book-1',
          campaignId: 'campaign-1',
          chapterId: 'chapter-1',
          type: BetaCommentType.plot,
          content: 'Ce passage contredit le chapitre précédent.',
        ),
      );
      final commentsForBook = await beta.commentsForBook('book-1');
      final commentsForCampaign = await beta.commentsForCampaign('campaign-1');
      final resolvedComment = await beta.updateCommentStatus(
        'comment-1',
        BetaCommentStatus.resolved,
      );
      await beta.deleteComment('comment-1');

      expect(betaReaders.single.username, 'sarah_seed');
      expect(invitations.single.id, 'invitation-1');
      expect(invitations.single.coverUrl, createdBook.coverUrl);
      expect(openCampaigns.single.id, 'campaign-1');
      expect(openCampaigns.single.engagedByMe, isTrue);
      expect(campaign.id, 'campaign-1');
      expect(campaign.coverUrl, createdBook.coverUrl);
      expect(campaigns.single.id, 'campaign-1');
      expect(campaignDetail.status, BetaCampaignStatus.active);
      expect(closedCampaign.status, BetaCampaignStatus.closed);
      expect(cancelledCampaign.status, BetaCampaignStatus.cancelled);
      expect(invitation.campaignId, 'campaign-1');
      expect(campaignInvitations.single.id, 'invitation-1');
      expect(sharedAfterUpdate.single.id, 'shared-1');
      expect(acceptedInvitation.status.apiValue, 'ACCEPTED');
      expect(refusedInvitation.status.apiValue, 'REFUSED');
      expect(sharedChapters.single.id, 'shared-1');
      expect(createdComment.type, BetaCommentType.plot);
      expect(commentsForBook.single.bookId, 'book-1');
      expect(commentsForCampaign.single.campaignId, 'campaign-1');
      expect(resolvedComment.status, BetaCommentStatus.resolved);

      final suggestion = await ai.requestWritingSuggestion(
        const AiWritingSuggestionRequest(
          selectedText: 'Elle était très triste.',
          actionType: AiWritingActionType.improveStyle,
        ),
      );
      final acceptedSuggestion = await ai.acceptSuggestion('suggestion-1');
      final modifiedSuggestion = await ai.modifySuggestion(
        'suggestion-1',
        'Elle avançait le cœur lourd.',
      );
      final ignoredSuggestion = await ai.ignoreSuggestion('suggestion-1');
      final recommendations = await ai.recommendBooks(
        const AiRecommendationRequest(
          queryText: 'Un thriller court et sombre',
          mood: 'SUSPENSE',
          preferredDuration: 'SHORT',
          preferredGenre: 'Thriller',
        ),
      );
      final recommendationRequests = await ai.myRecommendationRequests();

      expect(suggestion.id, 'suggestion-1');
      expect(acceptedSuggestion.status, AiSuggestionStatus.accepted);
      expect(modifiedSuggestion.status, AiSuggestionStatus.modified);
      expect(ignoredSuggestion.status, AiSuggestionStatus.ignored);
      expect(recommendations.single.book.id, 'book-1');
      expect(recommendations.single.book.coverUrl, createdBook.coverUrl);
      expect(recommendationRequests.single.queryText, contains('thriller'));

      final notificationItems = await notifications.myNotifications();
      final unreadCount = await notifications.unreadCount();
      final readNotification = await notifications.markAsRead('notification-1');
      await notifications.markAllAsRead();

      expect(notificationItems.single.id, 'notification-1');
      expect(unreadCount, 1);
      expect(readNotification.isRead, isTrue);

      expect(
        adapter.requestKeys,
        containsAll([
          'POST /auth/register',
          'POST /auth/login',
          'GET /auth/me',
          'GET /users/me',
          'GET /users/me/roles',
          'PUT /users/me/roles',
          'POST /books',
          'GET /books/my-books',
          'GET /books/book-1',
          'PUT /books/book-1',
          'PATCH /books/book-1/publish',
          'PATCH /books/book-1/archive',
          'POST /books/book-1/chapters',
          'GET /books/book-1/chapters',
          'GET /chapters/chapter-1',
          'PUT /chapters/chapter-1',
          'DELETE /chapters/chapter-1',
          'GET /catalog/books',
          'GET /catalog/books/latest',
          'GET /catalog/books/popular',
          'GET /catalog/books/search',
          'GET /catalog/books/book-1',
          'GET /external-books',
          'GET /external-books/123',
          'POST /books/import/gutendex/123',
          'GET /books/book-1/read',
          'GET /reading-progress/my',
          'GET /books/book-1/reading-progress',
          'POST /books/book-1/reading-progress',
          'PUT /books/book-1/reading-progress',
          'PATCH /books/book-1/reading-progress/finish',
          'POST /books/book-1/favorites',
          'DELETE /books/book-1/favorites',
          'GET /favorites/my',
          'GET /books/book-1/favorites/status',
          'POST /books/book-1/reviews',
          'GET /books/book-1/reviews',
          'GET /external-books/123/reviews',
          'POST /external-books/123/reviews',
          'GET /reviews/my',
          'PUT /reviews/review-1',
          'DELETE /reviews/review-1',
          'GET /users',
          'GET /beta-invitations/my-invitations',
          'GET /beta-campaigns',
          'POST /books/book-1/beta-campaigns',
          'GET /books/book-1/beta-campaigns',
          'GET /beta-campaigns/campaign-1',
          'PATCH /beta-campaigns/campaign-1/close',
          'PATCH /beta-campaigns/campaign-1/cancel',
          'POST /beta-campaigns/campaign-1/invitations',
          'GET /beta-campaigns/campaign-1/invitations',
          'PUT /beta-campaigns/campaign-1/chapters',
          'POST /beta-campaigns/campaign-1/chapters/chapter-1/views',
          'PATCH /beta-invitations/invitation-1/accept',
          'PATCH /beta-invitations/invitation-1/refuse',
          'GET /beta-campaigns/campaign-1/chapters',
          'POST /beta-comments',
          'GET /books/book-1/beta-comments',
          'GET /beta-campaigns/campaign-1/comments',
          'PATCH /beta-comments/comment-1/status',
          'DELETE /beta-comments/comment-1',
          'POST /ai/writing/suggestions',
          'PATCH /ai/writing/suggestions/suggestion-1/accept',
          'PATCH /ai/writing/suggestions/suggestion-1/modify',
          'PATCH /ai/writing/suggestions/suggestion-1/ignore',
          'POST /ai/recommendations/books',
          'GET /ai/recommendations/my-requests',
          'GET /notifications/my',
          'GET /notifications/unread-count',
          'PATCH /notifications/notification-1/read',
          'PATCH /notifications/read-all',
        ]),
      );

      final searchRequest = adapter.requests.firstWhere(
        (request) => request.key == 'GET /catalog/books/search',
      );
      expect(searchRequest.query['q'], 'nuit');

      final externalSearchRequest = adapter.requests.firstWhere(
        (request) => request.key == 'GET /external-books',
      );
      expect(externalSearchRequest.query['search'], 'Hugo');
      expect(externalSearchRequest.query['language'], 'fr');
      expect(externalSearchRequest.query['page'], 0);

      final roleRequest = adapter.requests.firstWhere(
        (request) => request.key == 'PUT /users/me/roles',
      );
      expect(roleRequest.data, containsPair('roles', ['AUTHOR', 'READER']));

      final createBookRequest = adapter.requests.firstWhere(
        (request) => request.key == 'POST /books',
      );
      expect(_formDataField(createBookRequest.data, 'title'), 'La Nuit Rouge');
      expect(
        _formDataFileName(createBookRequest.data, 'coverImage'),
        'nuit-rouge.jpg',
      );

      final updateBookRequest = adapter.requests.firstWhere(
        (request) => request.key == 'PUT /books/book-1',
      );
      expect(
        _formDataField(updateBookRequest.data, 'title'),
        'La Nuit Rouge corrigée',
      );
      expect(
        _formDataFileName(updateBookRequest.data, 'coverImage'),
        'nuit-rouge-v2.jpg',
      );
    });

    test(
      'falls back to JSON when book cover multipart is unsupported',
      () async {
        final adapter = _SeedHttpClientAdapter(
          _seedResponses(),
          unsupportedMultipartKeys: const {'POST /books'},
        );
        final dio = Dio(BaseOptions(baseUrl: 'http://plumora.test/api/v1'))
          ..httpClientAdapter = adapter;
        final books = BookApiService(dio);

        final createdBook = await books.createBook(
          BookUpsertRequest(
            title: 'La Nuit Rouge',
            description: 'Thriller littéraire.',
            genre: 'Thriller',
            visibility: 'PRIVATE',
            coverImage: BookCoverUpload(
              fileName: 'nuit-rouge.jpg',
              bytes: Uint8List.fromList([1, 2, 3]),
            ),
          ),
        );

        final createRequests = adapter.requests
            .where((request) => request.key == 'POST /books')
            .toList(growable: false);

        expect(createdBook.id, 'book-1');
        expect(createRequests, hasLength(2));
        expect(createRequests.first.data, isA<FormData>());
        expect(createRequests.last.data, isA<Map<String, dynamic>>());
        expect(createRequests.last.data, isNot(contains('coverImage')));
        expect(
          createRequests.last.data,
          containsPair('title', 'La Nuit Rouge'),
        );
      },
    );
  });
}

List<String> _collectRoutePaths(List<RouteBase> routes) {
  final paths = <String>[];

  void collect(RouteBase route) {
    if (route is GoRoute) {
      paths.add(route.path);
    }

    try {
      final childRoutes = (route as dynamic).routes;
      if (childRoutes is List<RouteBase>) {
        for (final child in childRoutes) {
          collect(child);
        }
      }
    } on Object {
      return;
    }
  }

  for (final route in routes) {
    collect(route);
  }

  return paths;
}

String? _formDataField(Object? data, String name) {
  if (data is! FormData) {
    return null;
  }

  for (final field in data.fields) {
    if (field.key == name) {
      return field.value;
    }
  }

  return null;
}

String? _formDataFileName(Object? data, String name) {
  if (data is! FormData) {
    return null;
  }

  for (final file in data.files) {
    if (file.key == name) {
      return file.value.filename;
    }
  }

  return null;
}

Map<String, Object?> _seedResponses() {
  final user = {
    'id': 'user-1',
    'firstName': 'Kevin',
    'lastName': 'Fonkou',
    'username': 'kevin',
    'email': 'kevin@plumora.test',
  };
  final book = {
    'id': 'book-1',
    'title': 'La Nuit Rouge',
    'description': 'Thriller littéraire.',
    'genre': 'Thriller',
    'visibility': 'PUBLIC',
    'coverUrl': 'https://cdn.plumora.test/covers/nuit-rouge.jpg',
    'status': 'DRAFT',
    'chapterCount': 1,
    'progress': 35,
    'feedbackCount': 2,
  };
  final publishedBook = {...book, 'status': 'PUBLISHED'};
  final archivedBook = {...book, 'status': 'ARCHIVED'};
  final updatedBook = {
    ...book,
    'title': 'La Nuit Rouge corrigée',
    'description': 'Résumé corrigé.',
    'coverUrl': 'https://cdn.plumora.test/covers/nuit-rouge-v2.jpg',
  };
  final chapter = {
    'id': 'chapter-1',
    'bookId': 'book-1',
    'title': 'Chapitre 1',
    'content': 'Le début.',
    'order': 1,
  };
  final updatedChapter = {...chapter, 'title': 'Chapitre 1 corrigé'};
  final catalogBook = {
    ...publishedBook,
    'authorName': 'Kevin Fonkou',
    'averageRating': 4.8,
    'reviewCount': 7,
    'readCount': 42,
    'estimatedReadingMinutes': 90,
  };
  final catalogDetail = {
    ...catalogBook,
    'chapters': [chapter],
  };
  final externalBook = {
    'externalId': '123',
    'source': 'GUTENDEX',
    'title': 'Les Miserables',
    'authors': ['Victor Hugo'],
    'summary': 'Un roman social.',
    'subjects': ['French fiction'],
    'languages': ['fr'],
    'copyright': false,
    'mediaType': 'Text',
    'downloadCount': 42,
    'coverUrl': 'https://covers.openlibrary.org/b/id/987-L.jpg?default=false',
    'readUrl': 'https://read',
    'formats': {'text/html': 'https://read'},
    'sourceUrl': 'https://www.gutenberg.org/ebooks/123',
    'imported': false,
    'internalBookId': null,
  };
  final importedExternalBook = {
    ...publishedBook,
    'id': 'book-3',
    'title': 'Les Miserables',
    'description': 'Un roman social.',
    'genre': 'Classique',
    'coverUrl': 'https://covers.openlibrary.org/b/id/987-L.jpg?default=false',
  };
  final progress = {
    'bookId': 'book-1',
    'chapterId': 'chapter-1',
    'progress': 0.35,
    'finished': false,
    'book': catalogBook,
  };
  final review = {
    'id': 'review-1',
    'bookId': 'book-1',
    'userId': 'user-2',
    'userName': 'Lecteur Seed',
    'rating': 5,
    'comment': 'Excellent.',
    'book': catalogBook,
  };
  final secondReview = {
    'id': 'review-2',
    'bookId': 'book-1',
    'userId': 'user-3',
    'userName': 'Lecteur Plumora',
    'rating': 4,
    'comment': 'Belle ambiance.',
    'book': catalogBook,
    'user': {'firstName': 'Clara', 'lastName': 'Martin'},
  };
  final externalReview = {
    'id': 'external-review-1',
    'externalId': '123',
    'userId': 'user-4',
    'userName': 'Lecteur externe',
    'rating': 5,
    'comment': 'Lecture externe excellente.',
  };
  final campaign = {
    'id': 'campaign-1',
    'bookId': 'book-1',
    'bookTitle': 'La Nuit Rouge',
    'bookCoverUrl': 'https://cdn.plumora.test/covers/nuit-rouge.jpg',
    'authorUsername': 'Kevin Fonkou',
    'status': 'ACTIVE',
    'instructions': 'Chercher les incohérences.',
    'deadline': '2026-06-12',
    'engagedByMe': true,
  };
  final invitation = {
    'id': 'invitation-1',
    'campaignId': 'campaign-1',
    'bookId': 'book-1',
    'bookTitle': 'La Nuit Rouge',
    'bookCoverUrl': 'https://cdn.plumora.test/covers/nuit-rouge.jpg',
    'status': 'PENDING',
  };
  final sharedChapter = {
    'id': 'shared-1',
    'campaignId': 'campaign-1',
    'bookId': 'book-1',
    'chapterId': 'chapter-1',
    'title': 'Chapitre 1',
    'content': 'Le début partagé.',
    'order': 1,
  };
  final betaComment = {
    'id': 'comment-1',
    'bookId': 'book-1',
    'campaignId': 'campaign-1',
    'chapterId': 'chapter-1',
    'chapterTitle': 'Chapitre 1',
    'commentText': 'Ce passage contredit le chapitre précédent.',
    'feedbackType': 'PLOT',
    'priority': 'HIGH',
    'status': 'OPEN',
    'betaReaderUsername': 'Sarah Seed',
  };
  final suggestion = {
    'id': 'suggestion-1',
    'suggestionText': 'Elle avançait le cœur lourd.',
    'explanation': 'Phrase plus incarnée.',
    'status': 'PENDING',
  };
  final recommendation = {
    'id': 'result-1',
    'book': catalogBook,
    'matchScore': 94,
    'reasons': ['Suspense court', 'Ambiance sombre'],
    'rank': 1,
  };
  final notification = {
    'id': 'notification-1',
    'title': 'Nouveau retour bêta',
    'message': 'Sarah a ajouté un commentaire.',
    'type': 'BETA_COMMENT',
    'isRead': false,
  };

  return {
    'POST /auth/register': {'accessToken': 'seed-token', 'user': user},
    'POST /auth/login': {'accessToken': 'seed-token', 'user': user},
    'GET /auth/me': user,
    'GET /users/me': user,
    'GET /users/me/roles': {
      'roles': [
        {'name': 'AUTHOR'},
        {'name': 'READER'},
      ],
    },
    'PUT /users/me/roles': {
      'roles': [
        {'name': 'AUTHOR'},
        {'name': 'READER'},
      ],
    },
    'POST /books': book,
    'GET /books/my-books': {
      'books': [
        book,
        {...book, 'id': 'book-2', 'title': 'Les Ombres de Minuit'},
      ],
    },
    'GET /books/book-1': book,
    'PUT /books/book-1': updatedBook,
    'PATCH /books/book-1/publish': publishedBook,
    'PATCH /books/book-1/archive': archivedBook,
    'POST /books/book-1/chapters': chapter,
    'GET /books/book-1/chapters': {
      'chapters': [chapter],
    },
    'GET /chapters/chapter-1': chapter,
    'PUT /chapters/chapter-1': updatedChapter,
    'DELETE /chapters/chapter-1': _emptyResponse,
    'GET /catalog/books': {
      'books': [catalogBook],
    },
    'GET /catalog/books/latest': {
      'books': [catalogBook],
    },
    'GET /catalog/books/popular': {
      'books': [catalogBook],
    },
    'GET /catalog/books/search': {
      'books': [catalogBook],
    },
    'GET /catalog/books/book-1': catalogDetail,
    'GET /external-books': {
      'content': [externalBook],
      'page': 0,
      'size': 32,
      'totalElements': 100,
      'totalPages': 4,
      'first': true,
      'last': false,
    },
    'GET /external-books/123': externalBook,
    'POST /books/import/gutendex/123': importedExternalBook,
    'GET /books/book-1/read': catalogDetail,
    'GET /reading-progress/my': {
      'progress': [progress],
    },
    'GET /books/book-1/reading-progress': progress,
    'POST /books/book-1/reading-progress': {...progress, 'progress': 0.25},
    'PUT /books/book-1/reading-progress': {...progress, 'progress': 0.65},
    'PATCH /books/book-1/reading-progress/finish': {
      ...progress,
      'progress': 1,
      'finished': true,
    },
    'POST /books/book-1/favorites': _emptyResponse,
    'DELETE /books/book-1/favorites': _emptyResponse,
    'GET /favorites/my': {
      'favorites': [
        {'id': 'favorite-1', 'book': catalogBook},
      ],
    },
    'GET /books/book-1/favorites/status': {'favorite': true},
    'POST /books/book-1/reviews': review,
    'GET /books/book-1/reviews': {
      'reviews': [review, secondReview],
    },
    'GET /external-books/123/reviews': {
      'reviews': [externalReview],
    },
    'POST /external-books/123/reviews': externalReview,
    'GET /reviews/my': {
      'reviews': [review],
    },
    'PUT /reviews/review-1': {...review, 'rating': 4, 'comment': 'Très bon.'},
    'DELETE /reviews/review-1': _emptyResponse,
    'GET /users': [
      {'id': 'user-2', 'username': 'sarah_seed'},
    ],
    'GET /beta-invitations/my-invitations': {
      'invitations': [invitation],
    },
    'GET /beta-campaigns': {
      'campaigns': [campaign],
    },
    'POST /books/book-1/beta-campaigns': campaign,
    'GET /books/book-1/beta-campaigns': {
      'campaigns': [campaign],
    },
    'GET /beta-campaigns/campaign-1': campaign,
    'PATCH /beta-campaigns/campaign-1/close': {...campaign, 'status': 'CLOSED'},
    'PATCH /beta-campaigns/campaign-1/cancel': {
      ...campaign,
      'status': 'CANCELLED',
    },
    'POST /beta-campaigns/campaign-1/invitations': {
      ...invitation,
      'campaignId': 'campaign-1',
    },
    'GET /beta-campaigns/campaign-1/invitations': {
      'invitations': [invitation],
    },
    'PUT /beta-campaigns/campaign-1/chapters': {
      'chapters': [sharedChapter],
    },
    'POST /beta-campaigns/campaign-1/chapters/chapter-1/views': _emptyResponse,
    'PATCH /beta-invitations/invitation-1/accept': {
      ...invitation,
      'status': 'ACCEPTED',
    },
    'PATCH /beta-invitations/invitation-1/refuse': {
      ...invitation,
      'status': 'REFUSED',
    },
    'GET /beta-campaigns/campaign-1/chapters': {
      'chapters': [sharedChapter],
    },
    'POST /beta-comments': betaComment,
    'GET /books/book-1/beta-comments': {
      'comments': [betaComment],
    },
    'GET /beta-campaigns/campaign-1/comments': {
      'comments': [betaComment],
    },
    'PATCH /beta-comments/comment-1/status': {
      ...betaComment,
      'status': 'RESOLVED',
    },
    'DELETE /beta-comments/comment-1': _emptyResponse,
    'POST /ai/writing/suggestions': suggestion,
    'PATCH /ai/writing/suggestions/suggestion-1/accept': {
      ...suggestion,
      'status': 'ACCEPTED',
    },
    'PATCH /ai/writing/suggestions/suggestion-1/modify': {
      ...suggestion,
      'suggestionText': 'Elle avançait le cœur lourd.',
      'status': 'MODIFIED',
    },
    'PATCH /ai/writing/suggestions/suggestion-1/ignore': {
      ...suggestion,
      'status': 'IGNORED',
    },
    'POST /ai/recommendations/books': {
      'recommendations': [recommendation],
    },
    'GET /ai/recommendations/my-requests': {
      'requests': [
        {
          'id': 'request-1',
          'queryText': 'Un thriller court et sombre',
          'mood': 'SUSPENSE',
        },
      ],
    },
    'GET /notifications/my': {
      'notifications': [notification],
    },
    'GET /notifications/unread-count': {'count': 1},
    'PATCH /notifications/notification-1/read': {
      ...notification,
      'isRead': true,
    },
    'PATCH /notifications/read-all': _emptyResponse,
  };
}

const _emptyResponse = _EmptyResponse();

class _EmptyResponse {
  const _EmptyResponse();
}

class _SeedRequest {
  const _SeedRequest({
    required this.method,
    required this.path,
    required this.query,
    this.data,
  });

  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Object? data;

  String get key => '$method $path';
}

class _SeedHttpClientAdapter implements HttpClientAdapter {
  _SeedHttpClientAdapter(
    this.responses, {
    this.unsupportedMultipartKeys = const {},
  });

  final Map<String, Object?> responses;
  final Set<String> unsupportedMultipartKeys;
  final List<_SeedRequest> requests = [];

  List<String> get requestKeys =>
      requests.map((request) => request.key).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final request = _SeedRequest(
      method: options.method.toUpperCase(),
      path: options.path,
      query: Map<String, dynamic>.from(options.queryParameters),
      data: options.data,
    );
    final key = request.key;
    requests.add(request);

    if (unsupportedMultipartKeys.contains(key) && options.data is FormData) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Unexpected server error'}),
        500,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (!responses.containsKey(key)) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Missing seed response for $key'}),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final response = responses[key];
    if (response == _emptyResponse) {
      return ResponseBody.fromString('', 204);
    }

    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
