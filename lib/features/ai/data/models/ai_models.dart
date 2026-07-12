import '../../../catalog/data/models/catalog_book_model.dart';

enum AiWritingActionType {
  reformulate('REFORMULATE', 'Reformuler'),
  improveStyle('IMPROVE_STYLE', 'Améliorer le style'),
  fixRepetitions('FIX_REPETITIONS', 'Corriger les répétitions'),
  makeMoreEmotional('MAKE_MORE_EMOTIONAL', 'Rendre plus émotionnel'),
  makeDialogueNatural('MAKE_DIALOGUE_NATURAL', 'Dialogue plus naturel');

  const AiWritingActionType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AiWritingActionType fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return AiWritingActionType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => AiWritingActionType.improveStyle,
    );
  }
}

enum AiSuggestionStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  modified('MODIFIED'),
  ignored('IGNORED'),
  unknown('UNKNOWN');

  const AiSuggestionStatus(this.apiValue);

  final String apiValue;

  static AiSuggestionStatus fromApi(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return AiSuggestionStatus.values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => AiSuggestionStatus.unknown,
    );
  }
}

class AiWritingSuggestionRequest {
  const AiWritingSuggestionRequest({
    required this.selectedText,
    required this.actionType,
    this.chapterId,
    this.contextText,
  });

  final String selectedText;
  final AiWritingActionType actionType;
  final String? chapterId;
  final String? contextText;

  Map<String, dynamic> toJson() {
    return {
      'selected_text': selectedText.trim(),
      'action_type': actionType.apiValue,
      if (chapterId != null && chapterId!.trim().isNotEmpty)
        'chapter_id': chapterId!.trim(),
      if (contextText != null && contextText!.trim().isNotEmpty)
        'context_text': contextText!.trim(),
    };
  }
}

class AiWritingSuggestionModel {
  const AiWritingSuggestionModel({
    required this.id,
    required this.suggestionText,
    this.requestId = '',
    this.explanation = '',
    this.status = AiSuggestionStatus.pending,
    this.createdAt,
  });

  final String id;
  final String requestId;
  final String suggestionText;
  final String explanation;
  final AiSuggestionStatus status;
  final DateTime? createdAt;

  factory AiWritingSuggestionModel.fromJson(Object? value) {
    final json = _readMap(value);
    return AiWritingSuggestionModel(
      id: _readString(json, [
        'id',
        'suggestionId',
        'suggestion_id',
        'idAiWritingSuggestion',
      ]),
      requestId: _readString(json, [
        'requestId',
        'request_id',
        'aiWritingRequestId',
      ]),
      suggestionText: _readString(json, [
        'suggestionText',
        'suggestion_text',
        'text',
        'content',
      ]),
      explanation: _readString(json, ['explanation', 'reason', 'details']),
      status: AiSuggestionStatus.fromApi(json['status']),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
    );
  }

  AiWritingSuggestionModel copyWith({
    String? id,
    String? requestId,
    String? suggestionText,
    String? explanation,
    AiSuggestionStatus? status,
    DateTime? createdAt,
  }) {
    return AiWritingSuggestionModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      suggestionText: suggestionText ?? this.suggestionText,
      explanation: explanation ?? this.explanation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AiRecommendationRequest {
  const AiRecommendationRequest({
    required this.queryText,
    this.mood,
    this.preferredDuration,
    this.preferredGenre,
  });

  final String queryText;
  final String? mood;
  final String? preferredDuration;
  final String? preferredGenre;

  Map<String, dynamic> toJson() {
    return {
      'query_text': queryText.trim(),
      if (mood != null && mood!.trim().isNotEmpty) 'mood': mood!.trim(),
      if (preferredDuration != null && preferredDuration!.trim().isNotEmpty)
        'preferred_duration': preferredDuration!.trim(),
      if (preferredGenre != null && preferredGenre!.trim().isNotEmpty)
        'preferred_genre': preferredGenre!.trim(),
    };
  }
}

class AiRecommendedBookModel {
  const AiRecommendedBookModel({
    required this.book,
    this.resultId = '',
    this.requestId = '',
    this.matchScore = 0,
    this.reasons = const [],
    this.rank = 0,
  });

  final CatalogBookModel book;
  final String resultId;
  final String requestId;
  final int matchScore;
  final List<String> reasons;
  final int rank;

  factory AiRecommendedBookModel.fromJson(Object? value) {
    final json = _readMap(value);
    final bookJson =
        _readMapOrNull(json['book']) ??
        _readMapOrNull(json['catalogBook']) ??
        json;

    return AiRecommendedBookModel(
      book: CatalogBookModel.fromJson(bookJson),
      resultId: _readString(json, ['id', 'resultId', 'result_id']),
      requestId: _readString(json, ['requestId', 'request_id']),
      matchScore: _readInt(json, [
        'matchScore',
        'match_score',
        'score',
        'compatibility',
      ]),
      reasons: _readStringList(json['reasons'] ?? json['reasonList']),
      rank: _readInt(json, ['rank', 'rankPosition', 'rank_position']),
    );
  }
}

class AiRecommendationRequestModel {
  const AiRecommendationRequestModel({
    required this.id,
    required this.queryText,
    this.mood,
    this.preferredDuration,
    this.preferredGenre,
    this.createdAt,
  });

  final String id;
  final String queryText;
  final String? mood;
  final String? preferredDuration;
  final String? preferredGenre;
  final DateTime? createdAt;

  factory AiRecommendationRequestModel.fromJson(Object? value) {
    final json = _readMap(value);
    return AiRecommendationRequestModel(
      id: _readString(json, ['id', 'requestId', 'request_id']),
      queryText: _readString(json, ['queryText', 'query_text', 'query']),
      mood: _readNullableString(json, ['mood']),
      preferredDuration: _readNullableString(json, [
        'preferredDuration',
        'preferred_duration',
      ]),
      preferredGenre: _readNullableString(json, [
        'preferredGenre',
        'preferred_genre',
      ]),
      createdAt: _readDate(json, ['createdAt', 'created_at']),
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

Map<String, dynamic>? _readMapOrNull(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  return null;
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  return _readNullableString(json, keys) ?? '';
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  return null;
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
        .map((item) => item.toString().trim())
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
