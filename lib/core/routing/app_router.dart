import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/beta_reading/presentation/beta_feedback_screen.dart';
import '../../features/catalog/presentation/discover_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/landing_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reading/presentation/library_screen.dart';
import '../../features/writing/presentation/author_dashboard_screen.dart';
import '../../features/writing/presentation/book_detail_author_screen.dart';
import '../../features/writing/presentation/chapter_editor_screen.dart';
import '../../features/writing/presentation/create_book_screen.dart';
import '../../features/writing/presentation/my_books_screen.dart';
import 'main_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.landing,
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
          path: AppRoutes.editor,
          name: 'editor',
          builder: (context, state) => const ChapterEditorScreen(),
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
          path: AppRoutes.betaFeedback,
          name: 'beta-feedback',
          builder: (context, state) => const BetaFeedbackScreen(),
        ),
        GoRoute(
          path: AppRoutes.library,
          name: 'library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

abstract final class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/roles';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String write = '/write';
  static const String manuscripts = '/manuscripts';
  static const String editor = '/editor';
  static const String createBook = '/books/new';
  static const String editBook = '/books/:bookId/edit';
  static const String authorBookDetail = '/books/:bookId/author';
  static const String chapterEditor = '/books/:bookId/editor';
  static const String betaFeedback = '/beta-feedback';
  static const String library = '/library';
  static const String profile = '/profile';

  static String authorBookDetailPath(String bookId) {
    final encoded = Uri.encodeComponent(bookId.trim());
    if (encoded.isEmpty) {
      return manuscripts;
    }

    return '/books/$encoded/author';
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
}
