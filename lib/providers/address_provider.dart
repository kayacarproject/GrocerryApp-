import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address.dart';
import '../repositories/address_repository.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'repository_providers.dart';

final addressesProvider =
    AsyncNotifierProvider<AddressesNotifier, List<Address>>(
      AddressesNotifier.new,
    );

class AddressesNotifier extends AsyncNotifier<List<Address>> {
  AddressRepository get _repo => ref.read(addressRepositoryProvider);

  @override
  Future<List<Address>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return _repo.getAddresses();
  }

  // Mutations re-fetch so the list (and default flags) match the server.
  Future<void> _refreshAfter(Future<void> Function() mutation) async {
    await mutation();
    state = AsyncData(await _repo.getAddresses());
  }

  // "Default" is its own endpoint; create/update don't accept the flag.
  Future<Address> add(Address address) async {
    late Address created;
    await _refreshAfter(() async {
      created = await _repo.create(address);
      if (address.isDefault && !created.isDefault) await _repo.setDefault(created.id);
    });
    return created;
  }

  Future<void> edit(Address address) => _refreshAfter(() async {
    final updated = await _repo.update(address);
    if (address.isDefault && !updated.isDefault) await _repo.setDefault(updated.id);
  });

  Future<void> delete(String id) async {
    await _refreshAfter(() => _repo.delete(id));
    final selected = ref.read(selectedAddressIdProvider);
    if (selected == id) ref.read(selectedAddressIdProvider.notifier).select(null);
  }

  Future<void> setDefault(String id) => _refreshAfter(() => _repo.setDefault(id));
}

final selectedAddressIdProvider =
    NotifierProvider<SelectedAddressIdNotifier, String?>(
      SelectedAddressIdNotifier.new,
    );

/// The address the user chose to deliver to, persisted across launches.
class SelectedAddressIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(currentUserIdProvider);
    return ref.read(localCacheProvider).selectedAddressId;
  }

  void select(String? id) {
    state = id;
    ref.read(localCacheProvider).setSelectedAddressId(id);
  }
}

/// Selected address, falling back to the default and then the first saved.
final selectedAddressProvider = Provider<Address?>((ref) {
  final addresses = ref.watch(addressesProvider).valueOrNull ?? const [];
  if (addresses.isEmpty) return null;
  final selectedId = ref.watch(selectedAddressIdProvider);
  return addresses.where((a) => a.id == selectedId).firstOrNull ??
      addresses.where((a) => a.isDefault).firstOrNull ??
      addresses.first;
});
