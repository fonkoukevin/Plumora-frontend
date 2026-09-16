import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../models/platform_stats_model.dart';
import '../services/home_api_service.dart';

final homeApiServiceProvider = Provider<HomeApiService>((ref) {
  return HomeApiService(ref.watch(dioProvider));
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(homeApiServiceProvider));
});

/// Real, server-computed platform totals for the pre-login landing page.
/// Never fall back to a hardcoded number when this errors — the landing
/// screen must show an honest placeholder instead (see `_StatsRow` /
/// `_HeroBadge` in `landing_screen.dart`).
final platformStatsProvider = FutureProvider<PlatformStatsModel>((ref) {
  return ref.watch(homeRepositoryProvider).platformStats();
});

class HomeRepository {
  const HomeRepository(this._apiService);

  final HomeApiService _apiService;

  Future<PlatformStatsModel> platformStats() {
    return _apiService.platformStats();
  }
}
