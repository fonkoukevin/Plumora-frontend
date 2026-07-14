/// Models for the stateless, Gemini-backed "Plumo IA" endpoints
/// (`/ai/writing/rewrite|summarize|continue|titles`, `/ai/beta-reading/analyze`,
/// `/ai/books/recommend`) -- distinct from the older persisted Mukeme-era
/// suggestion/recommendation flow in `ai_models.dart`, which keeps its own
/// history on the backend. These calls carry no state: each request stands
/// alone and returns a suggestion the user must review before applying.
library;

/// Maximum input length enforced client-side before even calling the
/// backend, mirroring `app.ai.max-input-chars` (default 12000 server-side;
/// the DTOs themselves hard-cap at 20000).
const int plumoAiMaxInputChars = 12000;

class AiWritingRequest {
  const AiWritingRequest({
    required this.text,
    this.language,
    this.tone,
    this.instruction,
    this.manuscriptId,
    this.chapterId,
  });

  final String text;
  final String? language;
  final String? tone;
  final String? instruction;
  final String? manuscriptId;
  final String? chapterId;

  Map<String, dynamic> toJson() {
    return {
      'text': text.trim(),
      if (language != null && language!.trim().isNotEmpty)
        'language': language!.trim(),
      if (tone != null && tone!.trim().isNotEmpty) 'tone': tone!.trim(),
      if (instruction != null && instruction!.trim().isNotEmpty)
        'instruction': instruction!.trim(),
      if (manuscriptId != null && manuscriptId!.trim().isNotEmpty)
        'manuscript_id': manuscriptId!.trim(),
      if (chapterId != null && chapterId!.trim().isNotEmpty)
        'chapter_id': chapterId!.trim(),
    };
  }
}

class AiWritingResponse {
  const AiWritingResponse({
    required this.suggestion,
    this.explanation = '',
    this.warnings = const [],
    this.provider = '',
    this.model = '',
    this.generatedAt,
  });

  final String suggestion;
  final String explanation;
  final List<String> warnings;
  final String provider;
  final String model;
  final DateTime? generatedAt;

  factory AiWritingResponse.fromJson(Object? value) {
    final json = _readMap(value);
    return AiWritingResponse(
      suggestion: _readString(json, ['suggestion', 'text', 'content']),
      explanation: _readString(json, ['explanation', 'reason']),
      warnings: _readStringList(json['warnings']),
      provider: _readString(json, ['provider']),
      model: _readString(json, ['model']),
      generatedAt: _readDate(json, ['generated_at', 'generatedAt']),
    );
  }
}

class AiTitleResponse {
  const AiTitleResponse({
    this.titles = const [],
    this.explanation = '',
    this.warnings = const [],
    this.provider = '',
    this.model = '',
    this.generatedAt,
  });

  final List<String> titles;
  final String explanation;
  final List<String> warnings;
  final String provider;
  final String model;
  final DateTime? generatedAt;

  factory AiTitleResponse.fromJson(Object? value) {
    final json = _readMap(value);
    return AiTitleResponse(
      titles: _readStringList(json['titles']),
      explanation: _readString(json, ['explanation', 'reason']),
      warnings: _readStringList(json['warnings']),
      provider: _readString(json, ['provider']),
      model: _readString(json, ['model']),
      generatedAt: _readDate(json, ['generated_at', 'generatedAt']),
    );
  }
}

class BetaReadingAnalysisRequest {
  const BetaReadingAnalysisRequest({
    required this.text,
    this.language,
    this.genre,
    this.expectedFeedbackLevel,
    this.manuscriptId,
    this.chapterId,
  });

  final String text;
  final String? language;
  final String? genre;
  final String? expectedFeedbackLevel;
  final String? manuscriptId;
  final String? chapterId;

  Map<String, dynamic> toJson() {
    return {
      'text': text.trim(),
      if (language != null && language!.trim().isNotEmpty)
        'language': language!.trim(),
      if (genre != null && genre!.trim().isNotEmpty) 'genre': genre!.trim(),
      if (expectedFeedbackLevel != null &&
          expectedFeedbackLevel!.trim().isNotEmpty)
        'expected_feedback_level': expectedFeedbackLevel!.trim(),
      if (manuscriptId != null && manuscriptId!.trim().isNotEmpty)
        'manuscript_id': manuscriptId!.trim(),
      if (chapterId != null && chapterId!.trim().isNotEmpty)
        'chapter_id': chapterId!.trim(),
    };
  }
}

