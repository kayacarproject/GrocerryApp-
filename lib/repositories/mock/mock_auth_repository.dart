import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../models/auth_session.dart';
import '../../models/user.dart';
import '../auth_repository.dart';
import 'mock_database.dart';

/// Demo auth. The OTP is always `123456`.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._db, this._tokens);

  static const _otp = '123456';
  static const _tokenPrefix = 'demo-access.';
  static const _resetPrefix = 'demo-reset.';

  final MockDatabase _db;
  final TokenStorage _tokens;
  final Map<String, ({User user, String password})> _pendingSignups = {};

  OtpChallenge _challenge(String email, OtpPurpose purpose) =>
      OtpChallenge(target: email, purpose: purpose, debugCode: _otp);

  Future<User> _startSession(User user) async {
    await _tokens.saveTokens(accessToken: '$_tokenPrefix${user.id}');
    return user;
  }

  @override
  Future<User?> restoreSession() async {
    final token = await _tokens.accessToken;
    if (token == null || !token.startsWith(_tokenPrefix)) return null;
    await mockLatency(300);
    final user = _db.userById(token.substring(_tokenPrefix.length));
    if (user == null) await _tokens.clear();
    return user;
  }

  @override
  Future<User> login({required String email, required String password}) async {
    await mockLatency(700);
    final user = _db.authenticate(email, password);
    if (user == null) {
      throw const ApiException(
        type: ApiErrorType.unauthorized,
        statusCode: 401,
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid credentials',
      );
    }
    return _startSession(user);
  }

  @override
  Future<OtpChallenge> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await mockLatency(700);
    if (_db.findByIdentifier(email) != null) {
      throw mockError('An account with this email already exists.');
    }
    if (_db.findByIdentifier(phone) != null) {
      throw mockError('An account with this phone number already exists.');
    }
    final user = User(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      createdAt: DateTime.now(),
    );
    _pendingSignups[user.email] = (user: user, password: password);
    return _challenge(user.email, OtpPurpose.registration);
  }

  @override
  Future<OtpChallenge> forgotPassword(String email) async {
    await mockLatency(600);
    // Like the real API, never reveal whether an account exists.
    return _challenge(email.trim().toLowerCase(), OtpPurpose.passwordReset);
  }

  @override
  Future<OtpVerification> verifyOtp(OtpChallenge challenge, String code) async {
    await mockLatency(600);
    if (code != _otp) throw mockError('Invalid or expired OTP');

    switch (challenge.purpose) {
      case OtpPurpose.registration:
        final pending = _pendingSignups.remove(challenge.target);
        if (pending == null) throw mockError('This code has expired. Please sign up again.');
        _db.addUser(pending.user, pending.password);
        await _db.save();
        final user = await _startSession(pending.user);
        return OtpVerification(
          session: AuthSession(accessToken: '$_tokenPrefix${user.id}', user: user),
        );
      case OtpPurpose.passwordReset:
        final user = _db.findByIdentifier(challenge.target);
        if (user == null) throw mockError('Invalid or expired OTP');
        return OtpVerification(resetToken: '$_resetPrefix${user.id}');
    }
  }

  @override
  Future<OtpChallenge> resendOtp(OtpChallenge challenge) async {
    await mockLatency(400);
    return _challenge(challenge.target, challenge.purpose);
  }

  @override
  Future<void> resetPassword(PasswordResetTicket ticket, String newPassword) async {
    await mockLatency(600);
    if (!ticket.token.startsWith(_resetPrefix)) {
      throw mockError('This reset link has expired.', ApiErrorType.unauthorized);
    }
    _db.setPassword(ticket.token.substring(_resetPrefix.length), newPassword);
    await _db.save();
  }

  @override
  Future<void> logout() async {
    await mockLatency(200);
    await _tokens.clear();
  }
}
