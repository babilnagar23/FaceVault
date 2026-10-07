import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _uuidKey = 'installation_uuid';

  Future<Map<String, dynamic>> getDeviceInfo() async {
    String installationId = await _getOrCreateInstallationId();
    String platform = Platform.operatingSystem;
    String manufacturer = 'Unknown';
    String model = 'Unknown';
    String osVersion = 'Unknown';

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      manufacturer = info.manufacturer;
      model = info.model;
      osVersion = info.version.release;
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      manufacturer = 'Apple';
      model = info.model;
      osVersion = info.systemVersion;
    }

    return {
      'platform': platform,
      'manufacturer': manufacturer,
      'model': model,
      'os_version': osVersion,
      'app_version': '0.1.0', // Normally from package_info_plus
      'installation_id': installationId,
    };
  }

  Future<String> _getOrCreateInstallationId() async {
    String? uuid = await _storage.read(key: _uuidKey);
    if (uuid == null) {
      uuid = const Uuid().v4();
      await _storage.write(key: _uuidKey, value: uuid);
    }
    return uuid;
  }
}
