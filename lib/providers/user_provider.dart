import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'repository_providers.dart';

final profileControllerProvider = Provider<ProfileController>(
  ProfileController.new,
);

class ProfileController {
  const ProfileController(this._ref);

  final Ref _ref;

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final user = await _ref
        .read(userRepositoryProvider)
        .updateProfile(name: name, email: email, phone: phone);
    _ref.read(authProvider.notifier).updateUser(user);
  }
}
