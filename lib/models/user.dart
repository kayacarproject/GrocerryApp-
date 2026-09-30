import '../core/utils/json_utils.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: Json.string(json['id']),
    name: Json.string(json['name'], 'Guest'),
    email: Json.string(json['email']),
    phone: Json.string(json['phone']),
    avatarUrl: Json.stringOrNull(json['profile_image'] ?? json['avatar_url']),
    createdAt: Json.date(json['created_at']),
  );

  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final DateTime? createdAt;

  String get firstName => name.split(' ').first;

  User copyWith({String? name, String? email, String? phone, String? avatarUrl}) =>
      User(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'profile_image': avatarUrl,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };
}
