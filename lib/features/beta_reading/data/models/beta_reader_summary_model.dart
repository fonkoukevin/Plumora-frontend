import 'beta_model_helpers.dart';

class BetaReaderSummaryModel {
  const BetaReaderSummaryModel({required this.id, required this.username});

  final String id;
  final String username;

  factory BetaReaderSummaryModel.fromJson(Object? value) {
    final json = readBetaMap(value);
    return BetaReaderSummaryModel(
      id: readBetaString(json, ['id', 'userId', 'user_id', 'uuid']),
      username: readBetaString(json, ['username', 'name', 'displayName']),
    );
  }
}
