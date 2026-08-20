import '../models/app_models.dart';
import 'app_repositories.dart';

// ─────────────────────────────────────────
// SHARED DEMO DATA
// ─────────────────────────────────────────

const _demoEmployee = Employee(
  id: 'EMP-1042',
  name: 'Aarav Mehta',
  department: 'Operations',
  role: 'Site Supervisor',
  project: 'Metro Expansion',
  location: 'Sector 17',
  shift: '09:00 - 18:00',
  faceEnrolled: true,
  deviceRegistered: true,
  siteCode: 'DEL-MR-02',
  zone: 'North Sector',
  managerName: 'K. Sharma',
);

// ─────────────────────────────────────────
// MOCK AUTH
// ─────────────────────────────────────────

class MockAuthApi implements AuthApi {
  bool _session = false;

  @override
  Future<bool> hasSession() async {
    await _delay(350);
    return _session;
  }

  @override
  Future<LoginResult> login(String employeeId, String password) async {
    await _delay(650);
    if (employeeId.trim().isEmpty || password.length < 4) {
      return const LoginResult(
        authenticated: false,
        firstDeviceLogin: false,
        message: 'Invalid Employee ID or password.',
      );
    }
    _session = true;
    return const LoginResult(
      authenticated: true,
      firstDeviceLogin: true,
      employeeId: 'EMP-1042',
    );
  }

  @override
  Future<void> logout() async => _session = false;
}

// ─────────────────────────────────────────
// MOCK USER
// ─────────────────────────────────────────

class MockUserApi implements UserApi {
  @override
  Future<Employee> currentEmployee() async {
    await _delay(200);
    return _demoEmployee;
  }

  @override
  Future<DeviceMetadata> deviceMetadata() async => const DeviceMetadata(
        name: 'Aarav\'s Phone',
        model: 'Pixel 8',
        osVersion: 'Android 15',
        appVersion: '1.0.0',
        registered: false,
      );

  @override
  Future<DeviceMetadata> registerDevice() async {
    await _delay(700);
    return const DeviceMetadata(
      name: 'Aarav\'s Phone',
      model: 'Pixel 8',
      osVersion: 'Android 15',
      appVersion: '1.0.0',
      registered: true,
    );
  }
}

// ─────────────────────────────────────────
// MOCK ATTENDANCE
// ─────────────────────────────────────────

