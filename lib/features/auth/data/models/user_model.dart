import 'role_model.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.username,
    this.avatarUrl,
    this.bio,
    this.roles = const [],
  });

  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final List<RoleModel> roles;

  String get displayName {
    final fullName = '$firstname $lastname'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return username ?? email;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _readString(json, ['id', 'idUser', 'id_user']),
      firstname: _readString(json, ['firstName', 'firstname', 'first_name']),
      lastname: _readString(json, ['lastName', 'lastname', 'last_name']),
      email: _readString(json, ['email']),
      username: _readNullableString(json, ['username']),
      avatarUrl: _readNullableString(json, ['avatarUrl', 'avatar_url']),
      bio: _readNullableString(json, ['bio']),
      roles: _readRoles(json['roles']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (bio != null) 'bio': bio,
      'roles': roles.map((role) => role.toJson()).toList(),
    };
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    return _readNullableString(json, keys) ?? '';
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return value.toString();
      }
    }

    return null;
  }

  static List<RoleModel> _readRoles(Object? value) {
    if (value is List) {
      return value
          .map(RoleModel.fromJson)
          .where((role) => role.name.isNotEmpty)
          .toList();
    }

    return const [];
  }
}
