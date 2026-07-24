import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plumora_app/features/reading/data/models/report_model.dart';
import 'package:plumora_app/features/reading/data/services/report_api_service.dart';

/// Same fake-adapter pattern as `auth_repository_test.dart`: every request
/// is answered synchronously by [handler], so these tests exercise the real
/// [ReportApiService] + Dio request-building without ever calling a real
/// backend.
class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ReportApiService _buildService(
  ResponseBody Function(RequestOptions options) handler,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://fake.test/api/v1'));
  dio.httpClientAdapter = _FakeHttpAdapter(handler);
  return ReportApiService(dio);
}

ResponseBody _json(int statusCode, String body) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('ReportCreateRequest.toJson', () {
    test('sends the reason and trims the description', () {
      final request = ReportCreateRequest(
        reason: ReportReason.harassment,
        description: '  Contenu problématique  ',
      );

      expect(request.toJson(), {
        'reason': 'HARASSMENT',
        'description': 'Contenu problématique',
      });
    });

    test('omits the description entirely when empty', () {
      final request = ReportCreateRequest(reason: ReportReason.other);

      expect(request.toJson(), {'reason': 'OTHER'});
    });
  });

  group('ReportApiService.createReport', () {
    test('POSTs to /books/{bookId}/reports with the right body', () async {
      RequestOptions? capturedOptions;
      final service = _buildService((options) {
        capturedOptions = options;
        return _json(
          201,
          '{"id":"report-1","bookId":"book-42","reason":"HARASSMENT",'
          '"description":"Contenu problématique","status":"OPEN",'
          '"createdAt":"2026-07-24T10:00:00Z"}',
        );
      });

      final report = await service.createReport(
        'book-42',
        const ReportCreateRequest(
          reason: ReportReason.harassment,
          description: 'Contenu problématique',
        ),
      );

      expect(capturedOptions?.path, '/books/book-42/reports');
      expect(capturedOptions?.method, 'POST');
      expect(capturedOptions?.data, {
        'reason': 'HARASSMENT',
        'description': 'Contenu problématique',
      });
      expect(report.id, 'report-1');
      expect(report.bookId, 'book-42');
      expect(report.status, 'OPEN');
    });

    test('a 404 (book not found) surfaces as a DioException', () async {
      final service = _buildService(
        (options) => _json(404, '{"message":"Book not found"}'),
      );

      await expectLater(
        service.createReport(
          'missing-book',
          const ReportCreateRequest(reason: ReportReason.other),
        ),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('a 409 (already reported) surfaces as a DioException', () async {
      final service = _buildService(
        (options) => _json(409, '{"message":"Already reported"}'),
      );

      await expectLater(
        service.createReport(
          'book-42',
          const ReportCreateRequest(reason: ReportReason.other),
        ),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'statusCode',
            409,
          ),
        ),
      );
    });
  });
}
