import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../../models/user.dart';

class UserApiService {
  const UserApiService(this._client);

  final ApiClient _client;

  static User _user(Object? data) => User.fromJson(Json.map(data));

  Future<User> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await _client.put(
      ApiEndpoints.profile,
      body: {'name': name, 'email': email, 'phone': phone},
      decoder: _user,
    );
    return response.data;
  }

  Future<User> uploadProfileImage(String filePath) async {
    final response = await _client.upload(
      ApiEndpoints.profileImage,
      filePath: filePath,
      fieldName: 'image',
      decoder: _user,
    );
    return response.data;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put(
      ApiEndpoints.changePassword,
      body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
      decoder: (_) {},
    );
  }
}
