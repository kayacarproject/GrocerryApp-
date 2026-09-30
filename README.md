# Basketly — Grocery Shopping App

A quick-commerce style grocery app built with Flutter, Riverpod, go_router and Dio.
It has an original brand ("Basketly", emerald + amber) and ships with a built-in
demo backend, so it runs fully offline until a real API is connected.

## Run it

```bash
flutter pub get
flutter run                                   # real API (default base URL below)
flutter run --dart-define=USE_MOCK=true       # offline demo backend
flutter run --dart-define=API_BASE_URL=https://your-host/api/v1
```

The default `API_BASE_URL` is the dev tunnel
`https://glgvkj81-3456.inc1.devtunnels.ms/api/v1` (see `lib/core/config/app_config.dart`).

Test logins (a **Fill** button appears on the login screen in development builds):

| Backend | Email | Password | OTP |
| --- | --- | --- | --- |
| Dev API server | `customer@grocery.test` | `Customer@123` | shown on the OTP screen (`debug_otp`) |
| Offline demo (`USE_MOCK=true`) | `demo@basketly.app` | `Demo@1234` | `123456` |

Nothing above the repository layer knows which backend is in use. The switch
lives in `lib/providers/repository_providers.dart`.

### API notes

- Coupons, delivery fee and tax are priced by `POST /checkout/preview`. The cart
  shows item totals only, and checkout shows the preview bill. Place Order stays
  disabled until the preview has loaded.
- The API filters by a single `brand`. The discount and in-stock filters are applied
  to each returned page on the device.
- There is no delivery-slot endpoint, so checkout shows a single "Deliver now" option.
- Profile image URLs that point at `localhost` are rewritten to the API host.

Live smoke test against the server:

```bash
LIVE_API=1 flutter test test/live_api_test.dart
```

## Architecture

```
UI (screens / widgets)
  ↓ ref.watch / ref.read
Providers (Riverpod Notifiers)
  ↓
Repositories (abstract interface)
  ├── Remote*Repository → services/api/*ApiService → ApiClient (Dio) → REST API
  └── Mock*Repository   → repositories/mock/MockDatabase (demo only)
```

| Folder | Contents |
| --- | --- |
| `lib/core/config` | `AppConfig` (base URL, mock flag, timeouts) from `--dart-define` |
| `lib/core/constants` | `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, `AppSizes`, `ApiEndpoints` |
| `lib/core/network` | `ApiClient`, `AuthInterceptor` (bearer + single-flight token refresh), `ApiException`, `NetworkInfo` |
| `lib/core/storage` | `TokenStorage` (Keystore/Keychain), `LocalCache` (prefs + offline cache) |
| `lib/core/router` | go_router config, auth redirects, 5-tab `StatefulShellRoute` |
| `lib/models` | null-safe models with `fromJson` / `toJson` |
| `lib/services/api` | one service per REST resource |
| `lib/repositories` | contracts + remote implementations, `mock/` demo backend |
| `lib/providers` | auth, catalog, product list (paginated), search (debounced), cart (optimistic), wishlist, addresses, checkout, orders (+ live tracking), notifications, settings |
| `lib/screens` | one folder per feature |
| `lib/widgets` | reusable `common/`, `product/`, `category/`, `cart/`, `order/` widgets |

## Key behaviours

- **Server-authoritative pricing.** The app never computes the final bill. Cart and
  order totals come from the backend (or the mock backend in demo mode). Orders are
  placed with IDs only (`PlaceOrderRequest`).
- **Optimistic cart.** Quantity changes show instantly. Requests are serialised, and
  the server's re-priced cart replaces local state once the last request finishes.
- **Payments.** `PaymentGateway` abstracts the provider SDK. Card data and PINs are
  never handled by the app; the server verifies the gateway reference.
- **Errors.** Every failure becomes an `ApiException` with a user-safe message.
  5xx bodies are never shown, and 422 field errors are mapped onto form fields.
- **Offline.** Categories, the home feed and recently viewed items are cached. An
  offline banner appears when the connection drops.
- **Loading.** Shimmer skeletons (`ProductSkeleton`, `CategorySkeleton`,
  `HomeSkeleton`, `OrderSkeleton`) instead of bare spinners.
- **Accessibility.** Semantic labels on icon controls, 48dp touch targets, and text
  scaling (capped at 130%) that card layouts account for.

## Expected API envelope

```json
{ "success": true, "message": "optional", "data": { }, "meta": { "current_page": 1, "per_page": 20, "total": 120, "last_page": 6 } }
```

Endpoints are listed in `lib/core/constants/api_endpoints.dart`.
The field names each model expects are in its `fromJson`.

## Tests

```bash
flutter test
```

Covers cart pricing rules, coupons, stock limits, order placement and payment
verification (against the demo backend), validators, null-safe parsing and
error-message safety.
