import 'package:crisislink_ai_app/app.dart';
import 'package:crisislink_ai_app/screens/launch_screen.dart';
import 'package:crisislink_ai_app/services/connectivity_service.dart';
import 'package:crisislink_ai_app/widgets/sos_emergency_button.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeConnectivityService implements ConnectivityService {
  const FakeConnectivityService(this.online);

  final bool online;

  @override
  Future<bool> isOnline() async => online;
}

void main() {
  testWidgets('launch screen redirects to SOS home screen', (tester) async {
    await tester.pumpWidget(
      CrisisLinkApp(connectivityService: const FakeConnectivityService(true)),
    );

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
    await tester.pumpWidget(
      CrisisLinkApp(connectivityService: const FakeConnectivityService(true)),
    );
    await tester.pump(LaunchScreen.displayDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Staff Access'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Responder'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Login as Staff'), findsOneWidget);
  });

  testWidgets('online SOS redirects to emergency type page', (tester) async {
    await tester.pumpWidget(
      CrisisLinkApp(connectivityService: const FakeConnectivityService(true)),
    );
    await tester.pump(LaunchScreen.displayDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final buttonFinder = find.byType(SosEmergencyButton);
    expect(buttonFinder, findsOneWidget);

    final shortHold =
        await tester.startGesture(tester.getCenter(buttonFinder));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Keep holding...'), findsOneWidget);
    await shortHold.up();
    await tester.pump();

    expect(find.text('Select Emergency Type'), findsNothing);
    expect(find.text('Hold for 10 seconds to activate emergency alert'), findsOneWidget);

    final fullHold = await tester.startGesture(tester.getCenter(buttonFinder));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10100));
    await tester.pump();
    await fullHold.up();
    await tester.pumpAndSettle();

    expect(find.text('Select Emergency Type'), findsOneWidget);
    expect(find.text('Choose the type of emergency'), findsOneWidget);
    expect(find.text('Medical Emergency'), findsOneWidget);
    expect(find.text('Safety/Security'), findsOneWidget);
    expect(find.text('Fire Emergency'), findsOneWidget);

    await tester.tap(find.text('Medical Emergency'));
    await tester.pumpAndSettle();

    expect(find.text('Describe Situation'), findsOneWidget);
    expect(find.text('Select one or skip to send immediately'), findsOneWidget);
    expect(find.text('Unconscious'), findsOneWidget);
    expect(find.text('Breathing problem'), findsOneWidget);
    expect(find.text('Send Without Description'), findsOneWidget);

    await tester.ensureVisible(find.text('Send Without Description'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Without Description'));
    await tester.pump();

    expect(find.text('Sending Emergency Alert...'), findsOneWidget);
    expect(find.text('Location transmitted'), findsOneWidget);
  });

  testWidgets('offline SOS redirects to offline emergency page', (tester) async {
    await tester.pumpWidget(
      CrisisLinkApp(connectivityService: const FakeConnectivityService(false)),
    );
    await tester.pump(LaunchScreen.displayDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final buttonFinder = find.byType(SosEmergencyButton);
    final fullHold = await tester.startGesture(tester.getCenter(buttonFinder));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10100));
    await tester.pump();
    await fullHold.up();
    await tester.pumpAndSettle();

    expect(find.text('Offline Emergency Mode'), findsOneWidget);
    expect(find.text('Calling 112'), findsOneWidget);
    expect(find.text('Sending Family Alert'), findsOneWidget);
    expect(find.text('Sharing Last Known Location'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });
}
