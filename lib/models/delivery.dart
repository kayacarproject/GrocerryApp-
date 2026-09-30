import '../core/utils/json_utils.dart';

class DeliverySlot {
  const DeliverySlot({
    required this.id,
    required this.label,
    required this.description,
    this.isAvailable = true,
    this.isExpress = false,
  });

  factory DeliverySlot.fromJson(Map<String, dynamic> json) => DeliverySlot(
    id: Json.string(json['id']),
    label: Json.string(json['label']),
    description: Json.string(json['description']),
    isAvailable: Json.boolean(json['is_available'], true),
    isExpress: Json.boolean(json['is_express']),
  );

  final String id;

  /// e.g. "Express" or "Today, 6 PM – 8 PM".
  final String label;
  final String description;
  final bool isAvailable;
  final bool isExpress;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'description': description,
    'is_available': isAvailable,
    'is_express': isExpress,
  };
}

/// Rider details, available once an order is picked up.
class DeliveryPartner {
  const DeliveryPartner({
    required this.name,
    required this.phone,
    this.vehicleNumber,
    this.rating,
  });

  factory DeliveryPartner.fromJson(Map<String, dynamic> json) => DeliveryPartner(
    name: Json.string(json['name']),
    phone: Json.string(json['phone']),
    vehicleNumber: Json.stringOrNull(json['vehicle_number']),
    rating: Json.decimalOrNull(json['rating']),
  );

  final String name;
  final String phone;
  final String? vehicleNumber;
  final double? rating;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'vehicle_number': vehicleNumber,
    'rating': rating,
  };
}

class Delivery {
  const Delivery({
    this.slot,
    this.partner,
    this.estimatedAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    final slot = Json.mapOrNull(json['slot']);
    final partner = Json.mapOrNull(json['partner']);
    return Delivery(
      slot: slot == null ? null : DeliverySlot.fromJson(slot),
      partner: partner == null ? null : DeliveryPartner.fromJson(partner),
      estimatedAt: Json.date(json['estimated_at']),
      assignedAt: Json.date(json['assigned_at']),
      pickedUpAt: Json.date(json['picked_up_at']),
      deliveredAt: Json.date(json['delivered_at']),
    );
  }

  final DeliverySlot? slot;
  final DeliveryPartner? partner;
  final DateTime? estimatedAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  Map<String, dynamic> toJson() => {
    'slot': slot?.toJson(),
    'partner': partner?.toJson(),
    'estimated_at': estimatedAt?.toUtc().toIso8601String(),
    'assigned_at': assignedAt?.toUtc().toIso8601String(),
    'picked_up_at': pickedUpAt?.toUtc().toIso8601String(),
    'delivered_at': deliveredAt?.toUtc().toIso8601String(),
  };
}
