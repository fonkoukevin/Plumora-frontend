class ResendVerificationRequest {
  const ResendVerificationRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() {
    return {'email': email.trim()};
  }
}
