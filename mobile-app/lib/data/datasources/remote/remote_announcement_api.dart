import 'package:dio/dio.dart';
import '../../models/app_models.dart';
import '../../repositories/app_repositories.dart';

class RemoteAnnouncementApi implements AnnouncementApi {
  RemoteAnnouncementApi(this._dio);
  final Dio _dio;

  @override
  Future<List<Announcement>> announcements() async {
    final res = await _dio.get('/announcements');
    return (res.data as List).map((e) => _parse(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Announcement> detail(String id) async {
    final res = await _dio.get('/announcements/$id');
    return _parse(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> acknowledge(String id) async {
    await _dio.post('/announcements/$id/acknowledge');
  }

  Announcement _parse(Map<String, dynamic> d) => Announcement(
        id: d['id'] as String,
        title: d['title'] as String,
        category: d['category'] as String,
        body: d['body'] as String,
        pinned: d['pinned'] as bool? ?? false,
        urgent: d['urgent'] as bool? ?? false,
        read: d['read'] as bool? ?? false,
        acknowledged: d['acknowledged'] as bool? ?? false,
        publishedAt: DateTime.tryParse(d['published_at'] as String? ?? '') ?? DateTime.now(),
        publisher: d['publisher'] as String?,
      );
}

class RemoteNotificationApi implements NotificationApi {
  RemoteNotificationApi(this._dio);
  final Dio _dio;

  @override
  Future<List<AppNotification>> notifications() async {
    final res = await _dio.get('/notifications');
    return (res.data as List).map((e) => _parseNote(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> markRead(String id) async => await _dio.post('/notifications/$id/read');

  @override
  Future<void> markAllRead() async => await _dio.post('/notifications/read-all');

  AppNotification _parseNote(Map<String, dynamic> d) => AppNotification(
        id: d['id'] as String,
        type: d['type'] as String,
        title: d['title'] as String,
        body: d['body'] as String,
        read: d['read'] as bool? ?? false,
        timestamp: DateTime.tryParse(d['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
