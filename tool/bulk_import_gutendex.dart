// Bulk-imports public domain books from Gutendex into the Plumora catalog.
//
// Reuses the exact endpoints the "Import domaine public" admin screen calls
// one book at a time (see lib/features/admin/presentation/
// admin_public_domain_import_screen.dart): GET /external-books to discover
// candidates, then POST /admin/books/import/gutendex/{id} for each one.
// Requires an ADMIN account on the target backend.
//
// Usage:
//   dart run tool/bulk_import_gutendex.dart --email=admin@plumora.fr --password=*** --count=100
//   dart run tool/bulk_import_gutendex.dart --token=eyJ... --language=fr --count=150
//   dart run tool/bulk_import_gutendex.dart --help
//
// Credentials/base URL can also come from env vars (avoids shell history):
//   PLUMORA_API_BASE_URL, PLUMORA_ADMIN_EMAIL, PLUMORA_ADMIN_PASSWORD, PLUMORA_ADMIN_TOKEN

import 'dart:io';

import 'package:dio/dio.dart';

const _defaultBaseUrl = 'http://localhost:8080/api/v1';
const _defaultCount = 100;
const _defaultDelayMs = 300;
const _maxPages = 300;

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (options.showHelp) {
    _printUsage();
    return;
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: options.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  final token = await _resolveToken(dio, options);
  if (token == null) {
    exit(1);
  }
  dio.options.headers['Authorization'] = 'Bearer $token';

  stdout.writeln(
    'Import Gutendex → cible ${options.count} livre(s) '
    '(langue: ${options.language ?? 'toutes'}'
    '${options.search != null ? ', recherche: "${options.search}"' : ''}'
    '${options.dryRun ? ', DRY-RUN' : ''}) sur ${options.baseUrl}',
  );

  var imported = 0;
  var alreadyExisted = 0;
  var failed = 0;
  var scanned = 0;
  var page = 0;

  while (imported + alreadyExisted < options.count && page < _maxPages) {
    List<Object?> content;
    bool isLastPage;
    try {
      final response = await dio.get(
        '/external-books',
        queryParameters: {
          'page': page,
          if (options.search != null) 'search': options.search,
          if (options.language != null) 'language': options.language,
        },
      );
      final body = _asMap(response.data);
      content = _asList(
        body['content'] ?? body['items'] ?? body['results'] ?? response.data,
      );
      isLastPage = body['last'] == true;
    } on DioException catch (e) {
      stderr.writeln('Erreur de recherche (page $page) : ${_describeError(e)}');
      break;
    }

    if (content.isEmpty) {
      stdout.writeln('Aucun résultat supplémentaire (page $page) — arrêt.');
      break;
    }

    for (final raw in content) {
      if (imported + alreadyExisted >= options.count) break;
      final book = _asMap(raw);
      scanned++;

      final source = (book['source'] ?? 'GUTENDEX').toString().toUpperCase();
      final externalId = _firstNonEmpty(book, ['externalId', 'id', 'gutendexId']);
      final alreadyImportedFlag = book['imported'] == true;
      final title = _firstNonEmpty(book, ['title', 'name']) ?? '(sans titre)';

      // Placeholder results (e.g. OPEN_LIBRARY fallback) don't carry a real
      // Gutendex id and can't be imported through this endpoint.
      if (source != 'GUTENDEX' || externalId == null) {
        continue;
      }
      if (alreadyImportedFlag) {
        continue;
      }

      if (options.dryRun) {
        imported++;
        stdout.writeln(
          '[${imported + alreadyExisted}/${options.count}] (dry-run) importerait : $title',
        );
        continue;
      }

      try {
        final response = await dio.post(
          '/admin/books/import/gutendex/$externalId',
        );
        final result = _asMap(response.data);
        if (result['alreadyExisted'] == true) {
          alreadyExisted++;
          stdout.writeln(
            '[${imported + alreadyExisted}/${options.count}] déjà présent : $title',
          );
        } else {
          imported++;
          stdout.writeln(
            '[${imported + alreadyExisted}/${options.count}] importé : $title',
          );
        }
      } on DioException catch (e) {
        failed++;
        stderr.writeln('Échec import "$title" ($externalId) : ${_describeError(e)}');
      }

      if (options.delay > Duration.zero) {
        await Future.delayed(options.delay);
      }
    }

    page++;
    if (isLastPage) {
      stdout.writeln('Dernière page Gutendex atteinte — arrêt.');
      break;
    }
  }

  stdout.writeln('---');
  stdout.writeln(
    'Terminé : $imported importé(s), $alreadyExisted déjà présent(s), '
    '$failed échec(s), $scanned livre(s) scanné(s).',
  );
  exit(failed > 0 && imported == 0 && alreadyExisted == 0 ? 1 : 0);
}

