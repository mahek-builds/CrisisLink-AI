import 'package:crisislink_ai_app/app.dart';
import 'package:crisislink_ai_app/screens/launch_screen.dart';
import 'package:crisislink_ai_app/services/connectivity_service.dart';
import 'package:crisislink_ai_app/services/location_service.dart';
import 'package:crisislink_ai_app/services/sos_api_service.dart';
import 'package:crisislink_ai_app/widgets/sos_emergency_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConnectivityService implements ConnectivityService {
  const FakeConnectivityService(this.online);

  final bool online;

  @override
  Future<bool> isOnline() async => online;
}

class FakeLocationService implements LocationService {
  const FakeLocationService();

  @override
  Future<AppLocation> getCurrentLocation() async {
    return const AppLocation(latitude: 28.61, longitude: 77.21);
  }
}

class FakeSosApiService extends SosApiService {
  const FakeSosApiService();

  @override
  Future<SosSubmissionResponse> createSosReport(
    SosCreateRequest request,
  ) async {
    return const SosSubmissionResponse(
      status: 'success',
      incidentId: 'demo-incident-1',
      uniqueReporters: 2,
      priority: 'HIGH',
    );
  }

  @override
  Future<AdminStats> fetchAdminStats() async {
    return const AdminStats(active: 3, working: 1, resolved: 8);
  }

  @override
  Future<List<IncidentSummary>> fetchLiveIncidents() async {
    return <IncidentSummary>[
      IncidentSummary(
        id: 'incident-admin-1',
        latitude: 28.61,
        longitude: 77.21,
        type: 'medical',
        priority: 'HIGH',
        status: 'active',
        reporterCount: 2,
        createdAt: DateTime.utc(2026, 4, 14, 12, 0),
      ),
    ];
  }

  @override
  Future<List<IncidentSummary>> fetchActiveIncidents() async {
    return <IncidentSummary>[
      IncidentSummary(
        id: 'incident-responder-1',
        latitude: 28.62,
        longitude: 77.22,
        type: 'fire',
        priority: 'CRITICAL',
        status: 'active',
        reporterCount: 4,
        createdAt: DateTime.utc(2026, 4, 14, 12, 5),
      ),
    ];
  }

  @override
  Future<IncidentDetailsResponse> fetchIncidentDetails(String incidentId) async {
    return IncidentDetailsResponse(
      details: IncidentSummary(
        id: incidentId,
        latitude: 28.62,
        longitude: 77.22,
        type: 'fire',
        priority: 'CRITICAL',
        status: 'active',
        reporterCount: 4,
        createdAt: DateTime.utc(2026, 4, 14, 12, 5),
      ),
      reports: const <IncidentReport>[
        IncidentReport(
          phoneNumber: '9999999999',
          reportType: 'fire',
          createdAt: null,
        ),
      ],
    );
  }

  @override
  Future<IncidentAnalysis> analyzeIncident(String incidentId) async {
    return const IncidentAnalysis(
      predictedPriority: 'CRITICAL',
      uniqueReporters: 4,
      isSuspicious: false,
      fraudReason: '',
      requiredUnits: 3,
      teamType: 'Fire Brigade & Rescue',
      actionPlan: 'Immediate Multi-Unit Dispatch + Area Cordoning',
      equipment: <String>['Water Tanker'],
    );
  }

  @override
  Future<ResolveIncidentResponse> resolveIncident(String incidentId) async {
    return ResolveIncidentResponse(
      status: 'success',
      message: 'Incident $incidentId marked as resolved',
    );
  }

  @override
  Future<AssignmentResponse> assignResponder({
    required String responderId,
    required String incidentId,
  }) async {
    return AssignmentResponse(
      status: 'assigned',
      responderId: responderId,
      incidentId: incidentId,
    );
  }

  @override
  Future<AssignmentResponse> releaseResponder(String responderId) async {
    return AssignmentResponse(
      status: 'released',
      responderId: responderId,
    );
  }
}