class MockAttendanceApi implements AttendanceApi {
  @override
  Future<AttendanceRecord> markAttendance() async {
    await _delay(1000);
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
      faceScore: 0.992,
      livenessScore: 0.97,
      gpsAccuracy: 4,
    );
  }

  @override
  Future<AttendanceVerificationResult> runVerification() async {
    await _delay(3500);
    return AttendanceVerificationResult(
      faceVerified: true,
      faceScore: 0.992,
      livenessVerified: true,
      livenessScore: 0.97,
      locationVerified: true,
      distanceMeters: 23,
      gpsAccuracyMeters: 4,
      assignedSite: 'Sector 17',
      timestamp: DateTime.now(),
      attendanceStatus: AttendanceStatus.present,
      syncStatus: SyncState.synced,
    );
  }

  @override
  Future<List<AttendanceRecord>> history() async => [
        AttendanceRecord(
          id: 'ATT-9001',
          date: DateTime.now(),
          status: AttendanceStatus.present,
          checkInTime: '09:02 AM',
          checkOutTime: '18:05 PM',
          assignedSite: 'Sector 17',
          distanceMeters: 23,
          faceStatus: 'Verified',
          livenessStatus: 'Verified',
          locationStatus: 'Verified',
          syncStatus: SyncState.synced,
          remarks: 'OK',
          faceScore: 0.992,
          livenessScore: 0.97,
          gpsAccuracy: 4,
        ),
        AttendanceRecord(
          id: 'ATT-9000',
          date: DateTime.now().subtract(const Duration(days: 1)),
          status: AttendanceStatus.present,
          checkInTime: '09:05 AM',
          checkOutTime: '17:58 PM',
          assignedSite: 'Sector 17',
          distanceMeters: 18,
          faceStatus: 'Verified',
          livenessStatus: 'Verified',
          locationStatus: 'Verified',
          syncStatus: SyncState.synced,
          remarks: 'OK',
          faceScore: 0.985,
          livenessScore: 0.96,
          gpsAccuracy: 6,
        ),
        AttendanceRecord(
          id: 'ATT-8999',
          date: DateTime.now().subtract(const Duration(days: 2)),
          status: AttendanceStatus.locationError,
          checkInTime: '09:08 AM',
          assignedSite: 'Sector 17',
          distanceMeters: 1400,
          faceStatus: 'Verified',
          livenessStatus: 'Verified',
          locationStatus: 'Failed',
          syncStatus: SyncState.synced,
          remarks: 'Outside assigned geofence. Pending admin review.',
          faceScore: 0.978,
          livenessScore: 0.94,
          gpsAccuracy: 18,
        ),
        AttendanceRecord(
          id: 'ATT-8998',
          date: DateTime.now().subtract(const Duration(days: 3)),
          status: AttendanceStatus.present,
          checkInTime: '08:58 AM',
          checkOutTime: '18:10 PM',
          assignedSite: 'Sector 17',
          distanceMeters: 31,
          faceStatus: 'Verified',
          livenessStatus: 'Verified',
          locationStatus: 'Verified',
          syncStatus: SyncState.synced,
          remarks: 'OK',
          faceScore: 0.989,
          livenessScore: 0.98,
          gpsAccuracy: 5,
        ),
        AttendanceRecord(
          id: 'ATT-8997',
          date: DateTime.now().subtract(const Duration(days: 4)),
          status: AttendanceStatus.late,
          checkInTime: '09:21 AM',
          checkOutTime: '18:30 PM',
          assignedSite: 'Sector 17',
          distanceMeters: 27,
          faceStatus: 'Verified',
          livenessStatus: 'Verified',
          locationStatus: 'Verified',
          syncStatus: SyncState.pending,
          remarks: 'Late arrival — 21 minutes after shift start.',
          faceScore: 0.981,
          livenessScore: 0.95,
          gpsAccuracy: 8,
        ),
        AttendanceRecord(
          id: 'ATT-8996',
          date: DateTime.now().subtract(const Duration(days: 5)),
          status: AttendanceStatus.present,
          checkInTime: '09:00 AM',
          checkOutTime: '17:55 PM',
          assignedSite: 'Sector 17',
          distanceMeters: 15,
          faceStatus: 'Verified',
          livenessStatus: 'Verified',
          locationStatus: 'Verified',
          syncStatus: SyncState.synced,
          remarks: 'OK',
          faceScore: 0.994,
          livenessScore: 0.99,
          gpsAccuracy: 3,
        ),
      ];

  @override
  Future<AttendanceRecord> detail(String id) async {
    final records = await history();
    return records.firstWhere(
      (record) => record.id == id,
      orElse: () => records.first,
    );
  }
}

// ─────────────────────────────────────────
// MOCK ANNOUNCEMENTS
// ─────────────────────────────────────────

class MockAnnouncementApi implements AnnouncementApi {
  final _acknowledged = <String>{};
  final _read = <String>{};

  @override
  Future<List<Announcement>> announcements() async {
    await _delay(200);
    return [
      Announcement(
        id: 'ANN-1',
        title: 'Safety Helmet Mandate — All Work Zones',
        category: 'Safety',
        body: 'Effective immediately, all personnel must wear helmets in active work zones. This applies to all sites including Sector 17 and Depot 4. Non-compliance may result in temporary suspension from site.',
        pinned: true,
        urgent: false,
        read: _read.contains('ANN-1'),
        acknowledged: _acknowledged.contains('ANN-1'),
        publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
        publisher: 'Safety Officer',
      ),
      Announcement(
        id: 'ANN-2',
        title: 'Emergency: Gate 3 Closure',
        category: 'Emergency',
        body: 'Gate 3 at Sector 17 is temporarily closed for structural inspection. Use Gate 1 for entry/exit. Expected re-opening by 14:00.',
        pinned: false,
        urgent: true,
        read: _read.contains('ANN-2'),
        acknowledged: _acknowledged.contains('ANN-2'),
        publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
        publisher: 'Operations Manager',
      ),
      Announcement(
        id: 'ANN-3',
        title: 'Holiday Schedule — Upcoming Public Holidays',
        category: 'Policy',
        body: 'Please review the updated holiday schedule for the remaining quarter. Attendance will be auto-marked as Leave for designated holidays.',
        pinned: false,
        urgent: false,
        read: _read.contains('ANN-3'),
        acknowledged: _acknowledged.contains('ANN-3'),
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        publisher: 'HR Department',
      ),
      Announcement(
        id: 'ANN-4',
        title: 'Project Update: Metro Expansion Phase II',
        category: 'Project',
        body: 'Phase II groundwork begins Monday. New geofence boundaries for Sector 17 will be active. Please ensure you are within the updated boundary when marking attendance.',
        pinned: false,
        urgent: false,
        read: _read.contains('ANN-4'),
        acknowledged: _acknowledged.contains('ANN-4'),
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        publisher: 'Project Manager',
      ),
    ];
  }

