import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';

final passwordResetRequestControllerProvider =
    AsyncNotifierProvider<PasswordResetRequestController, void>(
      PasswordResetRequestController.new,
    );

/// Drives the "Mot de passe oublié ?" screen: sends the reset email.
class PasswordResetRequestController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).requestPasswordReset(email);
    });
  }
}

final resetPasswordControllerProvider =
    AsyncNotifierProvider<ResetPasswordController, void>(
      ResetPasswordController.new,
    );

/// Drives the reset-password screen reached from the emailed link: submits
/// the token together with the new password.
class ResetPasswordController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String token,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(authRepositoryProvider)
          .resetPassword(token: token, newPassword: newPassword);
    });
  }
}
