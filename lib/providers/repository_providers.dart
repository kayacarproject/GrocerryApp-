import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../repositories/address_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/cart_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/mock/mock_address_repository.dart';
import '../repositories/mock/mock_auth_repository.dart';
import '../repositories/mock/mock_cart_repository.dart';
import '../repositories/mock/mock_catalog_repository.dart';
import '../repositories/mock/mock_database.dart';
import '../repositories/mock/mock_notification_repository.dart';
import '../repositories/mock/mock_order_repository.dart';
import '../repositories/mock/mock_user_repository.dart';
import '../repositories/mock/mock_wishlist_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/wishlist_repository.dart';
import '../services/api/address_api_service.dart';
import '../services/api/auth_api_service.dart';
import '../services/api/cart_api_service.dart';
import '../services/api/catalog_api_service.dart';
import '../services/api/notification_api_service.dart';
import '../services/api/order_api_service.dart';
import '../services/api/user_api_service.dart';
import '../services/api/wishlist_api_service.dart';
import 'core_providers.dart';

// The single switch between the demo backend and the real API. Nothing above
// the repository layer knows which one is in use.
const _useMock = AppConfig.useMockData;

final mockDatabaseProvider = Provider<MockDatabase>(
  (ref) => MockDatabase(ref.watch(localCacheProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  return _useMock
      ? MockAuthRepository(ref.watch(mockDatabaseProvider), tokens)
      : RemoteAuthRepository(AuthApiService(ref.watch(apiClientProvider)), tokens);
});

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => _useMock
      ? MockUserRepository(ref.watch(mockDatabaseProvider), ref.watch(tokenStorageProvider))
      : RemoteUserRepository(UserApiService(ref.watch(apiClientProvider))),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => _useMock
      ? MockCatalogRepository(ref.watch(mockDatabaseProvider))
      : RemoteCatalogRepository(
          CatalogApiService(ref.watch(apiClientProvider)),
          ref.watch(localCacheProvider),
        ),
);

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => _useMock
      ? MockCartRepository(ref.watch(mockDatabaseProvider))
      : RemoteCartRepository(CartApiService(ref.watch(apiClientProvider))),
);

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => _useMock
      ? MockWishlistRepository(ref.watch(mockDatabaseProvider))
      : RemoteWishlistRepository(WishlistApiService(ref.watch(apiClientProvider))),
);

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => _useMock
      ? MockAddressRepository(ref.watch(mockDatabaseProvider))
      : RemoteAddressRepository(AddressApiService(ref.watch(apiClientProvider))),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => _useMock
      ? MockOrderRepository(ref.watch(mockDatabaseProvider))
      : RemoteOrderRepository(OrderApiService(ref.watch(apiClientProvider))),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => _useMock
      ? MockNotificationRepository(ref.watch(mockDatabaseProvider))
      : RemoteNotificationRepository(
          NotificationApiService(ref.watch(apiClientProvider)),
        ),
);