  @override
  Future<Announcement> detail(String id) async {
    final items = await announcements();
    _read.add(id);
    return items.firstWhere((a) => a.id == id, orElse: () => items.first);
  }

  @override
  Future<void> acknowledge(String id) async {
    await _delay(200);
    _acknowledged.add(id);
  }
}

// ─────────────────────────────────────────
// MOCK NOTIFICATIONS
// ─────────────────────────────────────────

class MockNotificationApi implements NotificationApi {
  final _read = <String>{};

  final _items = [
    AppNotification(
      id: 'NOT-1',
      type: 'attendance',
      title: 'Shift Reminder',
      body: 'Your shift starts at 09:00. Mark attendance when you arrive.',
      read: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AppNotification(
      id: 'NOT-2',
      type: 'help',
      title: 'Help Ticket Update',
      body: 'Ticket #HELP-10382 is now In Progress.',
      read: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'NOT-3',
      type: 'announcement',
      title: 'New Safety Announcement',
      body: 'A new safety announcement requires your acknowledgement.',
      read: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: 'NOT-4',
      type: 'system',
      title: 'Sync Complete',
      body: '3 offline attendance records synced successfully.',
      read: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<AppNotification>> notifications() async {
    await _delay(200);
    return _items
        .map((n) => AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              read: _read.contains(n.id) || n.read,
              timestamp: n.timestamp,
            ))
        .toList();
  }

  @override
  Future<void> markRead(String id) async => _read.add(id);

  @override
  Future<void> markAllRead() async => _read.addAll(_items.map((n) => n.id));
}

// ─────────────────────────────────────────
// MOCK HELP
// ─────────────────────────────────────────

class MockHelpApi implements HelpApi {
  final _tickets = <HelpTicket>[];

  @override
  Future<List<String>> issueTypes() async => const [
        'Location Error',
        'Face Recognition Failed',
        'GPS Problem',
        'Camera Problem',
        'App Error',
        'Internet / Sync Issue',
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
    await _delay(600);
    final ticket = HelpTicket(
      id: '#HELP-${10382 + _tickets.length}',
      issueType: issueType,
      description: description,
      status: 'Open',
      createdAt: DateTime.now(),
      employeeId: 'EMP-1042',
      employeeName: 'Aarav Mehta',
    );
    _tickets.add(ticket);
    return ticket;
  }

  @override
  Future<HelpTicket> detail(String id) async {
    await _delay(200);
    return _tickets.firstWhere(
      (t) => t.id == id,
      orElse: () => HelpTicket(
        id: id,
        issueType: 'GPS Problem',
        description: 'GPS accuracy is unstable near Gate 2.',
        status: 'In Progress',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    );
  }

  @override
  Future<List<HelpTicket>> myTickets() async {
    await _delay(300);
    if (_tickets.isEmpty) {
      return [
        HelpTicket(
          id: '#HELP-10382',
          issueType: 'GPS Problem',
          description: 'GPS accuracy is unstable near Gate 2.',
          status: 'In Progress',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
    }
    return _tickets.reversed.toList();
  }
}

// ─────────────────────────────────────────
// MOCK SYNC
// ─────────────────────────────────────────

class MockSyncApi implements SyncApi {
  SyncState _status = SyncState.pending;
  final _queue = <SyncItem>[];

  @override
  Future<void> enqueue(String type, Map<String, Object?> payload) async {
    _status = SyncState.pending;
    _queue.add(SyncItem(
      id: 'SYNC-${_queue.length + 1}',
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> flush() async {
    _status = SyncState.syncing;
    await _delay(1500);
    _queue.clear();
    _status = SyncState.synced;
  }

  @override
  Future<SyncState> status() async => _status;

  @override
  Future<List<SyncItem>> pendingItems() async => List.unmodifiable(_queue);
}

// ─────────────────────────────────────────
// MOCK FACE ENROLLMENT
// ─────────────────────────────────────────

class MockFaceEnrollmentApi implements FaceEnrollmentApi {
  bool _enrolled = false;

  @override
  Future<bool> isEnrolled() async => _enrolled;

  @override
  Future<void> startEnrollment() async => await _delay(300);

  @override
  Future<void> completeEnrollment() async {
    await _delay(800);
    _enrolled = true;
  }
}

// ─────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────

Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));
