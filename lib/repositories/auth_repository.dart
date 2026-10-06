import '../core/network/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/json_utils.dart';
import '../models/auth_session.dart';
import '../models/user.dart';
import '../services/api/auth_api_service.dart';

abstract interface class AuthRepository {
  /// Returns the signed-in user if a valid session is stored, else `null`.
  Future<User?> restoreSession();

  Future<User> login({required String email, required String password});

  /// Creates the account. The user signs in afterwards with email + password.
  // TODO: restore email OTP verification once SMTP is configured.
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<OtpChallenge> forgotPassword(String email);

  /// Completes registration (persisting the session) or returns a reset token.
  Future<OtpVerification> verifyOtp(OtpChallenge challenge, String code);

  Future<OtpChallenge> resendOtp(OtpChallenge challenge);

  Future<void> resetPassword(PasswordResetTicket ticket, String newPassword);

  Future<void> logout();
}

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api, this._tokens);

  final AuthApiService _api;
  final TokenStorage _tokens;

  /// Registration token held in memory until the email is verified, so an
  /// unverified account is not signed in after an app restart.
  AuthSession? _pendingSession;

  Future<void> _persist(AuthSession session) => _tokens.saveTokens(
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
  );

  @override
  Future<User?> restoreSession() async {
    if (!await _tokens.hasSession) return null;
    try {
      return await _api.me();
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.unauthorized) {
        await _tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final session = await _api.login(email: email, password: password);
    await _persist(session);
    return session.user;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // The returned session is discarded so the user logs in explicitly.
    await _api.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  @override
  Future<OtpChallenge> forgotPassword(String email) => _api.forgotPassword(email);

  @override
  Future<OtpVerification> verifyOtp(OtpChallenge challenge, String code) async {
    final data = await _api.verifyOtp(
      email: challenge.target,
      otp: code,
      purpose: challenge.purpose,
    );

    switch (challenge.purpose) {
      case OtpPurpose.registration:
        final pending = _pendingSession;
        if (pending == null) {
          // App restarted mid-signup: the account exists and is now verified.
          throw const ApiException(
            type: ApiErrorType.badRequest,
            message: 'Email verified. Please log in to continue.',
          );
        }
        final user = data['user'] is Map ? User.fromJson(Json.map(data['user'])) : pending.user;
        final session = AuthSession(
          accessToken: pending.accessToken,
          refreshToken: pending.refreshToken,
          user: user,
        );
        await _persist(session);
        _pendingSession = null;
        return OtpVerification(session: session);
      case OtpPurpose.passwordReset:
        return OtpVerification(resetToken: Json.stringOrNull(data['reset_token']));
    }
  }

  @override
  Future<OtpChallenge> resendOtp(OtpChallenge challenge) =>
      challenge.purpose == OtpPurpose.passwordReset
      ? _api.forgotPassword(challenge.target)
      : _api.sendOtp(email: challenge.target, purpose: challenge.purpose);

  @override
  Future<void> resetPassword(PasswordResetTicket ticket, String newPassword) =>
      _api.resetPassword(email: ticket.email, resetToken: ticket.token, password: newPassword);

  @override
  Future<void> logout() async {
    try {
      await _api.logout();
    } on ApiException {
      // Server-side revocation is best effort; local sign-out always happens.
    } finally {
      await _tokens.clear();
    }
  }
}
