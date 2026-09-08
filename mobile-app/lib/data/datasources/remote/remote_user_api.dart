import 'package:dio/dio.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class RemoteUserApi implements UserApi {
  RemoteUserApi(this._dio);
  final Dio _dio;

  @override
  Future<Employee> currentEmployee() async {
    final res = await _dio.get('/employees/me');
    return _parseEmployee(res.data as Map<String, dynamic>);
  }

  @override
  Future<DeviceMetadata> deviceMetadata() async {
    try {
      final res = await _dio.get('/devices/me');
      if (res.data == null) {
        return const DeviceMetadata(name: 'Unknown', model: 'Unknown', osVersion: 'Unknown', appVersion: '1.0.0', registered: false);
      }
      return _parseDevice(res.data as Map<String, dynamic>);
    } catch (_) {
      return const DeviceMetadata(name: 'Unknown', model: 'Unknown', osVersion: 'Unknown', appVersion: '1.0.0', registered: false);
    }
  }

  @override
  Future<DeviceMetadata> registerDevice() async {
    // Gather real device info
    final res = await _dio.post('/devices/register', data: {
      'device_uuid': await _getDeviceUuid(),
      'platform': _getPlatform(),
      'app_version': '1.0.0',
    });
    return _parseDevice(res.data as Map<String, dynamic>);
  }

  Employee _parseEmployee(Map<String, dynamic> d) => Employee(
        id: d['id'] as String,
        name: d['full_name'] as String,
        department: d['department'] as String? ?? '',
        role: d['role'] as String? ?? '',
        project: d['project'] as String? ?? '',
        location: d['location'] as String? ?? '',
        shift: d['shift'] as String? ?? '',
        faceEnrolled: d['face_enrolled'] as bool? ?? false,
        deviceRegistered: d['device_registered'] as bool? ?? false,
        siteCode: d['site_code'] as String?,
        managerName: d['manager_name'] as String?,
      );

  DeviceMetadata _parseDevice(Map<String, dynamic> d) => DeviceMetadata(
        name: d['model'] as String? ?? 'Device',
        model: d['model'] as String? ?? 'Unknown',
        osVersion: d['os_version'] as String? ?? 'Unknown',
        appVersion: d['app_version'] as String? ?? '1.0.0',
        registered: d['status'] == 'REGISTERED',
      );

  Future<String> _getDeviceUuid() async {
    // In production: use device_info_plus to get real device ID
    return 'device-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _getPlatform() {
    // In production: Platform.isAndroid ? 'android' : 'ios'
    return 'android';
  }
}
