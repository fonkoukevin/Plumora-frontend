class ResetPasswordRequest {
  const ResetPasswordRequest({required this.token, required this.newPassword});

  final String token;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return {'token': token.trim(), 'newPassword': newPassword};
  }
}
