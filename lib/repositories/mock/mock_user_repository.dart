import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../models/user.dart';
import '../user_repository.dart';
import 'mock_database.dart';

class MockUserRepository implements UserRepository {
  MockUserRepository(this._db, this._tokens);

  final MockDatabase _db;
  final TokenStorage _tokens;

  Future<User> _currentUser() async {
    final token = await _tokens.accessToken ?? '';
    final user = _db.userById(token.split('.').last);
    if (user == null) {
      throw const ApiException(
        type: ApiErrorType.unauthorized,
        message: 'Your session has expired. Please log in again.',
      );
    }
    return user;
  }

  @override
  Future<User> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    await mockLatency(600);
    final current = await _currentUser();
    final emailOwner = _db.findByIdentifier(email);
    if (emailOwner != null && emailOwner.id != current.id) {
      throw mockError('This email is already used by another account.');
    }
    final updated = current.copyWith(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
    );
    _db.updateUser(updated);
    await _db.save();
    return updated;
  }

  @override
  Future<User> uploadAvatar(String filePath) async {
    await mockLatency();
    throw mockError('Photo upload needs the live server.', ApiErrorType.badRequest);
  }
}
