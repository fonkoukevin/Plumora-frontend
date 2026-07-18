import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../book/data/models/book_model.dart';
import '../models/external_book_model.dart';
import '../services/external_book_api_service.dart';

final externalBookApiServiceProvider = Provider<ExternalBookApiService>((ref) {
  return ExternalBookApiService(ref.watch(dioProvider));
});

final externalBookRepositoryProvider = Provider<ExternalBookRepository>((ref) {
  return ExternalBookRepository(ref.watch(externalBookApiServiceProvider));
});

final externalBookSearchProvider =
    FutureProvider.family<ExternalBookPage, ExternalBookSearchQuery>((
      ref,
      query,
    ) async {
      final page = await ref
          .watch(externalBookRepositoryProvider)
          .searchExternalBooks(
            search: query.search,
            language: query.language,
            topic: query.topic,
            page: query.page,
          );

      final language = _normalizeExternalLanguage(query.language);
      if (language.isEmpty) {
        return page;
      }

      final filteredBooks = page.content.where((book) {
        return book.languages.any(
          (value) => _normalizeExternalLanguage(value) == language,
        );
      }).toList();

      return ExternalBookPage(
        content: filteredBooks,
        page: page.page,
        size: page.size,
        totalElements: page.totalElements,
        totalPages: page.totalPages,
        first: page.first,
        last: page.last,
      );
    });

final externalBookDetailProvider = FutureProvider.family<ExternalBook, String>((
  ref,
  gutendexId,
) {
  return ref.watch(externalBookRepositoryProvider).getExternalBook(gutendexId);
});

class ExternalBookSearchQuery {
  const ExternalBookSearchQuery({
    this.search,
    this.language,
    this.topic,
    this.page = 0,
  });

  final String? search;
  final String? language;
  final String? topic;
  final int page;

  @override
  bool operator ==(Object other) {
    return other is ExternalBookSearchQuery &&
        other.search == search &&
        other.language == language &&
        other.topic == topic &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(search, language, topic, page);
}

class ExternalBookRepository {
  const ExternalBookRepository(this._apiService);

  final ExternalBookApiService _apiService;

  Future<ExternalBookPage> searchExternalBooks({
    String? search,
    String? language,
    String? topic,
    int page = 0,
  }) {
    return _withTransientRetry(
      () => _apiService.searchExternalBooks(
        search: search,
        language: language,
        topic: topic,
        page: page,
      ),
    );
  }

  Future<ExternalBook> getExternalBook(String gutendexId) {
    return _withTransientRetry(() => _apiService.getExternalBook(gutendexId));
  }

  Future<ExternalBook> getExternalBookDetails(String externalId) {
    return getExternalBook(externalId);
  }

  Future<BookModel> importGutendexBook(String gutendexId) {
    return _apiService.importGutendexBook(gutendexId);
  }

  Future<T> _withTransientRetry<T>(Future<T> Function() request) async {
    const delays = [
      Duration(milliseconds: 450),
      Duration(milliseconds: 900),
      Duration(milliseconds: 1400),
    ];

    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        return await request();
      } catch (error, stackTrace) {
        final lastAttempt = attempt == delays.length;
        if (lastAttempt || !_shouldRetry(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }

        await Future<void>.delayed(delays[attempt]);
      }
    }

    throw StateError('External book retry loop exited unexpectedly.');
  }

  bool _shouldRetry(Object error) {
    if (error is! DioException) {
      return false;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 500 ||
            statusCode == 502 ||
            statusCode == 503 ||
            statusCode == 504) {
          return true;
        }

        return _responseText(error.response?.data).contains('gutendex');
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
    }
  }

  String _responseText(Object? data) {
    if (data is Map) {
      return data.values.map(_responseText).join(' ').toLowerCase();
    }

    if (data is Iterable) {
      return data.map(_responseText).join(' ').toLowerCase();
    }

    return data?.toString().toLowerCase() ?? '';
  }
}

String _normalizeExternalLanguage(String? language) {
  final value = language?.trim().toLowerCase() ?? '';
  if (value.startsWith('fr-')) {
    return 'fr';
  }
  if (value.startsWith('en-')) {
    return 'en';
  }
  return value;
}
