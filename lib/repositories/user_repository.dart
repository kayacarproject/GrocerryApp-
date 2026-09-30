import '../models/user.dart';
import '../services/api/user_api_service.dart';

abstract interface class UserRepository {
  Future<User> updateProfile({
    required String name,
    required String email,
    required String phone,
  });

  Future<User> uploadAvatar(String filePath);
}

class RemoteUserRepository implements UserRepository {
  const RemoteUserRepository(this._api);

  final UserApiService _api;

  @override
  Future<User> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) => _api.updateProfile(name: name, email: email, phone: phone);

  @override
  Future<User> uploadAvatar(String filePath) => _api.uploadProfileImage(filePath);
}
