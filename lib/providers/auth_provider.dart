import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'core_providers.dart';
import 'repository_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState._(this.status, [this.user]);

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);
  const AuthState.authenticated(User user)
    : this._(AuthStatus.authenticated, user);

  final AuthStatus status;
  final User? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// The signed-in user's id. User-scoped providers watch this so they reset
/// automatically on login and logout.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authProvider.select((s) => s.user?.id)),
);

final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authProvider.select((s) => s.user)),
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Throws on network failure so the splash screen can offer a retry.
  Future<void> restoreSession() async {
    final user = await _repo.restoreSession();
    state = user == null
        ? const AuthState.unauthenticated()
        : AuthState.authenticated(user);
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _repo.login(
      email: email.trim().toLowerCase(),
      password: password,
    );
    state = AuthState.authenticated(user);
  }

  Future<OtpChallenge> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => _repo.register(
    name: name.trim(),
    email: email.trim().toLowerCase(),
    phone: phone.trim(),
    password: password,
  );

  Future<OtpChallenge> forgotPassword(String email) =>
      _repo.forgotPassword(email.trim().toLowerCase());

  Future<OtpVerification> verifyOtp(OtpChallenge challenge, String code) async {
    final result = await _repo.verifyOtp(challenge, code);
    final session = result.session;
    if (session != null) state = AuthState.authenticated(session.user);
    return result;
  }

  Future<OtpChallenge> resendOtp(OtpChallenge challenge) => _repo.resendOtp(challenge);

  Future<void> resetPassword(PasswordResetTicket ticket, String newPassword) =>
      _repo.resetPassword(ticket, newPassword);

  Future<void> logout() async {
    await _repo.logout();
    await ref.read(localCacheProvider).clearUserData();
    state = const AuthState.unauthenticated();
  }

  void handleSessionExpired() {
    if (state.isAuthenticated) state = const AuthState.unauthenticated();
  }

  void updateUser(User user) {
    if (state.isAuthenticated) state = AuthState.authenticated(user);
  }
}
