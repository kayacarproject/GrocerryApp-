import '../core/utils/json_utils.dart';
import 'pagination.dart';

/// Standard response envelope:
/// `{ "success": bool, "message": String?, "data": T, "meta": {...} }`.
/// Bodies without an envelope are treated as raw `data`.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.data,
    this.message,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Object? body,
    T Function(Object? data) decodeData,
  ) {
    final isEnvelope = body is Map && body.containsKey('data');
    final json = Json.map(body);
    final meta = Json.mapOrNull(json['meta']) ?? Json.mapOrNull(json['pagination']);
    return ApiResponse(
      success: isEnvelope ? Json.boolean(json['success'], true) : true,
      message: Json.stringOrNull(json['message']),
      data: decodeData(isEnvelope ? json['data'] : body),
      pagination: meta == null ? null : Pagination.fromJson(meta),
    );
  }

  final bool success;
  final String? message;
  final T data;
  final Pagination? pagination;

  Map<String, dynamic> toJson(Object? Function(T data) encodeData) => {
    'success': success,
    'message': message,
    'data': encodeData(data),
    if (pagination != null) 'meta': pagination!.toJson(),
  };
}
