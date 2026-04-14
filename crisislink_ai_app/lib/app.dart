import 'package:flutter/material.dart';

import 'screens/launch_screen.dart';
import 'services/connectivity_service.dart';
import 'services/location_service.dart';
import 'services/sos_api_service.dart';
import 'services/user_session_service.dart';
import 'theme/app_theme.dart';

class CrisisLinkApp extends StatelessWidget {
  const CrisisLinkApp({
    super.key,
    this.connectivityService = const DefaultConnectivityService(),
    this.locationService = const DefaultLocationService(),
    this.sosApiService = const SosApiService(),
    this.userSessionService = const DefaultUserSessionService(),
  });

  final ConnectivityService connectivityService;
  final LocationService locationService;
  final SosApiService sosApiService;
  final UserSessionService userSessionService;

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
        userSessionService: userSessionService,
      ),
    );
  }
}
