class RegisterRequest {
  const RegisterRequest({
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.password,
    this.username,
  });

  final String firstname;
  final String lastname;
  final String email;
  final String password;
  final String? username;

  Map<String, dynamic> toJson() {
    return {
      'firstname': firstname.trim(),
      'lastname': lastname.trim(),
      'username': _effectiveUsername,
      'email': email.trim(),
      'password': password,
    };
  }

  String get _effectiveUsername {
    final explicitUsername = username?.trim();
    if (explicitUsername != null && explicitUsername.isNotEmpty) {
      return explicitUsername;
    }

    return email.split('@').first.trim();
  }
}
