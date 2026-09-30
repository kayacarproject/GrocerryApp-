import '../models/address.dart';
import '../services/api/address_api_service.dart';

abstract interface class AddressRepository {
  Future<List<Address>> getAddresses();
  Future<Address> create(Address address);
  Future<Address> update(Address address);
  Future<void> delete(String id);
  Future<void> setDefault(String id);
}

class RemoteAddressRepository implements AddressRepository {
  const RemoteAddressRepository(this._api);

  final AddressApiService _api;

  @override
  Future<List<Address>> getAddresses() => _api.getAddresses();

  @override
  Future<Address> create(Address address) => _api.create(address);

  @override
  Future<Address> update(Address address) => _api.update(address);

  @override
  Future<void> delete(String id) => _api.delete(id);

  @override
  Future<void> setDefault(String id) => _api.setDefault(id);
}
