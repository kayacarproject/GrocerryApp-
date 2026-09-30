import 'package:dio/dio.dart';

import '../utils/json_utils.dart';

enum ApiErrorType {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  validation,
  tooManyRequests,
  server,
  serviceUnavailable,
  timeout,
  noInternet,
  cancelled,
  unknown,
}

/// The only error type that leaves the data layer. [message] is always safe
/// to show to users; raw server payloads are never surfaced.
class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });

  factory ApiException.fromDio(DioException error) {
    if (error.error is ApiException) return error.error! as ApiException;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          type: ApiErrorType.timeout,
          message: 'The request timed out. Please check your connection.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          type: ApiErrorType.noInternet,
          message: 'No internet connection. Check your network and try again.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          type: ApiErrorType.cancelled,
          message: 'Request was cancelled.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          type: ApiErrorType.unknown,
          message: 'Could not establish a secure connection.',
        );
      case DioExceptionType.badResponse:
        return ApiException.fromResponse(
          error.response?.statusCode,
          error.response?.data,
        );
      default:
        return const ApiException(
          type: ApiErrorType.unknown,
          message: 'Something went wrong. Please try again.',
        );
    }
  }

  factory ApiException.fromResponse(int? statusCode, Object? body) {
    final json = Json.map(body);
    // Only 4xx client errors carry messages written for end users (e.g.
    // "Coupon expired"). 5xx bodies may contain internals and are discarded.
    final serverMessage = Json.stringOrNull(json['message']);
    final safeMessage =
        (serverMessage != null && serverMessage.length <= 140) ? serverMessage : null;

    final type = switch (statusCode) {
      400 => ApiErrorType.badRequest,
      401 => ApiErrorType.unauthorized,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      422 => ApiErrorType.validation,
      429 => ApiErrorType.tooManyRequests,
      503 => ApiErrorType.serviceUnavailable,
      final code? when code >= 500 => ApiErrorType.server,
      _ => ApiErrorType.unknown,
    };

    final code = Json.stringOrNull(json['code']);
    final isClientError = statusCode != null && statusCode >= 400 && statusCode < 500;
    // A missing/expired token gets our own wording; other 401s (e.g. wrong
    // password) carry a message meant for the user.
    final isSessionError = type == ApiErrorType.unauthorized &&
        (code == null || code == 'UNAUTHENTICATED');
    return ApiException(
      type: type,
      statusCode: statusCode,
      code: code,
      message: (isClientError && !isSessionError)
          ? (safeMessage ?? defaultMessage(type))
          : defaultMessage(type),
      fieldErrors: _parseFieldErrors(json['errors']),
    );
  }

  final ApiErrorType type;
  final String message;
  final int? statusCode;

  /// Machine-readable error code from the API, e.g. `COUPON_INVALID`.
  final String? code;

  /// Per-field validation messages from 422 responses.
  final Map<String, String> fieldErrors;

  bool get isNetworkError =>
      type == ApiErrorType.noInternet || type == ApiErrorType.timeout;

  static String defaultMessage(ApiErrorType type) => switch (type) {
    ApiErrorType.badRequest => 'The request could not be processed.',
    ApiErrorType.unauthorized => 'Your session has expired. Please log in again.',
    ApiErrorType.forbidden => 'You do not have permission to do that.',
    ApiErrorType.notFound => 'We could not find what you were looking for.',
    ApiErrorType.validation => 'Please check the details and try again.',
    ApiErrorType.tooManyRequests =>
      'Too many attempts. Please wait a moment and try again.',
    ApiErrorType.server => 'Our servers are having trouble. Please try again soon.',
    ApiErrorType.serviceUnavailable =>
      'The service is temporarily unavailable. Please try again later.',
    ApiErrorType.timeout => 'The request timed out. Please check your connection.',
    ApiErrorType.noInternet =>
      'No internet connection. Check your network and try again.',
    ApiErrorType.cancelled => 'Request was cancelled.',
    ApiErrorType.unknown => 'Something went wrong. Please try again.',
  };

  /// Converts any thrown object into a user-safe message.
  static String messageOf(Object error) => error is ApiException
      ? error.message
      : defaultMessage(ApiErrorType.unknown);

  static Map<String, String> _parseFieldErrors(Object? errors) {
    if (errors is! Map) return const {};
    return errors.map((key, value) {
      final message = value is List && value.isNotEmpty
          ? value.first.toString()
          : value.toString();
      return MapEntry(key.toString(), message);
    });
  }

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}
