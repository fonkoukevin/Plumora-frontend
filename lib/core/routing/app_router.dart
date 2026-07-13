import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/ai/presentation/plumo_recommendation_screen.dart';
import '../../features/ai/presentation/plumo_writing_screen.dart';
import '../../features/admin/presentation/admin_access_denied_screen.dart';
import '../../features/admin/presentation/admin_ai_screen.dart';
import '../../features/admin/presentation/admin_catalog_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_public_domain_import_screen.dart';
import '../../features/admin/presentation/admin_reports_screen.dart';
import '../../features/admin/presentation/admin_route_guard.dart';
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/beta_reading/presentation/author_beta_comments_screen.dart';
import '../../features/beta_reading/presentation/beta_campaign_detail_author_screen.dart';
import '../../features/beta_reading/presentation/beta_campaigns_author_screen.dart';
import '../../features/beta_reading/presentation/beta_invitations_screen.dart';
import '../../features/beta_reading/presentation/beta_read_chapter_screen.dart';
import '../../features/beta_reading/presentation/beta_reading_chapters_screen.dart';
import '../../features/catalog/presentation/book_detail_screen.dart';
import '../../features/catalog/presentation/catalog_search_screen.dart';
import '../../features/catalog/presentation/discover_screen.dart';
import '../../features/catalog/presentation/external_book_detail_screen.dart';
import '../../features/catalog/presentation/public_domain_catalog_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/landing_screen.dart';
import '../../features/notification/presentation/notifications_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/preferences_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reading/presentation/library_screen.dart';
import '../../features/reading/presentation/my_favorites_screen.dart';
import '../../features/reading/presentation/my_reviews_screen.dart';
import '../../features/reading/presentation/reading_screen.dart';
import '../../features/writing/presentation/author_dashboard_screen.dart';
import '../../features/writing/presentation/book_detail_author_screen.dart';
import '../../features/writing/presentation/chapter_detail_author_screen.dart';
import '../../features/writing/presentation/chapter_editor_screen.dart';
import '../../features/writing/presentation/create_book_screen.dart';
import '../../features/writing/presentation/my_books_screen.dart';
import '../../features/writing/presentation/publish_book_screen.dart';
import '../widgets/plumora_placeholder_screen.dart';
import 'main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRedirectRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.landing,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      if (authState.isLoading && !authState.hasValue) {
        return null;
      }

      final session = authState.valueOrNull;
      final isAuthenticated = session?.isAuthenticated ?? false;

      final adminRedirect = AdminRouteGuard.redirect(
        location: state.matchedLocation,
        isAuthenticated: isAuthenticated,
        roleNames: session?.roles.map((role) => role.name).toList() ?? const [],
      );
      if (adminRedirect != null) {
        return adminRedirect;
      }

      if (isAuthenticated || _isPublicLocation(state.matchedLocation)) {
        return null;
      }

      return AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.landing,
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.editRoles,
        name: 'edit-roles',
        builder: (context, state) =>
            const RoleSelectionScreen(isOnboarding: false),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.preferences,
        name: 'preferences',
        builder: (context, state) => const PreferencesScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.discover,
            name: 'discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: AppRoutes.publicDomainCatalog,
            name: 'public-domain-catalog',
            builder: (context, state) => PublicDomainCatalogScreen(
              initialSearch: state.uri.queryParameters['search'] ?? '',
              initialLanguage: state.uri.queryParameters['language'],
              initialTopic: state.uri.queryParameters['topic'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.publicDomainBookDetail,
            name: 'public-domain-book-detail',
            builder: (context, state) {
              final gutendexId = Uri.decodeComponent(
                state.pathParameters['gutendexId'] ?? '',
              );
              return ExternalBookDetailScreen(gutendexId: gutendexId);
            },
          ),
          GoRoute(
            path: AppRoutes.catalogSearch,
            name: 'catalog-search',
            builder: (context, state) {
              return CatalogSearchScreen(
                initialQuery: state.uri.queryParameters['q'] ?? '',
              );
            },
          ),
          GoRoute(
            path: AppRoutes.catalogBookDetail,
            name: 'catalog-book-detail',
            builder: (context, state) {
              final bookId = Uri.decodeComponent(
                state.pathParameters['bookId'] ?? '',
              );
              return BookDetailScreen(bookId: bookId);
            },
          ),
          GoRoute(
            path: AppRoutes.plumoRecommendation,
            name: 'plumo-recommendation',
            builder: (context, state) => const PlumoRecommendationScreen(),
          ),
          GoRoute(
            path: AppRoutes.plumoWriting,
            name: 'plumo-writing',
            builder: (context, state) => PlumoWritingScreen(
              chapterId: state.uri.queryParameters['chapterId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.write,
            name: 'write',
            builder: (context, state) => const AuthorDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.manuscripts,
            name: 'manuscripts',
            builder: (context, state) => const MyBooksScreen(),
          ),
          GoRoute(
            path: AppRoutes.createBook,
            name: 'create-book',
            builder: (context, state) => const CreateBookScreen(),
          ),
          GoRoute(
            path: AppRoutes.editBook,
            name: 'edit-book',
            builder: (context, state) {
              final bookId = Uri.decodeComponent(
                state.pathParameters['bookId'] ?? '',
              );
              return CreateBookScreen(bookId: bookId);
            },
          ),
          GoRoute(
            path: AppRoutes.authorBookDetail,
            name: 'author-book-detail',
            builder: (context, state) {
              final bookId = Uri.decodeComponent(
                state.pathParameters['bookId'] ?? '',
              );
              return BookDetailAuthorScreen(bookId: bookId);
            },
          ),
          GoRoute(
            path: AppRoutes.publishBook,
            name: 'publish-book',
            builder: (context, state) {
              final bookId = Uri.decodeComponent(
                state.pathParameters['bookId'] ?? '',
              );
              return PublishBookScreen(bookId: bookId);
            },
          ),
          GoRoute(
            path: AppRoutes.authorChapterDetail,
            name: 'author-chapter-detail',
            builder: (context, state) {
              final chapterId = Uri.decodeComponent(
                state.pathParameters['chapterId'] ?? '',
              );
              return ChapterDetailAuthorScreen(
                chapterId: chapterId,
                bookId: state.uri.queryParameters['bookId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.betaFeedback,
            name: 'beta-feedback',
            builder: (context, state) => const AuthorBetaCommentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.royalties,
            name: 'royalties',
            builder: (context, state) => const PlumoraPlaceholderScreen(
              title: 'Revenus & Statistiques',
              subtitle:
                  'Les royalties réelles ne font pas partie du MVP actuel.',
              icon: Icons.trending_up_outlined,
            ),
          ),
          GoRoute(
            path: AppRoutes.authorBetaComments,
            name: 'author-beta-comments',
            builder: (context, state) {
              final bookId = Uri.decodeComponent(
                state.pathParameters['bookId'] ?? '',
              );
              return AuthorBetaCommentsScreen(bookId: bookId);
            },
          ),
          GoRoute(
            path: AppRoutes.authorBetaCampaigns,
            name: 'author-beta-campaigns',
            builder: (context, state) {
              final bookId = Uri.decodeComponent(
                state.pathParameters['bookId'] ?? '',
              );
              return BetaCampaignsAuthorScreen(bookId: bookId);
            },
          ),
          GoRoute(
            path: AppRoutes.authorBetaCampaignDetail,
            name: 'author-beta-campaign-detail',
            builder: (context, state) {
              final campaignId = Uri.decodeComponent(
                state.pathParameters['campaignId'] ?? '',
              );
              return BetaCampaignDetailAuthorScreen(
                campaignId: campaignId,
                bookId: state.uri.queryParameters['bookId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.betaInvitations,
            name: 'beta-invitations',
            builder: (context, state) => const BetaInvitationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.betaChapters,
            name: 'beta-chapters',
            builder: (context, state) {
              final campaignId = Uri.decodeComponent(
                state.pathParameters['campaignId'] ?? '',
              );
              return BetaReadingChaptersScreen(
                campaignId: campaignId,
                invitationId: state.uri.queryParameters['invitationId'],
                bookId: state.uri.queryParameters['bookId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.library,
            name: 'library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: AppRoutes.libraryFavorites,
            name: 'library-favorites',
            builder: (context, state) => const MyFavoritesScreen(),
          ),
          GoRoute(
            path: AppRoutes.libraryReviews,
            name: 'library-reviews',
            builder: (context, state) => const MyReviewsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
      // The chapter editor is a full-screen, immersive experience with no
      // bottom nav / sidebar (matching the Figma EditorPage/MobileEditorPage
      // mockups) — it lives outside the ShellRoute entirely, like `reading`
      // and `beta-read-chapter` below, instead of being nested inside the
      // shell and having MainShell conditionally hide its own chrome. That
      // conditional-hide approach caused a brief "No Material widget found"
      // flash when navigating in/out, because the widget tree structure
      // changed too abruptly at the same ShellRoute position.
      GoRoute(
        path: AppRoutes.editor,
        name: 'editor',
        builder: (context, state) => const ChapterEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.chapterEditor,
        name: 'chapter-editor',
        builder: (context, state) {
          final bookId = Uri.decodeComponent(
            state.pathParameters['bookId'] ?? '',
          );
          return ChapterEditorScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: AppRoutes.reading,
        name: 'reading',
        builder: (context, state) {
          final bookId = Uri.decodeComponent(
            state.pathParameters['bookId'] ?? '',
          );
          return ReadingScreen(
            bookId: bookId,
            initialChapterId: state.uri.queryParameters['chapterId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.betaReadChapter,
        name: 'beta-read-chapter',
        builder: (context, state) {
          final campaignId = Uri.decodeComponent(
            state.pathParameters['campaignId'] ?? '',
          );
          final chapterId = Uri.decodeComponent(
            state.pathParameters['chapterId'] ?? '',
          );
          return BetaReadChapterScreen(
            campaignId: campaignId,
            chapterId: chapterId,
            invitationId: state.uri.queryParameters['invitationId'],
            bookId: state.uri.queryParameters['bookId'],
          );
        },
      ),
      // Administration is a self-contained space with its own fixed dark
      // chrome (AdminShell) matching the Figma admin mockup, so — like the
      // editor/reading routes above — it lives outside MainShell's
      // ShellRoute rather than trying to make MainShell's nav conditionally
      // disappear for a completely different navigation structure.
      GoRoute(
        path: AppRoutes.adminAccessDenied,
        name: 'admin-access-denied',
        builder: (context, state) => const AdminAccessDeniedScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        name: 'admin-users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCatalog,
        name: 'admin-catalog',
        builder: (context, state) => const AdminCatalogScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPublicDomainImport,
        name: 'admin-public-domain-import',
        builder: (context, state) => const AdminPublicDomainImportScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        name: 'admin-reports',
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAi,
        name: 'admin-ai',
        builder: (context, state) => const AdminAiScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        name: 'admin-settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
    ],
  );
});

abstract final class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/roles';
  static const String editRoles = '/roles/edit';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String publicDomainCatalog = '/discover/public-domain';
  static const String publicDomainBookDetail =
      '/discover/public-domain/:gutendexId';
  static const String catalogSearch = '/discover/search';
  static const String catalogBookDetail = '/catalog/books/:bookId';
  static const String reading = '/books/:bookId/read';
  static const String plumoRecommendation = '/plumo/recommendation';
  static const String plumoWriting = '/plumo/writing';
  static const String write = '/write';
  static const String manuscripts = '/manuscripts';
  static const String editor = '/editor';
  static const String createBook = '/books/new';
  static const String editBook = '/books/:bookId/edit';
  static const String authorBookDetail = '/books/:bookId/author';
  static const String publishBook = '/books/:bookId/publish';
  static const String chapterEditor = '/books/:bookId/editor';
  static const String authorChapterDetail = '/chapters/:chapterId/author';
  static const String betaFeedback = '/beta-feedback';
  static const String royalties = '/royalties';
  static const String authorBetaComments = '/books/:bookId/beta-comments';
  static const String authorBetaCampaigns = '/books/:bookId/beta-campaigns';
  static const String authorBetaCampaignDetail = '/beta/campaigns/:campaignId';
  static const String betaInvitations = '/beta/invitations';
  static const String betaChapters = '/beta/campaigns/:campaignId/chapters';
  static const String betaReadChapter =
      '/beta/campaigns/:campaignId/chapters/:chapterId/read';
  static const String library = '/library';
  static const String libraryFavorites = '/library/favorites';
  static const String libraryReviews = '/library/reviews';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String preferences = '/profile/preferences';
  static const String notifications = '/notifications';
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminCatalog = '/admin/catalog';
  static const String adminPublicDomainImport = '/admin/public-domain-import';
  static const String adminReports = '/admin/reports';
  static const String adminAi = '/admin/ai';
  static const String adminSettings = '/admin/settings';
  static const String adminAccessDenied = '/admin/access-denied';

  static String authorBookDetailPath(String bookId) {
    final encoded = Uri.encodeComponent(bookId.trim());
    if (encoded.isEmpty) {
      return manuscripts;
    }

    return '/books/$encoded/author';
  }

  static String catalogSearchPath(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return catalogSearch;
    }

    return '$catalogSearch?q=${Uri.encodeQueryComponent(normalized)}';
  }

  static String publicDomainCatalogPath({
    String? search,
    String? language,
    String? topic,
  }) {
    final query = <String, String>{};
    final normalizedSearch = search?.trim();
    final normalizedLanguage = language?.trim().toLowerCase();
    final normalizedTopic = topic?.trim();

    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (normalizedLanguage == 'fr' || normalizedLanguage == 'en') {
      query['language'] = normalizedLanguage!;
    }
    if (normalizedTopic != null && normalizedTopic.isNotEmpty) {
      query['topic'] = normalizedTopic;
    }

    if (query.isEmpty) {
      return publicDomainCatalog;
    }

    final params = query.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');

    return '$publicDomainCatalog?$params';
  }

  static String publicDomainBookDetailPath(String gutendexId) {
    final encoded = Uri.encodeComponent(gutendexId.trim());
    if (encoded.isEmpty) {
      return publicDomainCatalog;
    }

    return '$publicDomainCatalog/$encoded';
  }

  static String catalogBookDetailPath(String bookId) {
    final encoded = Uri.encodeComponent(bookId.trim());
    if (encoded.isEmpty) {
      return discover;
    }

    return '/catalog/books/$encoded';
  }

  static String readingPath(String bookId, {String? chapterId}) {
    final encoded = Uri.encodeComponent(bookId.trim());
    if (encoded.isEmpty) {
      return library;
    }

    final normalizedChapterId = chapterId?.trim();
    if (normalizedChapterId == null || normalizedChapterId.isEmpty) {
      return '/books/$encoded/read';
    }

    return '/books/$encoded/read?chapterId=${Uri.encodeQueryComponent(normalizedChapterId)}';
  }

  static String editBookPath(String bookId) {
    final encoded = Uri.encodeComponent(bookId.trim());
    if (encoded.isEmpty) {
      return createBook;
    }

    return '/books/$encoded/edit';
  }

  static String chapterEditorPath(String bookId) {
    final encoded = Uri.encodeComponent(bookId.trim());
    if (encoded.isEmpty) {
      return editor;
    }

    return '/books/$encoded/editor';
  }

  static String publishBookPath(String bookId) {
    final encoded = Uri.encodeComponent(bookId.trim());
    if (encoded.isEmpty) {
      return write;
    }

    return '/books/$encoded/publish';
  }

  static String plumoWritingPath({String? chapterId}) {
    final normalizedChapterId = chapterId?.trim();
    if (normalizedChapterId == null || normalizedChapterId.isEmpty) {
      return plumoWriting;
    }

    return '$plumoWriting?chapterId=${Uri.encodeQueryComponent(normalizedChapterId)}';
  }

  static String authorChapterDetailPath(String chapterId, {String? bookId}) {
    final encoded = Uri.encodeComponent(chapterId.trim());
    if (encoded.isEmpty) {
      final normalizedBookId = bookId?.trim() ?? '';
      return normalizedBookId.isEmpty
          ? write
          : chapterEditorPath(normalizedBookId);
    }

    final normalizedBookId = bookId?.trim();
    if (normalizedBookId == null || normalizedBookId.isEmpty) {
      return '/chapters/$encoded/author';
    }

    return '/chapters/$encoded/author?bookId=${Uri.encodeQueryComponent(normalizedBookId)}';
  }

  static String authorBetaCommentsPath(String bookId) {
    final encoded = Uri.encodeComponent(bookId.trim());
    if (encoded.isEmpty) {
      return betaFeedback;
    }

    return '/books/$encoded/beta-comments';
  }

  static String authorBetaCampaignsPath(String bookId) {
    final encoded = Uri.encodeComponent(bookId.trim());
    if (encoded.isEmpty) {
      return write;
    }

    return '/books/$encoded/beta-campaigns';
  }

  static String authorBetaCampaignDetailPath(
    String campaignId, {
    String? bookId,
  }) {
    final encoded = Uri.encodeComponent(campaignId.trim());
    if (encoded.isEmpty) {
      final normalizedBookId = bookId?.trim() ?? '';
      return normalizedBookId.isEmpty
          ? betaFeedback
          : authorBetaCampaignsPath(normalizedBookId);
    }

    final normalizedBookId = bookId?.trim();
    if (normalizedBookId == null || normalizedBookId.isEmpty) {
      return '/beta/campaigns/$encoded';
    }

    return '/beta/campaigns/$encoded?bookId=${Uri.encodeQueryComponent(normalizedBookId)}';
  }

  static String betaChaptersPath(
    String campaignId, {
    String? invitationId,
    String? bookId,
  }) {
    final encoded = Uri.encodeComponent(campaignId.trim());
    if (encoded.isEmpty) {
      return library;
    }

    final query = <String, String>{};
    if (invitationId != null && invitationId.trim().isNotEmpty) {
      query['invitationId'] = invitationId.trim();
    }
    if (bookId != null && bookId.trim().isNotEmpty) {
      query['bookId'] = bookId.trim();
    }

    final params = query.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');

    return '/beta/campaigns/$encoded/chapters${params.isEmpty ? '' : '?$params'}';
  }

  static String betaReadChapterPath(
    String campaignId,
    String chapterId, {
    String? bookId,
    String? invitationId,
  }) {
    final encodedCampaign = Uri.encodeComponent(campaignId.trim());
    final encodedChapter = Uri.encodeComponent(chapterId.trim());
    if (encodedCampaign.isEmpty || encodedChapter.isEmpty) {
      return betaChaptersPath(
        campaignId,
        invitationId: invitationId,
        bookId: bookId,
      );
    }

    final query = <String, String>{};
    if (bookId != null && bookId.trim().isNotEmpty) {
      query['bookId'] = bookId.trim();
    }
    if (invitationId != null && invitationId.trim().isNotEmpty) {
      query['invitationId'] = invitationId.trim();
    }

    final params = query.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');

    return '/beta/campaigns/$encodedCampaign/chapters/$encodedChapter/read${params.isEmpty ? '' : '?$params'}';
  }
}

/// Locations reachable without an authenticated session: the marketing
/// landing page, the auth screens, and the public book catalog (so visitors
/// can browse before signing up). Everything else behind [MainShell] — the
/// home dashboard, writing tools, library, profile, notifications — as well
/// as the standalone reading/beta-reading routes require a session.
bool _isPublicLocation(String location) {
  if (location == AppRoutes.landing) {
    return true;
  }

  const publicPrefixes = ['/login', '/register', '/discover', '/catalog'];
  return publicPrefixes.any(
    (prefix) => location == prefix || location.startsWith('$prefix/'),
  );
}

class _AuthRedirectRefresh extends ChangeNotifier {
  _AuthRedirectRefresh(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }
}
