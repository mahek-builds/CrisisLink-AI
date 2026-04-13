import 'package:crisislink_ai_app/app.dart';
import 'package:crisislink_ai_app/screens/launch_screen.dart';
import 'package:crisislink_ai_app/widgets/sos_emergency_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('launch screen redirects to SOS home screen', (tester) async {
    await tester.pumpWidget(const CrisisLinkApp());

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
    await tester.pumpWidget(const CrisisLinkApp());
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

  testWidgets('SOS requires a full 3 second hold to activate', (tester) async {
    await tester.pumpWidget(const CrisisLinkApp());
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

    expect(find.text('LIVE'), findsNothing);
    expect(
      find.byKey(const Key('sos-hint-text')),
      findsOneWidget,
    );
    expect(
      find.text('Hold for 3 seconds to activate emergency alert'),
      findsOneWidget,
    );

    final fullHold = await tester.startGesture(tester.getCenter(buttonFinder));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump();
    await fullHold.up();
    await tester.pump();

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Emergency Alert Sent'), findsOneWidget);
    expect(
      find.text('Emergency alert is active. Stay on this screen for updates.'),
      findsOneWidget,
    );
    expect(
      find.text('Emergency alert activated. Dispatch has been notified.'),
      findsOneWidget,
    );
  });
}
