import 'package:dio/dio.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class RemoteNotificationApi implements NotificationApi {
  RemoteNotificationApi(this._dio);
  final Dio _dio;

  @override
  Future<List<AppNotification>> notifications() async {
    final res = await _dio.get('/notifications');
    return (res.data as List).map((e) => _parse(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> markRead(String id) => _dio.post('/notifications/$id/read');

  @override
  Future<void> markAllRead() => _dio.post('/notifications/read-all');

  AppNotification _parse(Map<String, dynamic> d) => AppNotification(
        id: d['id'] as String,
        type: d['type'] as String,
        title: d['title'] as String,
        body: d['body'] as String,
        read: d['read'] as bool? ?? false,
        timestamp: DateTime.tryParse(d['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