void main() {
  Widget buildApp({required bool online}) {
    return CrisisLinkApp(
      connectivityService: FakeConnectivityService(online),
      locationService: const FakeLocationService(),
      sosApiService: const FakeSosApiService(),
    );
  }

  testWidgets('launch screen redirects to SOS home screen', (tester) async {
    await tester.pumpWidget(buildApp(online: true));

    expect(find.text('EMERGENCY NEURAL NETWORK V4.0'), findsOneWidget);
    expect(find.text('INITIALIZING SECURE CONNECTION...'), findsOneWidget);
    expect(find.text('CrisisLink-AI'), findsNothing);

    await tester.pump(LaunchScreen.displayDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CrisisLink-AI'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Staff Access'), findsOneWidget);
  });

  testWidgets('staff access expands on the SOS screen', (tester) async {
    await tester.pumpWidget(buildApp(online: true));
    await tester.pump(LaunchScreen.displayDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Staff Access'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Responder'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Login as Responder'), findsOneWidget);
  });

  testWidgets('online SOS redirects to live emergency flow', (tester) async {
    await tester.pumpWidget(buildApp(online: true));
    await tester.pump(LaunchScreen.displayDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final buttonFinder = find.byType(SosEmergencyButton);
    expect(buttonFinder, findsOneWidget);

    final shortHold =
        await tester.startGesture(tester.getCenter(buttonFinder));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(
      find.text('Keep pressing until the ring completes to continue.'),
      findsOneWidget,
    );
    await shortHold.up();
    await tester.pump();

    expect(find.text('Select Emergency Type'), findsNothing);
    expect(
      find.text('Hold for 10 seconds to activate emergency alert'),
      findsOneWidget,
    );

    final fullHold = await tester.startGesture(tester.getCenter(buttonFinder));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10100));
    await tester.pump();
    await fullHold.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Select Emergency Type'), findsOneWidget);
    expect(find.text('Medical Emergency'), findsOneWidget);

    await tester.tap(find.text('Medical Emergency'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Describe Situation'), findsOneWidget);
    expect(
      find.text('Add your phone number and confirm live location before sending.'),
      findsOneWidget,
    );
    expect(find.text('Send Live Alert'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, '9999999999');
    await tester.pump();
    await tester.ensureVisible(find.text('Send Live Alert'));
    await tester.pump();
    await tester.tap(find.text('Send Live Alert'));
    await tester.pump();

    expect(find.text('Sending Emergency Alert...'), findsOneWidget);
    expect(find.text('Transmitting live backend request'), findsOneWidget);
  });

  testWidgets('offline SOS redirects to offline emergency page', (tester) async {
    await tester.pumpWidget(buildApp(online: false));
    await tester.pump(LaunchScreen.displayDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final buttonFinder = find.byType(SosEmergencyButton);
    final fullHold = await tester.startGesture(tester.getCenter(buttonFinder));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10100));
    await tester.pump();
    await fullHold.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Offline Emergency Mode'), findsOneWidget);
    expect(find.text('Calling 112'), findsOneWidget);
  });

  testWidgets('admin login opens admin dashboard', (tester) async {
    await tester.pumpWidget(buildApp(online: true));
    await tester.pump(LaunchScreen.displayDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Staff Access'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Admin'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(EditableText).at(0), 'admin');
    await tester.enterText(find.byType(EditableText).at(1), 'admin');
    await tester.tap(find.text('Login as Admin'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Admin Control Room'), findsOneWidget);
    expect(find.text('Live Incidents'), findsOneWidget);
  });

  testWidgets('responder login opens responder dashboard', (tester) async {
    await tester.pumpWidget(buildApp(online: true));
    await tester.pump(LaunchScreen.displayDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Staff Access'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(EditableText).at(0), 'resp');
    await tester.enterText(find.byType(EditableText).at(1), 'resp');
    await tester.tap(find.text('Login as Responder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Responder Dispatch'), findsOneWidget);
    expect(find.text('Assign Me'), findsOneWidget);
  });
}
