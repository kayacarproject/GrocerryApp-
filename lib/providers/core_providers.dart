import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/storage/local_cache.dart';
import '../core/storage/token_storage.dart';
import '../services/payment_gateway.dart';
import 'auth_provider.dart';

/// Overridden in `main()` once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final localCacheProvider = Provider<LocalCache>(
  (ref) => LocalCache(ref.watch(sharedPreferencesProvider)),
);

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    // Read lazily: only invoked after a failed token refresh.
    onSessionExpired: () =>
        ref.read(authProvider.notifier).handleSessionExpired(),
  ),
);

final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfo());

/// `true` while the device has a network connection.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final info = ref.watch(networkInfoProvider);
  yield await info.isOnline;
  yield* info.onStatusChange;
});

/// Replace with a real provider SDK integration for production.
final paymentGatewayProvider = Provider<PaymentGateway>(
  (ref) => const DemoPaymentGateway(),
);