Future<String?> _resolveToken(Dio dio, _Options options) async {
  if (options.token != null) {
    return options.token;
  }
  if (options.email == null || options.password == null) {
    stderr.writeln(
      'Fournis soit --token=<jwt>, soit --email=<...> --password=<...> '
      '(ou les variables d\'env correspondantes).',
    );
    _printUsage();
    return null;
  }

  stdout.writeln('Connexion en tant que ${options.email}...');
  try {
    final response = await dio.post(
      '/auth/login',
      data: {'email': options.email, 'password': options.password},
    );
    final body = _asMap(response.data);
    final data = body['data'];
    final tokenKeys = ['accessToken', 'access_token', 'token', 'jwt'];
    final token =
        _firstNonEmpty(body, tokenKeys) ??
        (data is Map ? _firstNonEmpty(_asMap(data), tokenKeys) : null);
    if (token == null) {
      stderr.writeln('Connexion réussie mais aucun token dans la réponse.');
      return null;
    }
    return token;
  } on DioException catch (e) {
    stderr.writeln('Échec de connexion : ${_describeError(e)}');
    return null;
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
  return const {};
}

List<Object?> _asList(Object? value) {
  if (value is List) return value;
  return const [];
}

String? _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

String _describeError(DioException e) {
  final status = e.response?.statusCode;
  final data = e.response?.data;
  if (status != null) {
    return 'HTTP $status ${data ?? e.message ?? ''}';
  }
  return e.message ?? e.toString();
}

class _Options {
  const _Options({
    required this.baseUrl,
    required this.count,
    required this.delay,
    this.email,
    this.password,
    this.token,
    this.language,
    this.search,
    this.dryRun = false,
    this.showHelp = false,
  });

  final String baseUrl;
  final int count;
  final Duration delay;
  final String? email;
  final String? password;
  final String? token;
  final String? language;
  final String? search;
  final bool dryRun;
  final bool showHelp;

  static _Options parse(List<String> arguments) {
    final map = <String, String>{};
    var dryRun = false;
    var showHelp = false;

    for (final arg in arguments) {
      if (arg == '--help' || arg == '-h') {
        showHelp = true;
        continue;
      }
      if (arg == '--dry-run') {
        dryRun = true;
        continue;
      }
      if (arg.startsWith('--') && arg.contains('=')) {
        final index = arg.indexOf('=');
        map[arg.substring(2, index)] = arg.substring(index + 1);
      }
    }

    String? env(String key) {
      final value = Platform.environment[key];
      return (value != null && value.trim().isNotEmpty) ? value.trim() : null;
    }

    return _Options(
      baseUrl: map['base-url'] ?? env('PLUMORA_API_BASE_URL') ?? _defaultBaseUrl,
      count: int.tryParse(map['count'] ?? '') ?? _defaultCount,
      delay: Duration(
        milliseconds: int.tryParse(map['delay-ms'] ?? '') ?? _defaultDelayMs,
      ),
      email: map['email'] ?? env('PLUMORA_ADMIN_EMAIL'),
      password: map['password'] ?? env('PLUMORA_ADMIN_PASSWORD'),
      token: map['token'] ?? env('PLUMORA_ADMIN_TOKEN'),
      language: map['language'],
      search: map['search'],
      dryRun: dryRun,
      showHelp: showHelp,
    );
  }
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run tool/bulk_import_gutendex.dart [options]

Importe en masse des livres du domaine public (Gutendex) dans le catalogue
Plumora, en réutilisant les mêmes endpoints que l'écran admin "Import domaine
public" (GET /external-books puis POST /admin/books/import/gutendex/{id}).
Nécessite un compte ADMIN sur le backend ciblé.

Options :
  --base-url=URL        Origine de l'API (défaut: $_defaultBaseUrl,
                         ou variable d'env PLUMORA_API_BASE_URL)
  --email=EMAIL          Email admin (ou variable d'env PLUMORA_ADMIN_EMAIL)
  --password=PASSWORD    Mot de passe admin (ou PLUMORA_ADMIN_PASSWORD)
  --token=JWT             Bearer token déjà obtenu, à la place d'email/password
                          (ou variable d'env PLUMORA_ADMIN_TOKEN)
  --count=N                Nombre de livres à importer (défaut: $_defaultCount)
  --language=fr|en|...      Filtre de langue passé à /external-books
  --search=TEXTE            Filtre titre/auteur passé à /external-books
  --delay-ms=300              Pause entre deux imports (défaut: ${_defaultDelayMs}ms)
  --dry-run                    N'appelle pas l'import, liste juste ce qui serait fait
  --help                       Affiche cette aide

Exemples :
  dart run tool/bulk_import_gutendex.dart --email=admin@plumora.fr --password=*** --count=150
  dart run tool/bulk_import_gutendex.dart --token=eyJ... --language=fr --count=100
  dart run tool/bulk_import_gutendex.dart --token=eyJ... --count=100 --dry-run
''');
}
