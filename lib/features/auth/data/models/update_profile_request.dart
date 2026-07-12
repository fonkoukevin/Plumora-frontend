class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.firstname,
    required this.lastname,
    required this.username,
    this.bio,
    this.avatarUrl,
  });

  final String firstname;
  final String lastname;
  final String username;
  final String? bio;
  final String? avatarUrl;

  Map<String, dynamic> toJson() {
    return {
      'firstname': firstname.trim(),
      'lastname': lastname.trim(),
      'username': username.trim(),
      'bio': bio?.trim(),
      'avatarUrl': avatarUrl,
    };
  }
}
