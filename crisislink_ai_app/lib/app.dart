import 'package:flutter/material.dart';

import 'screens/emergency_type_page.dart';
import 'screens/launch_screen.dart';
import 'screens/offline_emergency_page.dart';
import 'screens/sos_home_page.dart';
import 'services/connectivity_service.dart';
import 'theme/app_theme.dart';

class CrisisLinkApp extends StatelessWidget {
  const CrisisLinkApp({
    super.key,
    this.connectivityService = const DefaultConnectivityService(),
  });

  final ConnectivityService connectivityService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrisisLink AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: LaunchScreen(connectivityService: connectivityService),
      routes: {
        SosHomePage.routeName: (_) =>
            SosHomePage(connectivityService: connectivityService),
        EmergencyTypePage.routeName: (_) => const EmergencyTypePage(),
        OfflineEmergencyPage.routeName: (_) => const OfflineEmergencyPage(),
      },
    );
  }
}
