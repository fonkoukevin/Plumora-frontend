import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';

final verifyEmailControllerProvider =
    AsyncNotifierProvider<VerifyEmailController, void>(
      VerifyEmailController.new,
    );

/// Drives the verify-email screen reached from the emailed confirmation
/// link: submits the token. Mirrors `ResetPasswordController`.
class VerifyEmailController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(String token) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).verifyEmail(token);
    });
  }
}

final resendVerificationControllerProvider =
    AsyncNotifierProvider<ResendVerificationController, void>(
      ResendVerificationController.new,
    );

/// Drives the "Renvoyer l'email de confirmation" action, reachable both
/// right after registration and from the login screen when a login attempt
/// fails because the account's email isn't confirmed yet. Mirrors
/// `PasswordResetRequestController`.
class ResendVerificationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).resendVerificationEmail(email);
    });
  }
}
