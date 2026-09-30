import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';

/// Attaches the bearer token and transparently refreshes it once on 401.
///
/// Uses [QueuedInterceptor] so concurrent 401s wait for a single refresh
/// instead of each triggering their own.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
    required this.refreshDio,
    this.onSessionExpired,
  });

  /// Set `options.extra[skipAuthKey] = true` for public endpoints.
  static const skipAuthKey = 'skipAuth';
  static const _retriedKey = 'authRetried';

  final TokenStorage tokenStorage;

  /// The main client, used to replay the original request.
  final Dio dio;

  /// A bare client without this interceptor, used for the refresh call.
  final Dio refreshDio;
  final void Function()? onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final token = await tokenStorage.accessToken;
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final canRetry =
        request.extra[skipAuthKey] != true && request.extra[_retriedKey] != true;

    if (!isUnauthorized || !canRetry) return handler.next(err);

    final refreshed = await _refreshToken();
    if (!refreshed) {
      await tokenStorage.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }

    try {
      final token = await tokenStorage.accessToken;
      request.headers['Authorization'] = 'Bearer $token';
      request.extra[_retriedKey] = true;
      handler.resolve(await dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await tokenStorage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data?['data'];
      if (data is! Map || data['access_token'] == null) return false;
      await tokenStorage.saveTokens(
        accessToken: data['access_token'].toString(),
        refreshToken: data['refresh_token']?.toString(),
      );
      return true;
    } on DioException {
      return false;
    }
  }
}
