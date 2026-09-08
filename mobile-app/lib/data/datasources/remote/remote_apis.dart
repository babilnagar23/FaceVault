/// Remote API implementations — swap MockXxx for RemoteXxx in app_providers.dart
/// All implementations use Dio and point to the FaceVault FastAPI backend.
///
/// Usage: In app_providers.dart, change:
///   final authApiProvider = Provider<AuthApi>((ref) => MockAuthApi());
/// to:
///   final authApiProvider = Provider<AuthApi>((ref) => RemoteAuthApi(ref.watch(dioProvider)));

library remote_apis;

export 'remote_auth_api.dart';
export 'remote_user_api.dart';
export 'remote_attendance_api.dart';
export 'remote_announcement_api.dart';
export 'remote_notification_api.dart';
export 'remote_help_api.dart';
export 'remote_sync_api.dart';
export 'remote_face_enrollment_api.dart';
