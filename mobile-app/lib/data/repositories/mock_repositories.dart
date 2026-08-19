import '../models/app_models.dart';
import 'app_repositories.dart';

class MockAuthApi implements AuthApi {
  bool _session = false;

  @override
  Future<bool> hasSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _session;
  }

  @override
  Future<LoginResult> login(String employeeId, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (employeeId.trim().isEmpty || password.length < 4) {
      return const LoginResult(
        authenticated: false,
        firstDeviceLogin: false,
        message: 'Invalid employee ID or password.',
      );
    }
    _session = true;
    return const LoginResult(authenticated: true, firstDeviceLogin: true);
  }

  @override
  Future<void> logout() async => _session = false;
}

class MockUserApi implements UserApi {
  @override
  Future<Employee> currentEmployee() async => const Employee(
        id: 'EMP-1042',
        name: 'Aarav Mehta',
        department: 'Operations',
        role: 'Site Supervisor',
        project: 'Metro Expansion',
        location: 'Sector 17',
        shift: '09:00 - 18:00',
        faceEnrolled: true,
        deviceRegistered: true,
      );

  @override
  Future<DeviceMetadata> deviceMetadata() async => const DeviceMetadata(
        name: 'Employee Phone',
        model: 'Android Device',
        osVersion: 'Android 15',
        appVersion: '0.1.0',
        registered: false,
      );

  @override
  Future<DeviceMetadata> registerDevice() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const DeviceMetadata(
      name: 'Employee Phone',
      model: 'Android Device',
      osVersion: 'Android 15',
      appVersion: '0.1.0',
      registered: true,
    );
  }
}

class MockAttendanceApi implements AttendanceApi {
  @override
  Future<AttendanceRecord> markAttendance() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return AttendanceRecord(
      id: 'ATT-9001',
      date: DateTime.now(),
      status: AttendanceStatus.present,
      checkInTime: '09:02 AM',
      assignedSite: 'Sector 17',
      distanceMeters: 23,
      faceStatus: 'Verified',
      livenessStatus: 'Verified',
      locationStatus: 'Verified',
      syncStatus: SyncState.synced,
      remarks: 'Attendance marked successfully.',
    );
  }

  @override
  Future<List<AttendanceRecord>> history() async => List.generate(
        8,
        (index) => AttendanceRecord(
          id: 'ATT-${9000 + index}',
          date: DateTime.now().subtract(Duration(days: index)),
          status: index == 2
              ? AttendanceStatus.locationError
              : index == 4
                  ? AttendanceStatus.late
                  : AttendanceStatus.present,
          checkInTime: index == 4 ? '09:21 AM' : '09:02 AM',
          assignedSite: 'Sector 17',
          distanceMeters: index == 2 ? 1400 : 23,
          faceStatus: 'Verified',
          livenessStatus: 'Verified',
          locationStatus: index == 2 ? 'Failed' : 'Verified',
          syncStatus: index == 1 ? SyncState.pending : SyncState.synced,
          remarks: index == 2 ? 'Outside assigned geofence.' : 'OK',
        ),
      );

  @override
  Future<AttendanceRecord> detail(String id) async {
    final records = await history();
    return records.firstWhere((record) => record.id == id, orElse: () => records.first);
  }
}

class MockAnnouncementApi implements AnnouncementApi {
  @override
  Future<List<Announcement>> announcements() async => const [
        Announcement(
          id: 'ANN-1',
          title: 'Safety Update',
          category: 'Safety',
          body: 'Wear helmets in all active work zones.',
          pinned: true,
          urgent: false,
          read: false,
          acknowledged: false,
        ),
        Announcement(
          id: 'ANN-2',
          title: 'Emergency Alert',
          category: 'Emergency',
          body: 'Gate 3 is temporarily closed for maintenance.',
          pinned: false,
          urgent: true,
          read: true,
          acknowledged: true,
        ),
      ];
}

class MockNotificationApi implements NotificationApi {
  @override
  Future<List<String>> notifications() async => const [
        'Attendance reminder: your shift starts at 09:00.',
        'Help ticket #HELP-10382 is pending review.',
        'New safety announcement requires acknowledgement.',
      ];
}

class MockHelpApi implements HelpApi {
  @override
  Future<List<String>> issueTypes() async => const [
        'Location Error',
        'Face Recognition Failed',
        'GPS Problem',
        'Camera Problem',
        'App Error',
        'Internet/Sync Issue',
        'Wrong Assigned Location',
        'Permission Problem',
        'Attendance Missing',
        'Shift Timing Issue',
        'Device Changed',
        'Other',
      ];

  @override
  Future<HelpTicket> createTicket({
    required String issueType,
    required String description,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return HelpTicket(
      id: '#HELP-10382',
      issueType: issueType,
      description: description,
      status: 'Pending',
    );
  }
}

class MockSyncApi implements SyncApi {
  var _status = SyncState.pending;

  @override
  Future<void> enqueue(String type, Map<String, Object?> payload) async {
    _status = SyncState.pending;
  }

  @override
  Future<void> flush() async {
    _status = SyncState.syncing;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _status = SyncState.synced;
  }

  @override
  Future<SyncState> status() async => _status;
}

