import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/json_utils.dart';
import 'core_providers.dart';

class AppSettings {
  const AppSettings({
    this.orderUpdates = true,
    this.offersAndPromotions = true,
    this.whatsappUpdates = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    orderUpdates: Json.boolean(json['order_updates'], true),
    offersAndPromotions: Json.boolean(json['offers'], true),
    whatsappUpdates: Json.boolean(json['whatsapp']),
  );

  final bool orderUpdates;
  final bool offersAndPromotions;
  final bool whatsappUpdates;

  AppSettings copyWith({
    bool? orderUpdates,
    bool? offersAndPromotions,
    bool? whatsappUpdates,
  }) => AppSettings(
    orderUpdates: orderUpdates ?? this.orderUpdates,
    offersAndPromotions: offersAndPromotions ?? this.offersAndPromotions,
    whatsappUpdates: whatsappUpdates ?? this.whatsappUpdates,
  );

  Map<String, dynamic> toJson() => {
    'order_updates': orderUpdates,
    'offers': offersAndPromotions,
    'whatsapp': whatsappUpdates,
  };
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      AppSettings.fromJson(ref.read(localCacheProvider).settings);

  void update(AppSettings settings) {
    state = settings;
    ref.read(localCacheProvider).saveSettings(settings.toJson());
  }
}
