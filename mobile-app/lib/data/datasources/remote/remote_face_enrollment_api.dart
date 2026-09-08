import 'package:dio/dio.dart';
import '../../repositories/app_repositories.dart';

class RemoteFaceEnrollmentApi implements FaceEnrollmentApi {
  RemoteFaceEnrollmentApi(this._dio);
  final Dio _dio;

  @override
  Future<bool> isEnrolled() async {
    final res = await _dio.get('/biometrics/status');
    return (res.data as Map<String, dynamic>)['enrolled'] as bool? ?? false;
  }

  @override
  Future<void> startEnrollment() => _dio.post('/biometrics/enroll/start');

  @override
  Future<void> completeEnrollment() => _dio.post('/biometrics/enroll/complete', data: {
        'model_version': '1.0',
        'quality_score': 0.90,
        'liveness_score': 0.95,
      });
}
