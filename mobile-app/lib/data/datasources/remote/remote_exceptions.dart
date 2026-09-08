import 'package:dio/dio.dart';

/// Maps DioException to user-facing messages.
class RemoteException implements Exception {
  const RemoteException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;

  factory RemoteException.from(DioException e) {
    try {
      final data = e.response?.data as Map<String, dynamic>?;
      final error = data?['error'] as Map<String, dynamic>?;
      return RemoteException(
        error?['message'] as String? ?? 'An error occurred.',
        code: error?['code'] as String?,
        statusCode: e.response?.statusCode,
      );
    } catch (_) {
      return RemoteException(
        e.message ?? 'Network error.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isServerError => (statusCode ?? 0) >= 500;
  bool get isOffline => statusCode == null;

  @override
  String toString() => 'RemoteException($statusCode): $message';
}
