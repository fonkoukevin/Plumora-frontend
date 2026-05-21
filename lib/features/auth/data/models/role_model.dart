class RoleModel {
  const RoleModel({required this.name, this.description});

  final String name;
  final String? description;

  factory RoleModel.fromJson(Object? json) {
    if (json is String) {
      return RoleModel(name: json);
    }

    if (json is Map) {
      return RoleModel(
        name: (json['name'] ?? json['role'] ?? '').toString(),
        description: json['description']?.toString(),
      );
    }

    return const RoleModel(name: '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name, if (description != null) 'description': description};
  }
}
