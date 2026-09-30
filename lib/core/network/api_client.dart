import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/api_response.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

typedef JsonDecoder<T> = T Function(Object? data);

/// Single entry point for HTTP. Services call these typed helpers and never
/// touch Dio directly; every failure surfaces as an [ApiException].
///
/// Expected response envelope:
/// `{ "success": true, "message": "...", "data": ..., "meta": {...} }`
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    void Function()? onSessionExpired,
    String baseUrl = AppConfig.apiBaseUrl,
  }) : _dio = Dio(_options(baseUrl)) {
    final refreshDio = Dio(_options(baseUrl));
    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        dio: _dio,
        refreshDio: refreshDio,
        onSessionExpired: onSessionExpired,
      ),
    );
    if (AppConfig.isDevelopment && kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          // Keep bearer tokens out of logs.
          requestHeader: false,
          logPrint: (line) => debugPrint(line.toString()),
        ),
      );
    }
  }

  final Dio _dio;

  static BaseOptions _options(String baseUrl) => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    sendTimeout: AppConfig.sendTimeout,
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
    headers: {
      'Accept': 'application/json',
      // Dev Tunnels otherwise may answer with an HTML interstitial page.
      if (Uri.parse(baseUrl).host.endsWith('devtunnels.ms'))
        'X-Tunnel-Skip-AntiPhishing-Page': 'true',
    },
  );

  static Options _authOptions({bool auth = true}) =>
      Options(extra: {AuthInterceptor.skipAuthKey: !auth});

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required JsonDecoder<T> decoder,
    bool auth = true,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.get<dynamic>(
      path,
      queryParameters: query,
      options: _authOptions(auth: auth),
      cancelToken: cancelToken,
    ),
    decoder,
  );

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decoder,
    bool auth = true,
  }) => _send(
    () => _dio.post<dynamic>(
      path,
      data: body,
      options: _authOptions(auth: auth),
    ),
    decoder,
  );

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decoder,
  }) => _send(() => _dio.put<dynamic>(path, data: body), decoder);

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decoder,
  }) => _send(() => _dio.patch<dynamic>(path, data: body), decoder);

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decoder,
  }) => _send(() => _dio.delete<dynamic>(path, data: body), decoder);

  /// Multipart upload, e.g. a profile picture.
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic> fields = const {},
    required JsonDecoder<T> decoder,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      ...fields,
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _send(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
        onSendProgress: onSendProgress,
      ),
      decoder,
    );
  }

  Future<ApiResponse<T>> _send<T>(
    Future<Response<dynamic>> Function() request,
    JsonDecoder<T> decoder,
  ) async {
    try {
      final response = await request();
      final envelope = ApiResponse.fromJson(response.data, decoder);
      if (!envelope.success) {
        throw ApiException.fromResponse(response.statusCode ?? 400, response.data);
      }
      return envelope;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    } on ApiException {
      rethrow;
    } catch (error, stack) {
      // Parsing failures etc. Log for developers, show a generic message.
      debugPrint('ApiClient unexpected error: $error\n$stack');
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Something went wrong. Please try again.',
      );
    }
  }
}
