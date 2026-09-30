import '../core/utils/json_utils.dart';

/// Preset address names; any other name is shown as [other].
enum AddressLabel {
  home('Home'),
  work('Work'),
  other('Other');

  const AddressLabel(this.display);
  final String display;

  static AddressLabel fromName(String name) => AddressLabel.values.firstWhere(
    (l) => l.display.toLowerCase() == name.trim().toLowerCase(),
    orElse: () => AddressLabel.other,
  );
}

class Address {
  const Address({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: Json.string(json['id']),
    name: Json.string(json['name'], 'Home'),
    fullAddress: Json.string(json['full_address']),
    city: Json.string(json['city']),
    state: Json.string(json['state']),
    pincode: Json.string(json['pincode']),
    phone: Json.string(json['phone']),
    isDefault: Json.boolean(json['is_default']),
    latitude: Json.decimalOrNull(json['latitude']),
    longitude: Json.decimalOrNull(json['longitude']),
  );

  final String id;

  /// User-given name such as "Home" or "Work".
  final String name;

  /// House, building, street and area in one line.
  final String fullAddress;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  AddressLabel get label => AddressLabel.fromName(name);

  String get shortAddress => fullAddress;

  String get displayAddress =>
      [fullAddress, '$city, $state $pincode'].where((p) => p.trim().isNotEmpty).join(', ');

  Address copyWith({bool? isDefault}) => Address(
    id: id,
    name: name,
    fullAddress: fullAddress,
    city: city,
    state: state,
    pincode: pincode,
    phone: phone,
    isDefault: isDefault ?? this.isDefault,
    latitude: latitude,
    longitude: longitude,
  );

  /// Body for create / update. The API rejects unknown fields.
  Map<String, dynamic> toRequestJson() => {
    'name': name,
    'full_address': fullAddress,
    'city': city,
    'state': state,
    'pincode': pincode,
    'phone': phone,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    ...toRequestJson(),
    'is_default': isDefault,
  };
}
