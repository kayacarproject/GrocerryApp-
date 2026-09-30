import '../../core/network/api_exception.dart';
import '../../models/address.dart';
import '../address_repository.dart';
import 'mock_database.dart';

class MockAddressRepository implements AddressRepository {
  MockAddressRepository(this._db);

  final MockDatabase _db;

  List<Address> get _list => _db.addresses;

  void _makeDefault(String id) {
    for (var i = 0; i < _list.length; i++) {
      _list[i] = _list[i].copyWith(isDefault: _list[i].id == id);
    }
  }

  @override
  Future<List<Address>> getAddresses() async {
    await mockLatency(400);
    return List.unmodifiable(_list);
  }

  @override
  Future<Address> create(Address address) async {
    await mockLatency(500);
    final created = Address.fromJson({
      ...address.toJson(),
      'id': 'a${DateTime.now().millisecondsSinceEpoch}',
    });
    _list.add(created);
    if (_list.length == 1 || address.isDefault) _makeDefault(created.id);
    await _db.save();
    return _list.firstWhere((a) => a.id == created.id);
  }

  @override
  Future<Address> update(Address address) async {
    await mockLatency(500);
    final index = _list.indexWhere((a) => a.id == address.id);
    if (index < 0) {
      throw const ApiException(
        type: ApiErrorType.notFound,
        message: 'This address no longer exists.',
      );
    }
    _list[index] = address;
    if (address.isDefault) _makeDefault(address.id);
    await _db.save();
    return _list[index];
  }

  @override
  Future<void> delete(String id) async {
    await mockLatency(400);
    final removed = _list.where((a) => a.id == id).toList();
    _list.removeWhere((a) => a.id == id);
    if (removed.any((a) => a.isDefault) && _list.isNotEmpty) {
      _makeDefault(_list.first.id);
    }
    await _db.save();
  }

  @override
  Future<void> setDefault(String id) async {
    await mockLatency(300);
    _makeDefault(id);
    await _db.save();
  }
}