class BetaReadingAnalysisResponse {
  const BetaReadingAnalysisResponse({
    this.globalFeedback = '',
    this.strengths = const [],
    this.weaknesses = const [],
    this.clarityScore = 0,
    this.rhythmScore = 0,
    this.coherenceScore = 0,
    this.characterScore = 0,
    this.suggestions = const [],
    this.warnings = const [],
    this.provider = '',
    this.model = '',
    this.generatedAt,
  });

  final String globalFeedback;
  final List<String> strengths;
  final List<String> weaknesses;
  final int clarityScore;
  final int rhythmScore;
  final int coherenceScore;
  final int characterScore;
  final List<String> suggestions;
  final List<String> warnings;
  final String provider;
  final String model;
  final DateTime? generatedAt;

  factory BetaReadingAnalysisResponse.fromJson(Object? value) {
    final json = _readMap(value);
    return BetaReadingAnalysisResponse(
      globalFeedback: _readString(json, ['global_feedback', 'globalFeedback']),
      strengths: _readStringList(json['strengths']),
      weaknesses: _readStringList(json['weaknesses']),
      clarityScore: _readInt(json, ['clarity_score', 'clarityScore']),
      rhythmScore: _readInt(json, ['rhythm_score', 'rhythmScore']),
      coherenceScore: _readInt(json, ['coherence_score', 'coherenceScore']),
      characterScore: _readInt(json, ['character_score', 'characterScore']),
      suggestions: _readStringList(json['suggestions']),
      warnings: _readStringList(json['warnings']),
      provider: _readString(json, ['provider']),
      model: _readString(json, ['model']),
      generatedAt: _readDate(json, ['generated_at', 'generatedAt']),
    );
  }
}

class BookRecommendationRequest {
  const BookRecommendationRequest({
    this.userPreferences,
    this.favoriteGenres = const [],
    this.readingHistoryIds = const [],
    this.language,
    this.limit,
  });

  final String? userPreferences;
  final List<String> favoriteGenres;
  final List<String> readingHistoryIds;
  final String? language;
  final int? limit;

  Map<String, dynamic> toJson() {
    return {
      if (userPreferences != null && userPreferences!.trim().isNotEmpty)
        'user_preferences': userPreferences!.trim(),
      if (favoriteGenres.isNotEmpty) 'favorite_genres': favoriteGenres,
      if (readingHistoryIds.isNotEmpty)
        'reading_history_ids': readingHistoryIds,
      if (language != null && language!.trim().isNotEmpty)
        'language': language!.trim(),
      if (limit != null) 'limit': limit,
    };
  }
}

class BookRecommendationResponse {
  const BookRecommendationResponse({
    this.recommendations = const [],
    this.provider = '',
    this.model = '',
    this.generatedAt,
  });

  final List<BookRecommendationItem> recommendations;
  final String provider;
  final String model;
  final DateTime? generatedAt;

  factory BookRecommendationResponse.fromJson(Object? value) {
    final json = _readMap(value);
    final rawItems = json['recommendations'];
    return BookRecommendationResponse(
      recommendations: rawItems is List
          ? rawItems.map(BookRecommendationItem.fromJson).toList()
          : const [],
      provider: _readString(json, ['provider']),
      model: _readString(json, ['model']),
      generatedAt: _readDate(json, ['generated_at', 'generatedAt']),
    );
  }
}

class BookRecommendationItem {
  const BookRecommendationItem({
    required this.bookId,
    this.title = '',
    this.reason = '',
    this.score = 0,
  });

  final String bookId;
  final String title;
  final String reason;
  final int score;

  factory BookRecommendationItem.fromJson(Object? value) {
    final json = _readMap(value);
    return BookRecommendationItem(
      bookId: _readString(json, ['book_id', 'bookId', 'id']),
      title: _readString(json, ['title', 'name']),
      reason: _readString(json, ['reason', 'explanation']),
      score: _readInt(json, ['score', 'matchScore', 'match_score']),
    );
  }
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  return const {};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  return '';
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }

  return 0;
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return [value.trim()];
  }

  return const [];
}

DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is DateTime) {
      return value;
    }
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}
