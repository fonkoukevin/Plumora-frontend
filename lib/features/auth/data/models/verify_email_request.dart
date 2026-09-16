class VerifyEmailRequest {
  const VerifyEmailRequest({required this.token});

  final String token;

  Map<String, dynamic> toJson() {
    return {'token': token.trim()};
  }
}
