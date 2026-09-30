import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../../models/auth_session.dart';
import '../../models/user.dart';

class AuthApiService {
  const AuthApiService(this._client);

  final ApiClient _client;

  static const _deviceName = 'Basketly Android';

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.login,
      auth: false,
      body: {'email': email, 'password': password, 'device_name': _deviceName},
      decoder: (data) => AuthSession.fromJson(Json.map(data)),
    );
    return response.data;
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.register,
      auth: false,
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      },
      decoder: (data) => AuthSession.fromJson(Json.map(data)),
    );
    return response.data;
  }

  Future<OtpChallenge> sendOtp({
    required String email,
    required OtpPurpose purpose,
  }) async {
    final response = await _client.post(
      ApiEndpoints.sendOtp,
      auth: false,
      body: {'email': email, 'purpose': purpose.apiValue},
      decoder: (data) =>
          OtpChallenge.fromJson(Json.map(data), target: email, purpose: purpose),
    );
    return response.data;
  }

  Future<OtpChallenge> forgotPassword(String email) async {
    final response = await _client.post(
      ApiEndpoints.forgotPassword,
      auth: false,
      body: {'email': email},
      decoder: (data) => OtpChallenge.fromJson(
        Json.map(data),
        target: email,
        purpose: OtpPurpose.passwordReset,
      ),
    );
    return response.data;
  }

  /// Returns the raw `data`: `{verified, user}` or `{reset_token}`.
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required OtpPurpose purpose,
  }) async {
    final response = await _client.post(
      ApiEndpoints.verifyOtp,
      auth: false,
      body: {'email': email, 'purpose': purpose.apiValue, 'otp': otp},
      decoder: Json.map,
    );
    return response.data;
  }

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
  }) async {
    await _client.post(
      ApiEndpoints.resetPassword,
      auth: false,
      body: {
        'email': email,
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': password,
      },
      decoder: (_) {},
    );
  }

  Future<User> me() async {
    final response = await _client.get(
      ApiEndpoints.me,
      decoder: (data) => User.fromJson(Json.map(data)),
    );
    return response.data;
  }

  Future<void> logout() async {
    await _client.post(ApiEndpoints.logout, decoder: (_) {});
  }
}
