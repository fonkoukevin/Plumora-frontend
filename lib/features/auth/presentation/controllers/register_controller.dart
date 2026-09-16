import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/register_request.dart';
import '../../data/repositories/auth_repository.dart';

final registerControllerProvider =
    AsyncNotifierProvider<RegisterController, void>(RegisterController.new);

/// Drives the "Créer un compte" screen: submits the registration request.
/// Deliberately separate from [AuthController] — registration no longer
/// signs the user in (see `AuthRepository.register`), so it has nothing to
/// do with `AuthSession`. Mirrors `PasswordResetRequestController`.
class RegisterController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(RegisterRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).register(request);
    });
  }
}
