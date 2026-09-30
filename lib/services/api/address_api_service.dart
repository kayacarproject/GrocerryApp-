import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../../models/address.dart';

class AddressApiService {
  const AddressApiService(this._client);

  final ApiClient _client;

  static Address _address(Object? data) => Address.fromJson(Json.map(data));

  Future<List<Address>> getAddresses() async {
    final response = await _client.get(
      ApiEndpoints.addresses,
      decoder: (data) => Json.list(data, Address.fromJson),
    );
    return response.data;
  }

  Future<Address> create(Address address) async {
    final response = await _client.post(
      ApiEndpoints.addresses,
      body: address.toRequestJson(),
      decoder: _address,
    );
    return response.data;
  }

  Future<Address> update(Address address) async {
    final response = await _client.put(
      ApiEndpoints.address(address.id),
      body: address.toRequestJson(),
      decoder: _address,
    );
    return response.data;
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.address(id), decoder: (_) {});
  }

  Future<void> setDefault(String id) async {
    await _client.patch(ApiEndpoints.defaultAddress(id), decoder: (_) {});
  }
}
