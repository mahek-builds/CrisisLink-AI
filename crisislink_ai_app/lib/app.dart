import 'package:flutter/material.dart';

import 'screens/emergency_type_page.dart';
import 'screens/launch_screen.dart';
import 'screens/offline_emergency_page.dart';
import 'screens/sos_home_page.dart';
import 'services/connectivity_service.dart';
import 'services/location_service.dart';
import 'services/sos_api_service.dart';
import 'theme/app_theme.dart';

class CrisisLinkApp extends StatelessWidget {
  const CrisisLinkApp({
    super.key,
    this.connectivityService = const DefaultConnectivityService(),
    this.locationService = const DefaultLocationService(),
    this.sosApiService = const SosApiService(),
  });

  final ConnectivityService connectivityService;
  final LocationService locationService;
  final SosApiService sosApiService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrisisLink AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: LaunchScreen(
        connectivityService: connectivityService,
        locationService: locationService,
        sosApiService: sosApiService,
      ),
      routes: {
        SosHomePage.routeName: (_) => SosHomePage(
              connectivityService: connectivityService,
              locationService: locationService,
              sosApiService: sosApiService,
            ),
        EmergencyTypePage.routeName: (_) => EmergencyTypePage(
              locationService: locationService,
              sosApiService: sosApiService,
            ),
        OfflineEmergencyPage.routeName: (_) => const OfflineEmergencyPage(),
      },
    );
  }
}
