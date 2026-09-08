import 'package:dio/dio.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';
import 'remote_exceptions.dart';

class RemoteAuthApi implements AuthApi {
  RemoteAuthApi(this._dio);
  final Dio _dio;

  static const _base = '/auth';

  @override
  Future<bool> hasSession() async {
    try {
      await _dio.get('$_base/me');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return false;
      rethrow;
    }
  }

  @override
  Future<LoginResult> login(String employeeId, String password) async {
    try {
      final res = await _dio.post('$_base/login', data: {
        'employee_id': employeeId,
        'password': password,
      });
      final data = res.data as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;

      // Persist tokens in secure storage
      await _persistTokens(
        accessToken: tokens['access_token'] as String,
        refreshToken: tokens['refresh_token'] as String,
      );

      return LoginResult(
        authenticated: true,
        firstDeviceLogin: user['first_device_login'] as bool? ?? false,
        employeeId: user['id'] as String?,
      );
    } on DioException catch (e) {
      final message = _extractMessage(e);
      return LoginResult(
        authenticated: false,
        firstDeviceLogin: false,
        message: message,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('$_base/logout');
    } finally {
      await _clearTokens();
    }
  }

  Future<void> _persistTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // In production: use flutter_secure_storage
    // SecureStorage.write('access_token', accessToken);
    // SecureStorage.write('refresh_token', refreshToken);
    // For now, store in Dio default headers
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  Future<void> _clearTokens() async {
    _dio.options.headers.remove('Authorization');
  }

  String _extractMessage(DioException e) {
    try {
      final data = e.response?.data as Map<String, dynamic>?;
      return data?['error']?['message'] as String? ?? 'Authentication failed.';
    } catch (_) {
      return 'Authentication failed.';
    }
  }
}
