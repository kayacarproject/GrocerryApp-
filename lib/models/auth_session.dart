import '../core/utils/json_utils.dart';
import 'user.dart';

/// `{ "user": {...}, "token": "..." }` from login / register.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    this.refreshToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: Json.string(json['token'] ?? json['access_token']),
    refreshToken: Json.stringOrNull(json['refresh_token']),
    user: User.fromJson(Json.map(json['user'])),
  );

  final String accessToken;
  final String? refreshToken;
  final User user;

  Map<String, dynamic> toJson() => {
    'token': accessToken,
    'refresh_token': refreshToken,
    'user': user.toJson(),
  };
}

enum OtpPurpose {
  /// Verifies the email address of a newly registered account.
  registration('verification'),
  passwordReset('password_reset');

  const OtpPurpose(this.apiValue);
  final String apiValue;
}

/// The server has sent a one-time code to [target] (an email address).
class OtpChallenge {
  const OtpChallenge({
    required this.target,
    required this.purpose,
    this.resendAfterSeconds = 30,
    this.expiresInSeconds,
    this.debugCode,
  });

  factory OtpChallenge.fromJson(
    Map<String, dynamic> json, {
    required String target,
    required OtpPurpose purpose,
  }) => OtpChallenge(
    target: target,
    purpose: purpose,
    expiresInSeconds: Json.integerOrNull(json['expires_in']),
    debugCode: Json.stringOrNull(json['debug_otp']),
  );

  final String target;
  final OtpPurpose purpose;
  final int resendAfterSeconds;
  final int? expiresInSeconds;

  /// Only returned by development servers; shown as a hint in dev builds.
  final String? debugCode;
}

/// Authorises setting a new password for [email].
class PasswordResetTicket {
  const PasswordResetTicket({required this.email, required this.token});

  final String email;
  final String token;
}

/// Result of verifying an OTP: a session when a registration completes, or a
/// short-lived token that authorises a password reset.
class OtpVerification {
  const OtpVerification({this.session, this.resetToken});

  final AuthSession? session;
  final String? resetToken;
}
